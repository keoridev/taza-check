import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/decimal_utils.dart';
import '../../domain/entities/family_member.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/bee_mascot.dart';
import '../widgets/operator_logo.dart';

/// Multi-member Family Shield (`Семейный щит`) with cross-account
/// `number_reputation` detection and «Режим для родителей / бабушки».
class FamilyShieldScreen extends StatelessWidget {
  const FamilyShieldScreen({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRu = controller.language == AppLanguage.ru;
    final members = controller.familyMembers;
    final flags = controller.reputationFlags;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: SwitchListTile(
            value: controller.seniorMode,
            onChanged: (v) => controller.toggleSeniorMode(v),
            secondary: const Icon(Icons.accessibility_new_rounded, size: 30),
            title: Text(
              isRu
                  ? 'Режим для родителей / бабушки'
                  : 'Ата-эне / чоң эне режими',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              isRu
                  ? 'Увеличенный шрифт, высокий контраст и простые кнопки отключения'
                  : 'Чоң шрифт, жогорку контраст жана жөнөкөй баскычтар',
            ),
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final cols = w >= 1000 ? 4 : 2;
            final cardW = (w - (cols - 1) * 10) / cols;
            final isDark = theme.brightness == Brightness.dark;
            final cardBg = isDark ? AppTheme.carbonSurface : Colors.white;
            final borderColor = isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFE5E5EC);

            Widget bentoStat({
              required String label,
              required String value,
              required Color accent,
            }) {
              return SizedBox(
                width: cardW,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 3,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          maxLines: 1,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                bentoStat(
                  label: isRu ? 'Траты семьи' : 'Үй-бүлө',
                  value: '${formatSom(controller.totalFamilySpendSom)} сом',
                  accent: AppTheme.beelineYellow,
                ),
                bentoStat(
                  label: isRu ? 'Переплата' : 'Ашыкча',
                  value:
                      '${formatSom(controller.totalFamilyOverchargeSom)} сом',
                  accent: AppTheme.coralRed,
                ),
                bentoStat(
                  label: isRu ? 'Утечка / год' : 'Жылдык жоготуу',
                  value:
                      '${formatSom(controller.totalFamilyAnnualLeakSom)} сом',
                  accent: AppTheme.warmAmber,
                ),
                bentoStat(
                  label: isRu ? 'Защищено' : 'Корголгон',
                  value: '${members.length} ${isRu ? "номеров" : "номер"}',
                  accent: AppTheme.electricGreen,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Text(
          isRu ? 'Кросс-аккаунт угрозы' : 'Үй-бүлөлүк коркунучтар',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        if (flags.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                isRu
                    ? 'Массовых списаний с общих коротких номеров не выявлено.'
                    : 'Орток кыска номерлерден массалык акча алуу табылган жок.',
              ),
            ),
          )
        else
          ...flags.map((flag) => _buildFlagCard(context, flag, isRu)),
        const SizedBox(height: 20),
        Text(
          isRu ? 'Профили семьи' : 'Үй-бүлө мүчөлөрү',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        ...members.map((member) {
          final isActive = member.id == controller.activeMemberId;
          final res = member.result;
          final over = res?.totalOverchargeSom ?? Decimal.zero;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.65),
                  width: isActive ? 2 : 1,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  controller.selectMember(member.id);
                  controller.setTabIndex(0);
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: isActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceContainerHighest,
                            foregroundColor: isActive
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                            child: Text(
                              member.name.substring(0, 1),
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${member.name} — ${member.roleLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (res != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                              child: Text(
                                '${res.anomalies.length} ${isRu ? "аном." : "аном."}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: isRu ? 'Загрузить CSV' : 'CSV жүктөө',
                            onPressed: () =>
                                controller.loadCustomCsvForMember(member.id),
                            icon: const Icon(Icons.upload_file_rounded, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          OperatorLogo(
                            operatorName: member.operatorName,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            member.phone,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (res != null)
                            Expanded(
                              child: Text(
                                '${formatSom(res.report.totalSpendSom)} сом · '
                                '${isRu ? "переплата" : "ашыкча"} ${formatSom(over)} сом',
                                textAlign: TextAlign.end,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: over > Decimal.zero
                                      ? AppTheme.coralRed
                                      : AppTheme.electricGreen,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFlagCard(
    BuildContext context,
    FamilyReputationFlag flag,
    bool isRu,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.coralRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${isRu ? "Короткий номер" : "Кыска номер"} ${flag.shortCode}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  Text(
                    '-${formatSom(flag.totalFamilyLossSom)} сом',
                    style: const TextStyle(
                      color: AppTheme.coralRed,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              BeeMascot(
                state: MascotState.alert,
                compact: true,
                size: 58,
                language: controller.language,
                message: isRu ? flag.explanationRu : flag.explanationKy,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...flag.affectedMemberNames.map(
                    (name) => Chip(
                      avatar: const Icon(Icons.person_rounded, size: 16),
                      label: Text(name),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      await Clipboard.setData(const ClipboardData(text: 'СТОП'));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isRu
                                  ? 'Скопировано: СТОП (отправьте на ${flag.shortCode})'
                                  : 'Көчүрүлдү: СТОП (${flag.shortCode} номерине жөнөтүңүз)',
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.copy_rounded, size: 15),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              flag.ussdHint,
                              softWrap: true,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
