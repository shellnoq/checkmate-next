import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkmate_next/app/theme/board_theme.dart';
import 'package:checkmate_next/app/theme/theme_packs.dart';
import 'package:checkmate_next/core/storage/app_storage.dart';
import 'package:checkmate_next/domain/economy/coin_service.dart';
import 'package:checkmate_next/features/board/game_background.dart';
import 'package:checkmate_next/features/board/piece_set.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AppStorage.initForTesting(
      Directory.systemTemp.createTempSync('checkmate_themes').path,
    );
  });

  group('ThemePacks', () {
    test('paketler tekil, geçerli ve varlıkları kayıtlı', () {
      final ids = <String>{};
      for (final pack in ThemePacks.all) {
        expect(ids.add(pack.id), isTrue);
        expect(BoardTheme.fromId(pack.boardTheme.id).id, pack.boardTheme.id);
        expect(PieceSet.fromId(pack.pieceSet.id).id, pack.pieceSet.id);
        expect(pack.price, greaterThanOrEqualTo(0));
        final asset = pack.musicAsset;
        if (asset != null) {
          expect(File(asset).existsSync(), isTrue, reason: '$asset depoda yok');
        }
      }
      expect(ThemePacks.fromId('yok').id, 'classic');
    });

    test('ücretsiz paket baştan açık, ücretli paket coinle açılır', () async {
      await AppStorage.resetStats();
      expect(ThemePacks.classic.price, 0);

      // Yetersiz bakiye: satın alma başarısız.
      expect(await CoinService.trySpend(ThemePacks.space.price), isFalse);

      await CoinService.add(100);
      expect(await CoinService.trySpend(ThemePacks.space.price), isTrue);
      await AppStorage.setStat('theme_owned_space', 1);
      expect(AppStorage.statOf('theme_owned_space'), 1);
      expect(CoinService.balance, 100 - ThemePacks.space.price);
    });
  });

  group('GameBackground', () {
    testWidgets('none çocuğu olduğu gibi bırakır', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GameBackground(
            style: BackgroundStyle.none,
            child: Text('icerik'),
          ),
        ),
      );
      expect(find.text('icerik'), findsOneWidget);
      // Motifsiz stilde arka plan katmanı hiç kurulmaz.
      expect(
        find.descendant(
          of: find.byType(GameBackground),
          matching: find.byType(Stack),
        ),
        findsNothing,
      );
    });

    testWidgets('motifli stiller çizer ve çocuğu gösterir', (tester) async {
      for (final style in [
        BackgroundStyle.stars,
        BackgroundStyle.leaves,
        BackgroundStyle.dunes,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: GameBackground(style: style, child: const Text('icerik')),
          ),
        );
        expect(find.text('icerik'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
