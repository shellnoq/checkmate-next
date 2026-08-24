import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkmate_next/domain/puzzles/mate_solver.dart';
import 'package:checkmate_next/domain/puzzles/puzzle.dart';
import 'package:checkmate_next/domain/puzzles/puzzle_session.dart';

void main() {
  group('bulmaca verisi', () {
    test(
      'her bulmaca tam olarak bildirilen derinlikte zorunlu mattır',
      () {
        final ids = <String>{};
        for (final puzzle in PuzzleSet.all) {
          expect(ids.add(puzzle.id), isTrue, reason: 'yinelenen id');
          final position = Chess.fromSetup(Setup.parseFen(puzzle.fen));
          final depth = MateSolver.mateDepth(position, puzzle.mateIn + 1);
          expect(
            depth,
            puzzle.mateIn,
            reason: '${puzzle.id}: beklenen ${puzzle.mateIn}, bulunan $depth',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });

  group('PuzzleSession', () {
    Puzzle byId(String id) => PuzzleSet.all.firstWhere((p) => p.id == id);

    test('tek hamlelik mat çözülür', () {
      final session = PuzzleSession(byId('m1-backrank'));
      final feedback = session.playerMove(
        NormalMove(from: Square.a1, to: Square.a8),
      );
      expect(feedback, isA<PuzzleSolved>());
      expect(session.position.isCheckmate, isTrue);
    });

    test('yanlış hamle reddedilir ve reset başa sarar', () {
      final session = PuzzleSession(byId('m1-backrank'));
      final feedback = session.playerMove(
        NormalMove(from: Square.a1, to: Square.a7),
      );
      expect(feedback, isA<PuzzleWrong>());
      session.reset();
      expect(session.movesUsed, 0);
      expect(session.position.fen, byId('m1-backrank').fen);
    });

    test('iki hamlelik matta savunma yanıtlar ve mat tamamlanır', () {
      final session = PuzzleSession(byId('m2-ladder'));
      // 1.Rb7 matı korur; savunma her yanıtında 2.Ra8# ya da eşdeğeri gelir.
      final first = session.playerMove(
        NormalMove(from: Square.b1, to: Square.b7),
      );
      expect(first, isA<PuzzleContinues>());
      expect(session.isPlayersTurn, isTrue);
      expect(session.movesLeft, 1);

      final mate = session.playerMove(
        NormalMove(from: Square.a2, to: Square.a8),
      );
      expect(mate, isA<PuzzleSolved>());
    });

    test('matı elden kaçıran hamle yanlış sayılır', () {
      final session = PuzzleSession(byId('m2-ladder'));
      // 1.Ra2-a3 hiçbir şeyi zorlamaz; şah kaçar.
      final feedback = session.playerMove(
        NormalMove(from: Square.a2, to: Square.a3),
      );
      expect(feedback, isA<PuzzleWrong>());
    });

    test('yasadışı hamle yanlış sayılır ve durum bozulmaz', () {
      final session = PuzzleSession(byId('m2-ladder'));
      final before = session.position.fen;
      final feedback = session.playerMove(
        NormalMove(from: Square.b1, to: Square.b1),
      );
      expect(feedback, isA<PuzzleWrong>());
      expect(session.position.fen, before);
      expect(session.movesUsed, 0);
    });

    test(
      'üç hamlelik mat baştan sona oynanabilir',
      () {
        final session = PuzzleSession(byId('m3-ladder-center'));
        // Çözücünün kendisiyle oyna: her adımda matı koruyan bir hamle bul.
        var guard = 0;
        while (guard++ < 6) {
          NormalMove? keeping;
          for (final entry in session.position.legalMoves.entries) {
            for (final to in entry.value.squares) {
              final move = NormalMove(from: entry.key, to: to);
              final after = session.position.play(
                session.position.normalizeMove(move),
              );
              if (after.isCheckmate ||
                  _defenderCannotEscape(after, session.movesLeft - 1)) {
                keeping = move;
                break;
              }
            }
            if (keeping != null) break;
          }
          expect(keeping, isNotNull, reason: 'matı koruyan hamle bulunamadı');
          final feedback = session.playerMove(keeping!);
          if (feedback is PuzzleSolved) return;
          expect(feedback, isA<PuzzleContinues>());
        }
        fail('bulmaca beklenen sürede çözülemedi');
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}

bool _defenderCannotEscape(Position afterAttacker, int remaining) {
  if (remaining <= 0) return false;
  for (final entry in afterAttacker.legalMoves.entries) {
    for (final to in entry.value.squares) {
      final next = afterAttacker.play(
        afterAttacker.normalizeMove(NormalMove(from: entry.key, to: to)),
      );
      if (!MateSolver.canForceMate(next, remaining)) return false;
    }
  }
  return true;
}
