import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/settings.dart';
import '../../core/audio/sound_service.dart';
import '../../core/l10n/strings.dart';
import '../../core/storage/app_storage.dart';
import '../../domain/puzzles/puzzle.dart';
import '../../domain/economy/achievements.dart';
import '../../domain/economy/coin_service.dart';
import '../../domain/puzzles/puzzle_session.dart';
import '../board/chess_board.dart';

/// Tek bir bulmacanın oynandığı ekran.
class PuzzlePlayScreen extends ConsumerStatefulWidget {
  const PuzzlePlayScreen({super.key, required this.puzzleId});

  final String puzzleId;

  @override
  ConsumerState<PuzzlePlayScreen> createState() => _PuzzlePlayScreenState();
}

class _PuzzlePlayScreenState extends ConsumerState<PuzzlePlayScreen> {
  late final Puzzle _puzzle = PuzzleSet.all.firstWhere(
    (p) => p.id == widget.puzzleId,
  );
  late PuzzleSession _session = PuzzleSession(_puzzle);

  Square? _selected;
  (Square, Square)? _lastMove;
  bool _finished = false;

  Set<Square> get _destinations {
    final from = _selected;
    if (from == null) return const {};
    return makeLegalMoves(_session.position)[from] ?? const {};
  }

  void _onSquareTap(Square square) {
    if (_finished || !_session.isPlayersTurn) return;
    final from = _selected;
    if (from != null && _destinations.contains(square)) {
      _submit(NormalMove(from: from, to: square));
      return;
    }
    final piece = _session.position.board.pieceAt(square);
    setState(() {
      _selected = piece != null && piece.color == _session.playerSide
          ? square
          : null;
    });
  }

  void _onDrag(Square from, Square to) {
    if (_finished || !_session.isPlayersTurn) return;
    final dests = makeLegalMoves(_session.position)[from] ?? const {};
    if (dests.contains(to)) _submit(NormalMove(from: from, to: to));
  }

  void _submit(NormalMove move) {
    // Terfi gerekiyorsa vezirle tamamla; bulmaca setinde alt terfi yok.
    final piece = _session.position.board.pieceAt(move.from);
    final promoting =
        piece?.role == Role.pawn &&
        (move.to.rank == Rank.first || move.to.rank == Rank.eighth);
    final feedback = _session.playerMove(
      promoting ? move.withPromotion(Role.queen) : move,
    );

    switch (feedback) {
      case PuzzleSolved():
        SoundService.instance.play(Sfx.victory);
        setState(() {
          _selected = null;
          _lastMove = (move.from, move.to);
          _finished = true;
        });
        _rewardAndShow();
      case PuzzleWrong():
        SoundService.instance.haptic(HapticStrength.medium);
        setState(() => _selected = null);
        _showWrongBar();
      case PuzzleContinues(:final reply):
        SoundService.instance.play(Sfx.move);
        setState(() {
          _selected = null;
          _lastMove = (reply.from, reply.to);
        });
    }
  }

  Future<void> _rewardAndShow() async {
    final firstSolve = AppStorage.statOf('puzzle_solved_${_puzzle.id}') == 0;
    await AppStorage.bumpStat('puzzle_solved_${_puzzle.id}');
    await AppStorage.bumpStat('puzzles_solved_total');
    var earned = 0;
    if (firstSolve) {
      earned = CoinService.puzzleReward(_puzzle.mateIn);
      await CoinService.add(earned);
    }
    final unlocked = await AchievementService.checkAll();
    if (!mounted) return;
    final s = S.of(context);
    for (final achievement in unlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s.achievementUnlocked(achievement.label(s.tr), achievement.coins),
          ),
        ),
      );
    }
    await _showSolvedSheet(earned);
  }

  void _showWrongBar() {
    final s = S.of(context);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(s.wrongMove),
          action: SnackBarAction(
            label: s.tryAgain,
            onPressed: () => setState(() {
              _session.reset();
              _lastMove = null;
            }),
          ),
        ),
      );
  }

  Future<void> _showSolvedSheet(int earnedCoins) async {
    final s = S.of(context);
    final all = PuzzleSet.all;
    final index = all.indexWhere((p) => p.id == _puzzle.id);
    final next = index + 1 < all.length ? all[index + 1] : null;

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
                  Icons.emoji_events_outlined,
                  size: 44,
                  color: Color(0xFF3F9D6B),
                ),
                const SizedBox(height: 10),
                Text(
                  s.puzzleSolvedTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                if (next != null)
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.pushReplacement('/puzzle', extra: next.id);
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(s.nextPuzzle),
                  ),
                const SizedBox(height: 8),
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

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    final sideText = _session.playerSide == Side.white
        ? s.whiteToPlay
        : s.blackToPlay;

    return Scaffold(
      appBar: AppBar(title: Text(_puzzle.label(settings.turkish))),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                '$sideText · ${s.mateInN(_puzzle.mateIn)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
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
                    return SizedBox(
                      width: size,
                      height: size,
                      child: ChessBoard(
                        position: _session.position,
                        orientation: _session.playerSide,
                        boardTheme: settings.boardTheme,
                        pieceSet: settings.pieceSet,
                        selectedSquare: _selected,
                        legalDestinations: _destinations,
                        lastMove: _lastMove,
                        checkedSquare: _session.position.isCheck
                            ? _session.position.board.kingOf(
                                _session.position.turn,
                              )
                            : null,
                        interactive: !_finished,
                        showCoordinates: settings.showCoordinates,
                        showLegalMoves: settings.showLegalMoves,
                        onSquareTap: _onSquareTap,
                        onMove: _onDrag,
                      ),
                    );
                  },
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _session = PuzzleSession(_puzzle);
                    _selected = null;
                    _lastMove = null;
                    _finished = false;
                  }),
                  icon: const Icon(Icons.replay),
                  label: Text(s.tryAgain),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
