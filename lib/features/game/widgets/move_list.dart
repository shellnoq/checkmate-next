import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../../domain/model/move_record.dart';

/// Hamle listesi. Yatay şerit olarak gösterilir; bir hamleye dokunmak o
/// pozisyona götürür.
class MoveList extends StatefulWidget {
  const MoveList({
    super.key,
    required this.moves,
    required this.currentIndex,
    required this.onSelect,
  });

  final List<MoveRecord> moves;

  /// Gösterilen pozisyonun indeksi (0 = başlangıç, n = n. hamleden sonra).
  final int currentIndex;

  final ValueChanged<int> onSelect;

  @override
  State<MoveList> createState() => _MoveListState();
}

class _MoveListState extends State<MoveList> {
  final ScrollController _controller = ScrollController();

  @override
  void didUpdateWidget(covariant MoveList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.moves.length != widget.moves.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients) {
          _controller.animateTo(
            _controller.position.maxScrollExtent,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.moves.isEmpty) {
      return SizedBox(
        height: 40,
        child: Center(
          child: Text(
            '1.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: ListView.builder(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: widget.moves.length,
        itemBuilder: (context, index) {
          final record = widget.moves[index];
          final isCurrent = widget.currentIndex == index + 1;
          final showNumber = record.side == Side.white || index == 0;
          final moveNumber = (index ~/ 2) + 1;

          return Row(
            children: [
              if (showNumber)
                Padding(
                  padding: const EdgeInsets.only(right: 4, left: 4),
                  child: Text(
                    record.side == Side.white
                        ? '$moveNumber.'
                        : '$moveNumber…',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              GestureDetector(
                onTap: () => widget.onSelect(index + 1),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? theme.colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    record.san,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
