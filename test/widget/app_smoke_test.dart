import 'package:billing_shield/core/utils/decimal_utils.dart';
import 'package:billing_shield/presentation/app.dart';
import 'package:billing_shield/presentation/state/app_controller.dart';
import 'package:billing_shield/presentation/widgets/bee_mascot.dart';
import 'package:billing_shield/presentation/widgets/category_breakdown_chart.dart';
import 'package:billing_shield/presentation/widgets/daily_spend_chart.dart';
import 'package:billing_shield/presentation/widgets/operator_logo.dart';
import 'package:billing_shield/presentation/widgets/senior_dashboard_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Desktop layout renders KPIs, segmented analytics, BeeMascot, tabs, senior mode, and live claim total', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = AppController();
    await controller.loadDemoFamily();

    await tester.pumpWidget(
      BillingShieldApp(controller: controller, autoLoadDemo: false),
    );
    await tester.pump(const Duration(milliseconds: 350));

    // Overview Stories strip, Hero balance card, Bento metrics, and segmented analytics
    expect(find.byType(BeeMascot), findsWidgets);
    expect(find.textContaining('Расходы за'), findsOneWidget);
    expect(find.text('Прогноз утечки'), findsOneWidget);
    expect(find.text('Очистка CSV'), findsOneWidget);
    expect(find.text('Загрузить CSV'), findsOneWidget);

    expect(find.byType(DailySpendChart), findsOneWidget);
    await tester.tap(find.text('Категории'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(CategoryBreakdownChart), findsOneWidget);
    await tester.tap(find.text('Топ-5'));
    await tester.pump(const Duration(milliseconds: 250));

    await tester.ensureVisible(
      find.text('Подробнее: AI-резюме и проверка Decimal'),
    );
    await tester.tap(find.text('Подробнее: AI-резюме и проверка Decimal'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('AI-пояснение (опц.)'), findsOneWidget);

    // Navigate to Anomalies tab
    await tester.tap(find.text('Аномалии').first);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.textContaining('Фильтр по типу'), findsOneWidget);
    expect(find.byType(BeeMascot), findsWidgets);

    // Navigate to Family Shield tab
    await tester.tap(find.text('Семейный щит').first);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Режим для родителей / бабушки'), findsOneWidget);
    expect(find.text('Кросс-аккаунт угрозы'), findsOneWidget);
    expect(find.textContaining('4545'), findsWidgets);
    expect(find.byType(BeeMascot), findsWidgets);

    // Navigate to Tariff Optimizer tab
    await tester.tap(find.text('Подбор тарифа').first);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.textContaining('Лучший тариф ·'), findsOneWidget);

    // Navigate to Claim & Export tab and toggle checkbox
    await tester.tap(find.text('Заявление и экспорт').first);
    await tester.pump(const Duration(milliseconds: 350));

    final initialRefund = formatSom(controller.selectedClaimRefundTotal);
    expect(find.text('Сумма к возврату: $initialRefund сом'), findsOneWidget);

    final firstCheckbox = find.byType(CheckboxListTile).first;
    await tester.tap(firstCheckbox);
    await tester.pump(const Duration(milliseconds: 350));

    final updatedRefund = formatSom(controller.selectedClaimRefundTotal);
    expect(updatedRefund, isNot(equals(initialRefund)));
    expect(find.text('Сумма к возврату: $updatedRefund сом'), findsOneWidget);

    // Toggle Senior Mode and navigate back to Overview
    await tester.tap(find.text('Обзор').first);
    await tester.pump(const Duration(milliseconds: 350));
    controller.toggleSeniorMode(true);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(SeniorDashboardView), findsOneWidget);
    expect(find.byType(BeeMascot), findsOneWidget);
  });

  for (final viewport in const [Size(360, 800), Size(412, 915)]) {
    testWidgets(
      'Mobile layout (${viewport.width.toInt()}x${viewport.height.toInt()}) visits all 5 tabs, senior mode & light theme with zero overflow',
      (tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = AppController();
        await controller.loadDemoFamily();

        await tester.pumpWidget(
          BillingShieldApp(controller: controller, autoLoadDemo: false),
        );
        await tester.pump(const Duration(milliseconds: 350));

    // 1. Overview: Stories strip, Hero balance, Bento metrics, segmented switcher
    expect(find.byType(BeeMascot), findsOneWidget);
    expect(find.byType(OperatorLogo), findsWidgets);
    expect(find.textContaining('Расходы за'), findsOneWidget);
        expect(find.text('Прогноз утечки'), findsOneWidget);
        expect(find.text('Очистка CSV'), findsOneWidget);

        // Open Stories from top horizontal strip and step through all 4 slides
        if (viewport.width == 360) {
          await tester.tap(find.text('Итоги\nмесяца'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 250));
          expect(find.text('Твой месяц в цифрах'), findsOneWidget);
          await tester.tap(find.text('Далее →'));
          await tester.pump(const Duration(milliseconds: 200));
          expect(find.text('Главный пожиратель баланса'), findsOneWidget);
          await tester.tap(find.text('Далее →'));
          await tester.pump(const Duration(milliseconds: 200));
          expect(find.text('Сколько можно вернуть'), findsOneWidget);
          await tester.tap(find.text('Далее →'));
          await tester.pump(const Duration(milliseconds: 200));
          expect(find.text('Вердикт защиты'), findsOneWidget);
          await tester.tap(find.byIcon(Icons.close_rounded));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 250));
        }

        await tester.ensureVisible(find.text('Категории'));
        await tester.tap(find.text('Категории'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(CategoryBreakdownChart), findsOneWidget);
        await tester.tap(find.text('Топ-5'));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.text('По дням'));
        await tester.pump(const Duration(milliseconds: 200));

        await tester.ensureVisible(
          find.text('Подробнее: AI-резюме и проверка Decimal'),
        );
        await tester.tap(find.text('Подробнее: AI-резюме и проверка Decimal'));
        await tester.pump(const Duration(milliseconds: 200));

        // 2. Anomalies tab + SMS intercept simulator + scroll
        await tester.tap(find.text('Аномалии').last);
        await tester.pump(const Duration(milliseconds: 300));
        if (viewport.width == 360) {
          await tester.tap(find.text('Тест перехвата SMS'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          expect(find.textContaining('Гороскоп VIP'), findsOneWidget);
          await tester.ensureVisible(
            find.text('Заблокировать и отправить СТОП'),
          );
          await tester.tap(find.text('Заблокировать и отправить СТОП'));
          await tester.pump(const Duration(milliseconds: 250));
          expect(find.text('Угроза заблокирована!'), findsOneWidget);
          await tester.tap(find.text('Готово'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 350));
        }
        await tester.drag(find.byType(ListView).first, const Offset(0, -400));
        await tester.pump(const Duration(milliseconds: 200));

        // 3. Family Shield tab + scroll
        await tester.tap(find.text('Семья').last);
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Кросс-аккаунт угрозы'), findsOneWidget);
        await tester.drag(find.byType(ListView).first, const Offset(0, -400));
        await tester.pump(const Duration(milliseconds: 200));

        // 4. Tariff Optimizer tab + before/after bar + USSD button + scroll
        await tester.tap(find.text('Тарифы').last);
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.textContaining('Сейчас:'), findsOneWidget);
        await tester.drag(find.byType(ListView).first, const Offset(0, -400));
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.textContaining('Подключить · *'), findsWidgets);

        // 5. Claim & Export tab + scroll
        await tester.tap(find.text('Заявление').last);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.drag(find.byType(ListView).first, const Offset(0, -400));
        await tester.pump(const Duration(milliseconds: 200));

        // Toggle Light Theme, Kyrgyz Language ('ky') via settings menu, & Senior Mode
        await tester.tap(find.text('Обзор').last);
        await tester.pump(const Duration(milliseconds: 250));
        await tester.tap(find.byIcon(Icons.tune_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        await tester.tap(find.text('КЫР (Кыргызча)'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('Менин акчам кайда?'), findsOneWidget);
        expect(find.text('Прогноз утечки'), findsNothing);
        controller.toggleThemeMode();
        await tester.pump(const Duration(milliseconds: 250));
        controller.toggleSeniorMode(true);
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byType(SeniorDashboardView), findsOneWidget);
      },
    );
  }

  testWidgets('BeeMascot renders all 5 dedicated state assets and cycles tips on tap', (tester) async {
    for (final state in MascotState.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BeeMascot(
                state: state,
                cyclingMessages: const ['Совет 1', 'Совет 2'],
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 260));
      final img = tester.widget<Image>(find.byType(Image));
      final assetImg = img.image as AssetImage;
      expect(assetImg.assetName, equals(BeeMascot.assetForState(state)));
    }

    await tester.tap(find.byType(Image));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Совет 1'), findsOneWidget);
  });
}
