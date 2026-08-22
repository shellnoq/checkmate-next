import '../../engine/engine_models.dart';

/// Oynanabilir zorluk kademeleri.
///
/// Her kademe Stockfish'in `Skill Level` / `UCI_Elo` seçenekleri ve arama
/// sınırlarıyla eşlenir. Alt kademelerde motor kasıtlı olarak MultiPV
/// alternatiflerinden zayıf hamle seçer; üst kademelerde tam güç çalışır.
enum DifficultyLevel {
  beginner(
    id: 'beginner',
    trName: 'Acemi',
    enName: 'Beginner',
    approximateElo: 600,
  ),
  novice(
    id: 'novice',
    trName: 'Başlangıç',
    enName: 'Novice',
    approximateElo: 900,
  ),
  amateur(
    id: 'amateur',
    trName: 'Amatör',
    enName: 'Amateur',
    approximateElo: 1200,
  ),
  club(
    id: 'club',
    trName: 'Kulüp Oyuncusu',
    enName: 'Club Player',
    approximateElo: 1500,
  ),
  candidate(
    id: 'candidate',
    trName: 'Usta Adayı',
    enName: 'Candidate Master',
    approximateElo: 1800,
  ),
  expert(id: 'expert', trName: 'Uzman', enName: 'Expert', approximateElo: 2100),
  master(
    id: 'master',
    trName: 'Ulusal Usta',
    enName: 'National Master',
    approximateElo: 2400,
  ),
  grandmaster(
    id: 'grandmaster',
    trName: 'Büyükusta',
    enName: 'Grandmaster',
    approximateElo: 2900,
  );

  const DifficultyLevel({
    required this.id,
    required this.trName,
    required this.enName,
    required this.approximateElo,
  });

  final String id;
  final String trName;
  final String enName;

  /// Kademenin hedeflediği yaklaşık Elo.
  final int approximateElo;

  static DifficultyLevel fromId(String? id) => DifficultyLevel.values
      .firstWhere((d) => d.id == id, orElse: () => DifficultyLevel.club);

  String label(bool turkish) => turkish ? trName : enName;

  /// 1-8 arası görsel kademe göstergesi.
  int get tier => index + 1;

  /// Stockfish'e uygulanacak seçenekler.
  EngineOptions get engineOptions => switch (this) {
    // Stockfish'in UCI_Elo alt sınırı 1320'dir; bunun altındaki kademeler
    // Skill Level 0 + sığ arama + kasıtlı hata payı ile üretilir.
    DifficultyLevel.beginner => const EngineOptions(
      skillLevel: 0,
      blunderChance: 0.55,
      hashMb: 8,
    ),
    DifficultyLevel.novice => const EngineOptions(
      skillLevel: 1,
      blunderChance: 0.35,
      hashMb: 8,
    ),
    DifficultyLevel.amateur => const EngineOptions(
      skillLevel: 4,
      blunderChance: 0.15,
      hashMb: 16,
    ),
    DifficultyLevel.club => const EngineOptions(limitElo: 1500, hashMb: 16),
    DifficultyLevel.candidate => const EngineOptions(
      limitElo: 1800,
      hashMb: 32,
    ),
    DifficultyLevel.expert => const EngineOptions(limitElo: 2100, hashMb: 32),
    DifficultyLevel.master => const EngineOptions(limitElo: 2400, hashMb: 64),
    DifficultyLevel.grandmaster => const EngineOptions(threads: 2, hashMb: 64),
  };

  /// Kademenin arama sınırları.
  SearchLimits get searchLimits => switch (this) {
    DifficultyLevel.beginner => const SearchLimits(
      depth: 1,
      moveTimeMs: 300,
      multiPv: 5,
    ),
    DifficultyLevel.novice => const SearchLimits(
      depth: 2,
      moveTimeMs: 300,
      multiPv: 4,
    ),
    DifficultyLevel.amateur => const SearchLimits(
      depth: 5,
      moveTimeMs: 400,
      multiPv: 3,
    ),
    DifficultyLevel.club => const SearchLimits(moveTimeMs: 500),
    DifficultyLevel.candidate => const SearchLimits(moveTimeMs: 700),
    DifficultyLevel.expert => const SearchLimits(moveTimeMs: 1000),
    DifficultyLevel.master => const SearchLimits(moveTimeMs: 1500),
    DifficultyLevel.grandmaster => const SearchLimits(moveTimeMs: 2500),
  };

  /// Kademenin kısa tanıtımı.
  String description(bool turkish) => switch (this) {
    DifficultyLevel.beginner =>
      turkish
          ? 'Taşları yeni öğrenenler için. Sık hata yapar, taş bırakır.'
          : 'For absolute beginners. Blunders often, hangs pieces.',
    DifficultyLevel.novice =>
      turkish
          ? 'Basit tuzakları görür ama planı yoktur.'
          : 'Spots simple tactics but has no plan.',
    DifficultyLevel.amateur =>
      turkish
          ? 'Kısa taktikleri hesaplar, açılışta makul oynar.'
          : 'Calculates short tactics, plays reasonable openings.',
    DifficultyLevel.club =>
      turkish
          ? 'Kulüp seviyesinde tutarlı oyun. Bedava taş vermez.'
          : 'Consistent club-level play. Will not hand you material.',
    DifficultyLevel.candidate =>
      turkish
          ? 'Konum değerlendirmesi güçlü, taktik hatası nadirdir.'
          : 'Strong positional judgement, rare tactical slips.',
    DifficultyLevel.expert =>
      turkish
          ? 'Uzun varyantları hesaplar, oyunsonu tekniği iyidir.'
          : 'Deep calculation and solid endgame technique.',
    DifficultyLevel.master =>
      turkish
          ? 'Usta seviyesi. Küçük konum avantajlarını kazanca çevirir.'
          : 'Master level. Converts small edges into wins.',
    DifficultyLevel.grandmaster =>
      turkish
          ? 'Motor tam güçte. İnsan oyuncular için pratikte yenilmez.'
          : 'Engine at full strength. Practically unbeatable.',
  };
}
