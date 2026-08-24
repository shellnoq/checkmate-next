import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

/// Oyun sesleri.
enum Sfx { move, capture, castle, check, gameEnd, victory, lowTime }

enum HapticStrength { light, medium, selection }

/// Kısa efektleri düşük gecikmeyle çalar.
///
/// Her efekt için önceden yüklenmiş bir oynatıcı tutulur; çalma anında yalnızca
/// başa sarılıp başlatılır, böylece hamle sesi gecikmez.
class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  static const _assets = {
    Sfx.move: 'assets/sfx/move.wav',
    Sfx.capture: 'assets/sfx/capture.wav',
    Sfx.castle: 'assets/sfx/castle.wav',
    Sfx.check: 'assets/sfx/check.wav',
    Sfx.gameEnd: 'assets/sfx/game_end.wav',
    Sfx.victory: 'assets/sfx/victory.wav',
    Sfx.lowTime: 'assets/sfx/low_time.wav',
  };

  final Map<Sfx, AudioPlayer> _players = {};
  AudioPlayer? _music;
  String? _musicAsset;
  bool _ready = false;

  bool enabled = true;
  bool hapticsEnabled = true;

  /// Fon müziği düzeyi (0-1). Sıfırsa müzik hiç başlamaz.
  double musicVolume = 0;

  Future<void> preload() async {
    if (_ready) return;
    _ready = true;
    for (final entry in _assets.entries) {
      try {
        final player = AudioPlayer();
        await player.setAsset(entry.value);
        _players[entry.key] = player;
      } catch (e) {
        debugPrint('Ses yüklenemedi (${entry.value}): $e');
      }
    }
  }

  Future<void> play(Sfx sfx) async {
    if (!enabled) return;
    final player = _players[sfx];
    if (player == null) return;
    try {
      await player.seek(Duration.zero);
      await player.play();
    } catch (e) {
      debugPrint('Ses çalınamadı: $e');
    }
  }

  /// Verilen parçayı döngüde çalar. Aynı parça zaten çalıyorsa yalnızca ses
  /// düzeyini tazeler; `asset` boşsa ya da düzey sıfırsa müziği durdurur.
  Future<void> playMusic(String? asset) async {
    if (asset == null || musicVolume <= 0) {
      await stopMusic();
      return;
    }
    try {
      if (_musicAsset == asset && _music != null) {
        await _music!.setVolume(musicVolume);
        return;
      }
      await stopMusic();
      final player = AudioPlayer();
      await player.setAsset(asset);
      await player.setLoopMode(LoopMode.one);
      await player.setVolume(musicVolume);
      _music = player;
      _musicAsset = asset;
      unawaited(player.play());
    } catch (e) {
      debugPrint('Müzik çalınamadı ($asset): $e');
    }
  }

  Future<void> stopMusic() async {
    final player = _music;
    _music = null;
    _musicAsset = null;
    try {
      await player?.dispose();
    } catch (_) {}
  }

  void haptic([HapticStrength strength = HapticStrength.light]) {
    if (!hapticsEnabled) return;
    switch (strength) {
      case HapticStrength.light:
        HapticFeedback.lightImpact();
      case HapticStrength.medium:
        HapticFeedback.mediumImpact();
      case HapticStrength.selection:
        HapticFeedback.selectionClick();
    }
  }

  Future<void> dispose() async {
    await stopMusic();
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
    _ready = false;
  }
}
