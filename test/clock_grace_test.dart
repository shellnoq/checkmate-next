import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkmate_next/domain/game_controller.dart';
import 'package:checkmate_next/domain/match/match_protocol.dart';
import 'package:checkmate_next/domain/model/time_control.dart';

import 'support/fake_transport.dart';

void main() {
  GameController build({
    Duration grace = const Duration(milliseconds: 120),
  }) =>
      GameController(
        config: MatchConfig(
          matchId: 'test',
          kind: MatchKind.passAndPlay,
          localSide: Side.white,
          timeControl: TimeControl.blitz5,
        ),
        transport: FakeTransport(),
        analysisEnabled: false,
        clockGrace: grace,
      );

  group('saat açılış payı', () {
    test('saat hemen değil, pay dolunca başlar', () async {
      final controller = build();
      await controller.start();

      expect(controller.clock.isRunning, isFalse,
          reason: 'oyuncu daha taşlara bakarken süre erimemeli');

      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(controller.clock.isRunning, isTrue);
      expect(controller.clock.activeSide, Side.white);
      controller.dispose();
    });

    test('pay dolmadan hamle yapılırsa saat o anda başlar', () async {
      final controller = build(grace: const Duration(seconds: 5));
      await controller.start();

      controller.selectSquare(Square.e2);
      controller.selectSquare(Square.e4);

      expect(controller.clock.isRunning, isTrue);
      expect(controller.clock.activeSide, Side.black);
      // Beyaz henüz süre kaybetmedi: pay içinde oynadı.
      expect(controller.clock.remainingOf(Side.white),
          TimeControl.blitz5.initial);
      controller.dispose();
    });

    test('pay zamanlayıcısı hamleden sonra saati yeniden kurcalamaz',
        () async {
      final controller = build(grace: const Duration(milliseconds: 80));
      await controller.start();

      controller.selectSquare(Square.e2);
      controller.selectSquare(Square.e4);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Sıra hâlâ siyahta olmalı; zamanlayıcı beyazı yeniden başlatmamalı.
      expect(controller.clock.activeSide, Side.black);
      controller.dispose();
    });
  });

  group('kayda değerlik', () {
    test('hamlesiz oyun kayda değmez, hamleli oyun değer', () async {
      final controller = build();
      await controller.start();
      expect(controller.shouldRecord, isFalse);

      controller.selectSquare(Square.e2);
      controller.selectSquare(Square.e4);
      expect(controller.shouldRecord, isTrue);
      controller.dispose();
    });

    test('hamlesiz terk sonucu üretir ama kayda değmez', () async {
      final controller = build();
      await controller.start();

      await controller.resign();
      expect(controller.result, isNotNull);
      expect(controller.shouldRecord, isFalse);
      controller.dispose();
    });
  });
}
