import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/analysis_result.dart';
import '../constants/app_strings.dart';
import '../utils/decimal_utils.dart';
import '../utils/phone_normalizer.dart';

/// Optional LLM backend provider.
enum LlmProvider {
  none,
  gemini,
  ollama,
}

/// Configuration for optional LLM-generated subscriber explanations.
class LlmConfig {
  const LlmConfig({
    this.provider = LlmProvider.none,
    this.apiKey = '',
    this.model = 'gemini-2.5-flash',
    this.ollamaBaseUrl = 'http://localhost:11434',
  });

  final LlmProvider provider;
  final String apiKey;
  final String model;
  final String ollamaBaseUrl;
}

/// Deterministic set of verified facts extracted from an [AnalysisResult].
class VerifiedFacts {
  VerifiedFacts({
    required this.allowedDates,
    required this.allowedTimes,
    required this.allowedPhones,
    required this.allowedNumbers,
    required this.maxListOrdinal,
  });

  final Set<String> allowedDates;
  final Set<String> allowedTimes;
  final Set<String> allowedPhones;
  final Set<Decimal> allowedNumbers;
  final int maxListOrdinal;

  /// Builds verified ground-truth sets from [result].
  factory VerifiedFacts.fromResult(AnalysisResult result) {
    final dates = <String>{};
    final times = <String>{'00:00:00', '05:59:59', '06:00:00'};
    final phones = <String>{};
    final numbers = <Decimal>{
      Decimal.zero,
      Decimal.fromInt(3),
      Decimal.fromInt(6),
      Decimal.fromInt(7),
      Decimal.fromInt(12),
      Decimal.fromInt(20),
      Decimal.fromInt(60),
      Decimal.fromInt(result.records.length),
      Decimal.fromInt(result.droppedRows.length),
      Decimal.fromInt(result.anomalies.length),
      Decimal.fromInt(result.report.periodDays),
      Decimal.fromInt(result.report.totalSmsCount),
    };

    void addDecimalVariants(Decimal d) {
      numbers.add(d);
      numbers.add(d.round(scale: 2));
      numbers.add(d.round(scale: 1));
    }

    void addDateVariants(String yyyyMmDd) {
      dates.add(yyyyMmDd);
      final parts = yyyyMmDd.split('-');
      if (parts.length == 3) {
        dates.add('${parts[2]}.${parts[1]}.${parts[0]}');
      }
    }

    addDecimalVariants(result.report.totalSpendSom);
    addDecimalVariants(result.totalOverchargeSom);
    addDecimalVariants(result.annualLeakSom);
    addDecimalVariants(result.report.subscriptionSpendSom);
    addDecimalVariants(result.report.totalCallMinutes);
    addDecimalVariants(result.report.totalDataMb);

    for (final val in result.report.byCategory.values) {
      addDecimalVariants(val);
    }

    for (final day in result.report.byDay) {
      addDateVariants(day.date);
      addDecimalVariants(day.totalSom);
      numbers.add(Decimal.fromInt(day.recordCount));
    }

    for (final numSpend in result.report.topNumbers) {
      phones.add(numSpend.normalizedNumber);
      addDecimalVariants(numSpend.totalSom);
      numbers.add(Decimal.fromInt(numSpend.count));
      final asDec = Decimal.tryParse(numSpend.normalizedNumber);
      if (asDec != null) numbers.add(asDec);
    }

    for (final record in result.records) {
      final datePart = record.formattedDatetime.substring(0, 10);
      final timePart = record.formattedDatetime.substring(11, 19);
      addDateVariants(datePart);
      times.add(timePart);
      if (record.normalizedNumber.isNotEmpty) {
        phones.add(record.normalizedNumber);
      }
      if (isShortCode(record.rawNumber)) {
        final sc = cleanPhone(record.rawNumber);
        phones.add(sc);
        final scNum = Decimal.tryParse(sc);
        if (scNum != null) numbers.add(scNum);
      }
      addDecimalVariants(record.costSom);
      addDecimalVariants(record.durationSec);
      addDecimalVariants(record.mb);
      numbers.add(Decimal.fromInt(record.rowNumber));
    }

    for (final anomaly in result.anomalies) {
      final datePart = anomaly.datetime.length >= 10
          ? anomaly.datetime.substring(0, 10)
          : anomaly.datetime;
      addDateVariants(datePart);
      if (anomaly.datetime.length >= 19) {
        times.add(anomaly.datetime.substring(11, 19));
      }
      if (anomaly.number != null && anomaly.number!.isNotEmpty) {
        phones.add(normalizePhone(anomaly.number!));
        phones.add(cleanPhone(anomaly.number!));
        final nDec = Decimal.tryParse(cleanPhone(anomaly.number!));
        if (nDec != null) numbers.add(nDec);
      }
      addDecimalVariants(anomaly.costSom);
      addDecimalVariants(anomaly.overchargeSom);
      if (anomaly.rowNumber != null) {
        numbers.add(Decimal.fromInt(anomaly.rowNumber!));
      }
      if (anomaly.baselineMeanSom != null) {
        addDecimalVariants(anomaly.baselineMeanSom!);
      }
      if (anomaly.zScore != null) {
        addDecimalVariants(Decimal.parse(anomaly.zScore!.toStringAsFixed(2)));
        addDecimalVariants(Decimal.parse(anomaly.zScore!.toStringAsFixed(1)));
      }
    }

    final maxOrdinal = result.anomalies.length > 10 ? result.anomalies.length : 10;

    return VerifiedFacts(
      allowedDates: dates,
      allowedTimes: times,
      allowedPhones: phones,
      allowedNumbers: numbers,
      maxListOrdinal: maxOrdinal,
    );
  }
}

