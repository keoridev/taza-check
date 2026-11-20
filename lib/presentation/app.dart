import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import 'screens/anomalies_screen.dart';
import 'screens/claim_export_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/family_shield_screen.dart';
import 'screens/tariff_optimizer_screen.dart';
import 'state/app_controller.dart';
import 'theme/app_theme.dart';
import 'widgets/bee_mascot.dart';

/// Root Material 3 adaptive application for `billing_shield`.
class BillingShieldApp extends StatefulWidget {
  const BillingShieldApp({
    super.key,
    this.controller,
    this.autoLoadDemo = true,
  });

  final AppController? controller;
  final bool autoLoadDemo;

  @override
  State<BillingShieldApp> createState() => _BillingShieldAppState();
}

class _BillingShieldAppState extends State<BillingShieldApp> {
  late final AppController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? AppController();
    if (widget.autoLoadDemo && _controller.familyMembers.isEmpty) {
      _controller.loadDemoFamily();
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final senior = _controller.seniorMode;
        return MaterialApp(
          title: 'Где мои деньги? — Семейный финансовый щит',
          debugShowCheckedModeBanner: false,
          themeMode: _controller.themeMode,
          theme: AppTheme.light(seniorMode: senior),
          darkTheme: AppTheme.dark(seniorMode: senior),
          home: _MainShell(controller: _controller),
        );
      },
    );
  }
}

class _MainShell extends StatelessWidget {
  const _MainShell({required this.controller});

  final AppController controller;

  static const List<IconData> _icons = <IconData>[
    Icons.dashboard_outlined,
    Icons.warning_amber_outlined,
    Icons.family_restroom_outlined,
    Icons.auto_graph_outlined,
    Icons.description_outlined,
  ];

  static const List<IconData> _selectedIcons = <IconData>[
    Icons.dashboard_rounded,
    Icons.warning_amber_rounded,
    Icons.family_restroom_rounded,
    Icons.auto_graph_rounded,
    Icons.description_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 840;
    final isCompactMobile = width < 600;
    final labels = AppStrings.navLabels(controller.language);
    final mobileLabels = AppStrings.compactNavLabels(controller.language);
    final members = controller.familyMembers;
    final activeMember = controller.activeMember;
    final theme = Theme.of(context);

    final body = switch (controller.selectedTabIndex) {
      0 => DashboardScreen(controller: controller),
      1 => AnomaliesScreen(controller: controller),
      2 => FamilyShieldScreen(controller: controller),
      3 => TariffOptimizerScreen(controller: controller),
      _ => ClaimExportScreen(controller: controller),
    };

    final mainContent = isWide
        ? Row(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: NavigationRail(
                      backgroundColor: Colors.transparent,
                      selectedIndex: controller.selectedTabIndex,
                      onDestinationSelected: controller.setTabIndex,
                      extended: width >= 1120,
                      labelType: width >= 1120
                          ? NavigationRailLabelType.none
                          : NavigationRailLabelType.selected,
                      destinations: List<NavigationRailDestination>.generate(
                        labels.length,
                        (i) => NavigationRailDestination(
                          icon: Icon(_icons[i]),
                          selectedIcon: Icon(_selectedIcons[i]),
                          label: Text(labels[i]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(child: body),
            ],
          )
        : body;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: isCompactMobile ? 10 : 16,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isCompactMobile ? 6 : 7),
              decoration: BoxDecoration(
                color: AppTheme.beelineYellow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.shield_rounded,
                color: AppTheme.obsidianBlack,
                size: isCompactMobile ? 18 : 20,
              ),
            ),
            SizedBox(width: isCompactMobile ? 8 : 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppStrings.appTitle(controller.language),
                      maxLines: 1,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: isCompactMobile ? 15 : 17,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (isWide)
                    Text(
                      AppStrings.appSubtitle(controller.language),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (members.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: controller.language == AppLanguage.ru
                  ? 'Выбрать абонента'
                  : 'Абонентти тандоо',
              onSelected: controller.selectMember,
              itemBuilder: (_) => members
                  .map(
                    (m) => PopupMenuItem<String>(
                      value: m.id,
                      child: Text('${m.name} — ${m.roleLabel}'),
                    ),
                  )
                  .toList(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompactMobile ? 2 : 6,
                  vertical: 6,
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompactMobile ? 8 : 10,
                    vertical: isCompactMobile ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.beelineYellow,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_rounded,
                        size: isCompactMobile ? 14 : 16,
                        color: AppTheme.obsidianBlack,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        activeMember?.name ?? '',
                        style: TextStyle(
                          color: AppTheme.obsidianBlack,
                          fontWeight: FontWeight.w800,
                          fontSize: isCompactMobile ? 12 : 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          TextButton(
            style: isCompactMobile
                ? TextButton.styleFrom(
                    minimumSize: const Size(36, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )
                : null,
            onPressed: () => controller.setLanguage(
              controller.language == AppLanguage.ru
                  ? AppLanguage.ky
                  : AppLanguage.ru,
            ),
            child: Text(
              controller.language.shortLabel,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: isCompactMobile ? 12 : 14,
              ),
            ),
          ),
          IconButton(
            visualDensity: isCompactMobile ? VisualDensity.compact : null,
            padding: isCompactMobile ? EdgeInsets.zero : null,
            constraints: isCompactMobile
                ? const BoxConstraints(minWidth: 34, minHeight: 34)
                : null,
            tooltip: controller.language == AppLanguage.ru
                ? 'Режим для родителей / бабушки'
                : 'Ата-эне / чоң эне режими',
            onPressed: controller.toggleSeniorMode,
            icon: Icon(
              controller.seniorMode
                  ? Icons.accessibility_new_rounded
                  : Icons.accessibility_rounded,
              size: isCompactMobile ? 20 : 24,
              color: controller.seniorMode ? AppTheme.beelineYellow : null,
            ),
          ),
          IconButton(
            visualDensity: isCompactMobile ? VisualDensity.compact : null,
            padding: isCompactMobile ? EdgeInsets.zero : null,
            constraints: isCompactMobile
                ? const BoxConstraints(minWidth: 34, minHeight: 34)
                : null,
            tooltip: controller.themeMode == ThemeMode.dark
                ? 'Светлая тема'
                : 'Тёмная тема',
            onPressed: controller.toggleThemeMode,
            icon: Icon(
              controller.themeMode == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              size: isCompactMobile ? 20 : 24,
            ),
          ),
          if (isCompactMobile) const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          mainContent,
          if (controller.isBusy)
            Positioned.fill(
              child: ColoredBox(
                color: AppTheme.obsidianBlack.withValues(alpha: 0.78),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 460),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.carbonSurface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.beelineYellow,
                          width: 2,
                        ),
                      ),
                      child: BeeMascot(
                        state: MascotState.loader,
                        size: 108,
                        language: controller.language,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: controller.selectedTabIndex,
              onDestinationSelected: controller.setTabIndex,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: List<NavigationDestination>.generate(
                mobileLabels.length,
                (i) => NavigationDestination(
                  icon: Icon(_icons[i]),
                  selectedIcon: Icon(_selectedIcons[i]),
                  label: mobileLabels[i],
                ),
              ),
            ),
    );
  }
}
