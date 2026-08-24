import 'package:dartchess/dartchess.dart';

/// Zorunlu mat çözücüsü.
///
/// Motorsuz, tam arama: sıradaki tarafın rakip ne oynarsa oynasın en çok
/// [maxMoves] kendi hamlesinde mat edip edemeyeceğini kesin olarak söyler.
/// Bulmaca verisinin doğruluğu testlerde bununla kanıtlanır; ayrıca
/// bulmaca ekranı "hâlâ matta mı" kontrolünü motorsuz yapmak için kullanır.
/// Dallanma üstel olduğu için yalnızca az taşlı, zorlayıcı konumlarda
/// kullanılmalıdır.
class MateSolver {
  MateSolver._();

  /// En küçük `n <= maxMoves` ile "n hamlede mat" varsa onu, yoksa `null`
  /// döndürür.
  static int? mateDepth(Position position, int maxMoves) {
    for (int n = 1; n <= maxMoves; n++) {
      if (canForceMate(position, n)) return n;
    }
    return null;
  }

  /// Sıradaki taraf en çok [movesLeft] kendi hamlesinde matı zorlayabilir mi?
  static bool canForceMate(Position position, int movesLeft) {
    if (movesLeft <= 0 || position.isGameOver) return false;
    for (final move in _legalMoves(position)) {
      final after = position.play(move);
      if (after.isCheckmate) return true;
      if (movesLeft == 1) continue;
      if (after.isGameOver) continue; // pat ya da yetersiz materyal
      var allRepliesLose = true;
      for (final reply in _legalMoves(after)) {
        final next = after.play(reply);
        if (!canForceMate(next, movesLeft - 1)) {
          allRepliesLose = false;
          break;
        }
      }
      if (allRepliesLose) return true;
    }
    return false;
  }

  static Iterable<Move> _legalMoves(Position position) sync* {
    for (final entry in position.legalMoves.entries) {
      for (final to in entry.value.squares) {
        final move = NormalMove(from: entry.key, to: to);
        // Terfi: mat aramasında vezir ve at yeterlidir; kale ve fil vezirin
        // alt kümesidir, at ise farklı kareleri görür.
        final piece = position.board.pieceAt(entry.key);
        if (piece?.role == Role.pawn &&
            (to.rank == Rank.first || to.rank == Rank.eighth)) {
          yield move.withPromotion(Role.queen);
          yield move.withPromotion(Role.knight);
        } else {
          yield move;
        }
      }
    }
  }
}
