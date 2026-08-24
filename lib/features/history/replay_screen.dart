import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/engine_provider.dart';
import '../../app/providers/settings.dart';
import '../../core/l10n/strings.dart';
import '../../domain/analysis/game_analyzer.dart';
import '../../domain/model/difficulty.dart';
import '../../domain/model/game_result.dart';
import '../../domain/model/move_record.dart';
import '../../domain/openings/opening_book.dart';
import '../../engine/engine_models.dart';
import '../board/chess_board.dart';
import '../game/widgets/move_table.dart';
import 'quality_style.dart';

/// Maç tekrarı: arşivdeki bir oyunu ya da bir açılış satırını tahtada adım
/// adım oynatır; istenirse motorla hamle hamle değerlendirir.
class ReplayScreen extends ConsumerStatefulWidget {
  const ReplayScreen({super.key, required this.game});

  /// Arşiv kaydının kendisi ya da `kind: 'opening'` ile bir kitap satırı.
  final Map<String, Object?> game;

  @override
  ConsumerState<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends ConsumerState<ReplayScreen> {
  List<Position> _positions = const [];
  List<MoveRecord> _records = const [];
  String? _parseError;
  int _index = 0;

  Opening? _opening;
  int _bookPlies = 0;

  GameAnalysis? _analysis;
  bool _analyzing = false;
  bool _cancelled = false;
  int _done = 0;
  int _total = 0;

  bool get _isOpeningLine => widget.game['kind'] == 'opening';

  List<String> get _uci => switch (widget.game['uci']) {
    final List<dynamic> list => list.cast<String>(),
    _ => const <String>[],
  };

  String get _startFen =>
      (widget.game['startingFen'] as String?) ?? kInitialFEN;

  @override
  void initState() {
    super.initState();
    try {
      var position = Chess.fromSetup(Setup.parseFen(_startFen)) as Position;
      final positions = <Position>[position];
      final records = <MoveRecord>[];
      for (final uci in _uci) {
        final mover = position.turn;
        final move = position.normalizeMove(NormalMove.fromUci(uci));
        final (next, san) = position.makeSan(move);
        position = next;
        positions.add(position);
        records.add(
          MoveRecord(uci: uci, san: san, fenAfter: position.fen, side: mover),
        );
      }
      _positions = positions;
      _records = records;
      _index = _isOpeningLine ? 0 : records.length;
      _opening = OpeningBook.identify(_uci);
      _bookPlies = OpeningBook.bookPlies(_uci);
    } catch (e) {
      _parseError = '$e';
    }
  }

  @override
  void dispose() {
    _cancelled = true;
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    final engine = ref.read(chessEngineProvider);
    setState(() {
      _analyzing = true;
      _done = 0;
      _total = _positions.length;
    });
    try {
      await engine.start();
      // Analiz her zaman tam güçte yapılır; son oyunun zorluk ayarı kalmasın.
      await engine.applyOptions(const EngineOptions(threads: 2, hashMb: 64));
      final analysis = await GameAnalyzer.analyze(
        engine: engine,
        startFen: _startFen,
        uciMoves: _uci,
        bookPlies: _bookPlies,
        onProgress: (done, total) {
          if (mounted) {
            setState(() {
              _done = done;
              _total = total;
            });
          }
        },
        isCancelled: () => _cancelled || !mounted,
      );
      if (mounted && analysis != null) {
        setState(() => _analysis = analysis);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  MoveQuality? _qualityOf(int moveIndex) {
    final analysis = _analysis;
    if (analysis != null && moveIndex < analysis.qualities.length) {
      return analysis.qualities[moveIndex];
    }
    if (moveIndex < _bookPlies) return MoveQuality.book;
    return null;
  }

  String _qualityLabel(S s, MoveQuality quality) => switch (quality) {
    MoveQuality.book => s.qualityBook,
    MoveQuality.brilliant => s.qualityBrilliant,
    MoveQuality.good => s.qualityGood,
    MoveQuality.dubious => s.qualityDubious,
    MoveQuality.bad => s.qualityBad,
  };

  (String, String) _playerNames(S s) {
    if (widget.game['kind'] == 'passAndPlay') return (s.white, s.black);
    final localBlack = widget.game['localSide'] == 'black';
    final difficultyId = widget.game['difficulty'] as String?;
    final engineName = difficultyId == null
        ? 'Stockfish'
        : 'Stockfish · ${DifficultyLevel.fromId(difficultyId).label(s.tr)}';
    final you = s.tr ? 'Siz' : 'You';
    return localBlack ? (engineName, you) : (you, engineName);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    final title = _isOpeningLine
        ? (widget.game['openingName'] as String? ?? s.replay)
        : s.replay;

    if (_parseError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_parseError!),
          ),
        ),
      );
    }

    final orientation = widget.game['localSide'] == 'black'
        ? Side.black
        : Side.white;
    final lastMove = _index > 0
        ? () {
            final move = NormalMove.fromUci(_records[_index - 1].uci);
            return (move.from, move.to);
          }()
        : null;

    String? header;
    if (!_isOpeningLine) {
      final names = _playerNames(s);
      final resultJson = widget.game['result'];
      final result = resultJson is Map
          ? GameResult.fromJson(resultJson.cast<String, Object?>())
          : null;
      header =
          '${names.$1} – ${names.$2}'
          '${result != null ? ' · ${result.headline(s.tr)}' : ''}';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (!_isOpeningLine && _records.isNotEmpty)
            IconButton(
              tooltip: s.analyze,
              onPressed: _analyzing || _analysis != null ? null : _runAnalysis,
              icon: const Icon(Icons.insights_outlined),
            ),
          if (widget.game['pgn'] is String)
            IconButton(
              tooltip: s.copyPgn,
              icon: const Icon(Icons.copy_all_outlined),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await Clipboard.setData(
                  ClipboardData(text: widget.game['pgn']! as String),
                );
                messenger.showSnackBar(SnackBar(content: Text(s.pgnCopied)));
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (header != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text(
                  header,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (_opening != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
                child: Text(
                  '${_opening!.eco} · ${_opening!.label(s.tr)}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final boardSize = (constraints.maxWidth - 16).clamp(
                    0.0,
                    constraints.maxHeight * 0.62,
                  );
                  return Column(
                    children: [
                      Expanded(
                        flex: 0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: SizedBox(
                            width: boardSize,
                            height: boardSize,
                            child: ChessBoard(
                              position: _positions[_index],
                              orientation: orientation,
                              boardTheme: settings.boardTheme,
                              pieceSet: settings.pieceSet,
                              lastMove: lastMove,
                              interactive: false,
                              showCoordinates: settings.showCoordinates,
                              showLegalMoves: false,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 30, child: _qualityStrip(s, theme)),
                      if (_analyzing)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: _total == 0 ? null : _done / _total,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '$_done/$_total',
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      const Divider(height: 9),
                      Expanded(
                        child: MoveTable(
                          moves: _records,
                          currentIndex: _index,
                          onSelect: (i) => setState(() => _index = i),
                          emptyHint: s.moves,
                          qualityOf: _qualityOf,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 1),
            SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: _index > 0
                        ? () => setState(() => _index = 0)
                        : null,
                    icon: const Icon(Icons.first_page),
                  ),
                  IconButton(
                    onPressed: _index > 0
                        ? () => setState(() => _index--)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  IconButton(
                    onPressed: _index < _records.length
                        ? () => setState(() => _index++)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                  IconButton(
                    onPressed: _index < _records.length
                        ? () => setState(() => _index = _records.length)
                        : null,
                    icon: const Icon(Icons.last_page),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qualityStrip(S s, ThemeData theme) {
    if (_index == 0 || _records.isEmpty) return const SizedBox.shrink();
    final moveIndex = _index - 1;
    final quality = _qualityOf(moveIndex);
    if (quality == null) return const SizedBox.shrink();

    final loss = _analysis != null && moveIndex < _analysis!.cpLoss.length
        ? _analysis!.cpLoss[moveIndex]
        : null;
    final lossText = loss != null && loss > 25
        ? ' · −${(loss / 100).toStringAsFixed(1)}'
        : '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(quality.icon, size: 18, color: quality.color),
        const SizedBox(width: 6),
        Text(
          '${_records[moveIndex].san} · ${_qualityLabel(s, quality)}$lossText',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
