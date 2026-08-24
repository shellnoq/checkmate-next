import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:checkmate_next/core/storage/app_storage.dart';
import 'package:checkmate_next/domain/economy/achievements.dart';
import 'package:checkmate_next/domain/economy/coin_service.dart';
import 'package:checkmate_next/domain/puzzles/puzzle.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AppStorage.initForTesting(
      Directory.systemTemp.createTempSync('checkmate_economy').path,
    );
  });

  setUp(() async {
    await AppStorage.resetStats();
  });

  group('CoinService', () {
    test('oyun ödülü: kısa galibiyet az, uzun ve zor galibiyet çok verir', () {
      final cheap = CoinService.gameReward(
          won: true, draw: false, difficultyTier: 8, moveCount: 7);
      final earned = CoinService.gameReward(
          won: true, draw: false, difficultyTier: 8, moveCount: 40);
      final easy = CoinService.gameReward(
          won: true, draw: false, difficultyTier: 1, moveCount: 40);
      expect(cheap, 5);
      expect(earned, greaterThan(easy));
      expect(CoinService.gameReward(
          won: false, draw: true, difficultyTier: 3, moveCount: 30), 3);
      expect(CoinService.gameReward(
          won: false, draw: false, difficultyTier: 3, moveCount: 30), 1);
    });

    test('bakiye ekleme ve harcama', () async {
      expect(CoinService.balance, 0);
      await CoinService.add(25);
      expect(CoinService.balance, 25);
      expect(await CoinService.trySpend(10), isTrue);
      expect(CoinService.balance, 15);
      expect(await CoinService.trySpend(100), isFalse);
      expect(CoinService.balance, 15);
    });

    test('bulmaca ödülü derinlikle artar', () {
      expect(CoinService.puzzleReward(1), 5);
      expect(CoinService.puzzleReward(3), 15);
    });
  });

  group('AchievementService', () {
    test('koşulu sağlanan başarım bir kez açılır ve coinini verir', () async {
      await AppStorage.bumpStat('wins');
      await AppStorage.bumpStat('wins_club');

      final first = await AchievementService.checkAll();
      final ids = first.map((a) => a.id).toList();
      expect(ids, contains('first_win'));
      expect(ids, contains('beat_club'));
      expect(CoinService.balance,
          first.fold<int>(0, (sum, a) => sum + a.coins));

      // İkinci denetim aynı başarımları yeniden açmaz.
      final second = await AchievementService.checkAll();
      expect(second, isEmpty);
    });

    test('bulmaca başarımları set üzerinden hesaplanır', () async {
      for (final puzzle in PuzzleSet.all.where((p) => p.mateIn == 1)) {
        await AppStorage.bumpStat('puzzle_solved_${puzzle.id}');
      }
      await AppStorage.setStat('puzzles_solved_total', 6);
      final unlocked = await AchievementService.checkAll();
      final ids = unlocked.map((a) => a.id).toList();
      expect(ids, contains('first_puzzle'));
      expect(ids, contains('puzzle_all_m1'));
      expect(ids, isNot(contains('puzzle_master')));
    });

    test('tanımlar tekil ve alanlar dolu', () {
      final ids = <String>{};
      for (final achievement in AchievementService.all) {
        expect(ids.add(achievement.id), isTrue);
        expect(achievement.trName, isNotEmpty);
        expect(achievement.enName, isNotEmpty);
        expect(achievement.coins, greaterThan(0));
      }
    });
  });
}
