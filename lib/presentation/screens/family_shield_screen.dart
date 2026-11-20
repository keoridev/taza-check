import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/decimal_utils.dart';
import '../../domain/entities/family_member.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/kpi_card.dart';

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
            final cols = w >= 840 ? 3 : 1;
            final cardW = (w - (cols - 1) * 12) / cols;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: cardW,
                  child: KpiCard(
                    title: isRu ? 'Расходы всей семьи' : 'Үй-бүлөнүн чыгымы',
                    value: '${formatSom(controller.totalFamilySpendSom)} сом',
                    subtitle: '${members.length} ${isRu ? "номера" : "номер"}',
                    icon: Icons.family_restroom_rounded,
                    accentColor: AppTheme.beelineYellow,
                  ),
                ),
                SizedBox(
                  width: cardW,
                  child: KpiCard(
                    title: isRu ? 'Общая переплата' : 'Жалпы ашыкча төлөм',
                    value:
                        '${formatSom(controller.totalFamilyOverchargeSom)} сом',
                    subtitle: isRu ? 'К возврату семье' : 'Кайтаруу суммасы',
                    icon: Icons.savings_rounded,
                    accentColor: AppTheme.coralRed,
                  ),
                ),
                SizedBox(
                  width: cardW,
                  child: KpiCard(
                    title: isRu ? 'Утечка за год' : 'Жылдык жоготуу',
                    value:
                        '${formatSom(controller.totalFamilyAnnualLeakSom)} сом',
                    subtitle: isRu
                        ? 'Подписки × 12 по семье'
                        : 'Жазылуулар × 12',
                    icon: Icons.shield_rounded,
                    accentColor: AppTheme.warmAmber,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Text(
          isRu
              ? 'Кросс-аккаунт угрозы (`number_reputation`)'
              : 'Үй-бүлөлүк коркунучтар (`number_reputation`)',
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
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                onTap: () {
                  controller.selectMember(member.id);
                  controller.setTabIndex(0);
                },
                leading: CircleAvatar(
                  backgroundColor: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  foregroundColor: isActive
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  child: Text(member.name.substring(0, 1)),
                ),
                title: Text(
                  '${member.name} — ${member.roleLabel}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  res == null
                      ? member.phone
                      : '${member.phone} (${member.operatorName}) · '
                          '${formatSom(res.report.totalSpendSom)} сом · '
                          '${isRu ? "переплата" : "ашыкча"} ${formatSom(over)} сом',
                ),
                trailing: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (res != null)
                      Chip(
                        label: Text(
                          '${res.anomalies.length} ${isRu ? "аном." : "аном."}',
                        ),
                      ),
                    IconButton(
                      tooltip: isRu ? 'Загрузить CSV' : 'CSV жүктөө',
                      onPressed: () =>
                          controller.loadCustomCsvForMember(member.id),
                      icon: const Icon(Icons.upload_file_rounded),
                    ),
                  ],
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
        color: AppTheme.coralRed.withValues(alpha: 0.10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(
                    Icons.gpp_bad_rounded,
                    color: AppTheme.coralRed,
                  ),
                  Text(
                    '${isRu ? "Короткий номер" : "Кыска номер"} ${flag.shortCode}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.coralRed,
                        ),
                  ),
                  Chip(
                    label: Text(
                      '-${formatSom(flag.totalFamilyLossSom)} сом',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(isRu ? flag.explanationRu : flag.explanationKy),
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
                  ActionChip(
                    avatar: const Icon(Icons.copy_rounded, size: 16),
                    label: Text(flag.ussdHint),
                    onPressed: () async {
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
