import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Metin okuma: öğretmen anlatımı ve hikâyeler için.
///
/// Cihazın kendi TTS motorunu kullanır; ses dosyası taşınmaz. Motorun o dil
/// için kurulu olmadığı cihazlarda konuşma sessizce atlanır, akış metinle
/// devam eder.
class TtsService {
  TtsService._();

  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  String? _language;

  bool enabled = true;

  /// Konuşma bittiğinde çağrılır (hikâye akışı için).
  VoidCallback? onComplete;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      _tts.setCompletionHandler(() => onComplete?.call());
    } catch (e) {
      debugPrint('TTS başlatılamadı: $e');
    }
  }

  Future<void> speak(String text, {required bool turkish}) async {
    if (!enabled || text.isEmpty) return;
    await _ensureInitialized();
    try {
      final language = turkish ? 'tr-TR' : 'en-US';
      if (_language != language) {
        await _tts.setLanguage(language);
        _language = language;
      }
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS konuşamadı: $e');
    }
  }

  Future<void> stop() async {
    if (!_initialized) return;
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
