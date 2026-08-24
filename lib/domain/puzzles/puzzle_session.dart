import 'package:dartchess/dartchess.dart';

import 'mate_solver.dart';
import 'puzzle.dart';

/// Oyuncunun hamlesine verilen karşılık.
sealed class PuzzleFeedback {
  const PuzzleFeedback();
}

/// Mat edildi; bulmaca çözüldü.
class PuzzleSolved extends PuzzleFeedback {
  const PuzzleSolved();
}

/// Hamle matı kaçırdı; baştan denenmeli.
class PuzzleWrong extends PuzzleFeedback {
  const PuzzleWrong();
}

/// Hamle doğru; savunma [reply] ile yanıtladı, sıra yine oyuncuda.
class PuzzleContinues extends PuzzleFeedback {
  const PuzzleContinues(this.reply);

  final NormalMove reply;
}

/// Bir bulmacanın oynanışını yönetir.
///
/// Savunma tarafını da [MateSolver] oynar: en uzun direnen karşılığı seçer.
/// Motor gerekmez, davranış belirlenimcidir ve testlenebilir.
class PuzzleSession {
  PuzzleSession(this.puzzle)
    : position = Chess.fromSetup(Setup.parseFen(puzzle.fen)) {
    playerSide = position.turn;
  }

  final Puzzle puzzle;
  Position position;
  late final Side playerSide;

  /// Oyuncunun şimdiye kadar yaptığı hamle sayısı.
  int movesUsed = 0;

  final List<String> playedUci = [];

  bool get isPlayersTurn => position.turn == playerSide;

  int get movesLeft => puzzle.mateIn - movesUsed;

  /// Oyuncunun hamlesini işler.
  ///
  /// Terfi gerektiren hamle vezirle tamamlanmış olmalıdır; ekran bunu
  /// otomatik yapar.
  PuzzleFeedback playerMove(NormalMove move) {
    final normalized = position.normalizeMove(move);
    if (!position.isLegal(normalized)) return const PuzzleWrong();

    final after = position.play(normalized);
    movesUsed++;

    if (after.isCheckmate) {
      position = after;
      playedUci.add(move.uci);
      return const PuzzleSolved();
    }

    final remaining = puzzle.mateIn - movesUsed;
    if (remaining <= 0) return const PuzzleWrong();

    // Doğru hamle, savunma ne oynarsa oynasın matı korur.
    final replies = _legalMoves(after).toList();
    for (final reply in replies) {
      if (!MateSolver.canForceMate(after.play(reply), remaining)) {
        return const PuzzleWrong();
      }
    }

    // En uzun direnen savunmayı seç.
    NormalMove? best;
    var bestDepth = -1;
    for (final reply in replies) {
      final depth =
          MateSolver.mateDepth(after.play(reply), remaining) ?? remaining;
      if (depth > bestDepth) {
        bestDepth = depth;
        best = reply;
      }
    }
    final reply = best!;
    position = after.play(reply);
    playedUci
      ..add(move.uci)
      ..add(reply.uci);
    return PuzzleContinues(reply);
  }

  /// Bulmacayı başa sarar.
  void reset() {
    position = Chess.fromSetup(Setup.parseFen(puzzle.fen));
    movesUsed = 0;
    playedUci.clear();
  }

  static Iterable<NormalMove> _legalMoves(Position position) sync* {
    for (final entry in position.legalMoves.entries) {
      for (final to in entry.value.squares) {
        yield NormalMove(from: entry.key, to: to);
      }
    }
  }
}
