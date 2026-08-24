import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import 'piece_set.dart';

/// Taş çizimlerini üretir.
///
/// Takım tümüyle uygulama içinde tanımlanmıştır; dış bir görsel varlığa ya da
/// yazı tipine bağımlılık yoktur, böylece her platformda birebir aynı görünür.
/// Tüm şekiller 45x45 birimlik ortak bir ızgarada, aynı taban ve etek
/// geometrisiyle çizilir.
class PieceSvg {
  PieceSvg._();

  static final Map<String, String> _cache = {};

  static String of(Piece piece, PieceSet set) {
    final key = '${set.id}_${piece.color.name}_${piece.role.name}';
    return _cache.putIfAbsent(key, () => _build(piece, set));
  }

  static String _build(Piece piece, PieceSet set) {
    final fill = _hex(set.fillOf(piece.color));
    final stroke = _hex(set.strokeOf(piece.color));
    final detail = _hex(set.detailOf(piece.color));

    final body = switch (set.shape) {
      PieceShape.classic => switch (piece.role) {
        Role.pawn => _pawn(detail),
        Role.rook => _rook(detail),
        Role.knight => _knight(detail),
        Role.bishop => _bishop(detail),
        Role.queen => _queen(detail),
        Role.king => _king(detail),
      },
      PieceShape.playful => switch (piece.role) {
        Role.pawn => _playfulPawn(detail),
        Role.rook => _playfulRook(detail),
        Role.knight => _playfulKnight(detail),
        Role.bishop => _playfulBishop(detail),
        Role.queen => _playfulQueen(detail),
        Role.king => _playfulKing(detail),
      },
    };

    // Neşeli takımda daha kalın kontur: küçük ekranlarda ve küçük yaş
    // grubunda taşlar birbirinden daha kolay ayrılır.
    final strokeWidth = set.shape == PieceShape.playful ? 2.0 : 1.5;

    if (!set.dimensional) {
      return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 45 45">'
          '<g fill="$fill" stroke="$stroke" stroke-width="$strokeWidth" '
          'stroke-linejoin="round" stroke-linecap="round">'
          '$body'
          '</g></svg>';
    }

    // Kabartmalı çizim: sol üstten gelen ışığa göre degrade gövde, ince bir
    // tepe parlaması ve taşın altında yumuşak bir zemin gölgesi.
    final base = set.fillOf(piece.color);
    final gradientId = 'g_${set.id}_${piece.color.name}_${piece.role.name}';
    final top = _hex(_shift(base, 0.28));
    final mid = _hex(base);
    final bottom = _hex(_shift(base, -0.22));

    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 45 45">'
        '<defs>'
        '<linearGradient id="$gradientId" x1="0" y1="0" x2="1" y2="1">'
        '<stop offset="0" stop-color="$top"/>'
        '<stop offset="0.45" stop-color="$mid"/>'
        '<stop offset="1" stop-color="$bottom"/>'
        '</linearGradient>'
        '</defs>'
        '<ellipse cx="22.5" cy="41.6" rx="15.5" ry="2.6" fill="#000000" '
        'opacity="0.28"/>'
        '<g fill="url(#$gradientId)" stroke="$stroke" '
        'stroke-width="$strokeWidth" stroke-linejoin="round" '
        'stroke-linecap="round">'
        '$body'
        '</g></svg>';
  }

  /// Rengi [amount] kadar aydınlatır (pozitif) ya da koyulaştırır (negatif).
  static Color _shift(Color color, double amount) {
    int channel(double value) {
      final shifted = amount >= 0
          ? value + (255 - value) * amount
          : value * (1 + amount);
      return shifted.clamp(0, 255).round();
    }

    final argb = color.toARGB32();
    return Color.fromARGB(
      255,
      channel(((argb >> 16) & 0xFF).toDouble()),
      channel(((argb >> 8) & 0xFF).toDouble()),
      channel((argb & 0xFF).toDouble()),
    );
  }

  // ── Neşeli takım: tombul gövdeler, yuvarlak hatlar, kalın kontur ──