/// Output of validating an LLM response against [VerifiedFacts].
class LlmValidationResult {
  const LlmValidationResult({
    required this.isValid,
    required this.violations,
  });

  final bool isValid;
  final List<String> violations;
}

/// Strict anti-hallucination validator rejecting any invented dates, phones,
/// short codes, or numeric amounts not grounded in [VerifiedFacts].
abstract final class LlmResponseValidator {
  static final _isoDateRegex = RegExp(r'\b\d{4}-\d{2}-\d{2}\b');
  static final _dotDateRegex = RegExp(r'\b\d{2}\.\d{2}\.\d{4}\b');
  static final _timeRegex = RegExp(r'\b\d{2}:\d{2}:\d{2}\b');
  static final _phoneRegex = RegExp(
    r'(?:\+\d[\d\s\-()]{6,}\d|\b00996\d{6,}\b|\b996\d{6,}\b|\b0[2-9]\d{8}\b)',
  );
  static final _shortCodeContextRegex = RegExp(
    r'(?:короткий номер|номер|кыска номер|на)\s+(\d{3,6})\b',
    caseSensitive: false,
  );
  static final _leadingOrdinalRegex = RegExp(
    r'^(\s*)(\d+)([.)]\s+(?!сом|KGS|с\.|%|мин|сек|МБ|ГБ))',
    multiLine: true,
    caseSensitive: false,
  );
  static final _numberRegex = RegExp(r'(?:(?<=^|\s)-\d+(?:[.,]\d+)?|\b\d+(?:[.,]\d+)?)');

  /// Validates [text] against [facts]. Any unverified token triggers rejection.
  static LlmValidationResult validate(String text, VerifiedFacts facts) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const LlmValidationResult(
        isValid: false,
        violations: <String>['empty_response'],
      );
    }

    final violations = <String>[];
    var scrubbed = trimmed;

    // 1. Validate dates (`YYYY-MM-DD` and `DD.MM.YYYY`).
    scrubbed = scrubbed.replaceAllMapped(_isoDateRegex, (m) {
      final token = m.group(0)!;
      if (!facts.allowedDates.contains(token)) {
        violations.add('unverified_date:$token');
      }
      return ' ';
    });

    scrubbed = scrubbed.replaceAllMapped(_dotDateRegex, (m) {
      final token = m.group(0)!;
      if (!facts.allowedDates.contains(token)) {
        violations.add('unverified_date:$token');
      }
      return ' ';
    });

    // 2. Validate explicit timestamps (`HH:MM:SS`).
    scrubbed = scrubbed.replaceAllMapped(_timeRegex, (m) {
      final token = m.group(0)!;
      if (!facts.allowedTimes.contains(token)) {
        violations.add('unverified_time:$token');
      }
      return ' ';
    });

    // 3. Validate full phone numbers.
    scrubbed = scrubbed.replaceAllMapped(_phoneRegex, (m) {
      final raw = m.group(0)!;
      final normalized = normalizePhone(raw);
      if (!facts.allowedPhones.contains(normalized)) {
        violations.add('unverified_phone:$raw');
      }
      return ' ';
    });

    // 4. Validate short codes explicitly mentioned as phone/short numbers.
    for (final m in _shortCodeContextRegex.allMatches(scrubbed)) {
      final code = m.group(1)!;
      if (!facts.allowedPhones.contains(code)) {
        violations.add('unverified_short_code:$code');
      }
    }

    // 5. Strip safe bullet ordinals (`1. ...`, `2) ...`) before numeric sweep.
    scrubbed = scrubbed.replaceAllMapped(_leadingOrdinalRegex, (m) {
      final ord = int.tryParse(m.group(2)!);
      if (ord != null && ord >= 1 && ord <= facts.maxListOrdinal) {
        return '${m.group(1)} ';
      }
      return m.group(0)!;
    });

    // 6. Validate every remaining numeric token.
    for (final m in _numberRegex.allMatches(scrubbed)) {
      final rawNum = m.group(0)!;
      final normalized = rawNum.replaceAll(',', '.');
      final parsed = Decimal.tryParse(normalized);
      if (parsed == null || !facts.allowedNumbers.contains(parsed)) {
        violations.add('unverified_number:$rawNum');
      }
    }

    return LlmValidationResult(
      isValid: violations.isEmpty,
      violations: violations,
    );
  }
}

