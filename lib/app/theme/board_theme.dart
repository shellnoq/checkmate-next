import 'package:flutter/material.dart';

/// Tahta renk şeması.
class BoardTheme {
  final String id;
  final String trName;
  final String enName;
  final Color light;
  final Color dark;

  /// Son hamlenin vurgulandığı renk (karenin üzerine bindirilir).
  final Color lastMove;

  /// Seçili karenin rengi.
  final Color selection;

  /// Şah çeken şahın karesi.
  final Color check;

  /// Koordinat yazılarının rengi açık kareler üzerinde.
  final Color coordinateOnLight;
  final Color coordinateOnDark;

  const BoardTheme({
    required this.id,
    required this.trName,
    required this.enName,
    required this.light,
    required this.dark,
    required this.lastMove,
    required this.selection,
    required this.check,
    required this.coordinateOnLight,
    required this.coordinateOnDark,
  });

  String label(bool turkish) => turkish ? trName : enName;

  static const walnut = BoardTheme(
    id: 'walnut',
    trName: 'Ceviz',
    enName: 'Walnut',
    light: Color(0xFFE8D3B0),
    dark: Color(0xFF9C6B42),
    lastMove: Color(0x66F2C14E),
    selection: Color(0x8834D399),
    check: Color(0x99E11D48),
    coordinateOnLight: Color(0xFF8A5C36),
    coordinateOnDark: Color(0xFFE8D3B0),
  );

  static const tournament = BoardTheme(
    id: 'tournament',
    trName: 'Turnuva',
    enName: 'Tournament',
    light: Color(0xFFEEEED2),
    dark: Color(0xFF769656),
    lastMove: Color(0x88F7EC74),
    selection: Color(0x88BACA44),
    check: Color(0x99D64545),
    coordinateOnLight: Color(0xFF769656),
    coordinateOnDark: Color(0xFFEEEED2),
  );

  static const slate = BoardTheme(
    id: 'slate',
    trName: 'Arduvaz',
    enName: 'Slate',
    light: Color(0xFFD6DCE4),
    dark: Color(0xFF6C7A89),
    lastMove: Color(0x6699C1FF),
    selection: Color(0x8852B788),
    check: Color(0x99E5484D),
    coordinateOnLight: Color(0xFF56606B),
    coordinateOnDark: Color(0xFFD6DCE4),
  );

  static const midnight = BoardTheme(
    id: 'midnight',
    trName: 'Gece Mavisi',
    enName: 'Midnight',
    light: Color(0xFFB9C4D4),
    dark: Color(0xFF3D5068),
    lastMove: Color(0x669BB4FF),
    selection: Color(0x883FB984),
    check: Color(0x99FF5A6E),
    coordinateOnLight: Color(0xFF3D5068),
    coordinateOnDark: Color(0xFFB9C4D4),
  );

  static const marble = BoardTheme(
    id: 'marble',
    trName: 'Mermer',
    enName: 'Marble',
    light: Color(0xFFF2F0EB),
    dark: Color(0xFFA9A196),
    lastMove: Color(0x66FFD166),
    selection: Color(0x8873C7A2),
    check: Color(0x99E2555F),
    coordinateOnLight: Color(0xFF8A8378),
    coordinateOnDark: Color(0xFFF2F0EB),
  );

  /// Uzay paketi: Ay yüzeyi grileri.
  static const lunar = BoardTheme(
    id: 'lunar',
    trName: 'Ay Yüzeyi',
    enName: 'Lunar',
    light: Color(0xFFC9CDD4),
    dark: Color(0xFF565E6C),
    lastMove: Color(0x667FA8E0),
    selection: Color(0x8852B788),
    check: Color(0x99E5484D),
    coordinateOnLight: Color(0xFF565E6C),
    coordinateOnDark: Color(0xFFC9CDD4),
  );

  /// Orman paketi: yosun ve toprak.
  static const jungle = BoardTheme(
    id: 'jungle',
    trName: 'Orman',
    enName: 'Jungle',
    light: Color(0xFFD9E4C0),
    dark: Color(0xFF5F7F4A),
    lastMove: Color(0x88E7D96B),
    selection: Color(0x8842A05C),
    check: Color(0x99D64545),
    coordinateOnLight: Color(0xFF5F7F4A),
    coordinateOnDark: Color(0xFFD9E4C0),
  );

  /// Antik Mısır paketi: kum ve altın.
  static const desert = BoardTheme(
    id: 'desert',
    trName: 'Çöl',
    enName: 'Desert',
    light: Color(0xFFEFDCA8),
    dark: Color(0xFFB98A44),
    lastMove: Color(0x77E8B33C),
    selection: Color(0x8850A070),
    check: Color(0x99D14B40),
    coordinateOnLight: Color(0xFF8F6A32),
    coordinateOnDark: Color(0xFFF3E5BE),
  );

  static const all = <BoardTheme>[
    walnut,
    tournament,
    slate,
    midnight,
    marble,
    lunar,
    jungle,
    desert,
  ];

  static BoardTheme fromId(String? id) =>
      all.firstWhere((t) => t.id == id, orElse: () => walnut);
}