  static const _pBase =
      '<rect x="7.6" y="36.8" width="29.8" height="6.2" rx="3.1"/>';

  static const _pSkirt =
      '<path d="M14 28.4h17c.9 4.6 2.7 7 4.6 8.6H9.4'
      'c1.9-1.6 3.7-4 4.6-8.6z"/>';

  static const _pPedestal = '$_pSkirt$_pBase';

  static String _playfulPawn(String detail) =>
      '<circle cx="22.5" cy="13.2" r="6.4"/>'
      '<path d="M16.7 19.1c1.7 1.4 3.6 2.1 5.8 2.1s4.1-.7 5.8-2.1'
      'c2 2.2 3.2 5.2 3.2 8.5 0 .6 0 1.2-.1 1.8H13.6c-.1-.6-.1-1.2-.1-1.8 '
      '0-3.3 1.2-6.3 3.2-8.5z"/>'
      '$_pPedestal';

  static String _playfulRook(String detail) =>
      '<path d="M10.6 8h5.6v3.8h4.1V8h4.4v3.8h4.1V8h5.6v10.4l-3.2 2.6v8.4'
      'H13.8v-8.4l-3.2-2.6z"/>'
      '<path d="M15 23.6h15" stroke="$detail" stroke-width="1.6" '
      'fill="none"/>'
      '$_pPedestal';

  static String _playfulKnight(String detail) =>
      '<path d="M21.4 9.6c3.2-2.2 6.6-1.4 8.3 1.1l1-2.6 2.3 3.6'
      'c2 3.2 2.7 7.2 2.2 11.4-.3 2.4-.8 4.3-1.2 5.7H15.1'
      'c-.5-3.6.5-6.7 2.5-9.2l-4.4 2.4c-2-1.6-2.2-4-.6-6l5.4-5.2'
      'c1-1 2.1-1.7 3.4-2.2z"/>'
      '<circle cx="20.6" cy="16" r="2" fill="$detail" stroke="none"/>'
      '<circle cx="14.6" cy="20.4" r="1.1" fill="$detail" stroke="none"/>'
      '$_pPedestal';

  static String _playfulBishop(String detail) =>
      '<circle cx="22.5" cy="6.8" r="2.9"/>'
      '<path d="M22.5 9.8c4.6 3.9 7.5 8 7.5 11.9 0 4.2-3.4 7.1-7.5 7.1'
      's-7.5-2.9-7.5-7.1c0-3.9 2.9-8 7.5-11.9z"/>'
      '<circle cx="22.5" cy="18.6" r="2.3" fill="$detail" stroke="none"/>'
      '$_pPedestal';

  static String _playfulQueen(String detail) =>
      '<circle cx="10.6" cy="13" r="3.1"/>'
      '<circle cx="22.5" cy="9.2" r="3.5"/>'
      '<circle cx="34.4" cy="13" r="3.1"/>'
      '<path d="M10.6 15.4l3 13h17.8l3-13-6 5.2-5.9-7.6-5.9 7.6z"/>'
      '$_pPedestal';

  static String _playfulKing(String detail) =>
      '<path d="M20.5 3.2h4v3.6h3.6v4h-3.6v4h-4v-4h-3.6v-4h3.6z"/>'
      '<path d="M22.5 15c-6.1 0-11 4.5-11 10.2 0 1.2.2 2.3.5 3.4h21'
      'c.3-1.1.5-2.2.5-3.4 0-5.7-4.9-10.2-11-10.2z"/>'
      '<path d="M13.4 23.4h18.2" stroke="$detail" stroke-width="1.6" '
      'fill="none"/>'
      '$_pPedestal';

  // ── Ortak parçalar ──

  /// Tüm taşların oturduğu taban.
  static const _base =
      '<rect x="9.2" y="38.6" width="26.6" height="4.4" rx="2.2"/>';

  /// Tabandan gövdeye geçen etek.
  static const _skirt =
      '<path d="M12.6 30.8h19.8c1.4 4.2 2.7 6.5 3.9 8.1H8.7'
      'c1.2-1.6 2.5-3.9 3.9-8.1z"/>';

