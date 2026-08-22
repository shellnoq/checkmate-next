import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/settings.dart';
import '../../core/l10n/strings.dart';
import '../../core/storage/app_storage.dart';
import '../../domain/model/difficulty.dart';
import '../../domain/model/game_result.dart';

/// Oynanmış oyunların listesi.
class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key});

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen> {
  late List<Map<String, Object?>> _games;

  @override
  void initState() {
    super.initState();
    _games = AppStorage.archivedGames();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.archive),
        actions: [
          if (_games.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      settings.turkish
                          ? 'Tüm oyunlar silinsin mi?'
                          : 'Delete all games?',
                    ),
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
                  await AppStorage.clearArchive();
                  setState(() => _games = AppStorage.archivedGames());
                }
              },
            ),
        ],
      ),
      body: _games.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 44,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.noGamesYet,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: _games.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final game = _games[index];
                final result = GameResult.fromJson(
                  game['result']! as Map<String, Object?>,
                );
                final date = DateTime.tryParse(game['date'] as String? ?? '');
                final difficultyId = game['difficulty'] as String?;
                final difficulty = difficultyId == null
                    ? null
                    : DifficultyLevel.fromId(difficultyId);
                final localSide = game['localSide'] == 'black'
                    ? 'black'
                    : 'white';
                final won = result.winner?.name == localSide;

                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: result.isDraw
                          ? theme.colorScheme.surfaceContainerHighest
                          : won
                          ? const Color(0xFF3F9D6B).withValues(alpha: 0.16)
                          : const Color(0xFFC0554F).withValues(alpha: 0.16),
                    ),
                    child: Text(
                      result.isDraw
                          ? '½'
                          : won
                          ? '1'
                          : '0',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: result.isDraw
                            ? theme.colorScheme.onSurfaceVariant
                            : won
                            ? const Color(0xFF3F9D6B)
                            : const Color(0xFFC0554F),
                      ),
                    ),
                  ),
                  title: Text(
                    difficulty?.label(settings.turkish) ??
                        (settings.turkish ? 'İki Kişilik' : 'Two Players'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    [
                      result.detail(settings.turkish),
                      '${game['moveCount']} ${settings.turkish ? 'hamle' : 'moves'}',
                      if (date != null) _formatDate(date),
                    ].join(' · '),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy_all_outlined),
                    tooltip: s.copyPgn,
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await Clipboard.setData(
                        ClipboardData(text: game['pgn'] as String? ?? ''),
                      );
                      messenger.showSnackBar(
                        SnackBar(content: Text(s.pgnCopied)),
                      );
                    },
                  ),
                  onLongPress: () async {
                    await AppStorage.deleteArchivedGame(
                      game['_key']! as String,
                    );
                    setState(() => _games = AppStorage.archivedGames());
                  },
                );
              },
            ),
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.${date.year}';
}
