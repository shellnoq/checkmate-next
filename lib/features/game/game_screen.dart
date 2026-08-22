import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/engine_provider.dart';
import '../../app/providers/settings.dart';
import '../../core/audio/sound_service.dart';
import '../../core/l10n/strings.dart';
import '../../core/storage/app_storage.dart';
import '../../domain/game_controller.dart';
import '../../domain/match/match_protocol.dart';
import '../../domain/model/game_result.dart';
import '../../domain/model/move_record.dart';
import '../board/chess_board.dart';
import 'widgets/evaluation_bar.dart';
import 'widgets/move_table.dart';
import 'widgets/player_bar.dart';
import 'widgets/promotion_sheet.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.config});

  final MatchConfig config;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  GameController? _controller;
  Object? _startupError;
  bool _boardFlipped = false;
  bool _resultShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final settings = ref.read(settingsProvider);
    SoundService.instance
      ..enabled = settings.soundEnabled
      ..hapticsEnabled = settings.hapticsEnabled;
    unawaitedPreload();

    try {
      if (widget.config.kind == MatchKind.engine) {
        await ref.read(chessEngineProvider).start();
      }
      final transport = ref
          .read(matchTransportFactoryProvider)
          .create(widget.config.kind);
      final controller =
          GameController(
              config: widget.config,
              transport: transport,
              analysisEngine: ref.read(chessEngineProvider),
              analysisEnabled: settings.showEvaluation,
            )
            ..onMoveApplied = _onMoveApplied
            ..onGameEnded = _onGameEnded;

      if (!mounted) return;
      setState(() {
        _controller = controller;
        _boardFlipped = controller.shouldFlipBoard;
      });
      controller.addListener(_onControllerChanged);
      await controller.start();
    } catch (e) {
      if (!mounted) return;
      setState(() => _startupError = e);
    }
  }

  void unawaitedPreload() {
    SoundService.instance.preload();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
    final controller = _controller;
    if (controller == null) return;
    if (controller.pendingPromotion != null) _showPromotionSheet();
  }

  void _onMoveApplied(MoveRecord record) {
    final san = record.san;
    if (san.startsWith('O-O')) {
      SoundService.instance.play(Sfx.castle);
    } else if (san.contains('x')) {
      SoundService.instance.play(Sfx.capture);
    } else {
      SoundService.instance.play(Sfx.move);
    }
    if (san.endsWith('+')) SoundService.instance.play(Sfx.check);
    SoundService.instance.haptic(
      san.contains('x') ? HapticStrength.medium : HapticStrength.light,
    );
  }

  void _onGameEnded(GameResult result) {
    _persistResult(result);
    final localWon =
        result.winner != null &&
        widget.config.kind == MatchKind.engine &&
        result.winner == widget.config.localSide;
    SoundService.instance.play(localWon ? Sfx.victory : Sfx.gameEnd);
    SoundService.instance.haptic(HapticStrength.medium);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showResultSheet());
  }

  void _persistResult(GameResult result) {
    final controller = _controller;
    if (controller == null) return;
    if (widget.config.kind == MatchKind.engine) {
      if (result.isDraw) {
        AppStorage.bumpStat('draws');
      } else if (result.winner == widget.config.localSide) {
        AppStorage.bumpStat('wins');
        AppStorage.bumpStat('wins_${widget.config.difficulty?.id}');
      } else {
        AppStorage.bumpStat('losses');
      }
    }
    AppStorage.archiveGame({
      'date': DateTime.now().toIso8601String(),
      'kind': widget.config.kind.name,
      'difficulty': widget.config.difficulty?.id,
      'localSide': widget.config.localSide.name,
      'timeControl': widget.config.timeControl.id,
      'result': result.toJson(),
      'moveCount': controller.moves.length,
      'pgn': controller.toPgn(),
      'finalFen': controller.position.fen,
    });
  }

  Future<void> _showPromotionSheet() async {
    final controller = _controller;
    if (controller == null) return;
    final settings = ref.read(settingsProvider);

    if (settings.autoQueenPromotion) {
      controller.completePromotion(Role.queen);
      return;
    }

    final s = S.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => PromotionSheet(
        side: controller.position.turn,
        pieceSet: settings.pieceSet,
        title: s.promotion,
        onSelected: (role) {
          Navigator.of(context).pop();
          controller.completePromotion(role);
        },
        onCancel: () {
          Navigator.of(context).pop();
          controller.cancelPromotion();
        },
      ),
    );
  }

  Future<void> _showResultSheet() async {
    if (_resultShown || !mounted) return;
    final controller = _controller;
    final result = controller?.result;
    if (controller == null || result == null) return;
    _resultShown = true;

    final s = S.of(context);
    final settings = ref.read(settingsProvider);

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ResultSheet(
        result: result,
        turkish: settings.turkish,
        localSide: widget.config.kind == MatchKind.engine
            ? widget.config.localSide
            : null,
        strings: s,
        onRematch: () {
          Navigator.of(context).pop();
          _resultShown = false;
          controller.rematch();
        },
        onNewGame: () {
          Navigator.of(context).pop();
          context.pushReplacement('/new-game');
        },
        onCopyPgn: () async {
          await Clipboard.setData(ClipboardData(text: controller.toPgn()));
          if (!context.mounted) return;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(s.pgnCopied)));
        },
      ),
    );
  }

  Future<bool> _confirmLeave() async {
    final controller = _controller;
    if (controller == null || controller.phase != GamePhase.playing) {
      return true;
    }
    final s = S.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.confirmResign),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.resign),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = _controller;

    if (_startupError != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 42),
                const SizedBox(height: 16),
                Text(s.engineFailed, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  '$_startupError',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (controller == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(s.engineStarting),
            ],
          ),
        ),
      );
    }

    final orientation = _boardFlipped ? Side.black : Side.white;
    final displayed = controller.displayedPosition;
    final topSide = orientation == Side.white ? Side.black : Side.white;
    final bottomSide = topSide.opposite;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final router = GoRouter.of(context);
        if (!await _confirmLeave()) return;
        if (controller.phase == GamePhase.playing) {
          await controller.resign();
        }
        if (mounted) router.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title(s, settings.turkish)),
          actions: [
            IconButton(
              tooltip: s.flipBoard,
              onPressed: () => setState(() => _boardFlipped = !_boardFlipped),
              icon: const Icon(Icons.swap_vert),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                final messenger = ScaffoldMessenger.of(context);
                switch (value) {
                  case 'draw':
                    await controller.offerDraw();
                  case 'claim':
                    if (!controller.claimDrawIfEligible()) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(s.drawDeclined)),
                      );
                    }
                  case 'pgn':
                    await Clipboard.setData(
                      ClipboardData(text: controller.toPgn()),
                    );
                    messenger.showSnackBar(
                      SnackBar(content: Text(s.pgnCopied)),
                    );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'draw', child: Text(s.offerDraw)),
                PopupMenuItem(value: 'claim', child: Text(s.claimDraw)),
                PopupMenuItem(value: 'pgn', child: Text(s.copyPgn)),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Oyuncu çubukları tahtaya bitişik durur; üçü birlikte kalan
              // alanda ortalanır. Aksi hâlde çubuklar ekranın uçlarına
              // yapışır ve tahtanın çevresinde geniş boşluk kalır.
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const barHeight = 62.0;
                    final evalWidth = settings.showEvaluation ? 22.0 : 0.0;
                    // Tahta grubu ekranın en çok %72'sini alır; kalan alan
                    // notasyon paneline bırakılır. Kısa ekranlarda tahta
                    // küçülür, panel de kendiliğinden daralır.
                    final groupHeight = constraints.maxHeight * 0.72;
                    final available = groupHeight - barHeight * 2;
                    final boardSize = (constraints.maxWidth - evalWidth - 16)
                        .clamp(
                          0.0,
                          available > 0 ? available : constraints.maxHeight,
                        );

                    return Column(
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: barHeight,
                              width: boardSize + evalWidth + 16,
                              child: PlayerBar(
                                name: _nameOf(topSide, s),
                                side: topSide,
                                captured: controller.capturedBy(topSide),
                                materialAdvantage: _advantageOf(
                                  topSide,
                                  controller,
                                ),
                                pieceSet: settings.pieceSet,
                                isActive:
                                    controller.position.turn == topSide &&
                                    controller.phase == GamePhase.playing,
                                remaining: widget.config.timeControl.isUnlimited
                                    ? null
                                    : controller.clock.remainingOf(topSide),
                                subtitle:
                                    controller.opponentThinking &&
                                        controller.position.turn == topSide
                                    ? s.thinking
                                    : null,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (settings.showEvaluation) ...[
                                  SizedBox(
                                    height: boardSize,
                                    child: EvaluationBar(
                                      line: controller.evaluation,
                                      sideToMove: controller.position.turn,
                                      orientation: orientation,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                SizedBox(
                                  width: boardSize,
                                  height: boardSize,
                                  child: ChessBoard(
                                    position: displayed,
                                    orientation: orientation,
                                    boardTheme: settings.boardTheme,
                                    pieceSet: settings.pieceSet,
                                    legalDestinations:
                                        controller.destinationsForSelected,
                                    selectedSquare: controller.selectedSquare,
                                    lastMove: controller.lastMoveSquares,
                                    checkedSquare: controller.checkedKingSquare,
                                    hintMove: _hintSquares(controller),
                                    interactive:
                                        controller.phase == GamePhase.playing,
                                    showCoordinates: settings.showCoordinates,
                                    showLegalMoves: settings.showLegalMoves,
                                    onSquareTap: controller.selectSquare,
                                    onMove: controller.moveByDrag,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: barHeight,
                              width: boardSize + evalWidth + 16,
                              child: PlayerBar(
                                name: _nameOf(bottomSide, s),
                                side: bottomSide,
                                captured: controller.capturedBy(bottomSide),
                                materialAdvantage: _advantageOf(
                                  bottomSide,
                                  controller,
                                ),
                                pieceSet: settings.pieceSet,
                                isActive:
                                    controller.position.turn == bottomSide &&
                                    controller.phase == GamePhase.playing,
                                remaining: widget.config.timeControl.isUnlimited
                                    ? null
                                    : controller.clock.remainingOf(bottomSide),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 17, indent: 16, endIndent: 16),
                        Expanded(
                          child: MoveTable(
                            moves: controller.moves,
                            currentIndex: controller.browseIndex,
                            onSelect: controller.browseTo,
                            emptyHint: s.moves,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              _ActionBar(controller: controller, strings: s),
            ],
          ),
        ),
      ),
    );
  }

  (Square, Square)? _hintSquares(GameController controller) {
    final uci = controller.hintUci;
    if (uci == null) return null;
    final move = NormalMove.fromUci(uci);
    return (move.from, move.to);
  }

  int _advantageOf(Side side, GameController controller) {
    final balance = controller.materialBalance;
    final value = side == Side.white ? balance : -balance;
    return value > 0 ? value : 0;
  }

  String _title(S s, bool turkish) {
    if (widget.config.kind == MatchKind.passAndPlay) return s.passAndPlay;
    final difficulty = widget.config.difficulty;
    return difficulty == null ? s.playVsEngine : difficulty.label(turkish);
  }

  String _nameOf(Side side, S s) {
    if (widget.config.kind == MatchKind.passAndPlay) {
      return side == Side.white ? s.white : s.black;
    }
    if (side == widget.config.localSide) {
      return s.tr ? 'Siz' : 'You';
    }
    final difficulty = widget.config.difficulty;
    return difficulty == null
        ? 'Stockfish'
        : 'Stockfish · ${difficulty.label(s.tr)}';
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.controller, required this.strings});

  final GameController controller;
  final S strings;

  @override
  Widget build(BuildContext context) {
    final playing = controller.phase == GamePhase.playing;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ActionButton(
              icon: Icons.first_page,
              label: '',
              onPressed: controller.moves.isEmpty
                  ? null
                  : controller.browseStart,
            ),
            _ActionButton(
              icon: Icons.chevron_left,
              label: '',
              onPressed: controller.browseIndex > 0
                  ? controller.browsePrevious
                  : null,
            ),
            _ActionButton(
              icon: Icons.chevron_right,
              label: '',
              onPressed: controller.isBrowsingHistory
                  ? controller.browseNext
                  : null,
            ),
            _ActionButton(
              icon: Icons.undo,
              label: strings.takeback,
              onPressed: playing && controller.moves.isNotEmpty
                  ? controller.requestTakeback
                  : null,
            ),
            _ActionButton(
              icon: Icons.lightbulb_outline,
              label: strings.hint,
              busy: controller.hintLoading,
              onPressed: playing && !controller.opponentThinking
                  ? controller.requestHint
                  : null,
            ),
            _ActionButton(
              icon: Icons.flag_outlined,
              label: strings.resign,
              danger: true,
              onPressed: playing
                  ? () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(strings.confirmResign),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(strings.cancel),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(strings.resign),
                            ),
                          ],
                        ),
                      );
                      if (confirmed ?? false) await controller.resign();
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.danger = false,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool danger;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = onPressed == null
        ? scheme.onSurfaceVariant.withValues(alpha: 0.35)
        : danger
        ? const Color(0xFFC0554F)
        : scheme.onSurface;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              busy
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(icon, size: 22, color: color),
              if (label.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: color),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultSheet extends StatelessWidget {
  const _ResultSheet({
    required this.result,
    required this.turkish,
    required this.localSide,
    required this.strings,
    required this.onRematch,
    required this.onNewGame,
    required this.onCopyPgn,
  });

  final GameResult result;
  final bool turkish;
  final Side? localSide;
  final S strings;
  final VoidCallback onRematch;
  final VoidCallback onNewGame;
  final VoidCallback onCopyPgn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final won = localSide != null && result.winner == localSide;
    final accent = result.isDraw
        ? theme.colorScheme.onSurfaceVariant
        : won
        ? const Color(0xFF3F9D6B)
        : const Color(0xFFC0554F);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Icon(
                result.isDraw
                    ? Icons.handshake_outlined
                    : won
                    ? Icons.emoji_events_outlined
                    : Icons.sentiment_dissatisfied_outlined,
                size: 44,
                color: accent,
              ),
              const SizedBox(height: 12),
              Text(
                result.headline(turkish, localSide: localSide),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                result.detail(turkish),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRematch,
                icon: const Icon(Icons.replay),
                label: Text(strings.rematch),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onNewGame,
                icon: const Icon(Icons.tune),
                label: Text(strings.newGameShort),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onCopyPgn,
                icon: const Icon(Icons.copy_all_outlined),
                label: Text(strings.copyPgn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
