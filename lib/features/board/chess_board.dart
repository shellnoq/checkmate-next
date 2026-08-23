import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../app/theme/board_theme.dart';
import 'piece_set.dart';
import 'piece_widget.dart';

/// Tahtadaki bir taşın kimliği. Hamle animasyonunun doğru taşı taşıması için
/// pozisyonlar arasında korunur.
class _TrackedPiece {
  _TrackedPiece(this.id, this.piece, this.square);

  final int id;
  final Piece piece;
  Square square;
}

/// Tahtadan kalkan bir taş. Alınan taş anında yok olmaz; kısa bir büyüyüp
/// solma animasyonuyla çıkar, böylece hamlenin ne olduğu gözden kaçmaz.
class _CapturedPiece {
  _CapturedPiece(this.id, this.piece, this.square);

  final int id;
  final Piece piece;
  final Square square;
}

/// Etkileşimli satranç tahtası.
class ChessBoard extends StatefulWidget {
  const ChessBoard({
    super.key,
    required this.position,
    required this.orientation,
    required this.boardTheme,
    required this.pieceSet,
    this.legalDestinations = const {},
    this.selectedSquare,
    this.lastMove,
    this.checkedSquare,
    this.hintMove,
    this.interactive = true,
    this.showCoordinates = true,
    this.showLegalMoves = true,
    this.onSquareTap,
    this.onMove,
  });

  final Position position;

  /// Tahtanın hangi tarafa göre döndürüleceği.
  final Side orientation;

  final BoardTheme boardTheme;
  final PieceSet pieceSet;

  /// Seçili taşın gidebileceği kareler.
  final Set<Square> legalDestinations;
  final Square? selectedSquare;
  final (Square, Square)? lastMove;
  final Square? checkedSquare;

  /// İpucu oku için hamle.
  final (Square, Square)? hintMove;

  final bool interactive;
  final bool showCoordinates;
  final bool showLegalMoves;

  final void Function(Square square)? onSquareTap;
  final void Function(Square from, Square to)? onMove;

  @override
  State<ChessBoard> createState() => _ChessBoardState();
}

