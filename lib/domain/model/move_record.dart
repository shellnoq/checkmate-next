import 'package:dartchess/dartchess.dart';

/// Oynanmış tek bir yarım hamlenin kaydı.
class MoveRecord {
  /// UCI gösterimi (`e2e4`, `e7e8q`). Kablo üzerinde bu biçim kullanılır.
  final String uci;

  /// SAN gösterimi (`Nf3`, `O-O`, `exd8=Q+`). Arayüzde ve PGN'de kullanılır.
  final String san;

  /// Hamleden sonraki pozisyonun FEN'i.
  final String fenAfter;

  /// Hamleyi yapan taraf.
  final Side side;

  /// Hamleden sonra oyuncunun kalan süresi. Süresiz oyunda `null`.
  final Duration? clockAfter;

  /// Hamle için harcanan süre.
  final Duration? timeSpent;

  /// Motorun bu pozisyon için verdiği santipiyon değerlendirmesi (beyaz gözünden).
  final int? evaluationCp;

  const MoveRecord({
    required this.uci,
    required this.san,
    required this.fenAfter,
    required this.side,
    this.clockAfter,
    this.timeSpent,
    this.evaluationCp,
  });

  MoveRecord copyWith({int? evaluationCp}) => MoveRecord(
        uci: uci,
        san: san,
        fenAfter: fenAfter,
        side: side,
        clockAfter: clockAfter,
        timeSpent: timeSpent,
        evaluationCp: evaluationCp ?? this.evaluationCp,
      );

  Map<String, Object?> toJson() => {
        'uci': uci,
        'san': san,
        'fenAfter': fenAfter,
        'side': side.name,
        'clockAfterMs': clockAfter?.inMilliseconds,
        'timeSpentMs': timeSpent?.inMilliseconds,
        'evaluationCp': evaluationCp,
      };

  static MoveRecord fromJson(Map<String, Object?> json) => MoveRecord(
        uci: json['uci']! as String,
        san: json['san']! as String,
        fenAfter: json['fenAfter']! as String,
        side: json['side'] == 'black' ? Side.black : Side.white,
        clockAfter: json['clockAfterMs'] == null
            ? null
            : Duration(milliseconds: json['clockAfterMs']! as int),
        timeSpent: json['timeSpentMs'] == null
            ? null
            : Duration(milliseconds: json['timeSpentMs']! as int),
        evaluationCp: json['evaluationCp'] as int?,
      );
}
