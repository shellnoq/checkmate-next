import 'package:package_info_plus/package_info_plus.dart';

/// Uygulamanın kendi sürüm bilgisi.
///
/// Değer paketten okunur, koda gömülmez; böylece derlemede üretilen sürüm ile
/// ekranda görünen her zaman aynıdır.
class AppVersion {
  AppVersion._();

  static String _version = '';
  static String _build = '';

  /// `1.1.0 (19)` biçiminde. Henüz okunmadıysa boş dizedir.
  static String get label => _version.isEmpty ? '' : '$_version ($_build)';

  static String get version => _version;
  static String get build => _build;

  static Future<void> load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _version = info.version;
      _build = info.buildNumber;
    } catch (_) {
      // Sürüm bilgisi okunamazsa arayüz onsuz çalışmaya devam eder.
    }
  }
}
