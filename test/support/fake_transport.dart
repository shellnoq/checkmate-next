import 'dart:async';

import 'package:checkmate_next/domain/match/match_protocol.dart';
import 'package:checkmate_next/domain/match/match_transport.dart';

/// Testlerde rakip yerine geçen, gönderilen komutları kaydeden taşıma katmanı.
class FakeTransport implements MatchTransport {
  FakeTransport({this.kind = MatchKind.passAndPlay});

  final _events = StreamController<MatchEvent>.broadcast();
  final List<MatchCommand> sent = [];

  @override
  final MatchKind kind;

  @override
  Stream<MatchEvent> get events => _events.stream;

  @override
  MatchConnectionState get connectionState => MatchConnectionState.connected;

  List<String> openedWithMoves = const [];
  int opponentMoveRequests = 0;

  @override
  Future<void> open(MatchConfig config,
      {List<String> initialMovesUci = const []}) async {
    openedWithMoves = initialMovesUci;
    _events.add(MatchOpened(config));
  }

  @override
  Future<void> requestOpponentMove() async {
    opponentMoveRequests++;
  }

  @override
  Future<void> send(MatchCommand command) async => sent.add(command);

  @override
  Future<void> close() async => _events.close();

  /// Rakip hamlesini simüle eder.
  void reply(String uci) => _events.add(RemoteMove(uci: uci));
}