  /// Gövde ile eteği ayıran bilezik.
  static const _collar =
      '<rect x="14.3" y="26.6" width="16.4" height="4.8" rx="2.4"/>';

  static const _pedestal = '$_skirt$_collar$_base';

  // ── Taşlar ──

  static String _pawn(String detail) =>
      '<circle cx="22.5" cy="12.6" r="5.1"/>'
      '<path d="M17.7 17.6c1.4 1.1 3 1.7 4.8 1.7s3.4-.6 4.8-1.7'
      'c2.1 1.8 3.4 4.5 3.4 7.5 0 .7-.1 1.4-.2 2.1H14.5'
      'c-.1-.7-.2-1.4-.2-2.1 0-3 1.3-5.7 3.4-7.5z"/>'
      '$_pedestal';

  static String _rook(String detail) =>
      '<path d="M12 7h4.6v3.1h3.9V7h4v3.1h3.9V7H33v9.2l-3.1 2.6v8.9H15.1'
      'v-8.9L12 16.2z"/>'
      '<path d="M15.1 22.4h14.8" stroke="$detail" stroke-width="1.2" '
      'fill="none"/>'
      '$_pedestal';

  static String _knight(String detail) =>
      '<path d="M22 9.1c2.5-1.6 5-1.3 6.6.5l.8-2.4 2.2 3.2'
      'c2 3 2.8 7 2.4 11.2-.4 3.4-1 6-1.6 7.9H15.6'
      'c-.4-3.7.4-6.9 2-9.5l-4.2 2.4c-1.8-1.4-2-3.6-.6-5.4l5.4-5.4'
      'c1.1-1.1 2.4-1.8 3.8-2.5z"/>'
      '<circle cx="20.6" cy="15.4" r="1.35" fill="$detail" stroke="none"/>'
      '<path d="M27.4 11.8c1.9 2.4 2.8 5.6 2.8 9.6" stroke="$detail" '
      'stroke-width="1.2" fill="none"/>'
      '$_pedestal';

  static String _bishop(String detail) =>
      '<circle cx="22.5" cy="6.4" r="2.3"/>'
      '<path d="M22.5 8.9c4 3.7 6.7 7.8 6.7 11.4 0 3.7-3 6.4-6.7 6.4'
      's-6.7-2.7-6.7-6.4c0-3.6 2.7-7.7 6.7-11.4z"/>'
      '<path d="M20.2 15.4l4.6 4.6" stroke="$detail" stroke-width="1.4" '
      'fill="none"/>'
      '$_pedestal';

  static String _queen(String detail) =>
      '<circle cx="9.2" cy="13.2" r="2.2"/>'
      '<circle cx="16" cy="9.6" r="2.2"/>'
      '<circle cx="22.5" cy="8.1" r="2.4"/>'
      '<circle cx="29" cy="9.6" r="2.2"/>'
      '<circle cx="35.8" cy="13.2" r="2.2"/>'
      '<path d="M9.2 15L12.6 27h19.8L35.8 15l-6.5 5.9-3.8-9.7h-6l-3.8 9.7z"/>'
      '<path d="M13.6 23.4h17.8" stroke="$detail" stroke-width="1.2" '
      'fill="none"/>'
      '$_pedestal';

  static String _king(String detail) =>
      '<path d="M21.1 3.4h2.8v3.3h3.3v2.8h-3.3v3.9h-2.8V9.5h-3.3V6.7h3.3z"/>'
      '<path d="M22.5 13.4c-5.7 0-10.2 4.3-10.2 9.8 0 1.4.2 2.7.6 3.9h19.2'
      'c.4-1.2.6-2.5.6-3.9 0-5.5-4.5-9.8-10.2-9.8z"/>'
      '<path d="M13.4 21.6h18.2" stroke="$detail" stroke-width="1.2" '
      'fill="none"/>'
      '$_pedestal';

  static String _hex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}
