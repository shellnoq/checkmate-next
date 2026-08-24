import 'match_protocol.dart';

/// Bir maçın rakip tarafını temsil eden taşıma katmanı.
///
/// Oyun ekranı ve [GameController] rakibin kim olduğunu bilmez; yalnızca bu
/// arayüzle konuşur. Motora karşı oyun, aynı cihazda iki kişilik oyun ve
/// ileride eklenecek online oyun aynı sözleşmeyi gerçekler.
///
/// Online'a geçiş bu yüzden tek noktadan yapılır: `RemoteMatchTransport`
/// tamamlanır, `MatchTransportFactory` onu döndürür, üst katmanlarda hiçbir
/// değişiklik gerekmez.
abstract interface class MatchTransport {
  MatchKind get kind;

  /// Rakipten gelen olaylar.
  Stream<MatchEvent> get events;

  /// Anlık bağlantı durumu.
  MatchConnectionState get connectionState;

  /// Maçı kurar. Online'da sunucuya bağlanır.
  ///
  /// [initialMovesUci] verilirse maç o hamleler oynanmış hâlde açılır;
  /// kaydedilmiş bir oyuna devam ederken kullanılır.
  Future<void> open(
    MatchConfig config, {
    List<String> initialMovesUci = const [],
  });

  /// Sıra rakipteyse rakibi hamleye çağırır; kayıttan dönüşte gerekir.
  /// Sırası olmayan ya da rakibi yerel olan gerçeklemeler yok sayar.
  Future<void> requestOpponentMove();

  /// Yerel oyuncunun komutunu rakibe iletir.
  Future<void> send(MatchCommand command);

  /// Maçı kapatır ve kaynakları serbest bırakır.
  Future<void> close();
}
