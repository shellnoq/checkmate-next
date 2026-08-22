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

    final body = switch (piece.role) {
      Role.pawn => _pawn(detail),
      Role.rook => _rook(detail),
      Role.knight => _knight(detail),
      Role.bishop => _bishop(detail),
      Role.queen => _queen(detail),
      Role.king => _king(detail),
    };

    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 45 45">'
        '<g fill="$fill" stroke="$stroke" stroke-width="1.5" '
        'stroke-linejoin="round" stroke-linecap="round">'
        '$body'
        '</g></svg>';
  }

  // ── Ortak parçalar ──

  /// Tüm taşların oturduğu taban.
  static const _base =
      '<rect x="9.2" y="38.6" width="26.6" height="4.4" rx="2.2"/>';

  /// Tabandan gövdeye geçen etek.
  static const _skirt = '<path d="M12.6 30.8h19.8c1.4 4.2 2.7 6.5 3.9 8.1H8.7'
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
