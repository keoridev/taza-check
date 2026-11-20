import 'package:billing_shield/core/utils/decimal_utils.dart';
import 'package:billing_shield/presentation/app.dart';
import 'package:billing_shield/presentation/state/app_controller.dart';
import 'package:billing_shield/presentation/widgets/bee_mascot.dart';
import 'package:billing_shield/presentation/widgets/category_breakdown_chart.dart';
import 'package:billing_shield/presentation/widgets/daily_spend_chart.dart';
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

    // Overview KPI cards, BeeMascot hero pill, segmented analytics, and collapsible summary
    expect(find.byType(BeeMascot), findsWidgets);
    expect(find.text('Всего потрачено'), findsOneWidget);
    expect(find.text('Возможная переплата'), findsOneWidget);
    expect(find.text('Прогноз утечки за год (подписки × 12)'), findsOneWidget);
    expect(find.text('Отброшено битых строк'), findsOneWidget);

    expect(find.byType(DailySpendChart), findsOneWidget);
    await tester.tap(find.text('Категории'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(CategoryBreakdownChart), findsOneWidget);
    await tester.tap(find.text('Топ-5'));
    await tester.pump(const Duration(milliseconds: 250));

    await tester.scrollUntilVisible(
      find.text('Подробнее: AI-резюме и проверка Decimal'),
      250,
    );
    await tester.tap(find.text('Подробнее: AI-резюме и проверка Decimal'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('AI-пояснение (опц.)'), findsOneWidget);

    // Navigate to Anomalies tab
    await tester.tap(find.text('Аномалии').first);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.textContaining('Фильтр по типу аномалии'), findsOneWidget);
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
    expect(find.textContaining('Лучший тариф:'), findsOneWidget);

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

        final errors = <FlutterErrorDetails>[];
        final prevOnError = FlutterError.onError;
        FlutterError.onError = (details) => errors.add(details);
        addTearDown(() => FlutterError.onError = prevOnError);

        final controller = AppController();
        await controller.loadDemoFamily();

        await tester.pumpWidget(
          BillingShieldApp(controller: controller, autoLoadDemo: false),
        );
        await tester.pump(const Duration(milliseconds: 350));

        // 1. Overview: compact 2x2 KPIs, segmented switcher, collapsible audit
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byType(BeeMascot), findsOneWidget);
        expect(find.text('Всего трат'), findsOneWidget);
        expect(find.text('Переплата'), findsOneWidget);
        expect(find.text('Утечка / год'), findsOneWidget);
        expect(find.text('Битые строки'), findsOneWidget);

        await tester.tap(find.text('Категории'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(CategoryBreakdownChart), findsOneWidget);
        await tester.tap(find.text('Топ-5'));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.text('По дням'));
        await tester.pump(const Duration(milliseconds: 200));

        await tester.drag(find.byType(ListView).first, const Offset(0, -400));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.text('Подробнее: AI-резюме и проверка Decimal'));
        await tester.pump(const Duration(milliseconds: 200));

        // 2. Anomalies tab + scroll
        await tester.tap(find.text('Аномалии').last);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.drag(find.byType(ListView).first, const Offset(0, -400));
        await tester.pump(const Duration(milliseconds: 200));

        // 3. Family Shield tab + scroll
        await tester.tap(find.text('Семья').last);
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Кросс-аккаунт угрозы'), findsOneWidget);
        await tester.drag(find.byType(ListView).first, const Offset(0, -400));
        await tester.pump(const Duration(milliseconds: 200));

        // 4. Tariff Optimizer tab + scroll
        await tester.tap(find.text('Тарифы').last);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.drag(find.byType(ListView).first, const Offset(0, -400));
        await tester.pump(const Duration(milliseconds: 200));

        // 5. Claim & Export tab + scroll
        await tester.tap(find.text('Заявление').last);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.drag(find.byType(ListView).first, const Offset(0, -400));
        await tester.pump(const Duration(milliseconds: 200));

        // Toggle Light Theme & Senior Mode on Overview
        await tester.tap(find.text('Обзор').last);
        await tester.pump(const Duration(milliseconds: 250));
        controller.toggleThemeMode();
        await tester.pump(const Duration(milliseconds: 250));
        controller.toggleSeniorMode(true);
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byType(SeniorDashboardView), findsOneWidget);

        expect(errors, isEmpty, reason: 'Expected zero FlutterError / overflow on $viewport');
      },
    );
  }

  testWidgets('BeeMascot renders all 5 states and cycles tips on tap', (tester) async {
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
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(Image), findsOneWidget);
    }

    await tester.tap(find.byType(Image));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Совет 1'), findsOneWidget);
  });
}
