import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/settings.dart';
import '../../app/theme/theme_packs.dart';
import '../../core/l10n/strings.dart';
import '../../core/storage/app_storage.dart';
import '../../domain/economy/coin_service.dart';

/// Tema paketi mağazası: coin ile kilit açma ve paket seçimi.
class ThemesScreen extends ConsumerStatefulWidget {
  const ThemesScreen({super.key});

  @override
  ConsumerState<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends ConsumerState<ThemesScreen> {
  bool _isOwned(ThemePack pack) =>
      pack.price == 0 || AppStorage.statOf('theme_owned_${pack.id}') > 0;

  Future<void> _buyOrSelect(ThemePack pack) async {
    final s = S.of(context);
    final controller = ref.read(settingsProvider.notifier);
    if (_isOwned(pack)) {
      await controller.setThemePack(pack);
      if (mounted) setState(() {});
      return;
    }
    final paid = await CoinService.trySpend(pack.price);
    if (!paid) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s.notEnoughCoins)));
      }
      return;
    }
    await AppStorage.setStat('theme_owned_${pack.id}', 1);
    await controller.setThemePack(pack);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.themePacks),
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          for (final pack in ThemePacks.all)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PackCard(
                pack: pack,
                owned: _isOwned(pack),
                isActive: settings.themePack.id == pack.id,
                turkish: settings.turkish,
                onTap: () => _buyOrSelect(pack),
              ),
            ),
        ],
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.pack,
    required this.owned,
    required this.isActive,
    required this.turkish,
    required this.onTap,
  });

  final ThemePack pack;
  final bool owned;
  final bool isActive;
  final bool turkish;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = S.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Tahta önizlemesi: paketin iki karesi.
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 56,
                  height: 56,
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
                                        ? pack.boardTheme.light
                                        : pack.boardTheme.dark,
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pack.label(turkish),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        pack.boardTheme.label(turkish),
                        pack.pieceSet.label(turkish),
                        if (pack.musicAsset != null)
                          turkish ? 'Fon müziği' : 'Music',
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isActive)
                Chip(
                  label: Text(s.active),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: scheme.primaryContainer,
                  side: BorderSide.none,
                )
              else if (owned)
                OutlinedButton(onPressed: onTap, child: Text(s.select))
              else
                FilledButton.tonal(
                  onPressed: onTap,
                  child: Text(s.buyFor(pack.price)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
