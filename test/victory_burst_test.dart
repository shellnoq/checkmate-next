import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkmate_next/features/game/widgets/victory_burst.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(
      body: Center(child: SizedBox(width: 200, height: 80, child: child)),
    ),
  );

  testWidgets('bir kez patlar ve kendiliğinden durur', (tester) async {
    await tester.pumpWidget(wrap(const VictoryBurst()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);

    // Döngüye girmez; aksi hâlde pumpAndSettle zaman aşımına uğrardı.
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('dokunuşları engellemez', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Center(
                child: FilledButton(
                  onPressed: () => tapped = true,
                  child: const Text('Yeniden Oyna'),
                ),
              ),
              const Positioned.fill(child: VictoryBurst()),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.text('Yeniden Oyna'));
    expect(tapped, isTrue, reason: 'parçacık katmanı düğmeyi gölgelememeli');
    await tester.pumpAndSettle();
  });

  testWidgets('parçacık sayısı ayarlanabilir ve sıfır da geçerli', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const VictoryBurst(particleCount: 0)));
    await tester.pumpAndSettle();
    expect(find.byType(VictoryBurst), findsOneWidget);
  });
}
