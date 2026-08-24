import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

/// Taşların çizim ailesi.
///
/// Renk değil biçim farkıdır: [classic] Staunton silüetini izler, [playful]
/// daha tombul ve yuvarlak hatlıdır. Küçük yaş grubunda ikincisi kullanılır.
enum PieceShape { classic, playful }

/// Taş takımının renk şeması ve biçimi.
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
  final PieceShape shape;

  /// Doğruysa taşlar degrade dolgu ve zemin gölgesiyle, kabartmalı çizilir.
  final bool dimensional;

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
    this.shape = PieceShape.classic,
    this.dimensional = false,
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

  /// Küçük yaş grubu için: tombul biçimler, yüksek doygunluklu renkler.
  static const playful = PieceSet(
    id: 'playful',
    trName: 'Neşeli',
    enName: 'Playful',
    shape: PieceShape.playful,
    whiteFill: Color(0xFFFFF3D6),
    whiteStroke: Color(0xFFB4741E),
    whiteDetail: Color(0xFFB4741E),
    blackFill: Color(0xFF3E5C9A),
    blackStroke: Color(0xFF1F3260),
    blackDetail: Color(0xFFFFF3D6),
  );

  /// Derinlik yanılsaması: degrade gövde, parlama ve zemin gölgesi.
  static const depth = PieceSet(
    id: 'depth',
    trName: 'Derinlikli',
    enName: '3D Look',
    dimensional: true,
    whiteFill: Color(0xFFF4F1E8),
    whiteStroke: Color(0xFF2A2F35),
    whiteDetail: Color(0xFF2A2F35),
    blackFill: Color(0xFF31383F),
    blackStroke: Color(0xFF0B0F13),
    blackDetail: Color(0xFFE9E5DA),
  );

  static const all = <PieceSet>[classic, wood, cobalt, playful, depth];

  static PieceSet fromId(String? id) =>
      all.firstWhere((s) => s.id == id, orElse: () => classic);

  Color fillOf(Side side) => side == Side.white ? whiteFill : blackFill;
  Color strokeOf(Side side) => side == Side.white ? whiteStroke : blackStroke;
  Color detailOf(Side side) => side == Side.white ? whiteDetail : blackDetail;
}
