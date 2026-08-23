import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/settings.dart';
import '../../app/theme/board_theme.dart';
import '../../core/audio/sound_service.dart';
import '../../core/l10n/strings.dart';
import '../../core/utils/age_group.dart';
import '../../core/utils/app_version.dart';
import '../../core/storage/app_storage.dart';
import '../board/piece_set.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _SectionHeader(s.language),
          RadioGroup<String>(
            groupValue: settings.locale.languageCode,
            onChanged: (value) {
              if (value != null) controller.setLocale(Locale(value));
            },
            child: const Column(
              children: [
                RadioListTile<String>(value: 'tr', title: Text('Türkçe')),
                RadioListTile<String>(value: 'en', title: Text('English')),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.family_restroom),
            title: Text(s.parentArea),
            subtitle: Text(s.parentAreaSub),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/parent'),
          ),
          const Divider(),
          _SectionHeader(s.ageGroup),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              s.ageGroupHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (final group in AgeGroup.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AgeTile(
                      group: group,
                      selected: group == settings.ageGroup,
                      turkish: settings.turkish,
                      onTap: () => controller.setAgeGroup(group),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),
          _SectionHeader(settings.turkish ? 'Görünüm' : 'Appearance'),
          ListTile(
            title: Text(settings.turkish ? 'Tema' : 'Theme'),
            trailing: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.brightness_auto, size: 18),
                  tooltip: settings.turkish ? 'Sistem' : 'System',
                ),
                const ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode, size: 18),
                ),
                const ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode, size: 18),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (value) =>
                  controller.setThemeMode(value.first),
            ),
          ),
          _SectionHeader(s.boardTheme),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: BoardTheme.all.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final boardTheme = BoardTheme.all[index];
                final selected = boardTheme.id == settings.boardTheme.id;
                return GestureDetector(
                  onTap: () => controller.setBoardTheme(boardTheme),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Column(
                            children: [
                              for (int r = 0; r < 2; r++)
                                Expanded(
                                  child: Row(
                                    children: [
                                      for (int c = 0; c < 2; c++)
                                        Expanded(
                                          child: ColoredBox(
                                            color: (r + c).isEven
                                                ? boardTheme.light
                                                : boardTheme.dark,
                                            child: const SizedBox.expand(),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        boardTheme.label(settings.turkish),
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          _SectionHeader(s.pieceSet),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                for (final set in PieceSet.all)
                  ChoiceChip(
                    label: Text(set.label(settings.turkish)),
                    selected: set.id == settings.pieceSet.id,
                    onSelected: (_) => controller.setPieceSet(set),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          _SectionHeader(settings.turkish ? 'Oyun' : 'Gameplay'),
          SwitchListTile(
            title: Text(s.showCoordinates),
            value: settings.showCoordinates,
            onChanged: controller.setCoordinates,
          ),
          SwitchListTile(
            title: Text(s.showLegalMoves),
            value: settings.showLegalMoves,
            onChanged: controller.setLegalMoves,
          ),
          SwitchListTile(
            title: Text(s.showEvaluation),
            subtitle: Text(
              settings.turkish
                  ? 'Motorun konum değerlendirmesini tahtanın yanında gösterir'
                  : 'Shows the engine evaluation next to the board',
            ),
            value: settings.showEvaluation,
            onChanged: controller.setEvaluation,
          ),
          SwitchListTile(
            title: Text(s.autoQueen),
            value: settings.autoQueenPromotion,
            onChanged: controller.setAutoQueen,
          ),
          const Divider(),
          _SectionHeader(settings.turkish ? 'Geri bildirim' : 'Feedback'),
          SwitchListTile(
            title: Text(s.sound),
            value: settings.soundEnabled,
            onChanged: (value) {
              controller.setSound(value);
              SoundService.instance.enabled = value;
              if (value) SoundService.instance.play(Sfx.move);
            },
          ),
          SwitchListTile(
            title: Text(s.haptics),
            value: settings.hapticsEnabled,
            onChanged: (value) {
              controller.setHaptics(value);
              SoundService.instance.hapticsEnabled = value;
              if (value) SoundService.instance.haptic();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.restore),
            title: Text(s.resetStats),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(s.resetStats),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(s.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(s.ok),
                    ),
                  ],
                ),
              );
              if (confirmed ?? false) {
                await AppStorage.resetStats();
                messenger.showSnackBar(SnackBar(content: Text(s.ok)));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(s.about),
            subtitle: Text(
              [
                if (AppVersion.label.isNotEmpty)
                  '${settings.turkish ? 'Sürüm' : 'Version'} '
                      '${AppVersion.label}',
                settings.turkish
                    ? 'Motor: Stockfish (GPLv3). Kural motoru: dartchess.'
                    : 'Engine: Stockfish (GPLv3). Rules: dartchess.',
              ].join('\n'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(settings.turkish ? 'Lisanslar' : 'Licenses'),
            onTap: () => showLicensePage(
              context: context,
              applicationName: s.appName,
              applicationLegalese: 'Stockfish · GNU General Public License v3',
            ),
          ),
        ],
      ),
    );
  }
}

class _AgeTile extends StatelessWidget {
  const _AgeTile({
    required this.group,
    required this.selected,
    required this.turkish,
    required this.onTap,
  });

  final AgeGroup group;
  final bool selected;
  final bool turkish;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.6),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                size: 20,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.label(turkish),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? scheme.onPrimaryContainer
                            : scheme.onSurface,
                      ),
                    ),
                    Text(
                      group.range(turkish),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
