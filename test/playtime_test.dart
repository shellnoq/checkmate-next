import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkmate_next/domain/game_controller.dart';
import 'package:checkmate_next/domain/match/match_protocol.dart';
import 'package:checkmate_next/domain/model/time_control.dart';

import 'support/fake_transport.dart';

void main() {
  GameController build(FakeTransport transport) => GameController(
    config: MatchConfig(
      matchId: 'test',
      kind: MatchKind.passAndPlay,
      localSide: Side.white,
      timeControl: TimeControl.unlimited,
    ),
    transport: transport,
    analysisEnabled: false,
  );

  group('oynama süresi', () {
    test('oyun başlayınca sayaç işler', () async {
      final controller = build(FakeTransport());
      expect(controller.playedTime, Duration.zero);

      await controller.start();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(controller.playedTime, greaterThan(Duration.zero));
      controller.dispose();
    });

    test('arka plana alınınca durur, öne dönünce devam eder', () async {
      final controller = build(FakeTransport());
      await controller.start();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      controller.pausePlayClock();
      final atPause = controller.playedTime;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(
        controller.playedTime,
        atPause,
        reason: 'arka planda süre işlememeli',
      );

      controller.resumePlayClock();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(controller.playedTime, greaterThan(atPause));
      controller.dispose();
    });

    test('oyun bitince sayaç durur', () async {
      final transport = FakeTransport();
      final controller = build(transport);
      await controller.start();
      await Future<void>.delayed(const Duration(milliseconds: 40));

      await controller.resign();
      final atEnd = controller.playedTime;
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(controller.playedTime, atEnd);
      controller.dispose();
    });

    test('bitmiş oyunda öne dönmek sayacı yeniden başlatmaz', () async {
      final controller = build(FakeTransport());
      await controller.start();
      await controller.resign();
      final atEnd = controller.playedTime;

      controller.resumePlayClock();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(controller.playedTime, atEnd);
      controller.dispose();
    });
  });
}
