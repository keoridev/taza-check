import '../../domain/entities/anomaly.dart';
import '../../domain/entities/billing_record.dart';
import '../../domain/entities/dropped_row.dart';

/// Supported UI and legal claim languages.
enum AppLanguage {
  ru('ru', 'РУС'),
  ky('ky', 'КЫР'),
  en('en', 'ENG');

  const AppLanguage(this.code, this.shortLabel);

  final String code;
  final String shortLabel;
}

/// Centralized Russian, Kyrgyz, and English copy for domain & presentation layers.
abstract final class AppStrings {
  /// Compact trilingual lookup helper.
  static String tr(
    AppLanguage lang, {
    required String ru,
    required String ky,
    required String en,
  }) {
    return switch (lang) {
      AppLanguage.ru => ru,
      AppLanguage.ky => ky,
      AppLanguage.en => en,
    };
  }

  static String appTitle(AppLanguage lang) => switch (lang) {
        AppLanguage.ru => 'Где мои деньги?',
        AppLanguage.ky => 'Менин акчам кайда?',
        AppLanguage.en => 'Where is my money?',
      };

  static String appSubtitle(AppLanguage lang) => switch (lang) {
        AppLanguage.ru => 'Семейный финансовый щит',
        AppLanguage.ky => 'Үй-бүлөлүк каржы калканы',
        AppLanguage.en => 'Family Financial Shield',
      };

  static String currency(AppLanguage lang) =>
      lang == AppLanguage.en ? 'KGS' : 'сом';

  static String categoryLabel(BillingType type, AppLanguage lang) {
    return switch ((type, lang)) {
      (BillingType.call, AppLanguage.ru) => 'Звонки',
      (BillingType.call, AppLanguage.ky) => 'Чалуулар',
      (BillingType.call, AppLanguage.en) => 'Calls',
      (BillingType.sms, _) => 'SMS',
      (BillingType.data, AppLanguage.ru) => 'Интернет',
      (BillingType.data, AppLanguage.ky) => 'Интернет',
      (BillingType.data, AppLanguage.en) => 'Internet',
      (BillingType.subscription, AppLanguage.ru) => 'Подписки',
      (BillingType.subscription, AppLanguage.ky) => 'Жазылуулар',
      (BillingType.subscription, AppLanguage.en) => 'Subscriptions',
      (BillingType.content, AppLanguage.ru) => 'Контент-услуги',
      (BillingType.content, AppLanguage.ky) => 'Контент кызматтар',
      (BillingType.content, AppLanguage.en) => 'Content services',
    };
  }

  static String anomalyTitle(AnomalyType type, AppLanguage lang) {
    return switch ((type, lang)) {
      (AnomalyType.daySpike, AppLanguage.ru) => 'Резкий всплеск за день',
      (AnomalyType.daySpike, AppLanguage.ky) => 'Күндүк кескин өсүш',
      (AnomalyType.daySpike, AppLanguage.en) => 'Daily spend spike',
      (AnomalyType.nightCharge, AppLanguage.ru) => 'Ночное списание',
      (AnomalyType.nightCharge, AppLanguage.ky) => 'Түнкү акча алуу',
      (AnomalyType.nightCharge, AppLanguage.en) => 'Night charge',
      (AnomalyType.newSubscription, AppLanguage.ru) => 'Новая платная подписка',
      (AnomalyType.newSubscription, AppLanguage.ky) =>
        'Жаңы акы төлөнүүчү жазылуу',
      (AnomalyType.newSubscription, AppLanguage.en) => 'New paid subscription',
      (AnomalyType.duplicateCharge, AppLanguage.ru) => 'Двойное списание',
      (AnomalyType.duplicateCharge, AppLanguage.ky) => 'Эки жолу алынган төлөм',
      (AnomalyType.duplicateCharge, AppLanguage.en) => 'Duplicate charge',
      (AnomalyType.internationalRate, AppLanguage.ru) =>
        'Дорогой международный звонок',
      (AnomalyType.internationalRate, AppLanguage.ky) =>
        'Кымбат эл аралык чалуу',
      (AnomalyType.internationalRate, AppLanguage.en) =>
        'High international rate',
    };
  }

  static String dropReasonLabel(DropReason reason, AppLanguage lang) {
    return switch ((reason, lang)) {
      (DropReason.emptyLine, AppLanguage.ru) => 'Пустая строка',
      (DropReason.emptyLine, AppLanguage.ky) => 'Бош сап',
      (DropReason.emptyLine, AppLanguage.en) => 'Empty line',
      (DropReason.columnCount, AppLanguage.ru) => 'Неверное число колонок (≠ 6)',
      (DropReason.columnCount, AppLanguage.ky) =>
        'Тилкелер саны туура эмес (≠ 6)',
      (DropReason.columnCount, AppLanguage.en) => 'Invalid column count (≠ 6)',
      (DropReason.unknownType, AppLanguage.ru) => 'Неизвестный тип операции',
      (DropReason.unknownType, AppLanguage.ky) => 'Белгисиз операция түрү',
      (DropReason.unknownType, AppLanguage.en) => 'Unknown operation type',
      (DropReason.badDatetime, AppLanguage.ru) => 'Некорректная дата или время',
      (DropReason.badDatetime, AppLanguage.ky) => 'Туура эмес дата же убакыт',
      (DropReason.badDatetime, AppLanguage.en) => 'Invalid date or time',
      (DropReason.badNumber, AppLanguage.ru) => 'Некорректное число / сумма',
      (DropReason.badNumber, AppLanguage.ky) => 'Туура эмес сан же сумма',
      (DropReason.badNumber, AppLanguage.en) => 'Invalid number / amount',
    };
  }

  static List<String> navLabels(AppLanguage lang) => switch (lang) {
        AppLanguage.ru => const [
            'Обзор',
            'Аномалии',
            'Семейный щит',
            'Подбор тарифа',
            'Заявление и экспорт',
          ],
        AppLanguage.ky => const [
            'Жалпы сереп',
            'Аномалиялар',
            'Үй-бүлөлүк калкан',
            'Тариф тандоо',
            'Арыз жана экспорт',
          ],
        AppLanguage.en => const [
            'Overview',
            'Anomalies',
            'Family Shield',
            'Tariff Optimizer',
            'Claim & Export',
          ],
      };

  static List<String> compactNavLabels(AppLanguage lang) => switch (lang) {
        AppLanguage.ru => const [
            'Обзор',
            'Аномалии',
            'Семья',
            'Тарифы',
            'Заявление',
          ],
        AppLanguage.ky => const [
            'Сереп',
            'Аномалия',
            'Үй-бүлө',
            'Тариф',
            'Арыз',
          ],
        AppLanguage.en => const [
            'Home',
            'Alerts',
            'Family',
            'Plans',
            'Claim',
          ],
      };
}
