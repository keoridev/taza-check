import '../../domain/entities/anomaly.dart';
import '../constants/app_strings.dart';
import '../utils/date_utils.dart';
import '../utils/decimal_utils.dart';
import 'explainer.dart';

/// Subscriber details used to populate a legal pre-trial claim (`claim.txt`).
class SubscriberInfo {
  const SubscriberInfo({
    required this.fullName,
    required this.phone,
    required this.operatorName,
    this.city = 'г. Бишкек',
  });

  final String fullName;
  final String phone;
  final String operatorName;
  final String city;

  SubscriberInfo copyWith({
    String? fullName,
    String? phone,
    String? operatorName,
    String? city,
  }) {
    return SubscriberInfo(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      operatorName: operatorName ?? this.operatorName,
      city: city ?? this.city,
    );
  }
}

/// Generates legal pre-trial dispute claims referencing Kyrgyz consumer protection law.
class ClaimGenerator {
  /// Generates `claim.txt` in Russian or Kyrgyz for [selectedAnomalies].
  String generateClaim({
    required SubscriberInfo subscriber,
    required List<Anomaly> selectedAnomalies,
    required AppLanguage language,
    DateTime? date,
  }) {
    final now = date ?? DateTime.now();
    final formattedDate = formatDate(now);
    final refundTotal = Explainer.calculateTotalOvercharge(selectedAnomalies);
    final refundStr = formatSom(refundTotal);

    if (language == AppLanguage.ky) {
      return _buildKyrgyzClaim(
        subscriber: subscriber,
        anomalies: selectedAnomalies,
        refundStr: refundStr,
        dateStr: formattedDate,
      );
    }
    return _buildRussianClaim(
      subscriber: subscriber,
      anomalies: selectedAnomalies,
      refundStr: refundStr,
      dateStr: formattedDate,
    );
  }

  String _buildRussianClaim({
    required SubscriberInfo subscriber,
    required List<Anomaly> anomalies,
    required String refundStr,
    required String dateStr,
  }) {
    final itemsBuffer = StringBuffer();
    if (anomalies.isEmpty) {
      itemsBuffer.writeln('  (Спорные списания не выбраны)');
    } else {
      for (var i = 0; i < anomalies.length; i++) {
        final a = anomalies[i];
        itemsBuffer.writeln(
          '  ${i + 1}. [${a.datetime}] ${AppStrings.anomalyTitle(a.type, AppLanguage.ru)} '
          '| Номер: ${a.number ?? "-"} | Списание: ${formatSom(a.costSom)} сом '
          '| К возврату: ${formatSom(a.overchargeSom)} сом\n'
          '     Основание: ${a.reason}',
        );
      }
    }

    return '''
В Службу поддержки абонентов / Отдел по работе с претензиями
Оператор связи: ${subscriber.operatorName}
От абонента: ${subscriber.fullName}
Абонентский номер: ${subscriber.phone}
Город: ${subscriber.city}

ДОСУДЕБНАЯ ПРЕТЕНЗИЯ
о возврате неправомерно списанных денежных средств и отключении навязанных услуг

На основании Закона Кыргызской Республики «О защите прав потребителей» (ст. 15, 27, 31) и Правил оказания услуг подвижной радиотелефонной связи КР, прошу провести перерасчёт по моему лицевому счёту (${subscriber.phone}) и вернуть ошибочно / несогласованно списанные средства.

При аудите официальной детализации выявлены следующие спорные операции:
$itemsBuffer
Итоговая сумма к возврату (без двойного учёта): $refundStr сом.

Руководствуясь ст. 15 и 31 Закона КР «О защите прав потребителей», требую в течение 10 (десяти) календарных дней с момента получения настоящей претензии:
1. Вернуть на баланс абонентского номера ${subscriber.phone} сумму в размере $refundStr сом.
2. Отключить все платные контентные и сторонние подписки, подключённые без моего явного письменного или USSD-подтверждения.
3. Предоставить официальный письменный ответ о результатах рассмотрения претензии.

В случае отказа или игнорирования претензии в установленный срок оставляю за собой право обратиться в Службу антимонопольного регулирования при Министерстве экономики и коммерции КР, ГАС КР и в суд.

Дата: $dateStr
Подпись: _____________________ / ${subscriber.fullName} /
''';
  }

  String _buildKyrgyzClaim({
    required SubscriberInfo subscriber,
    required List<Anomaly> anomalies,
    required String refundStr,
    required String dateStr,
  }) {
    final itemsBuffer = StringBuffer();
    if (anomalies.isEmpty) {
      itemsBuffer.writeln('  (Талаштуу төлөмдөр тандалган жок)');
    } else {
      for (var i = 0; i < anomalies.length; i++) {
        final a = anomalies[i];
        itemsBuffer.writeln(
          '  ${i + 1}. [${a.datetime}] ${AppStrings.anomalyTitle(a.type, AppLanguage.ky)} '
          '| Номер: ${a.number ?? "-"} | Алынган: ${formatSom(a.costSom)} сом '
          '| Кайтарууга: ${formatSom(a.overchargeSom)} сом\n'
          '     Негиздеме: ${a.explanationKy}',
        );
      }
    }

    return '''
Абоненттерди колдоо кызматына / Дооматтарды кароо бөлүмүнө
Байланыш оператору: ${subscriber.operatorName}
Абонент: ${subscriber.fullName}
Телефон номери: ${subscriber.phone}
Шаар: ${subscriber.city}

СОТКО ЧЕЙИНКИ ДООМАТ АРЫЗ
мыйзамсыз алынган каражаттарды кайтаруу жана кошулган акы төлөнүүчү кызматтарды өчүрүү жөнүндө

Кыргыз Республикасынын «Керектөөчүлөрдүн укуктарын коргоо жөнүндө» Мыйзамынын (15, 27, 31-беренелери) негизинде, ${subscriber.phone} абоненттик номери боюнча эсепти кайра карап чыгууну жана макулдашылбастан алынган каражаттарды кайтарып берүүнү талап кылам.

Детализацияны текшерүүдө төмөнкү талаштуу төлөмдөр аныкталды:
$itemsBuffer
Кайтарууга жалпы сумма (эки эселенбей эсептелди): $refundStr сом.

КР «Керектөөчүлөрдүн укуктарын коргоо жөнүндө» Мыйзамына ылайык 10 (он) календардык күндүн ичинде:
1. ${subscriber.phone} номеринин балансына $refundStr сом өлчөмүндө каражатты кайтарып берүүңүздү;
2. Менин ачык макулдугумсуз кошулган бардык акы төлөнүүчү контент жана жазылуу кызматтарын өчүрүүңүздү;
3. Расмий жазуу жүзүндөгү жооп берүүңүздү талап кылам.

Талаптар аткарылбаган учурда КР Монополияга каршы жөнгө салуу кызматына жана сотко кайрылуу укугумду сактап калам.

Дата: $dateStr
Колу: _____________________ / ${subscriber.fullName} /
''';
  }
}
