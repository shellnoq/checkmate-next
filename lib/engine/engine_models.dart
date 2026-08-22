import 'package:flutter/foundation.dart';

/// Motorun yaşam döngüsü durumu.
enum EngineStatus { idle, starting, ready, searching, failed, disposed }

/// Motora verilecek arama sınırları.
@immutable
class SearchLimits {
  /// Sabit derinlik. `null` ise derinlik sınırı yoktur.
  final int? depth;

  /// Milisaniye cinsinden düşünme süresi. `null` ise süre sınırı yoktur.
  final int? moveTimeMs;

  /// Aynı anda kaç varyant üretileceği. Zayıf seviyelerde rastgele seçim
  /// yapabilmek için 1'den büyük olur.
  final int multiPv;

  const SearchLimits({this.depth, this.moveTimeMs, this.multiPv = 1})
    : assert(
        depth != null || moveTimeMs != null,
        'En az bir arama sınırı verilmelidir',
      );

  Map<String, Object?> toJson() => {
    'depth': depth,
    'moveTimeMs': moveTimeMs,
    'multiPv': multiPv,
  };
}

/// Motora uygulanacak UCI seçenekleri.
@immutable
class EngineOptions {
  /// `Skill Level` (0-20). `null` ise dokunulmaz.
  final int? skillLevel;

  /// `UCI_LimitStrength` + `UCI_Elo`. `null` ise tam güç.
  final int? limitElo;

  /// `Threads`.
  final int threads;

  /// `Hash` (MB).
  final int hashMb;

  /// Stockfish'in kendi zayıflatmasının yetmediği çok düşük seviyelerde,
  /// en iyi hamle yerine daha kötü bir varyantın seçilme olasılığı (0.0-1.0).
  final double blunderChance;

  const EngineOptions({
    this.skillLevel,
    this.limitElo,
    this.threads = 1,
    this.hashMb = 16,
    this.blunderChance = 0.0,
  });

  List<String> toUciCommands() {
    final cmds = <String>[
      'setoption name Threads value $threads',
      'setoption name Hash value $hashMb',
    ];
    if (skillLevel != null) {
      cmds.add('setoption name Skill Level value $skillLevel');
    } else {
      cmds.add('setoption name Skill Level value 20');
    }
    if (limitElo != null) {
      cmds.add('setoption name UCI_LimitStrength value true');
      cmds.add('setoption name UCI_Elo value $limitElo');
    } else {
      cmds.add('setoption name UCI_LimitStrength value false');
    }
    return cmds;
  }
}

/// Motorun tek bir varyant için ürettiği değerlendirme.
@immutable
class EngineLine {
  /// 1 tabanlı varyant sırası (MultiPV).
  final int multiPvIndex;

  /// Ulaşılan derinlik.
  final int depth;

  /// Santipiyon cinsinden skor. Mat varsa `null`.
  final int? centipawns;

  /// Kaç hamlede mat. Pozitif değer sıra sahibinin lehinedir.
  final int? mateIn;

  /// Baş varyant, UCI hamleleri hâlinde.
  final List<String> pv;

  const EngineLine({
    required this.multiPvIndex,
    required this.depth,
    this.centipawns,
    this.mateIn,
    this.pv = const [],
  });

  String? get bestMoveUci => pv.isEmpty ? null : pv.first;

  bool get isMate => mateIn != null;

  /// Değerlendirmeyi her zaman beyazın gözünden piyon cinsine çevirir.
  double? pawnsFromWhite({required bool whiteToMove}) {
    if (centipawns == null) return null;
    final v = centipawns! / 100.0;
    return whiteToMove ? v : -v;
  }

  @override
  String toString() =>
      'EngineLine(pv=$multiPvIndex d=$depth cp=$centipawns mate=$mateIn ${pv.take(3).join(' ')})';
}

/// Bir arama sonucunun tamamı.
@immutable
class SearchResult {
  /// Motorun oynamayı seçtiği hamle (UCI). Pozisyon bittiyse `null`.
  final String? bestMoveUci;

  /// Motorun beklediği karşı hamle.
  final String? ponderUci;

  /// MultiPV sırasına göre değerlendirmeler.
  final List<EngineLine> lines;

  /// Arama süresi.
  final Duration elapsed;

  const SearchResult({
    required this.bestMoveUci,
    this.ponderUci,
    this.lines = const [],
    this.elapsed = Duration.zero,
  });

  EngineLine? get principalVariation => lines.isEmpty
      ? null
      : lines.firstWhere((l) => l.multiPvIndex == 1, orElse: () => lines.first);
}