class _ChessBoardState extends State<ChessBoard>
    with SingleTickerProviderStateMixin {
  static const _animationDuration = Duration(milliseconds: 180);
  static const _captureDuration = Duration(milliseconds: 260);

  final List<_TrackedPiece> _tracked = [];

  /// Solmakta olan, tahtadan kalkmış taşlar.
  final List<_CapturedPiece> _captured = [];

  int _nextId = 0;

  Square? _dragFrom;
  Offset? _dragPosition;

  /// Şah çekildiği anda oynatılan sönümlü çift vuruş. Sürekli yanıp sönmek
  /// uzun düşünme sürelerinde rahatsız edici olacağından animasyon biter ve
  /// geriye sabit kırmızı vurgu kalır.
  late final AnimationController _checkPulse;

  @override
  void initState() {
    super.initState();
    _checkPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
    _syncPieces(widget.position, animate: false);
    if (widget.checkedSquare != null) _checkPulse.forward(from: 0);
  }

  @override
  void dispose() {
    _checkPulse.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChessBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position.fen != widget.position.fen) {
      _syncPieces(widget.position, animate: true);
    }
    final square = widget.checkedSquare;
    if (square != null && square != oldWidget.checkedSquare) {
      _checkPulse.forward(from: 0);
    } else if (square == null) {
      _checkPulse.value = 0;
    }
  }

  /// Yeni pozisyonu izlenen taş listesine yansıtır. Aynı kareden aynı taşın
  /// başka bir kareye geçtiği durumlarda kimlik korunur; böylece
  /// [AnimatedPositioned] taşı kaydırarak taşır.
  void _syncPieces(Position position, {required bool animate}) {
    final board = position.board;
    final target = <Square, Piece>{
      for (final square in board.occupied.squares)
        square: board.pieceAt(square)!,
    };

    final remaining = <_TrackedPiece>[];
    final unmatchedTargets = Map<Square, Piece>.from(target);

    // 1) Yerinde kalan taşlar.
    for (final tracked in _tracked) {
      final piece = unmatchedTargets[tracked.square];
      if (piece != null &&
          piece.role == tracked.piece.role &&
          piece.color == tracked.piece.color) {
        remaining.add(tracked);
        unmatchedTargets.remove(tracked.square);
      }
    }

    // 2) Yer değiştiren taşlar: aynı renk ve rolden artan bir taş varsa
    //    kimliği devral (terfi durumunda rol değişir, o zaman yeni kimlik).
    final leftovers = _tracked.where((t) => !remaining.contains(t)).toList();
    for (final entry in Map<Square, Piece>.from(unmatchedTargets).entries) {
      final match = leftovers.firstWhere(
        (t) =>
            t.piece.role == entry.value.role &&
            t.piece.color == entry.value.color,
        orElse: () => _TrackedPiece(-1, entry.value, entry.key),
      );
      if (match.id != -1) {
        leftovers.remove(match);
        match.square = entry.key;
        remaining.add(match);
        unmatchedTargets.remove(entry.key);
      }
    }

    // 3) Kalanlar yeni taş (terfi, yeni oyun).
    for (final entry in unmatchedTargets.entries) {
      remaining.add(_TrackedPiece(_nextId++, entry.value, entry.key));
    }

    // 4) Hiçbir hedefe denk gelmeyenler tahtadan kalkmıştır: alınan taş,
    //    geçerken alınan piyon ya da terfi eden piyonun kendisi. Tek bir
    //    hamlede en çok bir taş kalkabileceği için, daha fazlası bir hamle
    //    değil kurulum değişikliğidir (yeni oyun, geri alma) ve animasyonsuz
    //    geçilir.
    if (animate && leftovers.isNotEmpty && leftovers.length <= 2) {
      for (final gone in leftovers) {
        _captured.add(_CapturedPiece(_nextId++, gone.piece, gone.square));
      }
    }

    _tracked
      ..clear()
      ..addAll(remaining);
  }

  /// Ekran koordinatını kareye çevirir.
  Square? _squareAt(Offset local, double squareSize) {
    final col = (local.dx / squareSize).floor();
    final row = (local.dy / squareSize).floor();
    if (col < 0 || col > 7 || row < 0 || row > 7) return null;
    return _squareOfCell(row, col);
  }

  Square _squareOfCell(int row, int col) {
    if (widget.orientation == Side.white) {
      return Square.fromCoords(File(col), Rank(7 - row));
    }
    return Square.fromCoords(File(7 - col), Rank(row));
  }

  (int row, int col) _cellOfSquare(Square square) {
    if (widget.orientation == Side.white) {
      return (7 - square.rank, square.file);
    }
    return (square.rank, 7 - square.file);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.biggest.shortestSide;
        final squareSize = boardSize / 8;

        return SizedBox(
          width: boardSize,
          height: boardSize,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: widget.interactive
                ? (details) {
                    final square = _squareAt(details.localPosition, squareSize);
                    if (square != null) widget.onSquareTap?.call(square);
                  }
                : null,
            onPanStart: widget.interactive
                ? (details) {
                    final square = _squareAt(details.localPosition, squareSize);
                    if (square == null) return;
                    if (widget.position.board.pieceAt(square) == null) return;
                    setState(() {
                      _dragFrom = square;
                      _dragPosition = details.localPosition;
                    });
                    widget.onSquareTap?.call(square);
                  }
                : null,
            onPanUpdate: widget.interactive
                ? (details) {
                    if (_dragFrom == null) return;
                    setState(() => _dragPosition = details.localPosition);
                  }
                : null,
            onPanEnd: widget.interactive
                ? (_) {
                    final from = _dragFrom;
                    final position = _dragPosition;
                    setState(() {
                      _dragFrom = null;
                      _dragPosition = null;
                    });
                    if (from == null || position == null) return;
                    final to = _squareAt(position, squareSize);
                    if (to != null && to != from) {
                      widget.onMove?.call(from, to);
                    }
                  }
                : null,
            onPanCancel: widget.interactive
                ? () => setState(() {
                    _dragFrom = null;
                    _dragPosition = null;
                  })
                : null,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildSquares(squareSize),
                if (widget.showLegalMoves) _buildDestinations(squareSize),
                ..._buildCaptured(squareSize),
                ..._buildPieces(squareSize),
                if (widget.hintMove != null) _buildHint(squareSize),
                if (_dragFrom != null && _dragPosition != null)
                  _buildDragged(squareSize),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSquares(double squareSize) {
    final theme = widget.boardTheme;
    return SizedBox(
      width: squareSize * 8,
      height: squareSize * 8,
      child: Column(
        children: [
          for (int row = 0; row < 8; row++)
            Row(
              children: [
                for (int col = 0; col < 8; col++)
                  _buildSquare(row, col, squareSize, theme),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSquare(int row, int col, double size, BoardTheme theme) {
    final square = _squareOfCell(row, col);
    final isLight = (square.file + square.rank).isEven;
    final baseColor = isLight ? theme.light : theme.dark;

    final isChecked = widget.checkedSquare == square;

    Color? overlay;
    if (isChecked) {
      overlay = theme.check;
    } else if (widget.selectedSquare == square) {
      overlay = theme.selection;
    } else if (widget.lastMove != null &&
        (widget.lastMove!.$1 == square || widget.lastMove!.$2 == square)) {
      overlay = theme.lastMove;
    }

    final coordinateColor = isLight
        ? theme.coordinateOnLight
        : theme.coordinateOnDark;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: baseColor)),
          if (overlay != null)
            Positioned.fill(child: ColoredBox(color: overlay)),
          if (isChecked)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _checkPulse,
                builder: (context, _) {
                  final t = _checkPulse.value;
                  // İki vuruşluk, giderek sönen bir parlama.
                  final beat = math.sin(t * math.pi * 4).abs();
                  final strength = beat * (1 - t) * (1 - t);
                  if (strength <= 0.01) return const SizedBox.shrink();
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          theme.check.withValues(alpha: strength),
                          theme.check.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          if (widget.showCoordinates && col == 0)
            Positioned(
              left: size * 0.06,
              top: size * 0.04,
              child: Text(
                square.rank.name,
                style: TextStyle(
                  fontSize: size * 0.2,
                  fontWeight: FontWeight.w600,
                  color: coordinateColor,
                ),
              ),
            ),
          if (widget.showCoordinates && row == 7)
            Positioned(
              right: size * 0.06,
              bottom: size * 0.02,
              child: Text(
                square.file.name,
                style: TextStyle(
                  fontSize: size * 0.2,
                  fontWeight: FontWeight.w600,
                  color: coordinateColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDestinations(double squareSize) {
    if (widget.legalDestinations.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: Stack(
        children: [
          for (final square in widget.legalDestinations)
            _destinationMarker(square, squareSize),
        ],
      ),
    );
  }

  Widget _destinationMarker(Square square, double squareSize) {
    final (row, col) = _cellOfSquare(square);
    final isCapture = widget.position.board.pieceAt(square) != null;
    return Positioned(
      left: col * squareSize,
      top: row * squareSize,
      width: squareSize,
      height: squareSize,
      child: Center(
        child: isCapture
            ? Container(
                width: squareSize * 0.92,
                height: squareSize * 0.92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.28),
                    width: squareSize * 0.09,
                  ),
                ),
              )
            : Container(
                width: squareSize * 0.28,
                height: squareSize * 0.28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.22),
                ),
              ),
      ),
    );
  }

  List<Widget> _buildPieces(double squareSize) {
    return [
      for (final tracked in _tracked)
        AnimatedPositioned(
          key: ValueKey(tracked.id),
          duration: _animationDuration,
          curve: Curves.easeOutCubic,
          left: _cellOfSquare(tracked.square).$2 * squareSize,
          top: _cellOfSquare(tracked.square).$1 * squareSize,
          width: squareSize,
          height: squareSize,
          child: IgnorePointer(
            child: PieceWidget(
              piece: tracked.piece,
              size: squareSize,
              pieceSet: widget.pieceSet,
              opacity: _dragFrom == tracked.square ? 0.28 : 1.0,
            ),
          ),
        ),
    ];
  }

  /// Kalkan taşları büyüterek soldurur, bitince listeden düşürür.
  List<Widget> _buildCaptured(double squareSize) {
    return [
      for (final gone in _captured)
        Positioned(
          key: ValueKey('captured_${gone.id}'),
          left: _cellOfSquare(gone.square).$2 * squareSize,
          top: _cellOfSquare(gone.square).$1 * squareSize,
          width: squareSize,
          height: squareSize,
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: _captureDuration,
              curve: Curves.easeOut,
              onEnd: () {
                if (!mounted) return;
                setState(() => _captured.remove(gone));
              },
              builder: (context, t, child) => Opacity(
                opacity: (1 - t).clamp(0.0, 1.0),
                child: Transform.scale(scale: 1 + t * 0.45, child: child),
              ),
              child: PieceWidget(
                piece: gone.piece,
                size: squareSize,
                pieceSet: widget.pieceSet,
              ),
            ),
          ),
        ),
    ];
  }

  Widget _buildDragged(double squareSize) {
    final piece = widget.position.board.pieceAt(_dragFrom!);
    if (piece == null) return const SizedBox.shrink();
    // Sürüklenen taş parmağın biraz üzerinde durur; aksi hâlde parmak taşı
    // kapatır.
    final size = squareSize * 1.25;
    return Positioned(
      left: _dragPosition!.dx - size / 2,
      top: _dragPosition!.dy - size * 0.75,
      child: IgnorePointer(
        child: PieceWidget(piece: piece, size: size, pieceSet: widget.pieceSet),
      ),
    );
  }

  Widget _buildHint(double squareSize) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size(squareSize * 8, squareSize * 8),
        painter: _HintArrowPainter(
          from: _cellOfSquare(widget.hintMove!.$1),
          to: _cellOfSquare(widget.hintMove!.$2),
          squareSize: squareSize,
          color: const Color(0xCC2F6F4E),
        ),
      ),
    );
  }
}

