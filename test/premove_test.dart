import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkmate_next/domain/game_controller.dart';
import 'package:checkmate_next/domain/match/match_protocol.dart';
import 'package:checkmate_next/domain/model/time_control.dart';

import 'support/fake_transport.dart';

void main() {
  GameController build(
    FakeTransport transport, {
    String fen = kInitialFEN,
    Side localSide = Side.white,
  }) => GameController(
    config: MatchConfig(
      matchId: 'test',
      kind: MatchKind.engine,
      localSide: localSide,
      timeControl: TimeControl.unlimited,
      startingFen: fen,
    ),
    transport: transport,
    analysisEnabled: false,
  );

  group('ön hamle', () {
    test('sıra rakipteyken çizilir, sıra gelince oynanır', () async {
      final transport = FakeTransport(kind: MatchKind.engine);
      final controller = build(transport);
      await controller.start();

      controller.selectSquare(Square.e2);
      controller.selectSquare(Square.e4);
      expect(controller.isLocalTurn, isFalse);

      controller.selectSquare(Square.g1);
      expect(controller.premoveFrom, Square.g1);
      controller.selectSquare(Square.f3);
      expect(controller.premove?.uci, 'g1f3');
      expect(controller.premoveSquares, containsAll([Square.g1, Square.f3]));

      transport.reply('e7e5');
      await Future<void>.delayed(Duration.zero);

      expect(controller.moves.length, 3);
      expect(controller.moves.last.san, 'Nf3');
      expect(controller.premove, isNull);
      expect(controller.premoveSquares, isEmpty);
      controller.dispose();
    });

    test('yasadışı kalan ön hamle sessizce silinir', () async {
      final transport = FakeTransport(kind: MatchKind.engine);
      final controller = build(transport);
      await controller.start();

      controller.selectSquare(Square.e2);
      controller.selectSquare(Square.e4);
      // e4-e5 ancak e5 boşsa yasal; rakip e5 oynayınca imkânsızlaşır.
      controller.selectSquare(Square.e4);
      controller.selectSquare(Square.e5);
      expect(controller.premove?.uci, 'e4e5');

      transport.reply('e7e5');
      await Future<void>.delayed(Duration.zero);

      expect(controller.moves.length, 2);
      expect(controller.premove, isNull);
      expect(controller.isLocalTurn, isTrue);
      controller.dispose();
    });

    test('aynı kareye dokunmak seçimi, herhangi bir dokunuş ön hamleyi '
        'iptal eder', () async {
      final transport = FakeTransport(kind: MatchKind.engine);
      final controller = build(transport);
      await controller.start();
      controller.selectSquare(Square.e2);
      controller.selectSquare(Square.e4);

      controller.selectSquare(Square.g1);
      controller.selectSquare(Square.g1);
      expect(controller.premoveFrom, isNull);

      controller.selectSquare(Square.g1);
      controller.selectSquare(Square.f3);
      expect(controller.premove, isNotNull);
      controller.selectSquare(Square.a3);
      expect(controller.premove, isNull);
      controller.dispose();
    });

    test('rakip taşına ön hamle başlatılamaz', () async {
      final transport = FakeTransport(kind: MatchKind.engine);
      final controller = build(transport);
      await controller.start();
      controller.selectSquare(Square.e2);
      controller.selectSquare(Square.e4);

      controller.selectSquare(Square.e7);
      expect(controller.premoveFrom, isNull);
      controller.dispose();
    });

    test('terfili ön hamle vezire terfi eder', () async {
      final transport = FakeTransport(kind: MatchKind.engine);
      final controller = build(transport, fen: '7k/P7/8/8/8/8/8/K7 b - - 0 1');
      await controller.start();
      expect(controller.isLocalTurn, isFalse);

      controller.selectSquare(Square.a7);
      controller.selectSquare(Square.a8);
      expect(controller.premove?.uci, 'a7a8');

      transport.reply('h8g8');
      await Future<void>.delayed(Duration.zero);

      expect(controller.moves.last.uci, 'a7a8q');
      expect(controller.position.board.pieceAt(Square.a8)?.role, Role.queen);
      controller.dispose();
    });

    test('iki kişilik oyunda ön hamle yolu hiç açılmaz', () async {
      final transport = FakeTransport();
      final controller = GameController(
        config: MatchConfig(
          matchId: 'test',
          kind: MatchKind.passAndPlay,
          localSide: Side.white,
          timeControl: TimeControl.unlimited,
        ),
        transport: transport,
        analysisEnabled: false,
      );
      await controller.start();
      controller.selectSquare(Square.e2);
      controller.selectSquare(Square.e4);
      // Sıra siyahta ama iki kişilik oyunda bu da yereldir.
      controller.selectSquare(Square.e7);
      expect(controller.premoveFrom, isNull);
      expect(controller.selectedSquare, Square.e7);
      controller.dispose();
    });
  });
}
