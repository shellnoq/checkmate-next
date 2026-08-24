import 'dart:io';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkmate_next/core/storage/app_storage.dart';
import 'package:checkmate_next/domain/game_controller.dart';
import 'package:checkmate_next/domain/match/match_protocol.dart';
import 'package:checkmate_next/domain/model/time_control.dart';
import 'package:checkmate_next/domain/saved_games.dart';

import 'support/fake_transport.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AppStorage.initForTesting(
      Directory.systemTemp.createTempSync('checkmate_saved').path,
    );
  });

  SavedGame make(String level, DateTime at, [List<String>? uci]) => SavedGame(
    difficultyId: level,
    localSide: 'white',
    timeControlId: 'unlimited',
    uci: uci ?? const ['e2e4'],
    savedAt: at,
  );

  group('SavedGameStore', () {
    setUp(() async {
      for (final game in SavedGameStore.list()) {
        await SavedGameStore.delete(game.difficultyId);
      }
    });

    test('aynı kademeye kayıt üzerine yazar', () async {
      await SavedGameStore.save(make('club', DateTime(2026, 1, 1)));
      await SavedGameStore.save(
        make('club', DateTime(2026, 1, 2), ['e2e4', 'e7e5']),
      );
      final games = SavedGameStore.list();
      expect(games.length, 1);
      expect(games.single.moveCount, 2);
    });

    test('dördüncü kademe gelince en eski yuva boşalır', () async {
      await SavedGameStore.save(make('beginner', DateTime(2026, 1, 1)));
      await SavedGameStore.save(make('club', DateTime(2026, 1, 2)));
      await SavedGameStore.save(make('expert', DateTime(2026, 1, 3)));
      await SavedGameStore.save(make('master', DateTime(2026, 1, 4)));

      final games = SavedGameStore.list();
      expect(games.length, SavedGameStore.maxSlots);
      expect(games.map((g) => g.difficultyId), isNot(contains('beginner')));
      expect(games.first.difficultyId, 'master');
    });

    test('json gidiş dönüşü kayıpsız', () async {
      final original = SavedGame(
        difficultyId: 'expert',
        localSide: 'black',
        timeControlId: 'blitz5',
        uci: const ['e2e4', 'c7c5', 'g1f3'],
        savedAt: DateTime(2026, 8, 24, 12, 30),
        whiteRemainingMs: 123456,
        blackRemainingMs: 98765,
      );
      final copy = SavedGame.fromJson(original.toJson());
      expect(copy.difficultyId, original.difficultyId);
      expect(copy.localSide, original.localSide);
      expect(copy.uci, original.uci);
      expect(copy.whiteRemainingMs, original.whiteRemainingMs);
      expect(copy.savedAt, original.savedAt);
    });
  });

  group('kayıttan devam', () {
    GameController build(
      FakeTransport transport, {
      List<String> resume = const [],
      Side localSide = Side.white,
      TimeControl timeControl = TimeControl.unlimited,
      Duration? white,
      Duration? black,
    }) => GameController(
      config: MatchConfig(
        matchId: 'resume-test',
        kind: MatchKind.engine,
        localSide: localSide,
        timeControl: timeControl,
      ),
      transport: transport,
      analysisEnabled: false,
      resumeMovesUci: resume,
      resumeWhiteClock: white,
      resumeBlackClock: black,
    );

    test('hamleler sessizce kurulur, taşıma katmanına gönderilmez', () async {
      final transport = FakeTransport(kind: MatchKind.engine);
      final controller = build(transport, resume: ['e2e4', 'e7e5', 'g1f3']);
      await controller.start();

      expect(controller.moves.length, 3);
      expect(controller.moves.map((m) => m.san), ['e4', 'e5', 'Nf3']);
      expect(controller.position.turn, Side.black);
      expect(transport.sent, isEmpty);
      expect(transport.openedWithMoves, ['e2e4', 'e7e5', 'g1f3']);
      expect(controller.isLocalTurn, isFalse);
      controller.dispose();
    });

    test('kayıttan dönen saat değerleri geri yüklenir', () async {
      final transport = FakeTransport(kind: MatchKind.engine);
      final controller = build(
        transport,
        resume: ['e2e4', 'e7e5'],
        timeControl: TimeControl.blitz5,
        white: const Duration(seconds: 100),
        black: const Duration(seconds: 80),
      );
      await controller.start();

      expect(
        controller.clock.remainingOf(Side.white),
        const Duration(seconds: 100),
      );
      expect(
        controller.clock.remainingOf(Side.black),
        const Duration(seconds: 80),
      );
      controller.dispose();
    });

    test('devamdan sonra oyun normal sürer ve PGN bütündür', () async {
      final transport = FakeTransport(kind: MatchKind.engine);
      final controller = build(transport, resume: ['e2e4', 'e7e5']);
      await controller.start();

      controller.selectSquare(Square.g1);
      controller.selectSquare(Square.f3);
      expect(controller.moves.length, 3);
      expect(transport.sent.whereType<SubmitMove>().single.uci, 'g1f3');
      expect(controller.toPgn(), contains('1. e4 e5 2. Nf3'));
      controller.dispose();
    });
  });
}
