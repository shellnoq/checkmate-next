import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/settings.dart';
import '../../core/l10n/strings.dart';
import '../../core/storage/app_storage.dart';
import '../../domain/lessons/opening_lesson.dart';

/// Ders listesi.
class LessonsScreen extends ConsumerStatefulWidget {
  const LessonsScreen({super.key});

  @override
  ConsumerState<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends ConsumerState<LessonsScreen> {
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.lessons)),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          for (final lesson in LessonSet.all)
            Builder(
              builder: (context) {
                final done = AppStorage.statOf('lesson_done_${lesson.id}') > 0;
                return ListTile(
                  leading: Icon(
                    done ? Icons.check_circle : Icons.school_outlined,
                    color: done
                        ? const Color(0xFF3F9D6B)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(lesson.label(settings.turkish)),
                  subtitle: Text(
                    done
                        ? s.completedTag
                        : '${lesson.plies.where((p) => p.isStudent).length} '
                              '${settings.turkish ? 'hamle' : 'moves'}',
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () async {
                    await context.push('/lesson', extra: lesson.id);
                    if (mounted) setState(() {});
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}
