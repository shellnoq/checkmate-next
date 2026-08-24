import 'dart:async';
import 'dart:math';

import 'package:dartchess/dartchess.dart';

import '../../engine/chess_engine.dart';
import '../../engine/engine_models.dart';
import '../model/difficulty.dart';
import 'match_protocol.dart';
import 'match_transport.dart';

/// Cihaz üzerindeki Stockfish motorunu rakip olarak sunan taşıma katmanı.
class EngineMatchTransport implements MatchTransport {
  EngineMatchTransport(this._engine);

  final ChessEngine _engine;
  final StreamController<MatchEvent> _events =
      StreamController<MatchEvent>.broadcast();

  MatchConfig? _config;
  final List<String> _moves = [];
  MatchConnectionState _connection = MatchConnectionState.idle;
  bool _closed = false;

  /// Motorun düşünme süresini gerçekçi kılmak için alt sınır. Aksi hâlde
  /// zayıf kademelerde hamleler anında gelir ve oyun yapay hissettirir.
  static const _minimumThinkTime = Duration(milliseconds: 350);

  @override
  MatchKind get kind => MatchKind.engine;

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
    _moves
      ..clear()
      ..addAll(initialMovesUci);
    _setConnection(MatchConnectionState.connecting);

    final difficulty = config.difficulty ?? DifficultyLevel.club;
    await _engine.applyOptions(difficulty.engineOptions);

    _setConnection(MatchConnectionState.connected);
    _emit(MatchOpened(config));

    // Sıra motordaysa (yeni oyunda motor beyazsa ya da kayıt motorun
    // sırasında alınmışsa) ilk hamleyi o yapar.
    final startingSide = _sideToMoveOf(config.startingFen);
    final sideToMove = initialMovesUci.length.isEven
        ? startingSide
        : startingSide.opposite;
    if (sideToMove != config.localSide) {
      unawaited(_think());
    }
  }

  @override
  Future<void> requestOpponentMove() async {
    unawaited(_think());
  }

  @override
  Future<void> send(MatchCommand command) async {
    if (_closed) return;
    switch (command) {
      case SubmitMove(:final uci):
        _moves.add(uci);
        unawaited(_think());
      case ResignMatch():
        final winner = _config?.localSide.opposite;
        _emit(MatchEnded(reason: GameEndReason.resignation, winner: winner));
      case OfferDraw():
        // Motor beraberliği yalnızca konum belirgin biçimde eşitse kabul eder.
        unawaited(_considerDrawOffer());
      case RespondToDrawOffer(:final accept):
        if (accept) {
          _emit(const MatchEnded(reason: GameEndReason.drawAgreement));
        }
      case RequestTakeback():
        // Motora karşı geri alma her zaman kabul edilir: son iki yarım hamle.
        final plies = min(2, _moves.length);
        _moves.removeRange(_moves.length - plies, _moves.length);
        _emit(RemoteTakebackAccepted(plies));
      case RequestRematch():
        _moves.clear();
        if (_config != null) await open(_config!);
    }
  }

  Future<void> _considerDrawOffer() async {
    final config = _config;
    if (config == null) return;
    try {
      final result = await _engine.search(
        fen: config.startingFen,
        movesUci: List.of(_moves),
        limits: const SearchLimits(moveTimeMs: 500),
      );
      final line = result.principalVariation;
      final cp = line?.centipawns;
      // Skor motorun gözünden gelir; motor kayıptaysa ya da tam eşitse kabul.
      final accepts = line != null && !line.isMate && cp != null && cp <= 15;
      if (accepts) {
        _emit(const MatchEnded(reason: GameEndReason.drawAgreement));
      } else {
        _emit(const RemoteDrawOffer());
      }
    } catch (e) {
      _emit(MatchFailure(e));
    }
  }

  Future<void> _think() async {
    final config = _config;
    if (config == null || _closed) return;

    _emit(const RemoteThinking(true));
    final clock = Stopwatch()..start();
    try {
      final difficulty = config.difficulty ?? DifficultyLevel.club;
      final result = await _engine.search(
        fen: config.startingFen,
        movesUci: List.of(_moves),
        limits: difficulty.searchLimits,
      );
      if (_closed) return;

      final best = result.bestMoveUci;
      if (best == null) {
        // Motor hamle bulamadı: pozisyon bitmiştir, sonucu kural katmanı verir.
        _emit(const RemoteThinking(false));
        return;
      }

      // Yapay hızlılığı yumuşat.
      final remaining = _minimumThinkTime - clock.elapsed;
      if (remaining > Duration.zero) await Future<void>.delayed(remaining);
      if (_closed) return;

      _moves.add(best);
      _emit(const RemoteThinking(false));
      _emit(RemoteMove(uci: best));
    } catch (e) {
      if (_closed) return;
      _emit(const RemoteThinking(false));
      _emit(MatchFailure(e));
    }
  }

  /// Motorun düşünmesini bozmadan dışarıdan hamle listesini eşitler
  /// (ör. kullanıcı geri aldıktan sonra).
  void syncMoves(List<String> moves) {
    _moves
      ..clear()
      ..addAll(moves);
  }

  static Side _sideToMoveOf(String fen) {
    final parts = fen.split(' ');
    return parts.length > 1 && parts[1] == 'b' ? Side.black : Side.white;
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
    _closed = true;
    _setConnection(MatchConnectionState.closed);
    await _engine.stopSearch();
    await _events.close();
  }
}
