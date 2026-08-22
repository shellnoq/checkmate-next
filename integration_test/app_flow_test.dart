import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:satranc/features/board/chess_board.dart';
import 'package:satranc/main.dart' as app;

/// Uygulamayı gerçek cihazda baştan sona sürer.
///
/// Her ekranda kısa süre beklenir; bu sırada dışarıdan `adb screencap` ile
/// görüntü alınabilir.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ana ekrandan oyuna kadar tam akış', (tester) async {
    app.main();
    await _settle(tester, 3000);
    _mark('ANA_EKRAN');
    await _hold(tester, 2500);

    // Bilgisayara karşı
    await tester.tap(find.text('Bilgisayara Karşı'));
    await _settle(tester, 1500);
    _mark('OYUN_KURULUMU');
    await _hold(tester, 2500);

    // Zorluk: Uzman. Liste tembel oluşturulduğu için önce görünür kılınır.
    final list = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('Uzman'), 150, scrollable: list);
    await _settle(tester, 600);
    await tester.tap(find.text('Uzman'));
    await _settle(tester, 600);
    _mark('ZORLUK_SECILDI');
    await _hold(tester, 2000);

    // Süresiz oyun seçilir; saat tıklaması pump döngüsünü bozmasın.
    await tester.scrollUntilVisible(
      find.text('Süresiz'),
      150,
      scrollable: list,
    );
    await _settle(tester, 600);
    await tester.tap(find.text('Süresiz'));
    await _settle(tester, 600);
    _mark('SURE_SECILDI');
    await _hold(tester, 2000);

    // Oyunu başlat
    await tester.tap(find.text('Oyunu Başlat'));
    await _settle(tester, 1000);

    // Motorun açılmasını bekle: tahta görünene kadar.
    await _waitFor(
      tester,
      () => find.byType(ChessBoard).evaluate().isNotEmpty,
      'tahta görünmedi',
    );
    await _settle(tester, 1500);
    _mark('OYUN_EKRANI');
    await _hold(tester, 3000);

    // e2-e4 oyna
    await _tapSquare(tester, Square.e2);
    await _settle(tester, 500);
    _mark('TAS_SECILDI');
    await _hold(tester, 2000);

    await _tapSquare(tester, Square.e4);
    await _settle(tester, 800);
    _mark('HAMLE_OYNANDI');
    await _hold(tester, 4000);

    // Motorun yanıtı ve değerlendirme çubuğu
    await _settle(tester, 3000);
    _mark('MOTOR_YANITLADI');
    await _hold(tester, 3000);

    // İpucu iste
    final hint = find.text('İpucu');
    if (hint.evaluate().isNotEmpty) {
      await tester.tap(hint);
      await _settle(tester, 2500);
      _mark('IPUCU');
      await _hold(tester, 3000);
    }

    // Birkaç hamle daha oynanır ki hamle listesi ve alınan taşlar dolsun.
    for (final (from, to) in const [
      (Square.g1, Square.f3),
      (Square.f1, Square.c4),
      (Square.e1, Square.g1),
    ]) {
      await _tapSquare(tester, from);
      await _settle(tester, 400);
      await _tapSquare(tester, to);
      await _settle(tester, 3500);
    }
    _mark('ROK_SONRASI');
    await _hold(tester, 4000);

    expect(find.byType(ChessBoard), findsOneWidget);
  });
}

Future<void> _tapSquare(WidgetTester tester, Square square) async {
  final rect = tester.getRect(find.byType(ChessBoard));
  final size = rect.width / 8;
  final col = square.file.toInt();
  final row = 7 - square.rank.toInt();
  await tester.tapAt(
    Offset(rect.left + (col + 0.5) * size, rect.top + (row + 0.5) * size),
  );
}

Future<void> _settle(WidgetTester tester, int ms) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 60));
    await Future<void>.delayed(const Duration(milliseconds: 40));
  }
}

Future<void> _hold(WidgetTester tester, int ms) => _settle(tester, ms);

Future<void> _waitFor(
  WidgetTester tester,
  bool Function() condition,
  String description, {
  Duration timeout = const Duration(seconds: 40),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) fail('Zaman aşımı: $description');
    await tester.pump(const Duration(milliseconds: 100));
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

void _mark(String label) {
  // ignore: avoid_print
  print('[akis] $label ${DateTime.now().toIso8601String()}');
}
