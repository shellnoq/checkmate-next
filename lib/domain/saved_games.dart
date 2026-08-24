import 'dart:convert';

import '../core/storage/app_storage.dart';
import 'model/difficulty.dart';

/// Yarıda bırakılıp kaydedilmiş, motora karşı bir oyun.
class SavedGame {
  const SavedGame({
    required this.difficultyId,
    required this.localSide,
    required this.timeControlId,
    required this.uci,
    required this.savedAt,
    this.whiteRemainingMs,
    this.blackRemainingMs,
  });

  final String difficultyId;

  /// 'white' ya da 'black'.
  final String localSide;
  final String timeControlId;
  final List<String> uci;
  final DateTime savedAt;
  final int? whiteRemainingMs;
  final int? blackRemainingMs;

  int get moveCount => uci.length;

  Map<String, Object?> toJson() => {
    'difficultyId': difficultyId,
    'localSide': localSide,
    'timeControlId': timeControlId,
    'uci': uci,
    'savedAt': savedAt.toIso8601String(),
    'whiteRemainingMs': whiteRemainingMs,
    'blackRemainingMs': blackRemainingMs,
  };

  static SavedGame fromJson(Map<String, Object?> json) => SavedGame(
    difficultyId: json['difficultyId']! as String,
    localSide: json['localSide']! as String,
    timeControlId: json['timeControlId']! as String,
    uci: (json['uci']! as List).cast<String>(),
    savedAt: DateTime.parse(json['savedAt']! as String),
    whiteRemainingMs: json['whiteRemainingMs'] as int?,
    blackRemainingMs: json['blackRemainingMs'] as int?,
  );
}

/// Kayıt yuvaları.
///
/// Kural: her zorluk kademesinde en çok bir kayıt, toplamda en çok üç.
/// Aynı kademeye yeni kayıt eskisinin üzerine yazar; dördüncü bir kademe
/// kaydedilmek istenirse en eski kayıt silinir.
class SavedGameStore {
  SavedGameStore._();

  static const maxSlots = 3;

  static String _key(String difficultyId) => 'resume_$difficultyId';

  static SavedGame? forLevel(String difficultyId) {
    final raw = AppStorage.get<String>(_key(difficultyId), '');
    if (raw.isEmpty) return null;
    try {
      return SavedGame.fromJson(
        (jsonDecode(raw) as Map).cast<String, Object?>(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Kayıtları en yeniden eskiye sıralı döndürür.
  static List<SavedGame> list() {
    final games = <SavedGame>[
      for (final level in DifficultyLevel.values) ?forLevel(level.id),
    ]..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return games;
  }

  static Future<void> save(SavedGame game) async {
    final existing = list();
    final hasSlot = existing.any((g) => g.difficultyId == game.difficultyId);
    if (!hasSlot && existing.length >= maxSlots) {
      // En eski kayıt yuvası boşaltılır.
      await delete(existing.last.difficultyId);
    }
    await AppStorage.set(_key(game.difficultyId), jsonEncode(game.toJson()));
  }

  static Future<void> delete(String difficultyId) =>
      AppStorage.set(_key(difficultyId), '');
}
