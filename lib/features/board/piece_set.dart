import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

/// Taş takımının renk şeması.
class PieceSet {
  final String id;
  final String trName;
  final String enName;
  final Color whiteFill;
  final Color whiteStroke;
  final Color whiteDetail;
  final Color blackFill;
  final Color blackStroke;
  final Color blackDetail;

  const PieceSet({
    required this.id,
    required this.trName,
    required this.enName,
    required this.whiteFill,
    required this.whiteStroke,
    required this.whiteDetail,
    required this.blackFill,
    required this.blackStroke,
    required this.blackDetail,
  });

  String label(bool turkish) => turkish ? trName : enName;

  static const classic = PieceSet(
    id: 'classic',
    trName: 'Klasik',
    enName: 'Classic',
    whiteFill: Color(0xFFFBF8F1),
    whiteStroke: Color(0xFF1E2328),
    whiteDetail: Color(0xFF1E2328),
    blackFill: Color(0xFF23292F),
    blackStroke: Color(0xFF05080B),
    blackDetail: Color(0xFFE7E3DA),
  );

  static const wood = PieceSet(
    id: 'wood',
    trName: 'Ahşap',
    enName: 'Wood',
    whiteFill: Color(0xFFF0DDBC),
    whiteStroke: Color(0xFF5A3A1E),
    whiteDetail: Color(0xFF5A3A1E),
    blackFill: Color(0xFF4A2E18),
    blackStroke: Color(0xFF20120A),
    blackDetail: Color(0xFFF0DDBC),
  );

  static const cobalt = PieceSet(
    id: 'cobalt',
    trName: 'Kobalt',
    enName: 'Cobalt',
    whiteFill: Color(0xFFF2F6FA),
    whiteStroke: Color(0xFF1B3A5C),
    whiteDetail: Color(0xFF1B3A5C),
    blackFill: Color(0xFF1B3A5C),
    blackStroke: Color(0xFF0A1B2E),
    blackDetail: Color(0xFFDCE8F4),
  );

  static const all = <PieceSet>[classic, wood, cobalt];

  static PieceSet fromId(String? id) =>
      all.firstWhere((s) => s.id == id, orElse: () => classic);

  Color fillOf(Side side) => side == Side.white ? whiteFill : blackFill;
  Color strokeOf(Side side) => side == Side.white ? whiteStroke : blackStroke;
  Color detailOf(Side side) => side == Side.white ? whiteDetail : blackDetail;
}
