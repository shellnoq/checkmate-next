import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Uygulamanın tüm kalıcı verisi.
///
/// Hive kutuları düz anahtar/değer olarak kullanılır; tip üreticisine
/// (build_runner) ihtiyaç duyulmaz, böylece derleme zinciri sade kalır.
class AppStorage {
  static const _settingsBox = 'settings';
  static const _archiveBox = 'archive';
  static const _statsBox = 'stats';

  static late Box _settings;
  static late Box _archive;
  static late Box _stats;

  static Future<void> init() async {
    await Hive.initFlutter();
    _settings = await Hive.openBox(_settingsBox);
    _archive = await Hive.openBox(_archiveBox);
    _stats = await Hive.openBox(_statsBox);
  }

  // ── Ayarlar ──

  static T get<T>(String key, T fallback) {
    final value = _settings.get(key);
    return value is T ? value : fallback;
  }

  static Future<void> set(String key, Object? value) =>
      _settings.put(key, value);

  // ── Oyun arşivi ──

  /// Bitmiş bir oyunu arşive ekler. Anahtar zaman damgasıdır.
  static Future<void> archiveGame(Map<String, Object?> game) async {
    final key = DateTime.now().microsecondsSinceEpoch.toString();
    await _archive.put(key, jsonEncode(game));
  }

  /// Arşivi en yeniden eskiye doğru döndürür.
  static List<Map<String, Object?>> archivedGames() {
    final keys = _archive.keys.map((k) => k.toString()).toList()
      ..sort((a, b) => b.compareTo(a));
    return [
      for (final key in keys)
        if (_archive.get(key) is String)
          {
            ...jsonDecode(_archive.get(key) as String) as Map<String, Object?>,
            '_key': key,
          },
    ];
  }

  static Future<void> deleteArchivedGame(String key) => _archive.delete(key);

  static Future<void> clearArchive() => _archive.clear();

  // ── İstatistik ──

  static int statOf(String key) {
    final value = _stats.get(key);
    return value is int ? value : 0;
  }

  static Future<void> bumpStat(String key, [int by = 1]) =>
      _stats.put(key, statOf(key) + by);

  static Future<void> setStat(String key, int value) => _stats.put(key, value);

  static Future<void> resetStats() => _stats.clear();

  /// İstatistik kutusunun değişimlerini dinlemek için. Ana ekran bunu kullanır;
  /// böylece oyun bitip istatistik güncellendiğinde panel kendiliğinden
  /// tazelenir.
  static ValueListenable<Box> statsListenable() => _stats.listenable();
}
