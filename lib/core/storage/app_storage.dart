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

  // ── Oynama süresi ──
  //
  // Ebeveyn bölümü için iki eksende tutulur: zorluk kademesi başına toplam ve
  // gün başına toplam. Saniye cinsinden saklanır; dakikaya yuvarlamak kısa
  // oturumları görünmez kılardı.

  /// Bir oyunda geçen süreyi kademe ve gün toplamlarına ekler.
  static Future<void> addPlaytime(
    String difficultyId,
    Duration played, {
    DateTime? now,
  }) async {
    final seconds = played.inSeconds;
    if (seconds <= 0) return;
    await bumpStat('time_total', seconds);
    await bumpStat('time_level_$difficultyId', seconds);
    await bumpStat('time_day_${dayKey(now ?? DateTime.now())}', seconds);
  }

  /// Toplam oynama süresi.
  static Duration totalPlaytime() => Duration(seconds: statOf('time_total'));

  /// Bir zorluk kademesinde geçen süre.
  static Duration playtimeOfLevel(String difficultyId) =>
      Duration(seconds: statOf('time_level_$difficultyId'));

  /// Belirli bir günde geçen süre.
  static Duration playtimeOfDay(DateTime day) =>
      Duration(seconds: statOf('time_day_${dayKey(day)}'));

  // ── Ebeveyn kilidi ──
  //
  // Bu bir güvenlik sınırı değil, çocuğun ayarları kazara değiştirmesini
  // önleyen bir kapıdır; bu yüzden PIN düz metin saklanır. Gerçek bir güvenlik
  // gereksinimi doğarsa cihazın kendi kimlik doğrulaması kullanılmalıdır.

  static String? parentPin() {
    final value = _settings.get('parentPin');
    return value is String && value.isNotEmpty ? value : null;
  }

  static Future<void> setParentPin(String pin) =>
      _settings.put('parentPin', pin);

  static Future<void> clearParentPin() => _settings.delete('parentPin');

  /// `2026-08-23` biçiminde gün anahtarı.
  static String dayKey(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  /// İstatistik kutusunun değişimlerini dinlemek için. Ana ekran bunu kullanır;
  /// böylece oyun bitip istatistik güncellendiğinde panel kendiliğinden
  /// tazelenir.
  static ValueListenable<Box> statsListenable() => _stats.listenable();
}
