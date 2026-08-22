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
  bool _ready = false;

  bool enabled = true;
  bool hapticsEnabled = true;

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
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
    _ready = false;
  }
}