/// Result returned by [LlmService.generateSummary].
class LlmSummaryResult {
  const LlmSummaryResult({
    required this.text,
    required this.usedLlm,
    required this.usedFallback,
    required this.rejectionReasons,
  });

  final String text;
  final bool usedLlm;
  final bool usedFallback;
  final List<String> rejectionReasons;
}

/// Optional Gemini / Ollama summary generator protected by [LlmResponseValidator].
class LlmService {
  LlmService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Generates a summary via configured LLM and falls back instantaneously to
  /// the deterministic template if any network error or hallucination occurs.
  Future<LlmSummaryResult> generateSummary(
    AnalysisResult result, {
    required LlmConfig config,
    required AppLanguage language,
  }) async {
    final fallbackText =
        language == AppLanguage.ru ? result.summaryRu : result.summaryKy;

    if (config.provider == LlmProvider.none) {
      return LlmSummaryResult(
        text: fallbackText,
        usedLlm: false,
        usedFallback: false,
        rejectionReasons: const <String>[],
      );
    }

    if (config.provider == LlmProvider.gemini && config.apiKey.trim().isEmpty) {
      return LlmSummaryResult(
        text: fallbackText,
        usedLlm: false,
        usedFallback: true,
        rejectionReasons: const <String>['missing_gemini_api_key'],
      );
    }

    try {
      final prompt = _buildPrompt(result, language);
      final candidate = switch (config.provider) {
        LlmProvider.gemini => await _callGemini(config, prompt),
        LlmProvider.ollama => await _callOllama(config, prompt),
        LlmProvider.none => '',
      };

      final facts = VerifiedFacts.fromResult(result);
      final validation = LlmResponseValidator.validate(candidate, facts);
      if (!validation.isValid) {
        return LlmSummaryResult(
          text: fallbackText,
          usedLlm: false,
          usedFallback: true,
          rejectionReasons: validation.violations,
        );
      }

      return LlmSummaryResult(
        text: candidate.trim(),
        usedLlm: true,
        usedFallback: false,
        rejectionReasons: const <String>[],
      );
    } catch (e) {
      return LlmSummaryResult(
        text: fallbackText,
        usedLlm: false,
        usedFallback: true,
        rejectionReasons: <String>['llm_error:$e'],
      );
    }
  }

  Future<String> _callGemini(LlmConfig config, String prompt) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/${config.model}:generateContent',
    );
    final response = await _client
        .post(
          uri,
          headers: <String, String>{
            'Content-Type': 'application/json',
            'x-goog-api-key': config.apiKey.trim(),
          },
          body: jsonEncode(<String, dynamic>{
            'contents': <Map<String, dynamic>>[
              <String, dynamic>{
                'parts': <Map<String, dynamic>>[
                  <String, dynamic>{'text': prompt},
                ],
              },
            ],
            'generationConfig': <String, dynamic>{
              'temperature': 0.1,
              'maxOutputTokens': 280,
            },
          }),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(
      utf8.decode(response.bodyBytes, allowMalformed: true),
    ) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      return '';
    }
    final content =
        (candidates.first as Map<String, dynamic>)['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) {
      return '';
    }
    return ((parts.first as Map<String, dynamic>)['text'] as String?) ?? '';
  }

  Future<String> _callOllama(LlmConfig config, String prompt) async {
    final base = config.ollamaBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/api/generate');
    final response = await _client
        .post(
          uri,
          headers: const <String, String>{'Content-Type': 'application/json'},
          body: jsonEncode(<String, dynamic>{
            'model': config.model,
            'prompt': prompt,
            'stream': false,
          }),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(
      utf8.decode(response.bodyBytes, allowMalformed: true),
    ) as Map<String, dynamic>;
    return (decoded['response'] as String?) ?? '';
  }

  String _buildPrompt(AnalysisResult result, AppLanguage language) {
    final langName = language == AppLanguage.ru ? 'Russian' : 'Kyrgyz';
    final anomalyLines = result.anomalies
        .map(
          (a) =>
              '- ${a.datetime} | ${a.type.wireName} | number=${a.number ?? "-"} | cost=${formatSom(a.costSom)} | overcharge=${formatSom(a.overchargeSom)}',
        )
        .join('\n');

    return 'Summarize this telecom billing audit in $langName in 3 concise sentences. '
        'STRICT RULE: Use ONLY the exact numbers, dates, and phone numbers provided below. '
        'Do NOT invent any new amounts, dates, percentages, or phone numbers.\n'
        'Facts:\n'
        'period_days=${result.report.periodDays}\n'
        'total_spend_som=${formatSom(result.report.totalSpendSom)}\n'
        'total_overcharge_som=${formatSom(result.totalOverchargeSom)}\n'
        'annual_leak_som=${formatSom(result.annualLeakSom)}\n'
        'anomaly_count=${result.anomalies.length}\n'
        'dropped_rows=${result.droppedRows.length}\n'
        'anomalies:\n$anomalyLines';
  }
}
