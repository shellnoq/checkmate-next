import 'dart:io';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkmate_next/app/providers/engine_provider.dart';
import 'package:checkmate_next/core/storage/app_storage.dart';
import 'package:checkmate_next/domain/openings/opening_book.dart';
import 'package:checkmate_next/features/board/chess_board.dart';
import 'package:checkmate_next/features/history/replay_screen.dart';

import 'support/fake_engine.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AppStorage.initForTesting(
      Directory.systemTemp.createTempSync('checkmate_replay').path,
    );
  });

  Widget harness(Map<String, Object?> game) => ProviderScope(
    overrides: [chessEngineProvider.overrideWithValue(FakeEngine())],
    child: MaterialApp(
      locale: const Locale('tr'),
      home: ReplayScreen(game: game),
    ),
  );

  testWidgets('arşiv kaydı tahtada gezilir ve açılış adı görünür', (
    tester,
  ) async {
    final game = <String, Object?>{
      'kind': 'passAndPlay',
      'localSide': 'white',
      'startingFen': kInitialFEN,
      'uci': ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4'],
      'result': {'winner': null, 'reason': 'drawAgreement'},
      'pgn': '1. e4 e5 2. Nf3 Nc6 3. Bc4 1/2-1/2',
    };

    await tester.pumpWidget(harness(game));
    await tester.pumpAndSettle();

    expect(find.byType(ChessBoard), findsOneWidget);
    // Kayıt sonda açılır ve açılış tanınır. Ad, test kabuğunun dil
    // çözümlemesine bağlı olduğundan dil bağımsız ECO koduna bakılır.
    expect(find.textContaining('C50'), findsOneWidget);

    // Başa dön, ileri iki adım: kilitlenme ve taşma olmadan gezilmeli.
    await tester.tap(find.byIcon(Icons.first_page));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('açılış satırı analiz düğmesi olmadan açılır', (tester) async {
    final opening = OpeningBook.all.first;
    await tester.pumpWidget(
      harness(<String, Object?>{
        'kind': 'opening',
        'openingName': opening.trName,
        'uci': opening.uci,
        'startingFen': kInitialFEN,
      }),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ChessBoard), findsOneWidget);
    expect(find.byIcon(Icons.insights_outlined), findsNothing);
    // Kitap satırında her hamle kitap simgesi taşır.
    await tester.tap(find.byIcon(Icons.last_page));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.menu_book_rounded), findsWidgets);
  });
}
