import 'package:flutter_test/flutter_test.dart';
import 'package:checkmate_next/engine/uci_parser.dart';

void main() {
  group('UciParser.parseInfo', () {
    test('santipiyon skorunu ve varyantı çözer', () {
      final line = UciParser.parseInfo(
        'info depth 18 seldepth 24 multipv 1 score cp 34 nodes 120345 '
        'nps 900000 hashfull 120 tbhits 0 time 133 pv e2e4 e7e5 g1f3',
      );
      expect(line, isNotNull);
      expect(line!.depth, 18);
      expect(line.multiPvIndex, 1);
      expect(line.centipawns, 34);
      expect(line.mateIn, isNull);
      expect(line.pv, ['e2e4', 'e7e5', 'g1f3']);
      expect(line.bestMoveUci, 'e2e4');
      expect(line.isMate, isFalse);
    });

    test('mat skorunu çözer', () {
      final line = UciParser.parseInfo(
        'info depth 9 multipv 2 score mate -3 pv h7h8 g1g2',
      );
      expect(line!.mateIn, -3);
      expect(line.isMate, isTrue);
      expect(line.multiPvIndex, 2);
    });

    test('negatif skor ve tek hamlelik varyant', () {
      final line = UciParser.parseInfo('info depth 4 score cp -152 pv d7d5');
      expect(line!.centipawns, -152);
      expect(line.pv, ['d7d5']);
    });

    test('bilgi taşımayan satırlar yok sayılır', () {
      expect(
        UciParser.parseInfo('info string NNUE evaluation using net'),
        isNull,
      );
      expect(
        UciParser.parseInfo('info depth 1 currmove e2e4 currmovenumber 1'),
        isNull,
      );
      expect(UciParser.parseInfo('readyok'), isNull);
      expect(UciParser.parseInfo('bestmove e2e4'), isNull);
    });

    test('değerlendirme beyazın gözünden çevrilir', () {
      final line = UciParser.parseInfo('info depth 8 score cp 80 pv e2e4')!;
      expect(line.pawnsFromWhite(whiteToMove: true), 0.8);
      expect(line.pawnsFromWhite(whiteToMove: false), -0.8);
    });
  });

  group('UciParser.parseBestMove', () {
    test('hamle ve ponder çözülür', () {
      expect(UciParser.parseBestMove('bestmove e2e4 ponder e7e5'), (
        'e2e4',
        'e7e5',
      ));
    });

    test('ponder yoksa null döner', () {
      expect(UciParser.parseBestMove('bestmove g1f3'), ('g1f3', null));
    });

    test('terfi hamlesi korunur', () {
      expect(UciParser.parseBestMove('bestmove a7a8q').$1, 'a7a8q');
    });

    test('oynanacak hamle yoksa null döner', () {
      expect(UciParser.parseBestMove('bestmove (none)'), (null, null));
    });
  });
}
