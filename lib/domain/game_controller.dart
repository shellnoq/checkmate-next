import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';

import '../engine/chess_engine.dart';
import '../engine/engine_models.dart';
import 'chess_clock.dart';
import 'match/match_protocol.dart';
import 'match/match_transport.dart';
import 'model/game_result.dart';
import 'model/move_record.dart';

enum GamePhase { idle, playing, finished }

/// Bir maçın tüm durumunu ve kurallarını yöneten denetleyici.
///
/// Rakibin motor mu, aynı cihazdaki ikinci oyuncu mu, yoksa uzak bir oyuncu mu
/// olduğunu bilmez; yalnızca [MatchTransport] ile konuşur.
class GameController extends ChangeNotifier {
  GameController({
    required this.config,
    required MatchTransport transport,
    ChessEngine? analysisEngine,
    this.analysisEnabled = true,
  }) : _transport = transport,
       _analysisEngine = analysisEngine,
       _position = _positionFromFen(config.startingFen),
       clock = ChessClock(config.timeControl) {
    clock
      ..onTick = _onClockTick
      ..onFlag = _onFlag;
    _countRepetition(_position);
  }

  final MatchConfig config;
  final MatchTransport _transport;
  final ChessEngine? _analysisEngine;
  final bool analysisEnabled;
  final ChessClock clock;

  /// Hamle uygulandığında (yerel ya da rakip) çağrılır. Ses ve titreşim
  /// geri bildirimi için sunum katmanı bağlar.
  ValueChanged<MoveRecord>? onMoveApplied;

  /// Oyun bittiğinde çağrılır.
  ValueChanged<GameResult>? onGameEnded;

  StreamSubscription<MatchEvent>? _eventSub;

  Position _position;
  final List<MoveRecord> _moves = [];
  final Map<String, int> _repetitions = {};

  GamePhase _phase = GamePhase.idle;
  GameResult? _result;
  Square? _selected;
  Map<Square, Set<Square>> _legalDests = const {};
  NormalMove? _pendingPromotion;
  bool _opponentThinking = false;
  bool _drawOfferPending = false;
  EngineLine? _evaluation;
  String? _hintUci;
  bool _hintLoading = false;
  int _browseIndex = 0;
  Object? _lastError;
  int _analysisToken = 0;

  // ── Okunabilir durum ──

  /// Canlı pozisyon (tarihçede gezinme bunu değiştirmez).
  Position get position => _position;

  /// Tahtada gösterilen pozisyon. Tarihçede geziliyorsa geçmiş bir pozisyondur.
  Position get displayedPosition {
    if (_browseIndex >= _moves.length) return _position;
    if (_browseIndex == 0) return _positionFromFen(config.startingFen);
    return _positionFromFen(_moves[_browseIndex - 1].fenAfter);
  }

  bool get isBrowsingHistory => _browseIndex < _moves.length;
  int get browseIndex => _browseIndex;

  List<MoveRecord> get moves => List.unmodifiable(_moves);
  GamePhase get phase => _phase;
  GameResult? get result => _result;
  Square? get selectedSquare => _selected;
  NormalMove? get pendingPromotion => _pendingPromotion;
  bool get opponentThinking => _opponentThinking;
  bool get drawOfferPending => _drawOfferPending;
  EngineLine? get evaluation => _evaluation;
  String? get hintUci => _hintUci;
  bool get hintLoading => _hintLoading;
  Object? get lastError => _lastError;

  /// Gösterilen pozisyonda seçili karenin gidebileceği kareler.
  Set<Square> get destinationsForSelected =>
      _selected == null ? const {} : (_legalDests[_selected!] ?? const {});

  /// Son oynanan hamlenin kareleri (vurgulama için).
  (Square, Square)? get lastMoveSquares {
    final index = _browseIndex - 1;
    if (index < 0 || index >= _moves.length) return null;
    final move = NormalMove.fromUci(_moves[index].uci);
    return (move.from, move.to);
  }

  /// Şah çeken durumda şahın karesi.
  Square? get checkedKingSquare {
    final pos = displayedPosition;
    if (!pos.isCheck) return null;
    return pos.board.kingOf(pos.turn);
  }

  /// Yerel oyuncunun sırası mı? Aynı cihazda iki kişilik oyunda daima doğru.
  bool get isLocalTurn {
    if (_phase != GamePhase.playing) return false;
    if (config.kind == MatchKind.passAndPlay) return true;
    return _position.turn == config.localSide;
  }

