import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/settings.dart';
import '../../core/l10n/strings.dart';
import '../../core/storage/app_storage.dart';
import '../../domain/model/difficulty.dart';

/// Ebeveyn bölümü: oynama süresi dökümü ve günlük süre sınırı.
///
/// Girişte dört haneli bir PIN sorulur. Bu bir güvenlik sınırı değil, çocuğun
/// ayarları kazara değiştirmesini önleyen bir kapıdır.
class ParentAreaScreen extends ConsumerStatefulWidget {
  const ParentAreaScreen({super.key});

  @override
  ConsumerState<ParentAreaScreen> createState() => _ParentAreaScreenState();
}

class _ParentAreaScreenState extends ConsumerState<ParentAreaScreen> {
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.parentArea)),
      body: _unlocked
          ? const _ParentDashboard()
          : _PinGate(onUnlocked: () => setState(() => _unlocked = true)),
    );
  }
}

/// PIN belirleme ve doğrulama.
class _PinGate extends StatefulWidget {
  const _PinGate({required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<_PinGate> createState() => _PinGateState();
}

class _PinGateState extends State<_PinGate> {
  final TextEditingController _field = TextEditingController();
  String? _error;

  bool get _isFirstTime => AppStorage.parentPin() == null;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = S.of(context);
    final entered = _field.text.trim();
    if (entered.length != 4) {
      setState(() => _error = s.pinFourDigits);
      return;
    }
    if (_isFirstTime) {
      await AppStorage.setParentPin(entered);
      widget.onUnlocked();
      return;
    }
    if (entered == AppStorage.parentPin()) {
      widget.onUnlocked();
    } else {
      setState(() {
        _error = s.pinWrong;
        _field.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 44,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _isFirstTime ? s.pinCreate : s.pinEnter,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _isFirstTime ? s.pinCreateHint : s.pinEnterHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 180,
              child: TextField(
                controller: _field,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 4,
                style: const TextStyle(fontSize: 28, letterSpacing: 12),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  errorText: _error,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submit,
              child: Text(_isFirstTime ? s.pinSave : s.pinUnlock),
            ),
          ],
        ),
      ),
    );
  }
}

/// Süre dökümü ve sınır ayarı.
class _ParentDashboard extends ConsumerWidget {
  const _ParentDashboard();

  static const _limitOptions = [
    Duration.zero,
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(minutes: 45),
    Duration(minutes: 60),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);

    final today = AppStorage.playtimeOfDay(DateTime.now());
    final total = AppStorage.totalPlaytime();
    final wins = AppStorage.statOf('wins');
    final losses = AppStorage.statOf('losses');
    final draws = AppStorage.statOf('draws');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _SummaryCard(
          today: today,
          total: total,
          games: wins + losses + draws,
          turkish: settings.turkish,
        ),
        const SizedBox(height: 20),
        _Header(s.dailyLimit),
        Text(
          s.dailyLimitHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in _limitOptions)
              ChoiceChip(
                label: Text(
                  option == Duration.zero
                      ? s.noLimit
                      : '${option.inMinutes} ${s.minutesShort}',
                ),
                selected: settings.dailyLimit == option,
                onSelected: (_) => controller.setDailyLimit(option),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _Header(s.timePerLevel),
        const SizedBox(height: 4),
        _LevelBreakdown(turkish: settings.turkish),
        const SizedBox(height: 24),
        _Header(s.lastSevenDays),
        const SizedBox(height: 8),
        const _WeeklyChart(),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.today,
    required this.total,
    required this.games,
    required this.turkish,
  });

  final Duration today;
  final Duration total;
  final int games;
  final bool turkish;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            _Metric(label: s.today, value: formatDuration(today, turkish)),
            _Metric(label: s.overall, value: formatDuration(total, turkish)),
            _Metric(label: s.gamesPlayed, value: '$games'),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelBreakdown extends StatelessWidget {
  const _LevelBreakdown({required this.turkish});

  final bool turkish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries =
        [
            for (final level in DifficultyLevel.values)
              (level, AppStorage.playtimeOfLevel(level.id)),
          ].where((e) => e.$2 > Duration.zero).toList()
          ..sort((a, b) => b.$2.compareTo(a.$2));

    if (entries.isEmpty) {
      return Text(
        S.of(context).noGamesYet,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final longest = entries.first.$2;
    return Column(
      children: [
        for (final (level, played) in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    level.label(turkish),
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: longest.inSeconds == 0
                          ? 0
                          : played.inSeconds / longest.inSeconds,
                      minHeight: 8,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 62,
                  child: Text(
                    formatDuration(played, turkish),
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final days = [
      for (int i = 6; i >= 0; i--)
        (
          now.subtract(Duration(days: i)),
          AppStorage.playtimeOfDay(now.subtract(Duration(days: i))),
        ),
    ];
    final peak = days
        .map((d) => d.$2.inSeconds)
        .fold(0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (day, played) in days)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    played == Duration.zero ? '' : '${played.inMinutes}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: peak == 0 ? 3 : 3 + (played.inSeconds / peak) * 72,
                    decoration: BoxDecoration(
                      color: played == Duration.zero
                          ? theme.colorScheme.surfaceContainerHighest
                          : theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _weekdayLabel(context, day),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _weekdayLabel(BuildContext context, DateTime day) {
    const tr = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'];
    const en = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    final turkish = S.of(context).tr;
    return (turkish ? tr : en)[day.weekday - 1];
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
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

/// `1 sa 20 dk` ya da `12 dk` biçiminde okunur süre.
String formatDuration(Duration value, bool turkish) {
  final hours = value.inHours;
  final minutes = value.inMinutes % 60;
  if (hours > 0) {
    return turkish ? '$hours sa $minutes dk' : '${hours}h ${minutes}m';
  }
  if (value.inMinutes > 0) {
    return turkish ? '$minutes dk' : '${minutes}m';
  }
  return turkish ? '${value.inSeconds} sn' : '${value.inSeconds}s';
}
