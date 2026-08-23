import '../../domain/model/difficulty.dart';
import '../../features/board/piece_set.dart';

/// Oyuncunun yaş grubu.
///
/// Uygulamanın görsel yoğunluğunu tek noktadan ayarlar: küçük yaşta iri ve
/// renkli taşlar, coşkulu kutlama; yetişkinde sade görünüm. Zorluk ya da
/// kuralları değiştirmez — satranç her yaşta aynı satrançtır.
enum AgeGroup {
  child(
    id: 'child',
    trName: 'Çocuk',
    enName: 'Child',
    trRange: '4-8 yaş',
    enRange: 'ages 4-8',
  ),
  youth(
    id: 'youth',
    trName: 'Genç',
    enName: 'Youth',
    trRange: '9-13 yaş',
    enRange: 'ages 9-13',
  ),
  adult(
    id: 'adult',
    trName: 'Yetişkin',
    enName: 'Adult',
    trRange: '14 yaş ve üzeri',
    enRange: 'ages 14+',
  );

  const AgeGroup({
    required this.id,
    required this.trName,
    required this.enName,
    required this.trRange,
    required this.enRange,
  });

  final String id;
  final String trName;
  final String enName;
  final String trRange;
  final String enRange;

  static AgeGroup fromId(String? id) =>
      AgeGroup.values.firstWhere((g) => g.id == id, orElse: () => adult);

  String label(bool turkish) => turkish ? trName : enName;
  String range(bool turkish) => turkish ? trRange : enRange;

  /// Yaş grubu seçildiğinde önerilen taş takımı.
  PieceSet get suggestedPieceSet =>
      this == AgeGroup.child ? PieceSet.playful : PieceSet.classic;

  /// İlk oyunda önerilen zorluk kademesi.
  DifficultyLevel get suggestedDifficulty => switch (this) {
    AgeGroup.child => DifficultyLevel.beginner,
    AgeGroup.youth => DifficultyLevel.amateur,
    AgeGroup.adult => DifficultyLevel.club,
  };

  /// Galibiyet kutlamasındaki parçacık sayısı. Yetişkinde sıfırdır: kutlama
  /// yalnızca simgenin belirmesiyle sınırlı kalır.
  int get celebrationParticles => switch (this) {
    AgeGroup.child => 34,
    AgeGroup.youth => 20,
    AgeGroup.adult => 0,
  };
}
