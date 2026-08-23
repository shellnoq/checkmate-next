@Tags(['golden'])
library;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkmate_next/app/theme/board_theme.dart';
import 'package:checkmate_next/features/board/chess_board.dart';
import 'package:checkmate_next/features/board/piece_set.dart';

/// Tahtanın ve taş takımlarının görünümünü sabitler.
///
/// `flutter test --update-goldens` ile referans görüntüler yenilenir.
void main() {
  Widget wrap(Widget child) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF14171A),
      body: Center(child: SizedBox(width: 400, height: 400, child: child)),
    ),
  );

  testWidgets('başlangıç dizilişi — klasik takım, ceviz tahta', (tester) async {
    await tester.binding.setSurfaceSize(const Size(440, 440));
    await tester.pumpWidget(
      wrap(
        ChessBoard(
          position: Chess.initial,
          orientation: Side.white,
          boardTheme: BoardTheme.walnut,
          pieceSet: PieceSet.classic,
          interactive: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ChessBoard),
      matchesGoldenFile('goldens/board_initial_classic_walnut.png'),
    );
  });

  testWidgets('oyun ortası — turnuva tahtası, seçim ve hamle işaretleri', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(440, 440));
    final position = Chess.fromSetup(
      Setup.parseFen(
        'r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQ1RK1 b kq - 5 5',
      ),
    );
    await tester.pumpWidget(
      wrap(
        ChessBoard(
          position: position,
          orientation: Side.white,
          boardTheme: BoardTheme.tournament,
          pieceSet: PieceSet.wood,
          selectedSquare: Square.c6,
          legalDestinations: const {
            Square.a5,
            Square.b4,
            Square.d4,
            Square.e7,
            Square.b8,
          },
          lastMove: (Square.e1, Square.g1),
          hintMove: (Square.c6, Square.d4),
          interactive: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ChessBoard),
      matchesGoldenFile('goldens/board_midgame_tournament_wood.png'),
    );
  });

  testWidgets('neşeli takım — küçük yaş grubu görünümü', (tester) async {
    await tester.binding.setSurfaceSize(const Size(440, 440));
    await tester.pumpWidget(
      wrap(
        ChessBoard(
          position: Chess.initial,
          orientation: Side.white,
          boardTheme: BoardTheme.tournament,
          pieceSet: PieceSet.playful,
          interactive: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ChessBoard),
      matchesGoldenFile('goldens/board_playful.png'),
    );
  });

  testWidgets('siyah yönünde tahta — kobalt takım, şah vurgusu', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(440, 440));
    final position = Chess.fromSetup(
      Setup.parseFen(
        'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3',
      ),
    );
    await tester.pumpWidget(
      wrap(
        ChessBoard(
          position: position,
          orientation: Side.black,
          boardTheme: BoardTheme.midnight,
          pieceSet: PieceSet.cobalt,
          checkedSquare: Square.e1,
          interactive: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ChessBoard),
      matchesGoldenFile('goldens/board_black_midnight_cobalt.png'),
    );
  });
}
