import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satranc/domain/game_controller.dart';
import 'package:satranc/domain/match/match_protocol.dart';
import 'package:satranc/domain/match/match_transport.dart';
import 'package:satranc/domain/model/time_control.dart';

/// Testlerde rakip yerine geçen, gönderilen komutları kaydeden taşıma katmanı.
class FakeTransport implements MatchTransport {
  final _events = StreamController<MatchEvent>.broadcast();
  final List<MatchCommand> sent = [];

  @override
  MatchKind get kind => MatchKind.passAndPlay;

  @override
  Stream<MatchEvent> get events => _events.stream;

  @override
  MatchConnectionState get connectionState => MatchConnectionState.connected;

  @override
  Future<void> open(MatchConfig config) async =>
      _events.add(MatchOpened(config));

  @override
  Future<void> send(MatchCommand command) async => sent.add(command);

  @override
  Future<void> close() async => _events.close();

  /// Rakip hamlesini simüle eder.
  void reply(String uci) => _events.add(RemoteMove(uci: uci));
}

GameController build({
  String fen = kInitialFEN,
  MatchKind kind = MatchKind.passAndPlay,
  Side localSide = Side.white,
  required FakeTransport transport,
}) {
  return GameController(
    config: MatchConfig(
      matchId: 'test',
      kind: kind,
      localSide: localSide,
      timeControl: TimeControl.unlimited,
      startingFen: fen,
    ),
    transport: transport,
    analysisEnabled: false,
  );
}

