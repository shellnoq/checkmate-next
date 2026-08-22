# Online moda geçiş

Uygulama çevrimdışı çalışacak biçimde yazıldı, fakat online oyun sonradan
eklenebilsin diye maçın rakip tarafı baştan soyutlandı. Bu belge, sunucu
hazır olduğunda yapılacak işi ve sunucunun uyması gereken sözleşmeyi tanımlar.

## Mevcut yapı

```
GameScreen
    │
    ▼
GameController ──────► MatchTransport (arayüz)
   (kurallar, saat,          ├── EngineMatchTransport   → cihaz üzerindeki Stockfish
    tarihçe, PGN)            ├── LocalMatchTransport    → aynı cihazda iki oyuncu
                             └── RemoteMatchTransport   → uzak sunucu (iskelet hazır)
```

`GameController` rakibin kim olduğunu bilmez. Yalnızca [`MatchCommand`]
gönderir ve [`MatchEvent`] alır. Dolayısıyla online moda geçiş oyun mantığına
dokunmaz.

## Yapılacaklar

### 1. Mesaj kanalı gerçeklemesi

`lib/domain/match/remote_match_transport.dart` içindeki `MessageChannel`
arayüzü doldurulur. WebSocket için:

```yaml
dependencies:
  web_socket_channel: ^3.0.1
```

```dart
class WebSocketMessageChannel implements MessageChannel {
  WebSocketChannel? _channel;
  final _controller = StreamController<String>.broadcast();

  @override
  Stream<String> get incoming => _controller.stream;

  @override
  Future<void> connect(RemoteMatchEndpoint endpoint, String matchId) async {
    final uri = endpoint.baseUri.replace(
      path: '${endpoint.baseUri.path}/$matchId',
      queryParameters: {'token': endpoint.authToken ?? ''},
    );
    _channel = WebSocketChannel.connect(uri);
    _channel!.stream.listen(
      (m) => _controller.add(m as String),
      onError: _controller.addError,
    );
    await _channel!.ready;
  }

  @override
  void send(String payload) => _channel?.sink.add(payload);

  @override
  Future<void> close() async => _channel?.sink.close();
}
```

### 2. Fabrikanın açılması

`lib/domain/match/match_transport_factory.dart` içindeki `MatchKind.online`
dalı `UnsupportedError` yerine `RemoteMatchTransport` döndürür.

### 3. Ana ekran kartının etkinleştirilmesi

`lib/features/home/home_screen.dart` içindeki "Çevrimiçi" kartında
`enabled: false` kaldırılır; eşleşme ekranı eklenir.

### 4. `INTERNET` izni

`android/app/src/main/AndroidManifest.xml` dosyasına eklenir ve Play Console
veri güvenliği formu yeniden doldurulur.

## Sunucu sözleşmesi

Protokol `MatchCommand` ve `MatchEvent` sınıflarının JSON gösterimidir; her iki
yönde de `toJson` / `fromJson` bugün yazılıdır. Yeni bir biçim tanımlamaya
gerek yoktur.

### İstemci → sunucu

```json
{"type":"move","uci":"e2e4","remainingMs":298000}
{"type":"resign"}
{"type":"offerDraw"}
{"type":"respondDraw","accept":true}
{"type":"takeback"}
{"type":"rematch"}
```

### Sunucu → istemci

```json
{"type":"opened","config":{...}}
{"type":"move","uci":"e7e5","remainingMs":299100}
{"type":"thinking","value":true}
{"type":"drawOffer"}
{"type":"takebackAccepted","plies":2}
{"type":"ended","reason":"checkmate","winner":"white"}
{"type":"connection","state":"reconnecting"}
```

`reason` değerleri: `checkmate`, `stalemate`, `resignation`, `timeout`,
`drawAgreement`, `threefoldRepetition`, `fiftyMoveRule`,
`insufficientMaterial`, `abandoned`.

### Sunucudan beklenenler

- **Yetkili taraf sunucudur.** İstemci kuralları `dartchess` ile doğrular ama
  sunucu aynı doğrulamayı tekrarlamalı, geçersiz hamleyi reddetmelidir.
- **Saati sunucu tutar.** `remainingMs` alanı istemci saatini eşitlemek
  içindir; bayrak kararını sunucu verir.
- **Hamle biçimi UCI'dir** (`e2e4`, `e7e8q`). Rok standart biçimde
  gösterilir (`e1g1`), tahta-tarzı `e1h1` değil.
- **Yeniden bağlanmada** sunucu güncel FEN ve hamle listesini göndermelidir;
  bunun için protokole `{"type":"sync", ...}` olayı eklenecektir.

## Sırada olan, henüz yazılmamış parçalar

- Eşleşme (matchmaking) ekranı ve kuyruk
- Oyuncu kimliği ve Elo derecelendirmesi
- Yeniden bağlanma ve `sync` olayı
- Terk eden oyuncu için zaman aşımı politikası
