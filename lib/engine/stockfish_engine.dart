import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:stockfish/stockfish.dart';

import 'chess_engine.dart';
import 'engine_models.dart';

/// [ChessEngine]'in Stockfish (UCI, FFI) gerçeklemesi.
///
/// Native motor kendi isolate'inde çalışır; bu sınıf yalnızca UCI metin
/// protokolünü konuşur, dolayısıyla arayüz iş parçacığı hiç bloklanmaz.
class StockfishEngine implements ChessEngine {
  StockfishEngine({Random? random}) : _random = random ?? Random();

  static const _handshakeTimeout = Duration(seconds: 20);
  static const _searchTimeout = Duration(seconds: 90);

  final Random _random;
  final ValueNotifier<EngineStatus> _status =
      ValueNotifier(EngineStatus.idle);
  final StreamController<EngineLine> _infoController =
      StreamController<EngineLine>.broadcast();

  Stockfish? _stockfish;
  StreamSubscription<String>? _stdoutSub;

  Completer<void>? _uciOkCompleter;
  Completer<void>? _readyOkCompleter;
  Completer<SearchResult>? _searchCompleter;

  final Map<int, EngineLine> _pendingLines = {};
  Stopwatch? _searchClock;
  double _blunderChance = 0.0;
  Future<void>? _startFuture;

  @override
  ValueListenable<EngineStatus> get status => _status;

  @override
  Stream<EngineLine> get infoStream => _infoController.stream;

  bool get isReady => _status.value == EngineStatus.ready ||
      _status.value == EngineStatus.searching;

  @override
  Future<void> start() {
    // Çift başlatmaya karşı koruma: stockfish paketi aynı anda tek örneğe izin
    // verir, ikinci bir Stockfish() çağrısı StateError fırlatır.
    return _startFuture ??= _start();
  }

