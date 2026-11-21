import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_strings.dart';
import '../theme/app_theme.dart';
import 'bee_mascot.dart';

/// Opens a warm, simple, zero-jargon 5-slide interactive tutorial ("Обучалка")
/// designed for parents, grandparents, kids, and first-time users.
Future<void> showGuideStories(
  BuildContext context, {
  required AppLanguage language,
  required VoidCallback onEnableSeniorMode,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'GuideStories',
    barrierColor: Colors.black87,
    pageBuilder: (ctx, _, _) => _GuideStoriesView(
      language: language,
      onEnableSeniorMode: onEnableSeniorMode,
    ),
  );
}

class _GuideStoriesView extends StatefulWidget {
  const _GuideStoriesView({
    required this.language,
    required this.onEnableSeniorMode,
  });

  final AppLanguage language;
  final VoidCallback onEnableSeniorMode;

  @override
  State<_GuideStoriesView> createState() => _GuideStoriesViewState();
}

class _GuideStoriesViewState extends State<_GuideStoriesView> {
  int _index = 0;
  static const int _totalSlides = 5;

  void _next() {
    HapticFeedback.selectionClick();
    if (_index < _totalSlides - 1) {
      setState(() => _index++);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prev() {
    if (_index > 0) {
      HapticFeedback.selectionClick();
      setState(() => _index--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;
    final tr = AppStrings.tr;

    final slides = <({
      MascotState mascot,
      String stepBadge,
      String title,
      String body,
      String tip,
    })>[
      (
        mascot: MascotState.seniorHelper,
        stepBadge: tr(
          lang,
          ru: 'ОБУЧАЛКА · 1 ИЗ 5',
          ky: 'КОЛДОНМО · 1 / 5',
          en: 'QUICK GUIDE · 1 OF 5',
        ),
        title: tr(
          lang,
          ru: 'Привет! Я Пчёлка-помощник',
          ky: 'Салам! Мен жардамчы аарымын',
          en: 'Hi! I am your Bee helper',
        ),
        body: tr(
          lang,
          ru: 'Я простыми словами покажу, куда уходят деньги с баланса телефона, и помогу вернуть лишние списания.',
          ky: 'Телефонуңуздан акча кайда кетип жатканын жөнөкөй тилде көрсөтүп, ашыкча алынган сомдорду кайтарууга жардам берем.',
          en: 'I show in plain words where your mobile balance goes and help you recover sneaky overcharges — no tech skills needed.',
        ),
        tip: tr(
          lang,
          ru: 'Подходит для мамы, папы, бабушки и даже школьника',
          ky: 'Апа, ата, чоң эне жана балдар үчүн абдан жеңил',
          en: 'Made easy for parents, grandparents, and kids alike',
        ),
      ),
      (
        mascot: MascotState.loader,
        stepBadge: tr(
          lang,
          ru: 'ШАГ 1 · ЗАГРУЗКА',
          ky: '1-КАДАМ · ЖҮКТӨӨ',
          en: 'STEP 1 · UPLOAD',
        ),
        title: tr(
          lang,
          ru: 'Загрузите файл от оператора',
          ky: 'Оператордун файлын жүктөңүз',
          en: 'Load your operator bill',
        ),
        body: tr(
          lang,
          ru: 'На главном экране нажмите жёлтую кнопку «Загрузить CSV» и выберите файл детализации. Даже если там есть ошибки — я сам всё очищу!',
          ky: 'Башкы беттеги сары «CSV жүктөө» баскычын басып, файлды тандаңыз. Бузук саптар болсо, мен өзүм тазалап коём!',
          en: 'Tap the yellow "Load CSV" button on the home screen and pick your bill file. Even if rows are broken, I clean them automatically!',
        ),
        tip: tr(
          lang,
          ru: 'Работает офлайн — ваши данные не уходят чужим',
          ky: 'Интернетсиз иштейт — маалыматыңыз коопсуз',
          en: 'Works offline — your personal billing data stays private',
        ),
      ),
      (
        mascot: MascotState.alert,
        stepBadge: tr(
          lang,
          ru: 'ШАГ 2 · ПОИСК УТЕЧЕК',
          ky: '2-КАДАМ · ЖОГОТУУНУ ТАБУУ',
          en: 'STEP 2 · SPOT LEAKS',
        ),
        title: tr(
          lang,
          ru: 'Ловим скрытые списания',
          ky: 'Жашыруун төлөмдөрдү кармайбыз',
          en: 'Catch sneaky charges',
        ),
        body: tr(
          lang,
          ru: 'Я проверяю каждую строчку: ночные платные SMS, повторные списания за минуту и хитрые подписки на короткие номера 4545, 7070, 7575.',
          ky: 'Ар бир сапты текшерем: түнкү акы төлөнүүчү SMS, 1 мүнөттө эки жолу алынган акча жана 4545, 7070, 7575 кыска номерлер.',
          en: 'I check every line: late-night paid SMS, double charges within 60 seconds, and quiet subscriptions to short codes like 4545 or 7070.',
        ),
        tip: tr(
          lang,
          ru: 'Показываю точную сумму до тийина без ошибок',
          ky: 'Тыйынына чейин так эсептеп берем',
          en: 'Exact Decimal math down to the last cent — zero rounding drift',
        ),
      ),
      (
        mascot: MascotState.detective,
        stepBadge: tr(
          lang,
          ru: 'ШАГ 3 · ЗАЩИТА И ВОЗВРАТ',
          ky: '3-КАДАМ · ӨЧҮРҮҮ ЖАНА КАЙТАРУУ',
          en: 'STEP 3 · BLOCK & REFUND',
        ),
        title: tr(
          lang,
          ru: 'Отключаем в одно нажатие',
          ky: 'Бир баскыч менен өчүрөбүз',
          en: 'Cancel & claim in 1 tap',
        ),
        body: tr(
          lang,
          ru: 'Нажмите на подсказку «СТОП», чтобы скопировать команду отписки, а во вкладке «Заявление» готовая претензия оператору соберётся сама!',
          ky: '«СТОП» кеңешин басып өчүрүү командасын көчүрүңүз, ал эми «Арыз» бөлүмүндө даяр арыз өзү түзүлөт!',
          en: 'Tap the "STOP" hint to copy the unsubscribe command, and open the Claim tab to generate a ready-to-send refund request in 1 tap!',
        ),
        tip: tr(
          lang,
          ru: 'А ещё во вкладке «Тарифы» можно найти тариф дешевле',
          ky: '«Тариф» бөлүмүнөн арзаныраак тариф да таба аласыз',
          en: 'Plus, check the Plans tab to save thousands of KGS per year',
        ),
      ),
      (
        mascot: MascotState.happy,
        stepBadge: tr(
          lang,
          ru: 'ШАГ 4 · ДЛЯ БАБУШКИ И РОДИТЕЛЕЙ',
          ky: '4-КАДАМ · АТА-ЭНЕ ЖАНА ЧОҢ ЭНЕ ҮЧҮН',
          en: 'STEP 4 · PARENTS & GRANDMA MODE',
        ),
        title: tr(
          lang,
          ru: 'Крупный шрифт и спокойствие',
          ky: 'Чоң шрифт жана тынчтык',
          en: 'Big text & peace of mind',
        ),
        body: tr(
          lang,
          ru: 'Включите «Режим для родителей»: на экране останутся только крупные понятные кнопки, добрые подсказки и проверка всех номеров семьи.',
          ky: '«Ата-эне режимин» күйгүзсөңүз, экранда чоң түшүнүктүү баскычтар жана үй-бүлөнүн бардык номерлерин коргоо гана калат.',
          en: 'Turn on Parents Mode for extra-large text, high-contrast buttons, and calm everyday explanations protecting the whole family.',
        ),
        tip: tr(
          lang,
          ru: 'Вы всегда можете переключить режим обратно в меню настроек',
          ky: 'Режимди жөндөөлөрдөн каалаган убакта өчүрсөңүз болот',
          en: 'You can switch back anytime from the top settings menu',
        ),
      ),
    ];

    final slide = slides[_index];

    return Material(
      color: AppTheme.obsidianBlack,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF221D09),
                    AppTheme.carbonSurface,
                    AppTheme.obsidianBlack,
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppTheme.beelineYellow.withValues(alpha: 0.55),
                  width: 1.5,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: _prev,
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: _next,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 5 segmented Beeline-yellow progress bars
                        Row(
                          children: List<Widget>.generate(_totalSlides, (i) {
                            return Expanded(
                              child: Container(
                                height: 4,
                                margin: EdgeInsets.only(
                                  right: i < _totalSlides - 1 ? 6 : 0,
                                ),
                                decoration: BoxDecoration(
                                  color: i <= _index
                                      ? AppTheme.beelineYellow
                                      : Colors.white24,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.beelineYellow,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  slide.stepBadge,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.obsidianBlack,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  BeeMascot(
                                    state: slide.mascot,
                                    size: 118,
                                    showBubble: false,
                                    language: lang,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    slide.title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.carbonInput,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.07),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          slide.body,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            height: 1.45,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          slide.tip,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: AppTheme.beelineYellow,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_index == _totalSlides - 1) ...[
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.beelineYellow,
                              foregroundColor: AppTheme.obsidianBlack,
                            ),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              Navigator.of(context).pop();
                              widget.onEnableSeniorMode();
                            },
                            icon: const Icon(Icons.accessibility_new_rounded),
                            label: Text(
                              tr(
                                lang,
                                ru: 'Включить режим для родителей',
                                ky: 'Ата-эне режимин күйгүзүү',
                                en: 'Enable Parents & Grandma Mode',
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              tr(
                                lang,
                                ru: 'Понятно, поехали!',
                                ky: 'Түшүнүктүү, баштадык!',
                                en: 'Got it, let\'s go!',
                              ),
                            ),
                          ),
                        ] else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: _index > 0 ? _prev : null,
                                child: Text(
                                  tr(
                                    lang,
                                    ru: '← Назад',
                                    ky: '← Артка',
                                    en: '← Back',
                                  ),
                                ),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.beelineYellow,
                                  foregroundColor: AppTheme.obsidianBlack,
                                ),
                                onPressed: _next,
                                child: Text(
                                  tr(
                                    lang,
                                    ru: 'Дальше →',
                                    ky: 'Кийинки →',
                                    en: 'Next →',
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
