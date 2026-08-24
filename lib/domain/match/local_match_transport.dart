import 'dart:async';

import 'match_protocol.dart';
import 'match_transport.dart';

/// Aynı cihazda iki oyuncu. Rakip tarafı da yerel olduğu için taşıma katmanı
/// hamle üretmez; yalnızca oyun sonu ve beraberlik komutlarını yansıtır.
class LocalMatchTransport implements MatchTransport {
  final StreamController<MatchEvent> _events =
      StreamController<MatchEvent>.broadcast();
  MatchConfig? _config;
  MatchConnectionState _connection = MatchConnectionState.idle;

  @override
  MatchKind get kind => MatchKind.passAndPlay;

  @override
  Stream<MatchEvent> get events => _events.stream;

  @override
  MatchConnectionState get connectionState => _connection;

  @override
  Future<void> open(
    MatchConfig config, {
    List<String> initialMovesUci = const [],
  }) async {
    _config = config;
    _connection = MatchConnectionState.connected;
    _emit(MatchConnectionChanged(_connection));
    _emit(MatchOpened(config));
  }

  @override
  Future<void> send(MatchCommand command) async {
    switch (command) {
      case ResignMatch():
        // Sırası gelen taraf terk eder; kazananı üst katman belirler.
        _emit(const MatchEnded(reason: GameEndReason.resignation));
      case OfferDraw():
      case RespondToDrawOffer(accept: true):
        _emit(const MatchEnded(reason: GameEndReason.drawAgreement));
      case RequestTakeback():
        _emit(const RemoteTakebackAccepted(1));
      case RequestRematch():
        if (_config != null) await open(_config!);
      case SubmitMove():
      case RespondToDrawOffer():
        break;
    }
  }

  @override
  Future<void> requestOpponentMove() async {
    // Rakip de yerel; çağıracak kimse yok.
  }

  void _emit(MatchEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  @override
  Future<void> close() async {
    _connection = MatchConnectionState.closed;
    await _events.close();
  }
}