  /// Tahta yerel oyuncuya göre çevrilsin mi?
  bool get shouldFlipBoard => config.kind == MatchKind.passAndPlay
      ? false
      : config.localSide == Side.black;

  /// Materyal farkı (beyaz lehine pozitif), piyon cinsinden.
  int get materialBalance {
    const values = {
      Role.pawn: 1,
      Role.knight: 3,
      Role.bishop: 3,
      Role.rook: 5,
      Role.queen: 9,
      Role.king: 0,
    };
    final board = displayedPosition.board;
    int score = 0;
    for (final square in board.occupied.squares) {
      final piece = board.pieceAt(square)!;
      final value = values[piece.role]!;
      score += piece.color == Side.white ? value : -value;
    }
    return score;
  }

  /// Bir tarafın aldığı taşlar (başlangıç dizilişine göre eksikler).
  List<Role> capturedBy(Side side) {
    const initialCounts = {
      Role.pawn: 8,
      Role.knight: 2,
      Role.bishop: 2,
      Role.rook: 2,
      Role.queen: 1,
    };
    final board = displayedPosition.board;
    final opponent = side.opposite;
    final captured = <Role>[];
    for (final entry in initialCounts.entries) {
      final remaining = board
          .bySide(opponent)
          .intersect(board.byRole(entry.key))
          .size;
      for (int i = 0; i < entry.value - remaining; i++) {
        captured.add(entry.key);
      }
    }
    return captured;
  }

  // ── Yaşam döngüsü ──

  Future<void> start() async {
    _eventSub = _transport.events.listen(_onMatchEvent);
    _phase = GamePhase.playing;
    _refreshLegalDests();
    notifyListeners();
    try {
      await _transport.open(config);
    } catch (e) {
      _lastError = e;
      notifyListeners();
      return;
    }
    if (!config.timeControl.isUnlimited) {
      clock.start(_position.turn);
    }
    unawaited(_refreshEvaluation());
  }

  // ── Kullanıcı etkileşimi ──

  void selectSquare(Square square) {
    if (isBrowsingHistory) {
      // Geçmişte gezerken tahta salt okunurdur; dokunuş canlı konuma döndürür.
      goLive();
      return;
    }
    if (!isLocalTurn || _pendingPromotion != null) return;

    final current = _selected;
    if (current != null) {
      final dests = _legalDests[current] ?? const <Square>{};
      if (dests.contains(square)) {
        _submitUiMove(NormalMove(from: current, to: square));
        return;
      }
    }

    final piece = _position.board.pieceAt(square);
    if (piece != null && piece.color == _position.turn) {
      _selected = square;
    } else {
      _selected = null;
    }
    notifyListeners();
  }

  /// Sürükle-bırak ile hamle.
  void moveByDrag(Square from, Square to) {
    if (isBrowsingHistory || !isLocalTurn || _pendingPromotion != null) return;
    final dests = _legalDests[from] ?? const <Square>{};
    if (!dests.contains(to)) {
      _selected = null;
      notifyListeners();
      return;
    }
    _submitUiMove(NormalMove(from: from, to: to));
  }

  void _submitUiMove(NormalMove move) {
    if (_requiresPromotion(move)) {
      _pendingPromotion = move;
      _selected = null;
      notifyListeners();
      return;
    }
    _applyLocalMove(move);
  }

  bool _requiresPromotion(NormalMove move) {
    final piece = _position.board.pieceAt(move.from);
    if (piece == null || piece.role != Role.pawn) return false;
    final targetRank = move.to.rank;
    return (piece.color == Side.white && targetRank == Rank.eighth) ||
        (piece.color == Side.black && targetRank == Rank.first);
  }

  void completePromotion(Role role) {
    final pending = _pendingPromotion;
    if (pending == null) return;
    _pendingPromotion = null;
    _applyLocalMove(pending.withPromotion(role));
  }

  void cancelPromotion() {
    _pendingPromotion = null;
    notifyListeners();
  }

  void _applyLocalMove(NormalMove uiMove) {
    final remaining = config.timeControl.isUnlimited
        ? null
        : clock.remainingOf(_position.turn);
    final wireUci = _toStandardUci(uiMove);
    final applied = _applyMove(uiMove);
    if (!applied) return;

    _transport.send(
      SubmitMove(uci: wireUci, remainingMs: remaining?.inMilliseconds),
    );
  }