  Future<void> _start() async {
    if (isReady) return;
    _status.value = EngineStatus.starting;
    try {
      final sf = Stockfish();
      _stockfish = sf;
      _stdoutSub = sf.stdout.listen(_onLine, onError: (Object e) {
        _fail(e);
      });

      // Native motorun ayağa kalkmasını bekle.
      final deadline = DateTime.now().add(_handshakeTimeout);
      while (sf.state.value == StockfishState.starting) {
        if (DateTime.now().isAfter(deadline)) {
          throw TimeoutException('Stockfish başlatılamadı');
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      if (sf.state.value != StockfishState.ready) {
        throw StateError('Stockfish durumu: ${sf.state.value}');
      }

      _uciOkCompleter = Completer<void>();
      sf.stdin = 'uci';
      await _uciOkCompleter!.future.timeout(_handshakeTimeout);

      await _isReady();
      _status.value = EngineStatus.ready;
    } catch (e) {
      _startFuture = null;
      _fail(e);
      rethrow;
    }
  }

  Future<void> _isReady() async {
    final sf = _stockfish;
    if (sf == null) throw StateError('Motor başlatılmadı');
    _readyOkCompleter = Completer<void>();
    sf.stdin = 'isready';
    await _readyOkCompleter!.future.timeout(_handshakeTimeout);
  }

  @override
  Future<void> applyOptions(EngineOptions options) async {
    await start();
    final sf = _stockfish!;
    _blunderChance = options.blunderChance;
    for (final cmd in options.toUciCommands()) {
      sf.stdin = cmd;
    }
    await _isReady();
  }

  @override
  Future<SearchResult> search({
    required String fen,
    List<String> movesUci = const [],
    required SearchLimits limits,
  }) async {
    await start();
    final sf = _stockfish!;

    if (_searchCompleter != null && !_searchCompleter!.isCompleted) {
      // Önceki arama hâlâ sürüyorsa önce onu bitir.
      await stopSearch();
      await _searchCompleter!.future.catchError((_) => const SearchResult(
            bestMoveUci: null,
          ));
    }

    _pendingLines.clear();
    _searchClock = Stopwatch()..start();
    _searchCompleter = Completer<SearchResult>();
    _status.value = EngineStatus.searching;

    sf.stdin = 'setoption name MultiPV value ${limits.multiPv}';
    final position = movesUci.isEmpty
        ? 'position fen $fen'
        : 'position fen $fen moves ${movesUci.join(' ')}';
    sf.stdin = position;

    final go = StringBuffer('go');
    if (limits.depth != null) go.write(' depth ${limits.depth}');
    if (limits.moveTimeMs != null) go.write(' movetime ${limits.moveTimeMs}');
    sf.stdin = go.toString();

    try {
      return await _searchCompleter!.future.timeout(_searchTimeout);
    } on TimeoutException {
      await stopSearch();
      rethrow;
    } finally {
      if (_status.value == EngineStatus.searching) {
        _status.value = EngineStatus.ready;
      }
    }
  }

  @override
  Future<void> stopSearch() async {
    final sf = _stockfish;
    if (sf == null || _status.value != EngineStatus.searching) return;
    sf.stdin = 'stop';
  }

  // ── UCI çıktısının ayrıştırılması ──

  void _onLine(String line) {
    if (line.isEmpty) return;
    if (line == 'uciok') {
      _completeOnce(_uciOkCompleter);
      return;
    }
    if (line == 'readyok') {
      _completeOnce(_readyOkCompleter);
      return;
    }
    if (line.startsWith('info ')) {
      final parsed = _parseInfo(line);
      if (parsed != null) {
        _pendingLines[parsed.multiPvIndex] = parsed;
        if (!_infoController.isClosed) _infoController.add(parsed);
      }
      return;
    }
    if (line.startsWith('bestmove')) {
      _onBestMove(line);
    }
  }

  void _completeOnce(Completer<void>? c) {
    if (c != null && !c.isCompleted) c.complete();
  }

  /// `info depth 12 multipv 1 score cp 34 ... pv e2e4 e7e5` satırını ayrıştırır.
  EngineLine? _parseInfo(String line) {
    final tokens = line.split(RegExp(r'\s+'));
    if (tokens.contains('string')) return null;

    int depth = 0;
    int multiPv = 1;
    int? cp;
    int? mate;
    List<String> pv = const [];

    for (int i = 1; i < tokens.length; i++) {
      switch (tokens[i]) {
        case 'depth':
          depth = int.tryParse(_at(tokens, i + 1) ?? '') ?? depth;
        case 'multipv':
          multiPv = int.tryParse(_at(tokens, i + 1) ?? '') ?? multiPv;
        case 'score':
          final kind = _at(tokens, i + 1);
          final value = int.tryParse(_at(tokens, i + 2) ?? '');
          if (kind == 'cp') {
            cp = value;
          } else if (kind == 'mate') {
            mate = value;
          }
        case 'pv':
          pv = tokens.sublist(min(i + 1, tokens.length));
          i = tokens.length;
      }
    }

    if (pv.isEmpty && cp == null && mate == null) return null;
    return EngineLine(
      multiPvIndex: multiPv,
      depth: depth,
      centipawns: cp,
      mateIn: mate,
      pv: pv,
    );
  }

  static String? _at(List<String> list, int index) =>
      index >= 0 && index < list.length ? list[index] : null;

  void _onBestMove(String line) {
    final tokens = line.split(RegExp(r'\s+'));
    String? best = _at(tokens, 1);
    if (best == '(none)' || best == null || best.isEmpty) best = null;
    String? ponder;
    final ponderIndex = tokens.indexOf('ponder');
    if (ponderIndex != -1) ponder = _at(tokens, ponderIndex + 1);

    final lines = _pendingLines.values.toList()
      ..sort((a, b) => a.multiPvIndex.compareTo(b.multiPvIndex));

    final chosen = _applyWeakness(best, lines);

    _searchClock?.stop();
    final result = SearchResult(
      bestMoveUci: chosen,
      ponderUci: chosen == best ? ponder : null,
      lines: lines,
      elapsed: _searchClock?.elapsed ?? Duration.zero,
    );
    _searchClock = null;
    _status.value = EngineStatus.ready;

    final completer = _searchCompleter;
    _searchCompleter = null;
    if (completer != null && !completer.isCompleted) completer.complete(result);
  }

  /// Çok düşük seviyelerde Stockfish'in `Skill Level` zayıflatması yetmez;
  /// MultiPV ile üretilen alternatiflerden kasıtlı olarak daha zayıf bir
  /// hamle seçerek gerçekçi bir acemi rakip elde edilir.
  String? _applyWeakness(String? best, List<EngineLine> lines) {
    if (best == null || _blunderChance <= 0 || lines.length < 2) return best;
    if (_random.nextDouble() >= _blunderChance) return best;

    final alternatives = lines
        .where((l) => l.multiPvIndex > 1 && l.bestMoveUci != null)
        .toList();
    if (alternatives.isEmpty) return best;

    // Mat kaçırmayı ya da mat yemeyi rastgeleliğe bırakma: acemi de olsa
    // matı görmesi beklenen durumlarda en iyi hamlede kal.
    final pv1 = lines.firstWhere((l) => l.multiPvIndex == 1,
        orElse: () => alternatives.first);
    if (pv1.isMate) return best;

    // Sıraya göre azalan ağırlık: ikinci en iyi hamle en olası alternatif.
    final weights = <double>[
      for (int i = 0; i < alternatives.length; i++) 1.0 / (i + 1),
    ];
    final total = weights.fold<double>(0, (a, b) => a + b);
    var roll = _random.nextDouble() * total;
    for (int i = 0; i < alternatives.length; i++) {
      roll -= weights[i];
      if (roll <= 0) return alternatives[i].bestMoveUci;
    }
    return alternatives.last.bestMoveUci;
  }

  void _fail(Object error) {
    _status.value = EngineStatus.failed;
    final search = _searchCompleter;
    _searchCompleter = null;
    if (search != null && !search.isCompleted) search.completeError(error);
    _completeOnce(_uciOkCompleter);
    _completeOnce(_readyOkCompleter);
    debugPrint('StockfishEngine hatası: $error');
  }

  @override
  Future<void> dispose() async {
    await _stdoutSub?.cancel();
    _stdoutSub = null;
    try {
      _stockfish?.dispose();
    } catch (_) {
      // Motor zaten kapanmış olabilir.
    }
    _stockfish = null;
    _startFuture = null;
    _status.value = EngineStatus.disposed;
    await _infoController.close();
  }
}
