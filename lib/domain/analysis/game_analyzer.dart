import 'package:dartchess/dartchess.dart';

import '../../engine/chess_engine.dart';
import '../../engine/engine_models.dart';

/// Bir hamlenin sınıfı.
enum MoveQuality { book, brilliant, good, dubious, bad }

/// Bitmiş bir oyunun hamle hamle değerlendirmesi.
class GameAnalysis {
  const GameAnalysis({
    required this.qualities,
    required this.cpLoss,
    required this.whiteCp,
  });

  final List<MoveQuality> qualities;

  /// Hamle başına santipiyon kaybı (0 = en iyi hamle kadar iyi).
  final List<int> cpLoss;

  /// Pozisyon başına beyazın gözünden değerlendirme.
  final List<int> whiteCp;
}

/// Oyunu motorla hamle hamle değerlendirir ve her hamleyi sınıflar.
class GameAnalyzer {
  GameAnalyzer._();

  /// Mat skorlarının santipiyona indirgenmesinde kullanılan tavan.
  static const mateScore = 10000;

  /// Değerlendirmeyi her zaman beyazın gözünden santipiyona çevirir.
  static int whiteCentipawns(EngineLine line, {required Side sideToMove}) {
    int cp;
    final mate = line.mateIn;
    if (mate != null) {
      final magnitude = mateScore - mate.abs() * 10;
      cp = mate > 0 ? magnitude : -magnitude;
    } else {
      cp = line.centipawns ?? 0;
    }
    return sideToMove == Side.white ? cp : -cp;
  }

  /// Santipiyon kaybını sınıfa çevirir.
  ///
  /// Eşikler yaygın uygulamaya yakındır: en iyi hamleyle arasında çeyrek
  /// piyondan az fark olan hamle iyidir, bir piyonu aşan kayıp hatadır.
  static MoveQuality classify({
    required int cpLoss,
    required bool wasBestMove,
  }) {
    if (cpLoss <= 25) {
      return wasBestMove ? MoveQuality.brilliant : MoveQuality.good;
    }
    if (cpLoss <= 100) return MoveQuality.dubious;
    return MoveQuality.bad;
  }

  /// Oyunu değerlendirir. [isCancelled] doğru dönerse yarıda kesilir ve
  /// `null` döner.
  static Future<GameAnalysis?> analyze({
    required ChessEngine engine,
    required String startFen,
    required List<String> uciMoves,
    int bookPlies = 0,
    SearchLimits limits = const SearchLimits(depth: 12, moveTimeMs: 600),
    void Function(int done, int total)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final positions = <Position>[Chess.fromSetup(Setup.parseFen(startFen))];
    for (final uci in uciMoves) {
      final position = positions.last;
      final move = position.normalizeMove(NormalMove.fromUci(uci));
      positions.add(position.play(move));
    }

    final whiteCp = List<int>.filled(positions.length, 0);
    final bestUci = List<String?>.filled(positions.length, null);

    for (int i = 0; i < positions.length; i++) {
      if (isCancelled?.call() ?? false) return null;
      final position = positions[i];
      if (position.isGameOver) {
        // Motor bitmiş pozisyonda hamle üretmez; sonucu kural katmanı verir.
        whiteCp[i] = position.isCheckmate
            ? (position.turn == Side.white ? -mateScore : mateScore)
            : 0;
      } else {
        final result = await engine.search(
          fen: startFen,
          movesUci: uciMoves.sublist(0, i),
          limits: limits,
        );
        final line = result.principalVariation;
        whiteCp[i] = line == null
            ? 0
            : whiteCentipawns(line, sideToMove: position.turn);
        bestUci[i] = result.bestMoveUci;
      }
      onProgress?.call(i + 1, positions.length);
    }

    final qualities = <MoveQuality>[];
    final losses = <int>[];
    for (int i = 0; i < uciMoves.length; i++) {
      final mover = positions[i].turn;
      var loss = mover == Side.white
          ? whiteCp[i] - whiteCp[i + 1]
          : whiteCp[i + 1] - whiteCp[i];
      if (loss < 0) loss = 0;
      losses.add(loss);
      qualities.add(
        i < bookPlies
            ? MoveQuality.book
            : classify(cpLoss: loss, wasBestMove: uciMoves[i] == bestUci[i]),
      );
    }
    return GameAnalysis(qualities: qualities, cpLoss: losses, whiteCp: whiteCp);
  }
}