  /// Rok hamlesini standart UCI biçimine çevirir.
  ///
  /// `dartchess` rok için hem şah-iki-kare (`e1g1`) hem şah-kaleye (`e1h1`)
  /// gösterimini geçerli sayar. UCI protokolü ve online kablo biçimi ise
  /// (Chess960 dışında) yalnızca birincisini tanır; kullanıcı kaleye dokunarak
  /// rok yaptığında hamlenin motora yanlış gitmemesi için burada dönüştürülür.
  String _toStandardUci(NormalMove move) {
    final piece = _position.board.pieceAt(move.from);
    if (piece == null || piece.role != Role.king) return move.uci;
    final target = _position.board.pieceAt(move.to);
    if (target == null ||
        target.role != Role.rook ||
        target.color != piece.color) {
      return move.uci;
    }
    final kingSide = move.to.file > move.from.file;
    final destination = Square.fromCoords(
      File(kingSide ? 6 : 2),
      move.from.rank,
    );
    return NormalMove(from: move.from, to: destination).uci;
  }

  /// Hamleyi kural katmanına uygular, kaydeder ve oyun sonu kontrolü yapar.
  bool _applyMove(NormalMove uiMove) {
    final normalized = _position.normalizeMove(uiMove);
    if (!_position.isLegal(normalized)) {
      _selected = null;
      notifyListeners();
      return false;
    }

    final mover = _position.turn;
    final wireUci = _toStandardUci(uiMove);
    final (newPosition, san) = _position.makeSan(normalized);
    _position = newPosition;

    if (!config.timeControl.isUnlimited) {
      clock.switchTo(_position.turn);
    }

    _moves.add(
      MoveRecord(
        uci: wireUci,
        san: san,
        fenAfter: _position.fen,
        side: mover,
        clockAfter: config.timeControl.isUnlimited
            ? null
            : clock.remainingOf(mover),
      ),
    );
    _browseIndex = _moves.length;
    _selected = null;
    _hintUci = null;
    _countRepetition(_position);
    _refreshLegalDests();
    onMoveApplied?.call(_moves.last);
    notifyListeners();

    _checkGameEnd();
    if (_phase == GamePhase.playing) unawaited(_refreshEvaluation());
    return true;
  }

  Future<void> resign() async {
    if (_phase != GamePhase.playing) return;
    final loser = config.kind == MatchKind.passAndPlay
        ? _position.turn
        : config.localSide;
    _finish(
      GameResult(reason: GameEndReason.resignation, winner: loser.opposite),
    );
    await _transport.send(const ResignMatch());
  }

  Future<void> offerDraw() async {
    if (_phase != GamePhase.playing) return;
    await _transport.send(const OfferDraw());
  }

  Future<void> respondToDrawOffer(bool accept) async {
    _drawOfferPending = false;
    notifyListeners();
    await _transport.send(RespondToDrawOffer(accept: accept));
    if (accept) {
      _finish(const GameResult(reason: GameEndReason.drawAgreement));
    }
  }

  /// Beraberlik talebi: üç tekrar veya elli hamle kuralı sağlanıyorsa
  /// karşı tarafın onayı gerekmeden oyun biter.
  bool claimDrawIfEligible() {
    if (_phase != GamePhase.playing) return false;
    if (_repetitionCount(_position) >= 3) {
      _finish(const GameResult(reason: GameEndReason.threefoldRepetition));
      return true;
    }
    if (_position.halfmoves >= 100) {
      _finish(const GameResult(reason: GameEndReason.fiftyMoveRule));
      return true;
    }
    return false;
  }

  Future<void> requestTakeback() async {
    if (_phase != GamePhase.playing || _moves.isEmpty) return;
    await _transport.send(const RequestTakeback());
  }

  Future<void> rematch() async {
    _moves.clear();
    _repetitions.clear();
    _position = _positionFromFen(config.startingFen);
    _countRepetition(_position);
    _result = null;
    _phase = GamePhase.playing;
    _browseIndex = 0;
    _selected = null;
    _evaluation = null;
    _hintUci = null;
    _refreshLegalDests();
    notifyListeners();
    await _transport.send(const RequestRematch());
    if (!config.timeControl.isUnlimited) {
      clock.stop();
      clock.start(_position.turn);
    }
  }

