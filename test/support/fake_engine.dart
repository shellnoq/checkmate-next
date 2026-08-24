import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:checkmate_next/engine/chess_engine.dart';
import 'package:checkmate_next/engine/engine_models.dart';

/// Testlerde native Stockfish yerine geçen motor. Hiç hamle üretmez; amacı
/// arayüz testlerinin gerçek motoru başlatmaya çalışmasını önlemektir.
class FakeEngine implements ChessEngine {
  FakeEngine({this.onSearch});

  /// Verilirse her aramada çağrılır; sonuçlar buradan kurgulanır.
  SearchResult Function(String fen, List<String> movesUci)? onSearch;

  final ValueNotifier<EngineStatus> _status = ValueNotifier(EngineStatus.ready);
  final StreamController<EngineLine> _info =
      StreamController<EngineLine>.broadcast();

  int searchCount = 0;

  @override
  ValueListenable<EngineStatus> get status => _status;

  @override
  Stream<EngineLine> get infoStream => _info.stream;

  @override
  Future<void> start() async {}

  @override
  Future<void> applyOptions(EngineOptions options) async {}

  @override
  Future<SearchResult> search({
    required String fen,
    List<String> movesUci = const [],
    required SearchLimits limits,
  }) async {
    searchCount++;
    return onSearch?.call(fen, movesUci) ??
        const SearchResult(bestMoveUci: null);
  }

  @override
  Future<void> stopSearch() async {}

  @override
  Future<void> dispose() async {
    await _info.close();
  }
}
