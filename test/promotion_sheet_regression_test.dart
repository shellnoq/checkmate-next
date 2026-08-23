import 'dart:io';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkmate_next/app/providers/engine_provider.dart';
import 'package:checkmate_next/core/storage/app_storage.dart';
import 'package:checkmate_next/domain/match/match_protocol.dart';
import 'package:checkmate_next/domain/model/time_control.dart';
import 'package:checkmate_next/features/board/chess_board.dart';
import 'package:checkmate_next/features/game/game_screen.dart';
import 'package:checkmate_next/features/game/widgets/promotion_sheet.dart';

import 'support/fake_engine.dart';

/// Terfi penceresinin yalnızca bir kez açıldığını doğrular.
///
/// Denetleyici saat atımında ve motor değerlendirmesinde de bildirim ürettiği
/// için, koruma olmadan terfi beklerken pencere her bildirimde yeniden açılır
/// ve üst üste yığılır; kullanıcıya taş değişip duruyormuş gibi görünür.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AppStorage.initForTesting(
      Directory.systemTemp.createTempSync('checkmate_test').path,
    );
  });

  Widget harness(MatchConfig config) => ProviderScope(
        overrides: [chessEngineProvider.overrideWithValue(FakeEngine())],
        child: MaterialApp(
          locale: const Locale('tr'),
          home: GameScreen(config: config),
        ),
      );

  testWidgets('saat işlerken terfi penceresi tek kez açılır', (tester) async {
    // Beyaz piyon a7'de; a8'e giderek terfi eder. Süreli oyun seçildi ki
    // saat atımı sürekli bildirim üretsin.
    final config = MatchConfig(
      matchId: 'terfi',
      kind: MatchKind.passAndPlay,
      localSide: Side.white,
      timeControl: TimeControl.blitz5,
      startingFen: '7k/P7/8/8/8/8/8/K7 w - - 0 1',
    );

    await tester.pumpWidget(harness(config));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    final board = find.byType(ChessBoard);
    expect(board, findsOneWidget);

    Future<void> tapSquare(Square square) async {
      final rect = tester.getRect(board);
      final size = rect.width / 8;
      await tester.tapAt(Offset(
        rect.left + (square.file.toInt() + 0.5) * size,
        rect.top + (7 - square.rank.toInt() + 0.5) * size,
      ));
      await tester.pump(const Duration(milliseconds: 120));
    }

    await tapSquare(Square.a7);
    await tapSquare(Square.a8);

    // Saatin birkaç kez atmasına izin ver: her atım bir bildirim demektir.
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 220));
    }

    expect(
      find.byType(PromotionSheet),
      findsOneWidget,
      reason: 'terfi penceresi yalnızca bir kez açılmalı',
    );
  });
}
