import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Kazanılan oyunda sonuç kartının arkasında bir kez patlayan parçacıklar.
///
/// Tek seferlik çalışır ve durur; sürekli dönen bir animasyon oyun sonu
/// ekranını yorucu kılardı. Parçacıkların yönü ve hızı indeksten türetilir,
/// böylece her açılışta aynı görünür ve testlerde ölçülebilir.
class VictoryBurst extends StatefulWidget {
  const VictoryBurst({
    super.key,
    this.particleCount = 22,
    this.duration = const Duration(milliseconds: 1100),
    this.colors = const [
      Color(0xFF3F9D6B),
      Color(0xFFE9C46A),
      Color(0xFFF2F0EB),
    ],
  });

  final int particleCount;
  final Duration duration;
  final List<Color> colors;

  @override
  State<VictoryBurst> createState() => _VictoryBurstState();
}

class _VictoryBurstState extends State<VictoryBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _BurstPainter(
            progress: _controller.value,
            particleCount: widget.particleCount,
            colors: widget.colors,
          ),
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.progress,
    required this.particleCount,
    required this.colors,
  });

  final double progress;
  final int particleCount;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final origin = Offset(size.width / 2, size.height * 0.42);
    final reach = size.shortestSide * 0.9;
    // Hızlı çıkıp yavaşlayan yayılma, üstüne hafif düşüş.
    final spread = 1 - math.pow(1 - progress, 3).toDouble();
    final fade = (1 - progress) * (1 - progress);

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * math.pi * 2 + (i % 3) * 0.21;
      final speed = 0.55 + ((i * 37) % 45) / 100;
      final radius = reach * spread * speed;
      final gravity = size.height * 0.16 * progress * progress;

      final offset = Offset(
        origin.dx + math.cos(angle) * radius,
        origin.dy + math.sin(angle) * radius + gravity,
      );

      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: fade);
      final side = 2.5 + (i % 4);
      canvas.drawCircle(offset, side * (0.4 + fade * 0.6), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
