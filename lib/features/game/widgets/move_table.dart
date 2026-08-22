import 'package:flutter/material.dart';

import '../../../domain/model/move_record.dart';

/// Notasyon paneli: hamleleri sıra numarasıyla iki sütun hâlinde listeler.
///
/// Bir hamleye dokunmak o pozisyona götürür; canlı pozisyona dönmek için
/// listenin sonundaki hamleye ya da ileri okuna dokunulur.
class MoveTable extends StatefulWidget {
  const MoveTable({
    super.key,
    required this.moves,
    required this.currentIndex,
    required this.onSelect,
    this.emptyHint,
  });

  final List<MoveRecord> moves;

  /// Gösterilen pozisyonun indeksi (0 = başlangıç, n = n. yarım hamleden sonra).
  final int currentIndex;

  final ValueChanged<int> onSelect;

  /// Hiç hamle yokken gösterilecek metin.
  final String? emptyHint;

  @override
  State<MoveTable> createState() => _MoveTableState();
}

class _MoveTableState extends State<MoveTable> {
  final ScrollController _controller = ScrollController();

  static const _rowHeight = 38.0;

  @override
  void didUpdateWidget(covariant MoveTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex ||
        oldWidget.moves.length != widget.moves.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
    }
  }

  void _scrollToCurrent() {
    if (!_controller.hasClients) return;
    final row = ((widget.currentIndex - 1) ~/ 2).clamp(0, 1 << 30);
    final target = (row * _rowHeight - _controller.position.viewportDimension / 2)
        .clamp(0.0, _controller.position.maxScrollExtent);
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
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
      return Center(
        child: Text(
          widget.emptyHint ?? '',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final rowCount = (widget.moves.length + 1) ~/ 2;

    return ListView.builder(
      controller: _controller,
      padding: EdgeInsets.zero,
      itemCount: rowCount,
      itemBuilder: (context, row) {
        final whiteIndex = row * 2;
        final blackIndex = whiteIndex + 1;
        return Container(
          height: _rowHeight,
          color: row.isEven
              ? Colors.transparent
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.35),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  '${row + 1}.',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _cell(whiteIndex)),
              Expanded(child: _cell(blackIndex)),
            ],
          ),
        );
      },
    );
  }

  Widget _cell(int index) {
    if (index >= widget.moves.length) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final record = widget.moves[index];
    final isCurrent = widget.currentIndex == index + 1;

    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => widget.onSelect(index + 1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isCurrent
                ? theme.colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            record.san,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: isCurrent
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
