import 'dart:math';

import 'engine_models.dart';

/// UCI protokolünün motordan gelen satırlarını çözümler.
class UciParser {
  UciParser._();

  /// `info depth 12 multipv 1 score cp 34 ... pv e2e4 e7e5` satırını çözer.
  ///
  /// Değerlendirme ya da varyant taşımayan satırlar (`info string ...`,
  /// yalnızca `currmove` bildiren satırlar) için `null` döner.
  static EngineLine? parseInfo(String line) {
    if (!line.startsWith('info ')) return null;
    final tokens = line.split(RegExp(r'\s+'));
    if (tokens.contains('string')) return null;

    int depth = 0;
    int multiPv = 1;
    int? cp;
    int? mate;
    List<String> pv = const [];

    for (int i = 1; i < tokens.length; i++) {
      switch (tokens[i]) {
        case 'depth':
          depth = int.tryParse(_at(tokens, i + 1) ?? '') ?? depth;
        case 'multipv':
          multiPv = int.tryParse(_at(tokens, i + 1) ?? '') ?? multiPv;
        case 'score':
          final kind = _at(tokens, i + 1);
          final value = int.tryParse(_at(tokens, i + 2) ?? '');
          if (kind == 'cp') {
            cp = value;
          } else if (kind == 'mate') {
            mate = value;
          }
        case 'pv':
          pv = tokens.sublist(min(i + 1, tokens.length));
          i = tokens.length;
      }
    }

    if (pv.isEmpty && cp == null && mate == null) return null;
    return EngineLine(
      multiPvIndex: multiPv,
      depth: depth,
      centipawns: cp,
      mateIn: mate,
      pv: pv,
    );
  }

  /// `bestmove e2e4 ponder e7e5` satırından hamleleri çıkarır.
  ///
  /// Oynanacak hamle yoksa (`bestmove (none)`) ilk değer `null` olur.
  static (String? best, String? ponder) parseBestMove(String line) {
    final tokens = line.split(RegExp(r'\s+'));
    String? best = _at(tokens, 1);
    if (best == '(none)' || best == null || best.isEmpty) best = null;
    String? ponder;
    final ponderIndex = tokens.indexOf('ponder');
    if (ponderIndex != -1) ponder = _at(tokens, ponderIndex + 1);
    return (best, ponder);
  }

  static String? _at(List<String> list, int index) =>
      index >= 0 && index < list.length ? list[index] : null;
}
