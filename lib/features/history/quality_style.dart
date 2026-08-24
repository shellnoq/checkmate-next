import 'package:flutter/material.dart';

import '../../domain/analysis/game_analyzer.dart';

/// Hamle sınıflarının görsel karşılığı.
extension MoveQualityStyle on MoveQuality {
  IconData get icon => switch (this) {
    MoveQuality.book => Icons.menu_book_rounded,
    MoveQuality.brilliant => Icons.star_rounded,
    MoveQuality.good => Icons.check_rounded,
    MoveQuality.dubious => Icons.question_mark_rounded,
    MoveQuality.bad => Icons.close_rounded,
  };

  Color get color => switch (this) {
    MoveQuality.book => const Color(0xFF6E85B7),
    MoveQuality.brilliant => const Color(0xFFE0A62E),
    MoveQuality.good => const Color(0xFF3F9D6B),
    MoveQuality.dubious => const Color(0xFFCC7A00),
    MoveQuality.bad => const Color(0xFFC0554F),
  };
}
