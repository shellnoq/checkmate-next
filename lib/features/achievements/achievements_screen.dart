import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/settings.dart';
import '../../core/l10n/strings.dart';
import '../../domain/economy/achievements.dart';
import '../../domain/economy/coin_service.dart';

/// Başarım listesi ve coin bakiyesi.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final unlockedCount = AchievementService.all
        .where((a) => a.isUnlocked)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.achievements),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.paid_outlined, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${CoinService.balance}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              '$unlockedCount / ${AchievementService.all.length}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final achievement in AchievementService.all)
            Builder(
              builder: (context) {
                final unlocked = achievement.isUnlocked;
                return ListTile(
                  leading: Icon(
                    unlocked ? Icons.emoji_events : Icons.emoji_events_outlined,
                    color: unlocked
                        ? const Color(0xFFE0A62E)
                        : theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                  ),
                  title: Text(
                    achievement.label(settings.turkish),
                    style: TextStyle(
                      fontWeight: unlocked ? FontWeight.w600 : FontWeight.w400,
                      color: unlocked
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  subtitle: Text(achievement.hint(settings.turkish)),
                  trailing: Text(
                    '+${achievement.coins}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: unlocked
                          ? const Color(0xFFE0A62E)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
