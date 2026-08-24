import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/settings.dart';
import '../../core/l10n/strings.dart';
import '../../domain/stories/chess_stories.dart';

/// Hikâye listesi.
class StoriesScreen extends ConsumerWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.stories)),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          for (final story in StorySet.all)
            ListTile(
              leading: Icon(
                Icons.auto_stories,
                color: theme.colorScheme.primary,
              ),
              title: Text(story.title(settings.turkish)),
              subtitle: Text(
                story.paragraphs.first.text(settings.turkish),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => context.push('/story', extra: story.id),
            ),
        ],
      ),
    );
  }
}
