import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'piece_set.dart';
import 'piece_svg.dart';

/// Tek bir satranç taşı.
class PieceWidget extends StatelessWidget {
  const PieceWidget({
    super.key,
    required this.piece,
    required this.size,
    required this.pieceSet,
    this.opacity = 1.0,
  });

  final Piece piece;
  final double size;
  final PieceSet pieceSet;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final svg = PieceSvg.of(piece, pieceSet);
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: size,
        height: size,
        child: Padding(
          // Klasik takımda kare kenarına bir pay bırakılır. Neşeli takım
          // kareyi daha çok doldurur; küçük yaş grubunda taşların iri
          // görünmesi hem daha çekici hem dokunması daha kolay.
          padding: EdgeInsets.all(
            size * (pieceSet.shape == PieceShape.playful ? 0.005 : 0.04),
          ),
          child: SvgPicture.string(svg, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