/// İpucu okunu çizer.
class _HintArrowPainter extends CustomPainter {
  _HintArrowPainter({
    required this.from,
    required this.to,
    required this.squareSize,
    required this.color,
  });

  final (int, int) from;
  final (int, int) to;
  final double squareSize;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(
      (from.$2 + 0.5) * squareSize,
      (from.$1 + 0.5) * squareSize,
    );
    final end = Offset((to.$2 + 0.5) * squareSize, (to.$1 + 0.5) * squareSize);

    final direction = (end - start);
    final length = direction.distance;
    if (length == 0) return;
    final unit = direction / length;
    final headLength = squareSize * 0.42;
    final shaftEnd = end - unit * headLength;

    final paint = Paint()
      ..color = color
      ..strokeWidth = squareSize * 0.16
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, shaftEnd, paint);

    final perpendicular = Offset(-unit.dy, unit.dx) * (squareSize * 0.22);
    final head = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(shaftEnd.dx + perpendicular.dx, shaftEnd.dy + perpendicular.dy)
      ..lineTo(shaftEnd.dx - perpendicular.dx, shaftEnd.dy - perpendicular.dy)
      ..close();
    canvas.drawPath(head, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _HintArrowPainter oldDelegate) =>
      oldDelegate.from != from ||
      oldDelegate.to != to ||
      oldDelegate.squareSize != squareSize;
}
