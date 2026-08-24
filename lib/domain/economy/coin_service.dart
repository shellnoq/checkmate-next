import '../../core/storage/app_storage.dart';

/// Oyun içi coin cüzdanı.
///
/// Coin yalnızca oyun içinde kazanılır ve harcanır; gerçek parayla hiçbir
/// bağı yoktur. Bakiye istatistik kutusunda tutulur.
class CoinService {
  CoinService._();

  static int get balance => AppStorage.statOf('coins');

  static Future<void> add(int amount) async {
    if (amount <= 0) return;
    await AppStorage.bumpStat('coins', amount);
  }

  /// Yeterli bakiye varsa düşer ve `true` döner.
  static Future<bool> trySpend(int amount) async {
    if (amount <= 0) return true;
    if (balance < amount) return false;
    await AppStorage.bumpStat('coins', -amount);
    return true;
  }

  /// Motora karşı biten oyunun ödülü.
  ///
  /// Kısa galibiyet (çoban matı gibi) küçük ödül alır: ucuz zaferi taramaya
  /// dönüştürmemek için. Uzun ve üst kademede kazanılan oyun daha çok verir.
  /// Kaybeden de bir şey alır; oynamanın kendisi değerlidir.
  static int gameReward({
    required bool won,
    required bool draw,
    required int difficultyTier,
    required int moveCount,
  }) {
    if (draw) return 3;
    if (!won) return 1;
    if (moveCount < 15) return 5;
    return 8 + difficultyTier;
  }

  /// Bir bulmacanın ilk çözümünün ödülü.
  static int puzzleReward(int mateIn) => mateIn * 5;
}
