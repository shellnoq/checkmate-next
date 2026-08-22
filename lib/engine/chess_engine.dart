import 'package:flutter/foundation.dart';

import 'engine_models.dart';

/// Satranç motoru sözleşmesi.
///
/// Uygulamanın geri kalanı yalnızca bu arayüzü tanır. Stockfish yerine başka
/// bir motor (ör. sunucu tarafında çalışan bir analiz servisi) kullanılmak
/// istendiğinde tek yapılması gereken bu arayüzü yeniden gerçeklemektir.
abstract interface class ChessEngine {
  /// Motorun anlık durumu.
  ValueListenable<EngineStatus> get status;

  /// Motoru başlatır ve UCI el sıkışmasını tamamlar.
  Future<void> start();

  /// UCI seçeneklerini uygular. Motor hazır değilse önce başlatır.
  Future<void> applyOptions(EngineOptions options);

  /// Verilen pozisyondan itibaren arama yapar.
  ///
  /// [fen] başlangıç pozisyonu, [movesUci] o pozisyondan sonra oynanmış
  /// hamlelerdir. Böylece motor tekrar tespiti (üç tekrar) yapabilir.
  Future<SearchResult> search({
    required String fen,
    List<String> movesUci = const [],
    required SearchLimits limits,
  });

  /// Süren aramayı durdurur ve o ana kadarki en iyi hamleyi döndürtür.
  Future<void> stopSearch();

  /// Arama sırasında akan ara değerlendirmeler (değerlendirme çubuğu için).
  Stream<EngineLine> get infoStream;

  /// Motoru kapatır.
  Future<void> dispose();
}
