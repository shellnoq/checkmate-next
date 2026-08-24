import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/settings.dart';
import '../../core/audio/tts_service.dart';
import '../../core/l10n/strings.dart';
import '../../domain/stories/chess_stories.dart';

/// Hikâye okuyucu: metin her zaman görünür (altyazı), istenirse paragraf
/// paragraf seslendirilir; okunan paragraf vurgulanır ve görünüme kaydırılır.
class StoryScreen extends ConsumerStatefulWidget {
  const StoryScreen({super.key, required this.storyId});

  final String storyId;

  @override
  ConsumerState<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends ConsumerState<StoryScreen> {
  late final ChessStory _story = StorySet.all.firstWhere(
    (story) => story.id == widget.storyId,
  );
  final ScrollController _scroll = ScrollController();

  int? _speakingIndex;

  @override
  void dispose() {
    TtsService.instance
      ..onComplete = null
      ..stop();
    _scroll.dispose();
    super.dispose();
  }

  void _startListening() {
    final s = S.of(context);
    TtsService.instance
      ..enabled = true
      ..onComplete = _speakNext;
    setState(() => _speakingIndex = 0);
    TtsService.instance.speak(_story.paragraphs[0].text(s.tr), turkish: s.tr);
  }

  void _speakNext() {
    if (!mounted) return;
    final current = _speakingIndex;
    if (current == null) return;
    final next = current + 1;
    if (next >= _story.paragraphs.length) {
      setState(() => _speakingIndex = null);
      return;
    }
    final s = S.of(context);
    setState(() => _speakingIndex = next);
    _scroll.animateTo(
      (next * 96).toDouble().clamp(0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
    TtsService.instance.speak(
      _story.paragraphs[next].text(s.tr),
      turkish: s.tr,
    );
  }

  void _stopListening() {
    TtsService.instance
      ..onComplete = null
      ..stop();
    setState(() => _speakingIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final listening = _speakingIndex != null;

    return Scaffold(
      appBar: AppBar(title: Text(_story.title(settings.turkish))),
      body: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        itemCount: _story.paragraphs.length,
        itemBuilder: (context, index) {
          final active = _speakingIndex == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: active
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _story.paragraphs[index].text(settings.turkish),
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: listening ? _stopListening : _startListening,
        icon: Icon(listening ? Icons.stop : Icons.volume_up),
        label: Text(listening ? s.storyStop : s.storyListen),
      ),
    );
  }
}
