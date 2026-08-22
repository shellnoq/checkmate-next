import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/settings.dart';
import '../../core/l10n/strings.dart';
import '../../domain/match/match_protocol.dart';
import '../../domain/model/difficulty.dart';
import '../../domain/model/time_control.dart';

enum _ColourChoice { white, black, random }

/// Oyun kurulum ekranı: zorluk, renk ve süre seçimi.
class NewGameScreen extends ConsumerStatefulWidget {
  const NewGameScreen({super.key, required this.kind});

  final MatchKind kind;

  @override
  ConsumerState<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends ConsumerState<NewGameScreen> {
  late DifficultyLevel _difficulty;
  late TimeControl _timeControl;
  _ColourChoice _colour = _ColourChoice.white;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _difficulty = settings.lastDifficulty;
    _timeControl = settings.lastTimeControl;
  }

  bool get _vsEngine => widget.kind == MatchKind.engine;

  void _start() {
    final settings = ref.read(settingsProvider);
    ref
        .read(settingsProvider.notifier)
        .rememberSetup(_difficulty, _timeControl);

    final side = switch (_colour) {
      _ColourChoice.white => Side.white,
      _ColourChoice.black => Side.black,
      _ColourChoice.random => Random().nextBool() ? Side.white : Side.black,
    };

    final config = MatchConfig(
      matchId: DateTime.now().microsecondsSinceEpoch.toString(),
      kind: widget.kind,
      localSide: side,
      difficulty: _vsEngine ? _difficulty : null,
      timeControl: _timeControl,
    );

    context.pushReplacement('/game', extra: config);
    // `settings` yalnızca dil için okundu; analiz uyarısı vermesin diye
    // kullanılıyor.
    assert(settings.locale.languageCode.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_vsEngine ? s.playVsEngine : s.passAndPlay)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          if (_vsEngine) ...[
            _SectionTitle(s.difficulty),
            const SizedBox(height: 8),
            ...DifficultyLevel.values.map(
              (level) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _DifficultyTile(
                  level: level,
                  selected: level == _difficulty,
                  turkish: settings.turkish,
                  eloLabel: s.estimatedElo,
                  onTap: () => setState(() => _difficulty = level),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle(s.yourColor),
            const SizedBox(height: 8),
            SegmentedButton<_ColourChoice>(
              segments: [
                ButtonSegment(
                  value: _ColourChoice.white,
                  label: Text(s.white),
                  icon: const Icon(Icons.circle_outlined),
                ),
                ButtonSegment(
                  value: _ColourChoice.random,
                  label: Text(s.random),
                  icon: const Icon(Icons.shuffle),
                ),
                ButtonSegment(
                  value: _ColourChoice.black,
                  label: Text(s.black),
                  icon: const Icon(Icons.circle),
                ),
              ],
              selected: {_colour},
              onSelectionChanged: (value) =>
                  setState(() => _colour = value.first),
            ),
            const SizedBox(height: 24),
          ],
          _SectionTitle(s.timeControl),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final control in TimeControl.presets)
                ChoiceChip(
                  label: Text(
                    control.isUnlimited
                        ? control.label(settings.turkish)
                        : '${control.label(settings.turkish)} '
                              '${control.shortLabel}',
                  ),
                  selected: control.id == _timeControl.id,
                  onSelected: (_) => setState(() => _timeControl = control),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      settings.turkish
                          ? 'Motor cihazınızda çalışır; internet bağlantısı '
                                'gerekmez.'
                          : 'The engine runs on your device; no internet '
                                'connection required.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: _start,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(s.startGame),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
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

class _DifficultyTile extends StatelessWidget {
  const _DifficultyTile({
    required this.level,
    required this.selected,
    required this.turkish,
    required this.eloLabel,
    required this.onTap,
  });

  final DifficultyLevel level;
  final bool selected;
  final bool turkish;
  final String eloLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.6),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              _StrengthBars(tier: level.tier, active: selected),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.label(turkish),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? scheme.onPrimaryContainer
                            : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      level.description(turkish),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: selected
                            ? scheme.onPrimaryContainer.withValues(alpha: 0.8)
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '~${level.approximateElo}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: selected ? scheme.primary : scheme.onSurface,
                    ),
                  ),
                  Text(
                    eloLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
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

/// Zorluk kademesini gösteren dikey çubuklar.
class _StrengthBars extends StatelessWidget {
  const _StrengthBars({required this.tier, required this.active});

  final int tier;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 26,
      height: 30,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (int i = 0; i < 4; i++)
            Container(
              width: 4,
              height: 8.0 + i * 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: (tier / 2).ceil() > i
                    ? (active ? scheme.primary : scheme.onSurfaceVariant)
                    : scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
        ],
      ),
    );
  }
}