  /// Motordan ipucu ister. Motor rakip düşünürken çağrılmaz.
  Future<void> requestHint() async {
    final engine = _analysisEngine;
    if (engine == null || _opponentThinking || _phase != GamePhase.playing) {
      return;
    }
    _hintLoading = true;
    notifyListeners();
    try {
      final result = await engine.search(
        fen: config.startingFen,
        movesUci: _moves.map((m) => m.uci).toList(),
        limits: const SearchLimits(moveTimeMs: 800),
      );
      _hintUci = result.bestMoveUci;
    } catch (e) {
      _lastError = e;
    } finally {
      _hintLoading = false;
      notifyListeners();
    }
  }

  // ── Tarihçede gezinme ──

  void browseTo(int index) {
    _browseIndex = index.clamp(0, _moves.length);
    _selected = null;
    _refreshLegalDests();
    notifyListeners();
  }

  void browsePrevious() => browseTo(_browseIndex - 1);
  void browseNext() => browseTo(_browseIndex + 1);
  void browseStart() => browseTo(0);
  void goLive() => browseTo(_moves.length);

  // ── Taşıma katmanı olayları ──

  void _onMatchEvent(MatchEvent event) {
    switch (event) {
      case RemoteMove(:final uci):
        final move = NormalMove.fromUci(uci);
        _applyMove(move);
      case RemoteThinking(:final value):
        _opponentThinking = value;
        notifyListeners();
      case RemoteDrawOffer():
        _drawOfferPending = true;
        notifyListeners();
      case RemoteTakebackAccepted(:final plies):
        _undoPlies(plies);
      case MatchEnded(:final reason, :final winner):
        if (_phase == GamePhase.playing) {
          _finish(
            GameResult(
              reason: reason,
              winner:
                  winner ??
                  (reason == GameEndReason.resignation
                      ? config.localSide.opposite
                      : null),
            ),
          );
        }
      case MatchConnectionChanged():
        notifyListeners();
      case MatchFailure(:final error):
        _lastError = error;
        notifyListeners();
      case MatchOpened():
        break;
    }
  }

  void _undoPlies(int plies) {
    if (plies <= 0 || _moves.isEmpty) return;
    final count = plies > _moves.length ? _moves.length : plies;
    _moves.removeRange(_moves.length - count, _moves.length);
    _position = _moves.isEmpty
        ? _positionFromFen(config.startingFen)
        : _positionFromFen(_moves.last.fenAfter);
    _rebuildRepetitions();
    _browseIndex = _moves.length;
    _selected = null;
    _hintUci = null;
    _refreshLegalDests();
    notifyListeners();
    unawaited(_refreshEvaluation());
  }

  // ── Oyun sonu ──

  void _checkGameEnd() {
    final outcome = _position.outcome;
    if (outcome != null) {
      final reason = _position.isCheckmate
          ? GameEndReason.checkmate
          : _position.isStalemate
          ? GameEndReason.stalemate
          : GameEndReason.insufficientMaterial;
      _finish(GameResult(reason: reason, winner: outcome.winner));
      return;
    }
    if (_repetitionCount(_position) >= 5) {
      _finish(const GameResult(reason: GameEndReason.threefoldRepetition));
      return;
    }
    if (_position.halfmoves >= 150) {
      _finish(const GameResult(reason: GameEndReason.fiftyMoveRule));
    }
  }

  void _onFlag(Side loser) {
    if (_phase != GamePhase.playing) return;
    // FIDE 6.9: rakipte mat yapacak materyal yoksa süre bitişi beraberliktir.
    final winner = loser.opposite;
    final winnerCanMate = !_position.hasInsufficientMaterial(winner);
    _finish(
      GameResult(
        reason: GameEndReason.timeout,
        winner: winnerCanMate ? winner : null,
      ),
    );
  }

  void _finish(GameResult result) {
    if (_phase == GamePhase.finished) return;
    _phase = GamePhase.finished;
    _result = result;
    _selected = null;
    _pendingPromotion = null;
    _opponentThinking = false;
    clock.stop();
    _legalDests = const {};
    onGameEnded?.call(result);
    notifyListeners();
  }

  // ── Yardımcılar ──

  void _onClockTick() {
    if (_phase == GamePhase.playing) notifyListeners();
  }

  void _refreshLegalDests() {
    _legalDests = _phase == GamePhase.playing && !isBrowsingHistory
        ? makeLegalMoves(_position)
        : const {};
  }

