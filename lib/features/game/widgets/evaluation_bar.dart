import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../../engine/engine_models.dart';

/// Dikey değerlendirme çubuğu.
///
/// Motorun santipiyon değerlendirmesini beyazın payı olarak gösterir. Mat
/// varsa çubuk tamamen kazanan tarafa geçer.
class EvaluationBar extends StatelessWidget {
  const EvaluationBar({
    super.key,
    required this.line,
    required this.sideToMove,
    required this.orientation,
    this.width = 14,
  });

  final EngineLine? line;

  /// Değerlendirmenin ait olduğu, sırası gelen taraf.
  final Side sideToMove;

  /// Tahtanın yönü; çubuk da aynı yöne göre çizilir.
  final Side orientation;

  final double width;

  /// Beyazın payı (0.0-1.0).
  double get _whiteShare {
    final l = line;
    if (l == null) return 0.5;
    if (l.mateIn != null) {
      final mateForSideToMove = l.mateIn! > 0;
      final winner = mateForSideToMove ? sideToMove : sideToMove.opposite;
      return winner == Side.white ? 1.0 : 0.0;
    }
    final cp = l.centipawns;
    if (cp == null) return 0.5;
    final fromWhite = sideToMove == Side.white ? cp : -cp;
    // Lichess'in kullandığı yumuşatmaya yakın bir eğri: ±400 santipiyondan
    // sonra çubuk doygunlaşır.
    final clamped = fromWhite.clamp(-1000, 1000) / 1000;
    final curved =
        clamped.sign * (1 - (1 - clamped.abs()) * (1 - clamped.abs()));
    return (0.5 + curved * 0.5).clamp(0.02, 0.98);
  }

  String get _label {
    final l = line;
    if (l == null) return '';
    if (l.mateIn != null) {
      final n = l.mateIn!.abs();
      return 'M$n';
    }
    final cp = l.centipawns;
    if (cp == null) return '';
    final fromWhite = sideToMove == Side.white ? cp : -cp;
    final pawns = fromWhite / 100;
    return pawns.abs() >= 10
        ? pawns.toStringAsFixed(0)
        : pawns.abs().toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final share = _whiteShare;
    final whiteOnBottom = orientation == Side.white;

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final whiteHeight = height * share;

        return SizedBox(
          width: width,
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(width / 2),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(color: const Color(0xFF2A2E33)),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  left: 0,
                  right: 0,
                  top: whiteOnBottom ? height - whiteHeight : 0,
                  height: whiteHeight,
                  child: const ColoredBox(color: Color(0xFFEDEAE3)),
                ),
                if (_label.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: share > 0.5 ? null : 2,
                    bottom: share > 0.5 ? 2 : null,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        _label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: share > 0.5
                              ? const Color(0xFFEDEAE3)
                              : const Color(0xFF2A2E33),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
