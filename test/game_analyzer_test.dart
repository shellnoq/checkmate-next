import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkmate_next/domain/analysis/game_analyzer.dart';
import 'package:checkmate_next/engine/engine_models.dart';

import 'support/fake_engine.dart';

void main() {
  group('classify', () {
    test('eşikler beklendiği gibi', () {
      expect(
        GameAnalyzer.classify(cpLoss: 0, wasBestMove: true),
        MoveQuality.brilliant,
      );
      expect(
        GameAnalyzer.classify(cpLoss: 20, wasBestMove: false),
        MoveQuality.good,
      );
      expect(
        GameAnalyzer.classify(cpLoss: 60, wasBestMove: false),
        MoveQuality.dubious,
      );
      expect(
        GameAnalyzer.classify(cpLoss: 150, wasBestMove: false),
        MoveQuality.bad,
      );
      // En iyi hamle bile büyük kayıpla oynandıysa yıldız almaz.
      expect(
        GameAnalyzer.classify(cpLoss: 150, wasBestMove: true),
        MoveQuality.bad,
      );
    });
  });

  group('whiteCentipawns', () {
    EngineLine line({int? cp, int? mate}) =>
        EngineLine(multiPvIndex: 1, depth: 12, centipawns: cp, mateIn: mate);

    test('sıra siyahtayken işaret çevrilir', () {
      expect(
        GameAnalyzer.whiteCentipawns(line(cp: 40), sideToMove: Side.white),
        40,
      );
      expect(
        GameAnalyzer.whiteCentipawns(line(cp: 40), sideToMove: Side.black),
        -40,
      );
    });

    test('mat skoru santipiyon tavanına çevrilir', () {
      final m2 = GameAnalyzer.whiteCentipawns(
        line(mate: 2),
        sideToMove: Side.white,
      );
      expect(m2, greaterThan(9000));
      final opponentMates = GameAnalyzer.whiteCentipawns(
        line(mate: -3),
        sideToMove: Side.white,
      );
      expect(opponentMates, lessThan(-9000));
      // Siyah mat ediyorsa beyaz gözünden negatiftir.
      expect(
        GameAnalyzer.whiteCentipawns(line(mate: 2), sideToMove: Side.black),
        lessThan(-9000),
      );
    });
  });

  group('analyze', () {
    // Kurgu: e4 mükemmel, e5 şüpheli (60 kayıp), Nf3 kötü (150 kayıp).
    SearchResult scripted(String fen, List<String> moves) {
      switch (moves.length) {
        case 0:
          return const SearchResult(
            bestMoveUci: 'e2e4',
            lines: [
              EngineLine(
                multiPvIndex: 1,
                depth: 12,
                centipawns: 30,
                pv: ['e2e4'],
              ),
            ],
          );
        case 1: // sıra siyahta, beyaz +30
          return const SearchResult(
            bestMoveUci: 'c7c5',
            lines: [
              EngineLine(
                multiPvIndex: 1,
                depth: 12,
                centipawns: -30,
                pv: ['c7c5'],
              ),
            ],
          );
        case 2: // sıra beyazda, beyaz +90
          return const SearchResult(
            bestMoveUci: 'g1f3',
            lines: [
              EngineLine(
                multiPvIndex: 1,
                depth: 12,
                centipawns: 90,
                pv: ['g1f3'],
              ),
            ],
          );
        default: // sıra siyahta, beyaz -60
          return const SearchResult(
            bestMoveUci: 'b8c6',
            lines: [
              EngineLine(
                multiPvIndex: 1,
                depth: 12,
                centipawns: 60,
                pv: ['b8c6'],
              ),
            ],
          );
      }
    }

    test('kayıplar ve sınıflar doğru hesaplanır', () async {
      final engine = FakeEngine(onSearch: scripted);
      final analysis = await GameAnalyzer.analyze(
        engine: engine,
        startFen: kInitialFEN,
        uciMoves: ['e2e4', 'e7e5', 'g1f3'],
      );

      expect(analysis, isNotNull);
      expect(analysis!.cpLoss, [0, 60, 150]);
      expect(analysis.qualities, [
        MoveQuality.brilliant, // en iyi hamle, kayıpsız
        MoveQuality.dubious,
        MoveQuality.bad,
      ]);
      expect(engine.searchCount, 4);
    });

    test('kitap içindeki hamleler kitap olarak işaretlenir', () async {
      final engine = FakeEngine(onSearch: scripted);
      final analysis = await GameAnalyzer.analyze(
        engine: engine,
        startFen: kInitialFEN,
        uciMoves: ['e2e4', 'e7e5', 'g1f3'],
        bookPlies: 2,
      );
      expect(analysis!.qualities, [
        MoveQuality.book,
        MoveQuality.book,
        MoveQuality.bad,
      ]);
    });

    test('iptal edilince null döner', () async {
      final engine = FakeEngine(onSearch: scripted);
      var calls = 0;
      final analysis = await GameAnalyzer.analyze(
        engine: engine,
        startFen: kInitialFEN,
        uciMoves: ['e2e4', 'e7e5', 'g1f3'],
        isCancelled: () => ++calls > 2,
      );
      expect(analysis, isNull);
      expect(engine.searchCount, lessThan(4));
    });
  });
}
