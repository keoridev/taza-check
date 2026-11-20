import 'package:billing_shield/core/utils/decimal_utils.dart';
import 'package:billing_shield/presentation/app.dart';
import 'package:billing_shield/presentation/state/app_controller.dart';
import 'package:billing_shield/presentation/widgets/category_breakdown_chart.dart';
import 'package:billing_shield/presentation/widgets/daily_spend_chart.dart';
import 'package:billing_shield/presentation/widgets/senior_dashboard_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Desktop layout renders KPIs, charts, tabs, senior mode, and live claim total', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = AppController();
    await controller.loadDemoFamily();

    await tester.pumpWidget(
      BillingShieldApp(controller: controller, autoLoadDemo: false),
    );
    await tester.pumpAndSettle();

    // Overview KPI cards and charts
    expect(find.text('Всего потрачено'), findsOneWidget);
    expect(find.text('Возможная переплата'), findsOneWidget);
    expect(find.text('Прогноз утечки за год (подписки × 12)'), findsOneWidget);
    expect(find.text('Отброшено битых строк'), findsOneWidget);
    await tester.scrollUntilVisible(find.byType(DailySpendChart), 250);
    expect(find.byType(DailySpendChart), findsOneWidget);
    expect(find.byType(CategoryBreakdownChart), findsOneWidget);

    // Navigate to Anomalies tab
    await tester.tap(find.text('Аномалии').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Фильтр по типу аномалии'), findsOneWidget);

    // Navigate to Family Shield tab
    await tester.tap(find.text('Семейный щит').first);
    await tester.pumpAndSettle();
    expect(find.text('Режим для родителей / бабушки'), findsOneWidget);
    expect(find.textContaining('4545'), findsWidgets);

    // Navigate to Tariff Optimizer tab
    await tester.tap(find.text('Подбор тарифа').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Лучший тариф:'), findsOneWidget);

    // Navigate to Claim & Export tab and toggle checkbox
    await tester.tap(find.text('Заявление и экспорт').first);
    await tester.pumpAndSettle();

    final initialRefund = formatSom(controller.selectedClaimRefundTotal);
    expect(find.text('Сумма к возврату: $initialRefund сом'), findsOneWidget);

    final firstCheckbox = find.byType(CheckboxListTile).first;
    await tester.tap(firstCheckbox);
    await tester.pumpAndSettle();

    final updatedRefund = formatSom(controller.selectedClaimRefundTotal);
    expect(updatedRefund, isNot(equals(initialRefund)));
    expect(find.text('Сумма к возврату: $updatedRefund сом'), findsOneWidget);

    // Toggle Senior Mode and navigate back to Overview
    await tester.tap(find.text('Обзор').first);
    await tester.pumpAndSettle();
    controller.toggleSeniorMode(true);
    await tester.pumpAndSettle();
    expect(find.byType(SeniorDashboardView), findsOneWidget);
  });

  testWidgets('Mobile layout (412x915) renders cleanly with NavigationBar and zero overflow', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = AppController();
    await controller.loadDemoFamily();

    await tester.pumpWidget(
      BillingShieldApp(controller: controller, autoLoadDemo: false),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Всего потрачено'), findsOneWidget);
  });
}
