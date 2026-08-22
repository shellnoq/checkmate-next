import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../board/piece_set.dart';
import '../../board/piece_svg.dart';

/// Bir oyuncunun adı, aldığı taşlar ve saati.
class PlayerBar extends StatelessWidget {
  const PlayerBar({
    super.key,
    required this.name,
    required this.side,
    required this.captured,
    required this.materialAdvantage,
    required this.pieceSet,
    required this.isActive,
    this.remaining,
    this.subtitle,
  });

  final String name;
  final Side side;

  /// Bu oyuncunun aldığı taşlar.
  final List<Role> captured;

  /// Bu oyuncunun materyal üstünlüğü; sıfır veya negatifse gösterilmez.
  final int materialAdvantage;

  final PieceSet pieceSet;
  final bool isActive;
  final Duration? remaining;
  final String? subtitle;

  bool get _lowTime =>
      remaining != null && remaining! < const Duration(seconds: 30);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  side == Side.white ? pieceSet.whiteFill : pieceSet.blackFill,
              border: Border.all(color: scheme.outlineVariant),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color:
                        isActive ? scheme.onSurface : scheme.onSurfaceVariant,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                if (captured.isNotEmpty || materialAdvantage > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: _CapturedRow(
                      captured: captured,
                      advantage: materialAdvantage,
                      pieceSet: pieceSet,
                      capturedSide: side.opposite,
                    ),
                  ),
              ],
            ),
          ),
          if (remaining != null) ...[
            const SizedBox(width: 10),
            _ClockChip(
              remaining: remaining!,
              isActive: isActive,
              lowTime: _lowTime,
            ),
          ],
        ],
      ),
    );
  }
}

class _CapturedRow extends StatelessWidget {
  const _CapturedRow({
    required this.captured,
    required this.advantage,
    required this.pieceSet,
    required this.capturedSide,
  });

  final List<Role> captured;
  final int advantage;
  final PieceSet pieceSet;

  /// Alınan taşların rengi (rakibin rengi).
  final Side capturedSide;

  static const _order = [
    Role.pawn,
    Role.knight,
    Role.bishop,
    Role.rook,
    Role.queen,
  ];

  @override
  Widget build(BuildContext context) {
    final sorted = [
      for (final role in _order) ...captured.where((r) => r == role),
    ];
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final role in sorted)
          SizedBox(
            width: 13,
            height: 16,
            child: SvgPicture.string(
              PieceSvg.of(Piece(color: capturedSide, role: role), pieceSet),
              fit: BoxFit.contain,
            ),
          ),
        if (advantage > 0)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '+$advantage',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _ClockChip extends StatelessWidget {
  const _ClockChip({
    required this.remaining,
    required this.isActive,
    required this.lowTime,
  });

  final Duration remaining;
  final bool isActive;
  final bool lowTime;

  String get _formatted {
    final total = remaining.inMilliseconds;
    final minutes = total ~/ 60000;
    final seconds = (total % 60000) ~/ 1000;
    if (minutes == 0 && total < 20000) {
      final tenths = (total % 1000) ~/ 100;
      return '$seconds.$tenths';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background = lowTime && isActive
        ? const Color(0xFFC0554F)
        : isActive
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest;
    final foreground = lowTime && isActive
        ? Colors.white
        : isActive
            ? scheme.onPrimaryContainer
            : scheme.onSurfaceVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _formatted,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: foreground,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