void main() {
  group('GameController', () {
    test('geçerli hamle uygulanır ve SAN kaydedilir', () async {
      final transport = FakeTransport();
      final controller = build(transport: transport);
      await controller.start();

      controller.selectSquare(Square.e2);
      controller.selectSquare(Square.e4);

      expect(controller.moves.length, 1);
      expect(controller.moves.first.san, 'e4');
      expect(controller.moves.first.uci, 'e2e4');
      expect(controller.position.turn, Side.black);
      expect(transport.sent.whereType<SubmitMove>().length, 1);
      controller.dispose();
    });

    test('geçersiz hamle yok sayılır', () async {
      final transport = FakeTransport();
      final controller = build(transport: transport);
      await controller.start();

      controller.selectSquare(Square.e2);
      controller.selectSquare(Square.e5); // piyon iki kareden fazla gidemez
      expect(controller.moves, isEmpty);
      controller.dispose();
    });

    test('kısa rok yapılabilir ve SAN doğru üretilir', () async {
      final transport = FakeTransport();
      final controller = build(
        transport: transport,
        fen: 'r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq - 0 1',
      );
      await controller.start();

      controller.selectSquare(Square.e1);
      expect(controller.destinationsForSelected, contains(Square.g1));
      controller.selectSquare(Square.g1);

      expect(controller.moves.single.san, 'O-O');
      expect(controller.moves.single.uci, 'e1g1');
      expect(controller.position.board.pieceAt(Square.f1)?.role, Role.rook);
      controller.dispose();
    });

    test('kaleye dokunarak rok yapılırsa kabloya standart UCI gider', () async {
      final transport = FakeTransport();
      final controller = build(
        transport: transport,
        fen: 'r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq - 0 1',
      );
      await controller.start();

      // dartchess kaleyi de geçerli hedef sayar (e1h1); UCI protokolü ise
      // yalnızca e1g1 biçimini tanır.
      controller.selectSquare(Square.e1);
      expect(controller.destinationsForSelected, contains(Square.h1));
      controller.selectSquare(Square.h1);

      expect(controller.moves.single.san, 'O-O');
      expect(controller.moves.single.uci, 'e1g1');
      expect(transport.sent.whereType<SubmitMove>().single.uci, 'e1g1');
      controller.dispose();
    });

    test('uzun rok kabloya e1c1 olarak gider', () async {
      final transport = FakeTransport();
      final controller = build(
        transport: transport,
        fen: 'r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq - 0 1',
      );
      await controller.start();

      controller.selectSquare(Square.e1);
      controller.selectSquare(Square.a1);

      expect(controller.moves.single.san, 'O-O-O');
      expect(controller.moves.single.uci, 'e1c1');
      expect(controller.position.board.pieceAt(Square.c1)?.role, Role.king);
      controller.dispose();
    });

    test('motorun gönderdiği rok hamlesi uygulanır', () async {
      final transport = FakeTransport();
      final controller = build(
        transport: transport,
        kind: MatchKind.engine,
        localSide: Side.white,
        fen: 'r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq - 0 1',
      );
      await controller.start();

      controller.selectSquare(Square.e1);
      controller.selectSquare(Square.g1);
      transport.reply('e8g8');
      await Future<void>.delayed(Duration.zero);

      expect(controller.moves.last.san, 'O-O');
      expect(controller.position.board.pieceAt(Square.g8)?.role, Role.king);
      expect(controller.position.board.pieceAt(Square.f8)?.role, Role.rook);
      controller.dispose();
    });

    test('geçerken alma uygulanır', () async {
      final transport = FakeTransport();
      final controller = build(
        transport: transport,
        fen: 'rnbqkbnr/pp1ppppp/8/1Pp5/8/8/P1PPPPPP/RNBQKBNR w KQkq c6 0 3',
      );
      await controller.start();

      controller.selectSquare(Square.b5);
      expect(controller.destinationsForSelected, contains(Square.c6));
      controller.selectSquare(Square.c6);

      expect(controller.moves.single.san, 'bxc6');
      expect(controller.position.board.pieceAt(Square.c5), isNull);
      controller.dispose();
    });

    test('piyon terfisi seçim ister ve seçilen taşa dönüşür', () async {
      final transport = FakeTransport();
      final controller = build(
        transport: transport,
        fen: '8/P6k/8/8/8/8/8/K7 w - - 0 1',
      );
      await controller.start();

      controller.selectSquare(Square.a7);
      controller.selectSquare(Square.a8);
      expect(controller.pendingPromotion, isNotNull);
      expect(controller.moves, isEmpty);

      controller.completePromotion(Role.knight);
      expect(controller.moves.single.uci, 'a7a8n');
      expect(controller.position.board.pieceAt(Square.a8)?.role, Role.knight);
      controller.dispose();
    });

    test('şah mat oyunu bitirir', () async {
      final transport = FakeTransport();
      final controller = build(
        transport: transport,
        fen: '6k1/5ppp/8/8/8/8/8/R3K2R w KQ - 0 1',
      );
      await controller.start();

      controller.selectSquare(Square.a1);
      controller.selectSquare(Square.a8);

      expect(controller.phase, GamePhase.finished);
      expect(controller.result?.reason, GameEndReason.checkmate);
      expect(controller.result?.winner, Side.white);
      expect(controller.moves.single.san, endsWith('#'));
      controller.dispose();
    });

    test('pat beraberlikle biter', () async {
      final transport = FakeTransport();
      final controller = build(
        transport: transport,
        fen: '7k/8/8/8/8/8/6Q1/K7 w - - 0 1',
      );
      await controller.start();

      // Vezir g6'ya gider: siyah şah kaçamaz ama şah da çekilmez.
      controller.selectSquare(Square.g2);
      controller.selectSquare(Square.g6);

      expect(controller.result?.reason, GameEndReason.stalemate);
      expect(controller.result?.isDraw, isTrue);
      controller.dispose();
    });

    test('rakip hamlesi taşıma katmanından uygulanır', () async {
      final transport = FakeTransport();
      final controller = build(
        transport: transport,
        kind: MatchKind.engine,
        localSide: Side.white,
      );
      await controller.start();

      controller.selectSquare(Square.e2);
      controller.selectSquare(Square.e4);
      transport.reply('e7e5');
      await Future<void>.delayed(Duration.zero);

      expect(controller.moves.length, 2);
      expect(controller.moves.last.san, 'e5');
      expect(controller.position.turn, Side.white);
      controller.dispose();
    });

    test('üç kez tekrar talep edilebilir', () async {
      final transport = FakeTransport();
      final controller = build(transport: transport);
      await controller.start();

      // Atlar ileri geri oynatılarak pozisyon üç kez tekrarlanır.
      const cycle = [
        (Square.g1, Square.f3),
        (Square.g8, Square.f6),
        (Square.f3, Square.g1),
        (Square.f6, Square.g8),
      ];
      for (int i = 0; i < 2; i++) {
        for (final (from, to) in cycle) {
          controller.selectSquare(from);
          controller.selectSquare(to);
        }
      }

      expect(controller.moves.length, 8);
      expect(controller.claimDrawIfEligible(), isTrue);
      expect(controller.result?.reason, GameEndReason.threefoldRepetition);
      controller.dispose();
    });

    test('tarihçede gezinme canlı pozisyonu bozmaz', () async {
      final transport = FakeTransport();
      final controller = build(transport: transport);
      await controller.start();

      controller.selectSquare(Square.e2);
      controller.selectSquare(Square.e4);
      controller.selectSquare(Square.e7);
      controller.selectSquare(Square.e5);

      final liveFen = controller.position.fen;
      controller.browseStart();
      expect(controller.isBrowsingHistory, isTrue);
      expect(controller.displayedPosition.fen, kInitialFEN);
      expect(controller.position.fen, liveFen);

      controller.goLive();
      expect(controller.isBrowsingHistory, isFalse);
      controller.dispose();
    });

    test('PGN başlıkları ve hamleleri içerir', () async {
      final transport = FakeTransport();
      final controller = build(transport: transport);
      await controller.start();

      controller.selectSquare(Square.e2);
      controller.selectSquare(Square.e4);
      controller.selectSquare(Square.c7);
      controller.selectSquare(Square.c5);

      final pgn = controller.toPgn(date: DateTime(2026, 8, 23));
      expect(pgn, contains('[Date "2026.08.23"]'));
      expect(pgn, contains('[Result "*"]'));
      expect(pgn, contains('1. e4 c5'));
      controller.dispose();
    });

    test('terk eden taraf kaybeder', () async {
      final transport = FakeTransport();
      final controller = build(
        transport: transport,
        kind: MatchKind.engine,
        localSide: Side.white,
      );
      await controller.start();

      await controller.resign();
      expect(controller.result?.reason, GameEndReason.resignation);
      expect(controller.result?.winner, Side.black);
      expect(transport.sent.whereType<ResignMatch>().length, 1);
      controller.dispose();
    });
  });
}
