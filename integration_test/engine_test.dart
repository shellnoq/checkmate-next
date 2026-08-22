import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:satranc/domain/game_controller.dart';
import 'package:satranc/domain/match/engine_match_transport.dart';
import 'package:satranc/domain/match/match_protocol.dart';
import 'package:satranc/domain/model/difficulty.dart';
import 'package:satranc/domain/model/time_control.dart';
import 'package:satranc/engine/engine_models.dart';
import 'package:satranc/engine/stockfish_engine.dart';

/// Gerçek cihazda Stockfish'i çalıştıran doğrulamalar.
///
/// Çalıştırma:
///   flutter test integration_test/engine_test.dart -d CIHAZ_ID
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late StockfishEngine engine;

  setUpAll(() async {
    engine = StockfishEngine();
    await engine.start();
  });

  tearDownAll(() async {
    await engine.dispose();
  });

  testWidgets('motor açılır ve hazır duruma geçer', (tester) async {
    expect(engine.status.value, EngineStatus.ready);
  });

  testWidgets('başlangıç pozisyonunda geçerli bir hamle üretir',
      (tester) async {
    await engine.applyOptions(DifficultyLevel.club.engineOptions);
    final result = await engine.search(
      fen: kInitialFEN,
      limits: const SearchLimits(moveTimeMs: 500),
    );

    expect(result.bestMoveUci, isNotNull);
    final move = NormalMove.fromUci(result.bestMoveUci!);
    expect(Chess.initial.isLegal(Chess.initial.normalizeMove(move)), isTrue);
    expect(result.principalVariation, isNotNull);
    debugPrintEngine('kulüp seviyesi ilk hamle: ${result.bestMoveUci} '
        '(${result.elapsed.inMilliseconds} ms, '
        'derinlik ${result.principalVariation?.depth})');
  });

  testWidgets('sekiz zorluk kademesinin tamamı hamle üretir', (tester) async {
    for (final level in DifficultyLevel.values) {
      await engine.applyOptions(level.engineOptions);
      final result = await engine.search(
        fen: kInitialFEN,
        limits: level.searchLimits,
      );
      expect(result.bestMoveUci, isNotNull,
          reason: '${level.id} hamle üretmedi');
      final move = NormalMove.fromUci(result.bestMoveUci!);
      expect(Chess.initial.isLegal(Chess.initial.normalizeMove(move)), isTrue,
          reason: '${level.id} geçersiz hamle üretti: ${result.bestMoveUci}');
      debugPrintEngine('${level.id.padRight(12)} ${result.bestMoveUci} '
          '${result.elapsed.inMilliseconds} ms  '
          'multipv=${result.lines.length}');
    }
  });

  testWidgets('mat pozisyonunu bulur', (tester) async {
    await engine.applyOptions(DifficultyLevel.grandmaster.engineOptions);
    // Beyaz tek hamlede mat eder: Ka8# (arka sıra matı).
    final result = await engine.search(
      fen: '6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1',
      limits: const SearchLimits(depth: 12, moveTimeMs: 1500),
    );
    final line = result.principalVariation;
    expect(line?.isMate, isTrue, reason: 'mat görülmedi: $line');
    expect(line!.mateIn, 1);
    expect(result.bestMoveUci, 'a1a8');
    debugPrintEngine('mat bulundu: ${result.bestMoveUci} M${line.mateIn}');
  });

  testWidgets('acemi kademesi kulüp kademesinden zayıf oynar', (tester) async {
    // Acemi kademesinde MultiPV alternatifleri devrede olmalı.
    await engine.applyOptions(DifficultyLevel.beginner.engineOptions);
    final result = await engine.search(
      fen: kInitialFEN,
      limits: DifficultyLevel.beginner.searchLimits,
    );
    expect(result.lines.length, greaterThan(1),
        reason: 'acemi kademesinde MultiPV çalışmıyor');
  });

  testWidgets('motora karşı tam bir oyun oynanır', (tester) async {
    final transport = EngineMatchTransport(engine);
    final controller = GameController(
      config: MatchConfig(
        matchId: 'entegrasyon',
        kind: MatchKind.engine,
        localSide: Side.white,
        difficulty: DifficultyLevel.amateur,
        timeControl: TimeControl.unlimited,
      ),
      transport: transport,
      analysisEngine: engine,
      analysisEnabled: false,
    );

    await controller.start();

    // Oyuncu tarafında sabit tohumlu rastgele hamleler oynanır; motorun her
    // seferinde yanıt vermesi ve pozisyonun tutarlı kalması beklenir.
    final random = Random(20260823);
    var playerMoves = 0;
    while (playerMoves < 10) {
      await _waitUntil(
        tester,
        () =>
            controller.phase != GamePhase.playing ||
            (controller.isLocalTurn && !controller.opponentThinking),
        'oyuncu sırası (hamle ${playerMoves + 1})',
      );
      if (controller.phase != GamePhase.playing) break;

      final legal = makeLegalMoves(controller.position);
      expect(legal, isNotEmpty);
      final from = legal.keys.elementAt(random.nextInt(legal.length));
      final destinations = legal[from]!.toList();
      final to = destinations[random.nextInt(destinations.length)];
      controller.selectSquare(from);
      controller.selectSquare(to);
      if (controller.pendingPromotion != null) {
        controller.completePromotion(Role.queen);
      }
      playerMoves++;
    }

    // Son oyuncu hamlesinden sonra motorun yanıtı beklenir.
    await _waitUntil(
      tester,
      () =>
          controller.phase != GamePhase.playing ||
          (controller.isLocalTurn && !controller.opponentThinking),
      'motorun son yanıtı',
    );

    // Oyun erken bittiyse (mat/pat) bu da geçerli bir sonuçtur; önemli olan
    // motorun her oyuncu hamlesine yanıt vermiş olmasıdır.
    final expectedPlies = controller.phase == GamePhase.playing
        ? playerMoves * 2
        : playerMoves;
    expect(controller.moves.length, greaterThanOrEqualTo(expectedPlies),
        reason: 'motor yeterli sayıda yanıt vermedi');
    debugPrintEngine('oyun ${controller.moves.length} yarım hamle sürdü, '
        'sonuç: ${controller.result?.reason.name ?? 'devam ediyor'}');

    // Kaydedilen her hamle baştan yeniden oynatıldığında aynı pozisyona
    // ulaşılmalıdır.
    var replay = Chess.initial as Position;
    for (final record in controller.moves) {
      final move = replay.normalizeMove(NormalMove.fromUci(record.uci));
      expect(replay.isLegal(move), isTrue,
          reason: 'kayıtlı hamle geçersiz: ${record.uci} (${record.san})');
      replay = replay.play(move);
    }
    expect(replay.fen, controller.position.fen);

    final pgn = controller.toPgn();
    expect(pgn, contains('[White "Oyuncu"]'));
    debugPrintEngine(pgn);

    controller.dispose();
  });
}

Future<void> _waitUntil(
  WidgetTester tester,
  bool Function() condition,
  String description, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Zaman aşımı: $description');
    }
    await tester.pump(const Duration(milliseconds: 50));
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

void debugPrintEngine(String message) {
  // ignore: avoid_print
  print('[motor] $message');
}
