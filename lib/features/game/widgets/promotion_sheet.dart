import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../board/piece_set.dart';
import '../../board/piece_svg.dart';

/// Terfi taşı seçimi.
class PromotionSheet extends StatelessWidget {
  const PromotionSheet({
    super.key,
    required this.side,
    required this.pieceSet,
    required this.title,
    required this.onSelected,
    required this.onCancel,
  });

  final Side side;
  final PieceSet pieceSet;
  final String title;
  final ValueChanged<Role> onSelected;
  final VoidCallback onCancel;

  static const _roles = [Role.queen, Role.rook, Role.bishop, Role.knight];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final role in _roles)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onSelected(role),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: SvgPicture.string(
                            PieceSvg.of(
                              Piece(color: side, role: role),
                              pieceSet,
                            ),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onCancel,
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
