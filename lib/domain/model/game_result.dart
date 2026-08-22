import 'package:dartchess/dartchess.dart';

import '../match/match_protocol.dart';

/// Bitmiş bir oyunun sonucu.
class GameResult {
  /// Kazanan taraf. Beraberlikte `null`.
  final Side? winner;
  final GameEndReason reason;

  const GameResult({required this.reason, this.winner});

  bool get isDraw => winner == null;

  /// PGN `Result` etiketi.
  String get pgnResult => switch (winner) {
    Side.white => '1-0',
    Side.black => '0-1',
    null => '1/2-1/2',
  };

  String headline(bool turkish, {Side? localSide}) {
    if (isDraw) return turkish ? 'Beraberlik' : 'Draw';
    if (localSide != null) {
      final won = winner == localSide;
      if (turkish) return won ? 'Kazandınız' : 'Kaybettiniz';
      return won ? 'You won' : 'You lost';
    }
    if (turkish) {
      return winner == Side.white ? 'Beyaz kazandı' : 'Siyah kazandı';
    }
    return winner == Side.white ? 'White wins' : 'Black wins';
  }

  String detail(bool turkish) => switch (reason) {
    GameEndReason.checkmate => turkish ? 'Şah mat' : 'By checkmate',
    GameEndReason.stalemate => turkish ? 'Pat' : 'Stalemate',
    GameEndReason.resignation => turkish ? 'Terk' : 'By resignation',
    GameEndReason.timeout => turkish ? 'Süre bitti' : 'On time',
    GameEndReason.drawAgreement =>
      turkish ? 'Anlaşmalı beraberlik' : 'By agreement',
    GameEndReason.threefoldRepetition =>
      turkish ? 'Üç kez tekrar' : 'Threefold repetition',
    GameEndReason.fiftyMoveRule =>
      turkish ? 'Elli hamle kuralı' : 'Fifty-move rule',
    GameEndReason.insufficientMaterial =>
      turkish ? 'Yetersiz materyal' : 'Insufficient material',
    GameEndReason.abandoned => turkish ? 'Yarıda bırakıldı' : 'Abandoned',
  };

  Map<String, Object?> toJson() => {
    'winner': winner?.name,
    'reason': reason.name,
  };

  static GameResult fromJson(Map<String, Object?> json) => GameResult(
    reason: GameEndReason.values.firstWhere(
      (r) => r.name == json['reason'],
      orElse: () => GameEndReason.abandoned,
    ),
    winner: switch (json['winner']) {
      'white' => Side.white,
      'black' => Side.black,
      _ => null,
    },
  );
}
