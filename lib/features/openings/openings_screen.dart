import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/settings.dart';
import '../../core/l10n/strings.dart';
import '../../domain/openings/opening_book.dart';

/// Dünya açılış ve savunmalarının listesi; her satır tahtada izlenebilir.
class OpeningsScreen extends ConsumerWidget {
  const OpeningsScreen({super.key});

  String _categoryLabel(S s, OpeningCategory category) => switch (category) {
    OpeningCategory.open => s.categoryOpen,
    OpeningCategory.semiOpen => s.categorySemiOpen,
    OpeningCategory.closed => s.categoryClosed,
    OpeningCategory.flank => s.categoryFlank,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.openingLibrary)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          for (final category in OpeningCategory.values) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
              child: Text(
                _categoryLabel(s, category).toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final opening in OpeningBook.all.where(
              (o) => o.category == category,
            ))
              ListTile(
                dense: true,
                leading: Container(
                  width: 44,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    opening.eco,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(opening.label(settings.turkish)),
                subtitle: Text(
                  opening.san,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () => context.push(
                  '/replay',
                  extra: <String, Object?>{
                    'kind': 'opening',
                    'openingName': opening.label(settings.turkish),
                    'uci': opening.uci,
                    'startingFen': kInitialFEN,
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}
