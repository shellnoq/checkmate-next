import 'package:flutter_test/flutter_test.dart';
import 'package:checkmate_next/features/parent/parent_area_screen.dart';

void main() {
  group('süre biçimlendirme', () {
    test('bir dakikanın altı saniye olarak gösterilir', () {
      expect(formatDuration(const Duration(seconds: 42), true), '42 sn');
      expect(formatDuration(const Duration(seconds: 42), false), '42s');
    });

    test('bir saatin altı dakika olarak gösterilir', () {
      expect(formatDuration(const Duration(minutes: 12), true), '12 dk');
      expect(
        formatDuration(const Duration(minutes: 12, seconds: 30), false),
        '12m',
      );
    });

    test('bir saatten uzun süre saat ve dakika ile gösterilir', () {
      expect(
        formatDuration(const Duration(hours: 1, minutes: 20), true),
        '1 sa 20 dk',
      );
      expect(
        formatDuration(const Duration(hours: 2, minutes: 5), false),
        '2h 5m',
      );
    });

    test('sıfır süre saniye olarak gösterilir', () {
      expect(formatDuration(Duration.zero, true), '0 sn');
    });
  });
}
