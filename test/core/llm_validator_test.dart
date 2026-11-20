import 'dart:convert';

import 'package:billing_shield/core/constants/app_strings.dart';
import 'package:billing_shield/core/engine/billing_analyzer.dart';
import 'package:billing_shield/core/engine/llm_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  final analyzer = BillingAnalyzer();
  const sampleCsv = 'datetime,type,number,duration_sec,mb,cost_som\n'
      '2026-09-05 13:05:00,subscription,4545,0,0,15.00\n'
      '2026-09-10 02:15:30,content,4545,0,0,25.00\n';

  final result = analyzer.analyzeCsvString(sampleCsv, sourceName: 'sample.csv');
  final facts = VerifiedFacts.fromResult(result);

  group('LlmResponseValidator anti-hallucination checks', () {
    test('accepts response grounded strictly in verified facts', () {
      const candidate =
          '1. За период 2 дн. потрачено 40.00 сом, переплата составила 40.00 сом.\n'
          '2. Обнаружено 2 аномалии: 2026-09-05 (подписка на номер 4545 на 15.00 сом) '
          'и ночное списание 2026-09-10 02:15:30 на 25.00 сом.';

      final validation = LlmResponseValidator.validate(candidate, facts);
      expect(validation.isValid, isTrue, reason: validation.violations.join(', '));
    });

    test('rejects hallucinated monetary amount', () {
      const candidate = 'Вы потратили 40.00 сом, но возможный возврат 999.99 сом.';
      final validation = LlmResponseValidator.validate(candidate, facts);
      expect(validation.isValid, isFalse);
      expect(validation.violations, contains('unverified_number:999.99'));
    });

    test('rejects hallucinated phone number or short code', () {
      const candidate = 'Списание прошло на номер +996777000111 и короткий номер 8888.';
      final validation = LlmResponseValidator.validate(candidate, facts);
      expect(validation.isValid, isFalse);
      expect(validation.violations, contains('unverified_phone:+996777000111'));
      expect(validation.violations, contains('unverified_short_code:8888'));
    });

    test('rejects hallucinated date', () {
      const candidate = 'Аномалия зафиксирована 2026-12-31 на сумму 15.00 сом.';
      final validation = LlmResponseValidator.validate(candidate, facts);
      expect(validation.isValid, isFalse);
      expect(validation.violations, contains('unverified_date:2026-12-31'));
    });
  });

  group('LlmService automatic deterministic fallback', () {
    test('falls back to deterministic template when Gemini returns hallucinated numbers', () async {
      final mockClient = MockClient((request) async {
        return http.Response.bytes(
          utf8.encode(
            jsonEncode(<String, dynamic>{
              'candidates': <Map<String, dynamic>>[
                <String, dynamic>{
                  'content': <String, dynamic>{
                    'parts': <Map<String, dynamic>>[
                      <String, dynamic>{
                        'text': 'Ваша переплата равна 777.00 сом!',
                      },
                    ],
                  },
                },
              ],
            }),
          ),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = LlmService(client: mockClient);
      final out = await service.generateSummary(
        result,
        config: const LlmConfig(
          provider: LlmProvider.gemini,
          apiKey: 'fake-key',
        ),
        language: AppLanguage.ru,
      );

      expect(out.usedLlm, isFalse);
      expect(out.usedFallback, isTrue);
      expect(out.text, equals(result.summaryRu));
      expect(out.rejectionReasons, contains('unverified_number:777.00'));
    });

    test('returns verified Gemini summary when response passes validator', () async {
      final mockClient = MockClient((request) async {
        return http.Response.bytes(
          utf8.encode(
            jsonEncode(<String, dynamic>{
              'candidates': <Map<String, dynamic>>[
                <String, dynamic>{
                  'content': <String, dynamic>{
                    'parts': <Map<String, dynamic>>[
                      <String, dynamic>{
                        'text': 'Всего потрачено 40.00 сом, переплата 40.00 сом по номеру 4545.',
                      },
                    ],
                  },
                },
              ],
            }),
          ),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = LlmService(client: mockClient);
      final out = await service.generateSummary(
        result,
        config: const LlmConfig(
          provider: LlmProvider.gemini,
          apiKey: 'fake-key',
        ),
        language: AppLanguage.ru,
      );

      expect(out.usedLlm, isTrue);
      expect(out.usedFallback, isFalse);
      expect(out.rejectionReasons, isEmpty);
      expect(out.text, contains('40.00'));
    });
  });
}
