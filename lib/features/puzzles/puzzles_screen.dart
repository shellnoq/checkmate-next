import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/settings.dart';
import '../../core/l10n/strings.dart';
import '../../core/storage/app_storage.dart';
import '../../domain/puzzles/puzzle.dart';

/// Bulmaca listesi; derinliğe göre gruplanır, çözülenler işaretlenir.
class PuzzlesScreen extends ConsumerStatefulWidget {
  const PuzzlesScreen({super.key});

  @override
  ConsumerState<PuzzlesScreen> createState() => _PuzzlesScreenState();
}

class _PuzzlesScreenState extends ConsumerState<PuzzlesScreen> {
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final depths = PuzzleSet.all.map((p) => p.mateIn).toSet().toList()..sort();

    return Scaffold(
      appBar: AppBar(title: Text(s.puzzles)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          for (final depth in depths) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
              child: Text(
                s.mateInN(depth).toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final puzzle in PuzzleSet.all.where((p) => p.mateIn == depth))
              Builder(
                builder: (context) {
                  final solved =
                      AppStorage.statOf('puzzle_solved_${puzzle.id}') > 0;
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      solved ? Icons.check_circle : Icons.extension_outlined,
                      color: solved
                          ? const Color(0xFF3F9D6B)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(puzzle.label(settings.turkish)),
                    subtitle: Text(solved ? s.solvedTag : s.mateInN(depth)),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () async {
                      await context.push('/puzzle', extra: puzzle.id);
                      if (mounted) setState(() {});
                    },
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}
