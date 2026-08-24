import 'package:flutter_test/flutter_test.dart';
import 'package:checkmate_next/core/l10n/endgame_quotes.dart';

void main() {
  group('EndgameQuotes', () {
    test('aynı tohum aynı sözü verir', () {
      final a = EndgameQuotes.pick(won: true, seed: 7);
      final b = EndgameQuotes.pick(won: true, seed: 7);
      expect(a.tr, b.tr);
    });

    test('her havuzdan söz seçilebilir ve alanlar dolu', () {
      for (final won in [true, false, null]) {
        for (int seed = 0; seed < 8; seed++) {
          final quote = EndgameQuotes.pick(won: won, seed: seed);
          expect(quote.tr, isNotEmpty);
          expect(quote.en, isNotEmpty);
          expect(quote.author, isNotEmpty);
        }
      }
    });
  });
}
