import '../../engine/chess_engine.dart';
import 'engine_match_transport.dart';
import 'local_match_transport.dart';
import 'match_protocol.dart';
import 'match_transport.dart';

/// Maç türüne göre uygun taşıma katmanını üretir.
///
/// Online mod açıldığında burada [MatchKind.online] dalı
/// `RemoteMatchTransport` döndürecek biçimde doldurulur; oyun ekranı ve
/// denetleyici hiç değişmez.
class MatchTransportFactory {
  const MatchTransportFactory(this._engine);

  final ChessEngine _engine;

  MatchTransport create(MatchKind kind) => switch (kind) {
        MatchKind.engine => EngineMatchTransport(_engine),
        MatchKind.passAndPlay => LocalMatchTransport(),
        MatchKind.online => throw UnsupportedError(
            'Online mod henüz etkin değil. RemoteMatchTransport bir '
            'MessageChannel gerçeklemesi ile bağlandığında bu dal açılacak.'),
      };
}
