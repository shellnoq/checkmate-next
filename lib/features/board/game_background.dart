import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/theme_packs.dart';

/// Oyun ekranının arkasına tema paketinin motifini çizer.
///
/// Motifler sabit tohumla üretilir: her açılışta aynı görünür, test edilebilir
/// ve dikkat dağıtmayacak kadar soluktur. [BackgroundStyle.none] hiçbir şey
/// çizmez; ekran temanın kendi zemininde kalır.
class GameBackground extends StatelessWidget {
  const GameBackground({super.key, required this.style, required this.child});

  final BackgroundStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (style == BackgroundStyle.none) return child;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: switch (style) {
                BackgroundStyle.stars => const [
                  Color(0xFF0B1026),
                  Color(0xFF1A2138),
                ],
                BackgroundStyle.leaves =>
                  dark
                      ? const [Color(0xFF132214), Color(0xFF1C2E1E)]
                      : const [Color(0xFFE3EED6), Color(0xFFCFE0BC)],
                BackgroundStyle.dunes =>
                  dark
                      ? const [Color(0xFF2A2113), Color(0xFF3A2E1A)]
                      : const [Color(0xFFF4E7C3), Color(0xFFE6D0A0)],
                BackgroundStyle.none => const [Colors.transparent],
              },
            ),
          ),
        ),
        CustomPaint(painter: _MotifPainter(style, dark)),
        child,
      ],
    );
  }
}

class _MotifPainter extends CustomPainter {
  _MotifPainter(this.style, this.dark);

  final BackgroundStyle style;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(7);
    switch (style) {
      case BackgroundStyle.stars:
        final paint = Paint()..color = const Color(0xAAE8ECF6);
        for (int i = 0; i < 70; i++) {
          final dx = random.nextDouble() * size.width;
          final dy = random.nextDouble() * size.height;
          canvas.drawCircle(
            Offset(dx, dy),
            0.6 + random.nextDouble() * 1.2,
            paint
              ..color = paint.color.withValues(
                alpha: 0.25 + random.nextDouble() * 0.5,
              ),
          );
        }
        // Uzak bir gezegen ve halkası.
        final planet = Offset(size.width * 0.82, size.height * 0.14);
        canvas.drawCircle(planet, 26, Paint()..color = const Color(0x553E5C8A));
        canvas.drawOval(
          Rect.fromCenter(center: planet, width: 84, height: 18),
          Paint()
            ..color = const Color(0x44718AB5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      case BackgroundStyle.leaves:
        final paint = Paint()
          ..color = dark ? const Color(0x2247A05C) : const Color(0x33477A44);
        for (int i = 0; i < 26; i++) {
          final dx = random.nextDouble() * size.width;
          final dy = random.nextDouble() * size.height;
          final length = 14.0 + random.nextDouble() * 18;
          canvas.save();
          canvas.translate(dx, dy);
          canvas.rotate(random.nextDouble() * math.pi);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: length,
              height: length * 0.42,
            ),
            paint,
          );
          canvas.restore();
        }
      case BackgroundStyle.dunes:
        final paint = Paint()
          ..color = dark ? const Color(0x33C9A25C) : const Color(0x338F6A32)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        for (int i = 0; i < 6; i++) {
          final baseY = size.height * (0.2 + i * 0.14);
          final path = Path()..moveTo(0, baseY);
          for (double x = 0; x <= size.width; x += 24) {
            path.quadraticBezierTo(
              x + 12,
              baseY + math.sin(x / 40 + i) * 8 - 8,
              x + 24,
              baseY,
            );
          }
          canvas.drawPath(path, paint);
        }
        // Ufukta bir piramit.
        final base = Offset(size.width * 0.78, size.height * 0.2);
        final pyramid = Path()
          ..moveTo(base.dx - 34, base.dy)
          ..lineTo(base.dx, base.dy - 40)
          ..lineTo(base.dx + 34, base.dy)
          ..close();
        canvas.drawPath(pyramid, Paint()..color = const Color(0x338F6A32));
      case BackgroundStyle.none:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _MotifPainter oldDelegate) =>
      oldDelegate.style != style || oldDelegate.dark != dark;
}
