import 'package:flutter_test/flutter_test.dart';
import 'package:satranc/domain/model/difficulty.dart';

void main() {
  group('DifficultyLevel', () {
    test('sekiz kademe tanımlıdır ve Elo değerleri artar', () {
      expect(DifficultyLevel.values.length, 8);
      for (int i = 1; i < DifficultyLevel.values.length; i++) {
        expect(
          DifficultyLevel.values[i].approximateElo,
          greaterThan(DifficultyLevel.values[i - 1].approximateElo),
        );
      }
    });

    test('kimlikten çözümleme çalışır, bilinmeyen kimlik kulübe düşer', () {
      expect(DifficultyLevel.fromId('master'), DifficultyLevel.master);
      expect(DifficultyLevel.fromId('yok'), DifficultyLevel.club);
      expect(DifficultyLevel.fromId(null), DifficultyLevel.club);
    });

    test('UCI_Elo yalnızca Stockfish alt sınırının üstünde kullanılır', () {
      for (final level in DifficultyLevel.values) {
        final elo = level.engineOptions.limitElo;
        if (elo != null) {
          expect(elo, greaterThanOrEqualTo(1320));
        }
      }
    });

    test('alt kademeler MultiPV ile hata payı kullanır', () {
      expect(
        DifficultyLevel.beginner.engineOptions.blunderChance,
        greaterThan(0),
      );
      expect(DifficultyLevel.beginner.searchLimits.multiPv, greaterThan(1));
      expect(DifficultyLevel.grandmaster.engineOptions.blunderChance, 0);
      expect(DifficultyLevel.grandmaster.engineOptions.limitElo, isNull);
    });

    test('UCI komutları beklenen seçenekleri üretir', () {
      final cmds = DifficultyLevel.club.engineOptions.toUciCommands();
      expect(cmds, contains('setoption name UCI_LimitStrength value true'));
      expect(cmds, contains('setoption name UCI_Elo value 1500'));

      final full = DifficultyLevel.grandmaster.engineOptions.toUciCommands();
      expect(full, contains('setoption name UCI_LimitStrength value false'));
      expect(full, contains('setoption name Skill Level value 20'));
    });
  });
}
