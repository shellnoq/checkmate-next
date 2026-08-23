import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkmate_next/domain/chess_clock.dart';
import 'package:checkmate_next/domain/model/time_control.dart';

void main() {
  group('ChessClock', () {
    test('süresiz kontrolde saat çalışmaz', () {
      final clock = ChessClock(TimeControl.unlimited);
      clock.start(Side.white);
      expect(clock.isRunning, isFalse);
      clock.dispose();
    });

    test('taraf değişince artış eklenir', () async {
      const control = TimeControl(
        id: 'test',
        trName: 'Test',
        enName: 'Test',
        initial: Duration(seconds: 10),
        increment: Duration(seconds: 2),
      );
      final clock = ChessClock(control);
      clock.start(Side.white);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      clock.switchTo(Side.black);

      // Harcanan süre düşülür, ardından 2 saniye artış eklenir.
      final white = clock.remainingOf(Side.white);
      expect(white, greaterThan(const Duration(seconds: 11)));
      expect(white, lessThanOrEqualTo(const Duration(seconds: 12)));
      expect(clock.activeSide, Side.black);
      clock.dispose();
    });

    test('süre bitince bayrak düşer', () async {
      const control = TimeControl(
        id: 'test',
        trName: 'Test',
        enName: 'Test',
        initial: Duration(milliseconds: 250),
      );
      final clock = ChessClock(control);
      Side? flagged;
      clock.onFlag = (side) => flagged = side;
      clock.start(Side.white);
      await Future<void>.delayed(const Duration(milliseconds: 700));
      expect(flagged, Side.white);
      expect(clock.remainingOf(Side.white), Duration.zero);
      clock.dispose();
    });
  });
}
