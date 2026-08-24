import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/settings.dart';
import '../../core/audio/sound_service.dart';
import '../../core/audio/tts_service.dart';
import '../../core/l10n/strings.dart';
import '../../core/storage/app_storage.dart';
import '../../domain/economy/achievements.dart';
import '../../domain/economy/coin_service.dart';
import '../../domain/lessons/opening_lesson.dart';
import '../board/chess_board.dart';

/// Tek bir açılış dersinin işlendiği ekran.
///
/// Öğretmen her adımı yazıyla ve istenirse sesle anlatır; öğrenci beklenen
/// hamleyi oynar, siyahın yanıtını öğretmen kendisi oynar. Yanlış denemede
/// ipucu oku belirir, akış bozulmaz.
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  late final OpeningLesson _lesson = LessonSet.all.firstWhere(
    (l) => l.id == widget.lessonId,
  );

  Position _position = Chess.initial;
  int _ply = 0;
  Square? _selected;
  (Square, Square)? _lastMove;
  bool _showHint = false;
  bool _finished = false;

  bool get _voiceOn => AppStorage.get<bool>('lessonVoice', true);

  LessonPly? get _current =>
      _ply < _lesson.plies.length ? _lesson.plies[_ply] : null;

  NormalMove get _expectedMove => NormalMove.fromUci(_lesson.uci[_ply]);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakCurrent());
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  void _speakCurrent() {
    final step = _current;
    if (step == null || !mounted) return;
    final s = S.of(context);
    TtsService.instance.enabled = _voiceOn;
    TtsService.instance.speak(step.text(s.tr), turkish: s.tr);
  }

  void _advanceAfterStudentMove() {
    // Öğretmenin (siyahın) yanıtını kısa bir gecikmeyle oynat.
    final reply = _current;
    if (reply == null || reply.isStudent) {
      _maybeFinish();
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 550), () {
      if (!mounted) return;
      final move = _position.normalizeMove(_expectedMove);
      setState(() {
        _lastMove = (_expectedMove.from, _expectedMove.to);
        _position = _position.play(move);
        _ply++;
      });
      SoundService.instance.play(Sfx.move);
      _speakCurrentReplyThenNext(reply);
    });
  }

  void _speakCurrentReplyThenNext(LessonPly reply) {
    final s = S.of(context);
    TtsService.instance.enabled = _voiceOn;
    TtsService.instance.speak(reply.text(s.tr), turkish: s.tr);
    _maybeFinish();
  }

  Future<void> _maybeFinish() async {
    if (_ply < _lesson.plies.length || _finished) return;
    _finished = true;
    final firstTime = AppStorage.statOf('lesson_done_${_lesson.id}') == 0;
    await AppStorage.bumpStat('lesson_done_${_lesson.id}');
    var earned = 0;
    if (firstTime) {
      earned = 10;
      await CoinService.add(earned);
    }
    await AchievementService.checkAll();
    if (!mounted) return;
    final s = S.of(context);
    SoundService.instance.play(Sfx.victory);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.school_outlined,
                  size: 44,
                  color: Color(0xFF3F9D6B),
                ),
                const SizedBox(height: 10),
                Text(
                  s.lessonDone,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (earned > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    s.coinsEarned(earned),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFFE0A62E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.pop();
                  },
                  child: Text(s.backToList),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onStudentAttempt(NormalMove move) {
    final expected = _expectedMove;
    final matches = move.from == expected.from && move.to == expected.to;
    if (!matches) {
      SoundService.instance.haptic(HapticStrength.medium);
      final s = S.of(context);
      setState(() {
        _selected = null;
        _showHint = true;
      });
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(s.lessonWrong)));
      return;
    }
    final normalized = _position.normalizeMove(expected);
    setState(() {
      _selected = null;
      _showHint = false;
      _lastMove = (expected.from, expected.to);
      _position = _position.play(normalized);
      _ply++;
    });
    SoundService.instance.play(Sfx.move);
    _advanceAfterStudentMove();
  }

  void _onSquareTap(Square square) {
    final step = _current;
    if (step == null || !step.isStudent) return;
    final from = _selected;
    if (from != null && from != square) {
      _onStudentAttempt(NormalMove(from: from, to: square));
      return;
    }
    final piece = _position.board.pieceAt(square);
    setState(() {
      _selected = piece != null && piece.color == Side.white ? square : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final step = _current;

    return Scaffold(
      appBar: AppBar(
        title: Text(_lesson.label(settings.turkish)),
        actions: [
          IconButton(
            tooltip: s.teacherVoice,
            icon: Icon(
              _voiceOn ? Icons.record_voice_over : Icons.voice_over_off,
            ),
            onPressed: () async {
              await AppStorage.set('lessonVoice', !_voiceOn);
              if (!_voiceOn) {
                _speakCurrent();
              } else {
                TtsService.instance.stop();
              }
              setState(() {});
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Öğretmen paneli
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.school,
                          size: 20,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step?.text(settings.turkish) ?? '',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (step != null && step.isStudent)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${s.lessonYourTurn} · ${step.san}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = (constraints.maxWidth - 16).clamp(
                      0.0,
                      constraints.maxHeight,
                    );
                    final interactive = step?.isStudent ?? false;
                    return SizedBox(
                      width: size,
                      height: size,
                      child: ChessBoard(
                        position: _position,
                        orientation: Side.white,
                        boardTheme: settings.boardTheme,
                        pieceSet: settings.pieceSet,
                        selectedSquare: _selected,
                        legalDestinations: _selected == null
                            ? const {}
                            : (makeLegalMoves(_position)[_selected!] ??
                                  const {}),
                        lastMove: _lastMove,
                        hintMove: _showHint && step != null && step.isStudent
                            ? (_expectedMove.from, _expectedMove.to)
                            : null,
                        interactive: interactive,
                        showCoordinates: settings.showCoordinates,
                        showLegalMoves: settings.showLegalMoves,
                        onSquareTap: _onSquareTap,
                        onMove: (from, to) =>
                            _onStudentAttempt(NormalMove(from: from, to: to)),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: LinearProgressIndicator(
                value: _ply / _lesson.plies.length,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
