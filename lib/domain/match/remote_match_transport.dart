import 'dart:async';
import 'dart:convert';

import 'match_protocol.dart';
import 'match_transport.dart';

/// Online maç sunucusunun adresi ve kimlik bilgisi.
///
/// Sunucu tarafı devreye alındığında yalnızca bu yapılandırma doldurulur.
class RemoteMatchEndpoint {
  /// Örn. `wss://api.ornek.com/v1/match`.
  final Uri baseUri;

  /// Oturum jetonu. Kimlik doğrulama eklenene kadar `null` kalabilir.
  final String? authToken;

  const RemoteMatchEndpoint({required this.baseUri, this.authToken});
}

/// Bir çift yönlü mesaj kanalı (WebSocket, SSE+HTTP, gRPC vb.) soyutlaması.
///
/// Bu ara katman sayesinde uygulamaya `web_socket_channel` gibi bir bağımlılık
/// eklemek zorunda kalmadan protokol bugünden sabitlenmiştir. Online moda
/// geçerken tek yapılacak iş bu arayüzü gerçekleyen bir sınıf yazmaktır.
abstract interface class MessageChannel {
  Stream<String> get incoming;
  Future<void> connect(RemoteMatchEndpoint endpoint, String matchId);
  void send(String payload);
  Future<void> close();
}

/// Uzak sunucu üzerinden oynanan maç.
///
/// Protokol [MatchCommand] / [MatchEvent] JSON gösterimidir; yani sunucu
/// sözleşmesi hâlihazırda tanımlıdır:
///
/// ```
/// istemci -> sunucu : {"type":"move","uci":"e2e4","remainingMs":298000}
/// sunucu  -> istemci: {"type":"move","uci":"e7e5","remainingMs":299100}
/// sunucu  -> istemci: {"type":"ended","reason":"checkmate","winner":"white"}
/// ```
///
/// Kural doğrulaması istemcide `dartchess` ile yapılır; sunucu yetkili taraf
/// olarak aynı doğrulamayı tekrarlamalı ve saati o tutmalıdır.
class RemoteMatchTransport implements MatchTransport {
  RemoteMatchTransport({
    required this.endpoint,
    required MessageChannel channel,
  }) : _channel = channel;

  final RemoteMatchEndpoint endpoint;
  final MessageChannel _channel;

  final StreamController<MatchEvent> _events =
      StreamController<MatchEvent>.broadcast();
  StreamSubscription<String>? _sub;
  MatchConnectionState _connection = MatchConnectionState.idle;

  @override
  MatchKind get kind => MatchKind.online;

  @override
  Stream<MatchEvent> get events => _events.stream;

  @override
  MatchConnectionState get connectionState => _connection;

  @override
  Future<void> open(
    MatchConfig config, {
    List<String> initialMovesUci = const [],
  }) async {
    _setConnection(MatchConnectionState.connecting);
    _sub = _channel.incoming.listen(
      _onPayload,
      onError: (Object e) {
        _emit(MatchFailure(e));
        _setConnection(MatchConnectionState.reconnecting);
      },
    );
    await _channel.connect(endpoint, config.matchId);
    _setConnection(MatchConnectionState.connected);
    _emit(MatchOpened(config));
  }

  @override
  Future<void> send(MatchCommand command) async {
    _channel.send(jsonEncode(command.toJson()));
  }

  @override
  Future<void> requestOpponentMove() async {
    // Sunucu sıra bilgisini kendisi tutar; ayrıca çağrı gerekmez.
  }

  void _onPayload(String payload) {
    try {
      final json = jsonDecode(payload) as Map<String, Object?>;
      _emit(MatchEvent.fromJson(json));
    } catch (e) {
      _emit(MatchFailure(e));
    }
  }

  void _setConnection(MatchConnectionState state) {
    _connection = state;
    _emit(MatchConnectionChanged(state));
  }

  void _emit(MatchEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    await _channel.close();
    _setConnection(MatchConnectionState.closed);
    await _events.close();
  }
}
