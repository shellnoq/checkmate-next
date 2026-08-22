import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/match/match_transport_factory.dart';
import '../../engine/chess_engine.dart';
import '../../engine/stockfish_engine.dart';

/// Uygulama boyunca tek bir Stockfish örneği kullanılır; native motor aynı
/// anda birden fazla örneğe izin vermez.
final chessEngineProvider = Provider<ChessEngine>((ref) {
  final engine = StockfishEngine();
  ref.onDispose(engine.dispose);
  return engine;
});

/// Motorun ayağa kalkmasını bekleyen tek seferlik başlatma.
final engineStartupProvider = FutureProvider<void>((ref) async {
  await ref.watch(chessEngineProvider).start();
});

final matchTransportFactoryProvider = Provider<MatchTransportFactory>(
  (ref) => MatchTransportFactory(ref.watch(chessEngineProvider)),
);
