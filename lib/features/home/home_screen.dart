import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/settings.dart';
import '../../core/l10n/strings.dart';
import '../../core/storage/app_storage.dart';
import '../../core/utils/app_version.dart';
import '../../domain/economy/coin_service.dart';
import '../board/piece_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(settings: settings)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList.list(
                children: [
                  _ModeCard(
                    icon: Icons.memory_outlined,
                    title: s.playVsEngine,
                    subtitle: s.playVsEngineSub,
                    highlighted: true,
                    onTap: () => context.push('/new-game'),
                  ),
                  const SizedBox(height: 12),
                  _ModeCard(
                    icon: Icons.people_alt_outlined,
                    title: s.passAndPlay,
                    subtitle: s.passAndPlaySub,
                    onTap: () => context.push('/new-game?mode=local'),
                  ),
                  const SizedBox(height: 12),
                  _ModeCard(
                    icon: Icons.public,
                    title: s.onlinePlay,
                    subtitle: s.onlineSub,
                    badge: s.onlineSoon,
                    enabled: false,
                    onTap: () {},
                  ),
                  const SizedBox(height: 24),
                  _StatsPanel(turkish: settings.turkish),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/lessons'),
                          icon: const Icon(Icons.school_outlined),
                          label: Text(s.lessons),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/openings'),
                          icon: const Icon(Icons.auto_stories_outlined),
                          label: Text(s.openingLibrary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/puzzles'),
                          icon: const Icon(Icons.extension_outlined),
                          label: Text(s.puzzles),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/achievements'),
                          icon: const Icon(Icons.emoji_events_outlined),
                          label: Text(
                            '${s.achievements} · ${CoinService.balance}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/themes'),
                          icon: const Icon(Icons.palette_outlined),
                          label: Text(s.themePacks),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/stories'),
                          icon: const Icon(Icons.menu_book_outlined),
                          label: Text(s.stories),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/archive'),
                          icon: const Icon(Icons.history),
                          label: Text(s.archive),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/settings'),
                          icon: const Icon(Icons.tune),
                          label: Text(s.settings),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      AppVersion.label.isEmpty
                          ? 'Stockfish'
                          : 'Stockfish · ${AppVersion.label}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: PieceWidget(
              piece: const Piece(color: Side.white, role: Role.knight),
              size: 52,
              pieceSet: settings.pieceSet,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.appName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  settings.turkish
                      ? 'Stockfish motoru · 8 zorluk kademesi'
                      : 'Stockfish engine · 8 difficulty levels',
                  style: theme.textTheme.bodySmall?.copyWith(
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
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.enabled = true,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;
  final bool enabled;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: highlighted ? scheme.primaryContainer : null,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: highlighted
                        ? scheme.primary.withValues(alpha: 0.18)
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: highlighted
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: highlighted
                                    ? scheme.onPrimaryContainer
                                    : scheme.onSurface,
                              ),
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                badge!,
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: highlighted
                              ? scheme.onPrimaryContainer.withValues(
                                  alpha: 0.75,
                                )
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.turkish});

  final bool turkish;

  @override
  Widget build(BuildContext context) {
    // Kutu dinlenir: oyun bitince istatistikler kendiliğinden tazelenir.
    return ValueListenableBuilder(
      valueListenable: AppStorage.statsListenable(),
      builder: (context, _, _) => _buildPanel(context),
    );
  }

  Widget _buildPanel(BuildContext context) {
    final theme = Theme.of(context);
    final wins = AppStorage.statOf('wins');
    final losses = AppStorage.statOf('losses');
    final draws = AppStorage.statOf('draws');
    final total = wins + losses + draws;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              turkish ? 'İstatistikler' : 'Statistics',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (total == 0)
              Text(
                turkish ? 'Henüz oyun yok' : 'No games yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Row(
                children: [
                  _StatTile(
                    label: turkish ? 'Galibiyet' : 'Wins',
                    value: wins,
                    color: const Color(0xFF3F9D6B),
                  ),
                  _StatTile(
                    label: turkish ? 'Beraberlik' : 'Draws',
                    value: draws,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  _StatTile(
                    label: turkish ? 'Mağlubiyet' : 'Losses',
                    value: losses,
                    color: const Color(0xFFC0554F),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
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
