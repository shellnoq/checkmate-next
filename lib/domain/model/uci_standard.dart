import 'package:dartchess/dartchess.dart';

/// Rok hamlesini standart UCI biçimine çevirir.
///
/// `dartchess` rok için hem şah-iki-kare (`e1g1`) hem şah-kaleye (`e1h1`)
/// gösterimini geçerli sayar. UCI protokolü ve kayıt biçimi ise (Chess960
/// dışında) yalnızca birincisini tanır; kaleye dokunarak yapılan rok da,
/// kitap satırından çözülen rok da burada tek biçime indirgenir.
String standardizeCastlingUci(Position position, NormalMove move) {
  final piece = position.board.pieceAt(move.from);
  if (piece == null || piece.role != Role.king) return move.uci;
  final target = position.board.pieceAt(move.to);
  if (target == null ||
      target.role != Role.rook ||
      target.color != piece.color) {
    return move.uci;
  }
  final kingSide = move.to.file > move.from.file;
  return NormalMove(
    from: move.from,
    to: Square.fromCoords(File(kingSide ? 6 : 2), move.from.rank),
  ).uci;
}
