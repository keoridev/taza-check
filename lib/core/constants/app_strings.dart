import '../../domain/entities/anomaly.dart';
import '../../domain/entities/billing_record.dart';
import '../../domain/entities/dropped_row.dart';

/// Supported UI and legal claim languages.
enum AppLanguage {
  ru('ru', 'РУС'),
  ky('ky', 'КЫР');

  const AppLanguage(this.code, this.shortLabel);

  final String code;
  final String shortLabel;
}

/// Centralized Russian and Kyrgyz copy for domain & presentation layers.
abstract final class AppStrings {
  static String appTitle(AppLanguage lang) => lang == AppLanguage.ru
      ? 'Где мои деньги?'
      : 'Менин акчам кайда?';

  static String appSubtitle(AppLanguage lang) => lang == AppLanguage.ru
      ? 'Семейный финансовый щит'
      : 'Үй-бүлөлүк каржы калканы';

  static String categoryLabel(BillingType type, AppLanguage lang) {
    return switch ((type, lang)) {
      (BillingType.call, AppLanguage.ru) => 'Звонки',
      (BillingType.call, AppLanguage.ky) => 'Чалуулар',
      (BillingType.sms, AppLanguage.ru) => 'SMS',
      (BillingType.sms, AppLanguage.ky) => 'SMS',
      (BillingType.data, AppLanguage.ru) => 'Интернет',
      (BillingType.data, AppLanguage.ky) => 'Интернет',
      (BillingType.subscription, AppLanguage.ru) => 'Подписки',
      (BillingType.subscription, AppLanguage.ky) => 'Жазылуулар',
      (BillingType.content, AppLanguage.ru) => 'Контент-услуги',
      (BillingType.content, AppLanguage.ky) => 'Контент кызматтар',
    };
  }

  static String anomalyTitle(AnomalyType type, AppLanguage lang) {
    return switch ((type, lang)) {
      (AnomalyType.daySpike, AppLanguage.ru) => 'Резкий всплеск за день',
      (AnomalyType.daySpike, AppLanguage.ky) => 'Күндүк кескин өсүш',
      (AnomalyType.nightCharge, AppLanguage.ru) => 'Ночное списание',
      (AnomalyType.nightCharge, AppLanguage.ky) => 'Түнкү акча алуу',
      (AnomalyType.newSubscription, AppLanguage.ru) => 'Новая платная подписка',
      (AnomalyType.newSubscription, AppLanguage.ky) => 'Жаңы акы төлөнүүчү жазылуу',
      (AnomalyType.duplicateCharge, AppLanguage.ru) => 'Двойное списание',
      (AnomalyType.duplicateCharge, AppLanguage.ky) => 'Эки жолу алынган төлөм',
      (AnomalyType.internationalRate, AppLanguage.ru) => 'Дорогой международный звонок',
      (AnomalyType.internationalRate, AppLanguage.ky) => 'Кымбат эл аралык чалуу',
    };
  }

  static String dropReasonLabel(DropReason reason, AppLanguage lang) {
    return switch ((reason, lang)) {
      (DropReason.emptyLine, AppLanguage.ru) => 'Пустая строка',
      (DropReason.emptyLine, AppLanguage.ky) => 'Бош сап',
      (DropReason.columnCount, AppLanguage.ru) => 'Неверное число колонок (≠ 6)',
      (DropReason.columnCount, AppLanguage.ky) => 'Тилкелер саны туура эмес (≠ 6)',
      (DropReason.unknownType, AppLanguage.ru) => 'Неизвестный тип операции',
      (DropReason.unknownType, AppLanguage.ky) => 'Белгисиз операция түрү',
      (DropReason.badDatetime, AppLanguage.ru) => 'Некорректная дата или время',
      (DropReason.badDatetime, AppLanguage.ky) => 'Туура эмес дата же убакыт',
      (DropReason.badNumber, AppLanguage.ru) => 'Некорректное число / сумма',
      (DropReason.badNumber, AppLanguage.ky) => 'Туура эмес сан же сумма',
    };
  }

  static List<String> navLabels(AppLanguage lang) => lang == AppLanguage.ru
      ? const [
          'Обзор',
          'Аномалии',
          'Семейный щит',
          'Подбор тарифа',
          'Заявление и экспорт',
        ]
      : const [
          'Жалпы сереп',
          'Аномалиялар',
          'Үй-бүлөлүк калкан',
          'Тариф тандоо',
          'Арыз жана экспорт',
        ];

  static List<String> compactNavLabels(AppLanguage lang) => lang == AppLanguage.ru
      ? const [
          'Обзор',
          'Аномалии',
          'Семья',
          'Тарифы',
          'Заявление',
        ]
      : const [
          'Сереп',
          'Аномалия',
          'Үй-бүлө',
          'Тариф',
          'Арыз',
        ];
}
