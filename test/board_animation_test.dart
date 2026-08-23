import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkmate_next/app/theme/board_theme.dart';
import 'package:checkmate_next/features/board/chess_board.dart';
import 'package:checkmate_next/features/board/piece_set.dart';
import 'package:checkmate_next/features/board/piece_widget.dart';

/// Tahta animasyonlarının davranışını sabitler. Görüntü karşılaştırması değil,
/// widget ağacındaki durum üzerinden ölçüm yapılır; böylece yazı tipi ve çizim
/// arka ucundan bağımsız çalışır.
void main() {
  Widget board(Position position, {Square? checked}) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 400,
          height: 400,
          child: ChessBoard(
            position: position,
            orientation: Side.white,
            boardTheme: BoardTheme.walnut,
            pieceSet: PieceSet.classic,
            checkedSquare: checked,
            interactive: false,
          ),
        ),
      ),
    ),
  );

  Position pos(String fen) => Chess.fromSetup(Setup.parseFen(fen));

  group('şah uyarısı', () {
    testWidgets('şah çekilince sönümlü vuruş oynar ve kendiliğinden durur', (
      tester,
    ) async {
      final quiet = pos(kInitialFEN);
      // Siyah şah e8'de, beyaz vezir e7'de şah çekiyor.
      final check = pos('4k3/4Q3/8/8/8/8/8/4K3 b - - 0 1');

      await tester.pumpWidget(board(quiet));
      await tester.pumpAndSettle();

      await tester.pumpWidget(board(check, checked: Square.e8));
      await tester.pump(const Duration(milliseconds: 120));

      // Animasyon sürüyor: henüz oturmamış olmalı.
      expect(tester.binding.hasScheduledFrame, isTrue);

      // Sonsuz döngü değil; belirli sürede durur, aksi hâlde bu satır
      // zaman aşımına uğrardı.
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('şah kalkınca vuruş sıfırlanır', (tester) async {
      final check = pos('4k3/4Q3/8/8/8/8/8/4K3 b - - 0 1');
      await tester.pumpWidget(board(check, checked: Square.e8));
      await tester.pumpAndSettle();

      await tester.pumpWidget(board(check));
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('taş alma animasyonu', () {
    testWidgets('alınan taş hemen kaybolmaz, kısa süre görünür kalır', (
      tester,
    ) async {
      // Beyaz fil c4, siyah at f7'de; fil f7'yi alır.
      final before = pos(
        'rnbqkb1r/pppppnpp/8/8/2B5/8/PPPPPPPP/RNBQK1NR w KQkq - 0 1',
      );
      final after = pos(
        'rnbqkb1r/pppppBpp/8/8/8/8/PPPPPPPP/RNBQK1NR b KQkq - 0 1',
      );

      await tester.pumpWidget(board(before));
      await tester.pumpAndSettle();
      final initial = tester.widgetList(find.byType(PieceWidget)).length;

      await tester.pumpWidget(board(after));
      await tester.pump(const Duration(milliseconds: 60));

      // Alınan at hâlâ çizilmekte: taş sayısı, kalan taş sayısından fazla.
      final during = tester.widgetList(find.byType(PieceWidget)).length;
      expect(
        during,
        initial,
        reason: 'alınan taş animasyon sürerken tahtada kalmalı',
      );

      // Animasyon bitince listeden düşer.
      await tester.pumpAndSettle();
      final settled = tester.widgetList(find.byType(PieceWidget)).length;
      expect(settled, initial - 1);
    });

    testWidgets('taş alınmayan hamlede fazladan taş çizilmez', (tester) async {
      final before = pos(kInitialFEN);
      final after = pos(
        'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
      );

      await tester.pumpWidget(board(before));
      await tester.pumpAndSettle();
      expect(tester.widgetList(find.byType(PieceWidget)).length, 32);

      await tester.pumpWidget(board(after));
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.widgetList(find.byType(PieceWidget)).length, 32);
    });

    testWidgets('yeni oyun kurulumunda toplu solma yaşanmaz', (tester) async {
      // Az taşlı bir konumdan başlangıç dizilişine dönmek bir hamle değildir;
      // kalkan taş animasyonu tetiklenmemelidir.
      final endgame = pos('8/8/4k3/8/8/4K3/8/8 w - - 0 1');
      await tester.pumpWidget(board(endgame));
      await tester.pumpAndSettle();

      await tester.pumpWidget(board(pos(kInitialFEN)));
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.widgetList(find.byType(PieceWidget)).length, 32);
    });
  });
}
