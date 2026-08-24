import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkmate_next/domain/openings/opening_book.dart';

void main() {
  group('OpeningBook', () {
    test('tablodaki her satır başlangıçtan itibaren yasaldır', () {
      for (final opening in OpeningBook.all) {
        // `uci` ilk erişimde SAN'ı oynayarak üretilir; geçersiz bir satır
        // burada StateError fırlatır.
        expect(opening.uci, isNotEmpty, reason: opening.trName);

        // Üretilen UCI de baştan oynanabilir olmalı.
        Position position = Chess.initial;
        for (final uci in opening.uci) {
          final move = position.normalizeMove(NormalMove.fromUci(uci));
          expect(
            position.isLegal(move),
            isTrue,
            reason: '${opening.trName}: $uci',
          );
          position = position.play(move);
        }
      }
    });

    test('eco kodları ve adlar boş değil, satırlar benzersiz', () {
      final seen = <String>{};
      for (final opening in OpeningBook.all) {
        expect(opening.eco, isNotEmpty);
        expect(opening.trName, isNotEmpty);
        expect(opening.enName, isNotEmpty);
        expect(
          seen.add(opening.san),
          isTrue,
          reason: 'yinelenen satır: ${opening.san}',
        );
      }
    });

    test('en derin tam satır seçilir', () {
      final italian = compileSanLine('e4 e5 Nf3 Nc6 Bc4');
      expect(OpeningBook.identify(italian)?.trName, 'İtalyan Açılışı');

      final giuoco = compileSanLine('e4 e5 Nf3 Nc6 Bc4 Bc5 c3 Nf6');
      expect(OpeningBook.identify(giuoco)?.trName, 'Giuoco Piano');

      final najdorf = compileSanLine(
        'e4 c5 Nf3 d6 d4 cxd4 Nxd4 Nf6 Nc3 a6 Be2',
      );
      expect(OpeningBook.identify(najdorf)?.trName, 'Sicilya, Najdorf');
    });

    test('kitap dışı oyun tanınmaz', () {
      expect(OpeningBook.identify(['a2a3']), isNull);
      expect(OpeningBook.identify([]), isNull);
      expect(OpeningBook.bookPlies(['a2a3']), 0);
    });

    test('bookPlies satırın yarısında da doğru sayar', () {
      final moves = compileSanLine('e4 c5 Nf3 d6 d4 cxd4 Nxd4 Nf6 Nc3 a6');
      expect(OpeningBook.bookPlies(moves), 10);
      // Kitaptan çıkan devam sayacı büyütmez.
      expect(OpeningBook.bookPlies([...moves, 'a2a3']), 10);
      // İlk iki hamle birçok satırın önekidir.
      expect(OpeningBook.bookPlies(compileSanLine('e4 e5')), greaterThan(1));
    });

    test('rok kitap satırında standart UCI ile yazılır', () {
      final closed = OpeningBook.all.firstWhere(
        (o) => o.trName == 'İspanyol, Kapalı',
      );
      expect(closed.uci, contains('e1g1'));
      expect(closed.uci, isNot(contains('e1h1')));
    });
  });
}
