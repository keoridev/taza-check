import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_strings.dart';
import 'screens/anomalies_screen.dart';
import 'screens/claim_export_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/family_shield_screen.dart';
import 'screens/tariff_optimizer_screen.dart';
import 'state/app_controller.dart';
import 'theme/app_theme.dart';
import 'widgets/bee_mascot.dart';
import 'widgets/operator_logo.dart';

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
  bool _precachedMascots = false;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precachedMascots) {
      _precachedMascots = true;
      BeeMascot.precacheAll(context);
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
    Icons.grid_view_outlined,
    Icons.bolt_outlined,
    Icons.people_alt_outlined,
    Icons.sim_card_outlined,
    Icons.description_outlined,
  ];

  static const List<IconData> _selectedIcons = <IconData>[
    Icons.grid_view_rounded,
    Icons.bolt_rounded,
    Icons.people_alt_rounded,
    Icons.sim_card_rounded,
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
    final lang = controller.language;

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
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: NavigationRail(
                      backgroundColor: Colors.transparent,
                      selectedIndex: controller.selectedTabIndex,
                      onDestinationSelected: (i) {
                        HapticFeedback.selectionClick();
                        controller.setTabIndex(i);
                      },
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

    final isDark = theme.brightness == Brightness.dark;
    final circleBtnBg = isDark
        ? const Color(0xFF1A1A1F)
        : const Color(0xFFEAEAEF);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: isCompactMobile ? 14 : 20,
        title: Row(
          children: [
            // Minimal Beeline-inspired geometric circle/stripe brand mark
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.34, 0.34, 0.66, 0.66, 1.0],
                  colors: [
                    AppTheme.beelineYellow,
                    AppTheme.beelineYellow,
                    Color(0xFF09090B),
                    Color(0xFF09090B),
                    AppTheme.beelineYellow,
                    AppTheme.beelineYellow,
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                  width: 1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  AppStrings.appTitle(controller.language),
                  maxLines: 1,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: isCompactMobile ? 16 : 18,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (members.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: AppStrings.tr(
                lang,
                ru: 'Выбрать абонента',
                ky: 'Абонентти тандоо',
                en: 'Switch profile',
              ),
              onSelected: (id) {
                HapticFeedback.selectionClick();
                controller.selectMember(id);
              },
              itemBuilder: (_) => members
                  .map(
                    (m) => PopupMenuItem<String>(
                      value: m.id,
                      child: Text('${m.name} · ${m.operatorName}'),
                    ),
                  )
                  .toList(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: circleBtnBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OperatorLogo(
                      operatorName: activeMember?.operatorName ?? 'O!',
                      size: 20,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      activeMember?.name ?? 'Я',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 6),
          // Circular button 1: CSV Upload (+)
          IconButton(
            tooltip: AppStrings.tr(
              lang,
              ru: 'Загрузить CSV',
              ky: 'CSV жүктөө',
              en: 'Load CSV',
            ),
            onPressed: controller.loadCustomCsvForActiveMember,
            style: IconButton.styleFrom(
              backgroundColor: circleBtnBg,
              minimumSize: const Size(36, 36),
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
          ),
          const SizedBox(width: 6),
          // Circular button 2: Preferences (Language RU/KY/EN, Theme, Senior Mode, Demo)
          PopupMenuButton<String>(
            tooltip: AppStrings.tr(
              controller.language,
              ru: 'Настройки',
              ky: 'Жөндөөлөр',
              en: 'Settings',
            ),
            onSelected: (action) {
              switch (action) {
                case 'lang_ru':
                  HapticFeedback.selectionClick();
                  controller.setLanguage(AppLanguage.ru);
                case 'lang_ky':
                  HapticFeedback.selectionClick();
                  controller.setLanguage(AppLanguage.ky);
                case 'lang_en':
                  HapticFeedback.selectionClick();
                  controller.setLanguage(AppLanguage.en);
                case 'theme':
                  HapticFeedback.selectionClick();
                  controller.toggleThemeMode();
                case 'senior':
                  HapticFeedback.mediumImpact();
                  controller.toggleSeniorMode();
                case 'demo':
                  controller.loadDemoFamily();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                value: 'lang_ru',
                child: Row(
                  children: [
                    Icon(
                      Icons.translate_rounded,
                      size: 18,
                      color: controller.language == AppLanguage.ru
                          ? AppTheme.beelineYellow
                          : null,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('РУС (Русский)')),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'lang_ky',
                child: Row(
                  children: [
                    Icon(
                      Icons.translate_rounded,
                      size: 18,
                      color: controller.language == AppLanguage.ky
                          ? AppTheme.beelineYellow
                          : null,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('КЫР (Кыргызча)')),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'lang_en',
                child: Row(
                  children: [
                    Icon(
                      Icons.translate_rounded,
                      size: 18,
                      color: controller.language == AppLanguage.en
                          ? AppTheme.beelineYellow
                          : null,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('ENG (English)')),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(
                      controller.themeMode == ThemeMode.dark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        controller.themeMode == ThemeMode.dark
                            ? AppStrings.tr(
                                controller.language,
                                ru: 'Светлая тема',
                                ky: 'Жарык тема',
                                en: 'Light theme',
                              )
                            : AppStrings.tr(
                                controller.language,
                                ru: 'Тёмная тема',
                                ky: 'Караңгы тема',
                                en: 'Dark theme',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'senior',
                child: Row(
                  children: [
                    const Icon(Icons.accessibility_new_rounded, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppStrings.tr(
                          controller.language,
                          ru: 'Режим для родителей',
                          ky: 'Ата-эне режими',
                          en: 'Parents & Grandma mode',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'demo',
                child: Row(
                  children: [
                    const Icon(Icons.refresh_rounded, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppStrings.tr(
                          controller.language,
                          ru: 'Загрузить демо',
                          ky: 'Демо жүктөө',
                          en: 'Load demo family',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: circleBtnBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.tune_rounded, size: 18),
            ),
          ),
          const SizedBox(width: 10),
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
          : _SleekBottomBar(
              selectedIndex: controller.selectedTabIndex,
              onDestinationSelected: controller.setTabIndex,
              labels: mobileLabels,
              icons: _icons,
              selectedIcons: _selectedIcons,
            ),
    );
  }
}

class _SleekBottomBar extends StatelessWidget {
  const _SleekBottomBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.labels,
    required this.icons,
    required this.selectedIcons,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<String> labels;
  final List<IconData> icons;
  final List<IconData> selectedIcons;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F12) : Colors.white;
    final inactiveColor = isDark ? AppTheme.coolGray : const Color(0xFF6B6B76);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFE5E5EC),
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List<Widget>.generate(labels.length, (i) {
              final selected = i == selectedIndex;
              final activeColor = isDark
                  ? AppTheme.beelineYellow
                  : AppTheme.obsidianBlack;
              return Expanded(
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onDestinationSelected(i);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedScale(
                        scale: selected ? 1.08 : 1.0,
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          selected ? selectedIcons[i] : icons[i],
                          size: 22,
                          color: selected ? activeColor : inactiveColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        labels[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w500,
                          color: selected ? activeColor : inactiveColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: selected ? 14 : 0,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppTheme.beelineYellow,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