  Future<void> _refreshEvaluation() async {
    final engine = _analysisEngine;
    if (!analysisEnabled || engine == null) return;
    if (_opponentThinking || _phase != GamePhase.playing) return;

    final token = ++_analysisToken;
    try {
      final result = await engine.search(
        fen: config.startingFen,
        movesUci: _moves.map((m) => m.uci).toList(),
        limits: const SearchLimits(depth: 12, moveTimeMs: 400),
      );
      if (token != _analysisToken) return;
      _evaluation = result.principalVariation;
      notifyListeners();
    } catch (_) {
      // Değerlendirme isteğe bağlıdır; başarısızlığı oyunu etkilemez.
    }
  }

  /// Tekrar sayımı için pozisyon anahtarı: taş dizilişi, sıra, rok ve geçerken
  /// alma hakları. Yarım hamle sayacı ve hamle numarası dışarıda bırakılır.
  static String _repetitionKey(Position position) =>
      position.fen.split(' ').take(4).join(' ');

  void _countRepetition(Position position) {
    final key = _repetitionKey(position);
    _repetitions[key] = (_repetitions[key] ?? 0) + 1;
  }

  int _repetitionCount(Position position) =>
      _repetitions[_repetitionKey(position)] ?? 0;

  void _rebuildRepetitions() {
    _repetitions.clear();
    _countRepetition(_positionFromFen(config.startingFen));
    for (final move in _moves) {
      _countRepetition(_positionFromFen(move.fenAfter));
    }
  }

  static Position _positionFromFen(String fen) =>
      Chess.fromSetup(Setup.parseFen(fen));

  /// Oyunu PGN olarak dışa aktarır.
  String toPgn({String? event, String? white, String? black, DateTime? date}) {
    final buffer = StringBuffer();
    final stamp = date ?? DateTime.now();
    final dateTag =
        '${stamp.year}.'
        '${stamp.month.toString().padLeft(2, '0')}.'
        '${stamp.day.toString().padLeft(2, '0')}';

    buffer.writeln('[Event "${event ?? 'Satranç Ustası'}"]');
    buffer.writeln('[Site "Satranç Ustası"]');
    buffer.writeln('[Date "$dateTag"]');
    buffer.writeln('[Round "-"]');
    buffer.writeln('[White "${white ?? _defaultName(Side.white)}"]');
    buffer.writeln('[Black "${black ?? _defaultName(Side.black)}"]');
    buffer.writeln('[Result "${_result?.pgnResult ?? '*'}"]');
    if (config.startingFen != kInitialFEN) {
      buffer.writeln('[SetUp "1"]');
      buffer.writeln('[FEN "${config.startingFen}"]');
    }
    if (!config.timeControl.isUnlimited) {
      buffer.writeln(
        '[TimeControl "${config.timeControl.initial.inSeconds}'
        '+${config.timeControl.increment.inSeconds}"]',
      );
    }
    buffer.writeln();

    final startingSide = _positionFromFen(config.startingFen).turn;
    var moveNumber = _positionFromFen(config.startingFen).fullmoves;
    final line = StringBuffer();
    for (int i = 0; i < _moves.length; i++) {
      final record = _moves[i];
      if (record.side == Side.white) {
        line.write('$moveNumber. ');
      } else if (i == 0 && startingSide == Side.black) {
        line.write('$moveNumber... ');
      }
      line.write('${record.san} ');
      if (record.side == Side.black) moveNumber++;
    }
    line.write(_result?.pgnResult ?? '*');
    buffer.writeln(_wrap(line.toString(), 80));
    return buffer.toString();
  }

  String _defaultName(Side side) {
    if (config.kind == MatchKind.passAndPlay) {
      return side == Side.white ? 'Beyaz' : 'Siyah';
    }
    final engineName = config.difficulty == null
        ? 'Stockfish'
        : 'Stockfish (${config.difficulty!.trName})';
    return side == config.localSide ? 'Oyuncu' : engineName;
  }

  static String _wrap(String text, int width) {
    final words = text.split(' ');
    final buffer = StringBuffer();
    var lineLength = 0;
    for (final word in words) {
      if (lineLength + word.length + 1 > width) {
        buffer.writeln();
        lineLength = 0;
      } else if (lineLength > 0) {
        buffer.write(' ');
        lineLength++;
      }
      buffer.write(word);
      lineLength += word.length;
    }
    return buffer.toString();
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    clock.dispose();
    _transport.close();
    super.dispose();
  }
}
