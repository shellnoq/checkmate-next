import 'board_theme.dart';
import '../../features/board/piece_set.dart';

/// Oyun ekranının arkasına çizilen motif.
enum BackgroundStyle { none, stars, leaves, dunes }

/// Tahta, taş takımı, arka plan ve fon müziğini birlikte taşıyan paket.
///
/// Paketler coin ile açılır; `price` sıfırsa baştan açıktır. Paket seçmek
/// tahta ve taş ayarlarını o paketin varsayılanına çevirir; kullanıcı sonra
/// yine tek tek değiştirebilir.
class ThemePack {
  const ThemePack({
    required this.id,
    required this.trName,
    required this.enName,
    required this.price,
    required this.boardTheme,
    required this.pieceSet,
    required this.background,
    this.musicAsset,
  });

  final String id;
  final String trName;
  final String enName;

  /// Coin cinsinden fiyat; 0 = ücretsiz.
  final int price;

  final BoardTheme boardTheme;
  final PieceSet pieceSet;
  final BackgroundStyle background;

  /// Döngüde çalınan fon müziği; yoksa paket sessizdir.
  final String? musicAsset;

  String label(bool turkish) => turkish ? trName : enName;
}

class ThemePacks {
  ThemePacks._();

  static const classic = ThemePack(
    id: 'classic',
    trName: 'Klasik',
    enName: 'Classic',
    price: 0,
    boardTheme: BoardTheme.walnut,
    pieceSet: PieceSet.classic,
    background: BackgroundStyle.none,
  );

  static const space = ThemePack(
    id: 'space',
    trName: 'Uzay',
    enName: 'Space',
    price: 50,
    boardTheme: BoardTheme.lunar,
    pieceSet: PieceSet.cobalt,
    background: BackgroundStyle.stars,
    musicAsset: 'assets/music/space_drone.wav',
  );

  static const jungle = ThemePack(
    id: 'jungle',
    trName: 'Dinozor Ormanı',
    enName: 'Dino Jungle',
    price: 40,
    boardTheme: BoardTheme.jungle,
    pieceSet: PieceSet.playful,
    background: BackgroundStyle.leaves,
    musicAsset: 'assets/music/jungle_loop.wav',
  );

  static const egypt = ThemePack(
    id: 'egypt',
    trName: 'Antik Mısır',
    enName: 'Ancient Egypt',
    price: 60,
    boardTheme: BoardTheme.desert,
    pieceSet: PieceSet.wood,
    background: BackgroundStyle.dunes,
    musicAsset: 'assets/music/desert_loop.wav',
  );

  static const all = <ThemePack>[classic, space, jungle, egypt];

  static ThemePack fromId(String? id) =>
      all.firstWhere((p) => p.id == id, orElse: () => classic);
}
