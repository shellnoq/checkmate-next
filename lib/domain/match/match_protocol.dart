import 'package:dartchess/dartchess.dart';

import '../model/difficulty.dart';
import '../model/time_control.dart';

/// Maçın hangi rakiple oynandığı.
enum MatchKind {
  /// Cihaz üzerindeki Stockfish motoruna karşı.
  engine,

  /// Aynı cihazda iki oyuncu.
  passAndPlay,

  /// Uzak sunucu üzerinden gerçek rakip. (Bkz. `remote_match_transport.dart`)
  online,
}

/// Taşıma katmanının bağlantı durumu. Çevrimdışı modlarda daima [connected].
enum MatchConnectionState { idle, connecting, connected, reconnecting, closed }

/// Oyunun bitiş nedeni.
enum GameEndReason {
  checkmate,
  stalemate,
  resignation,
  timeout,
  drawAgreement,
  threefoldRepetition,
  fiftyMoveRule,
  insufficientMaterial,
  abandoned,
}

/// Bir maçın kurulum parametreleri.
class MatchConfig {
  /// Maçın kimliği. Çevrimdışı maçlarda yerel olarak üretilir, online maçta
  /// sunucudan gelir.
  final String matchId;
  final MatchKind kind;

  /// Yerel oyuncunun rengi. [MatchKind.passAndPlay] için anlamsızdır.
  final Side localSide;

  /// Motor rakip için zorluk. Online maçta `null`.
  final DifficultyLevel? difficulty;

  final TimeControl timeControl;

  /// Başlangıç pozisyonu (FEN). Standart oyunda ilk pozisyon.
  final String startingFen;

  /// Online maçta rakibin görünen adı.
  final String? opponentName;

  const MatchConfig({
    required this.matchId,
    required this.kind,
    required this.localSide,
    required this.timeControl,
    this.difficulty,
    this.startingFen = kInitialFEN,
    this.opponentName,
  });

  Map<String, Object?> toJson() => {
        'matchId': matchId,
        'kind': kind.name,
        'localSide': localSide.name,
        'difficulty': difficulty?.id,
        'timeControl': {
          'id': timeControl.id,
          'initialMs': timeControl.initial.inMilliseconds,
          'incrementMs': timeControl.increment.inMilliseconds,
        },
        'startingFen': startingFen,
        'opponentName': opponentName,
      };

  static MatchConfig fromJson(Map<String, Object?> json) => MatchConfig(
        matchId: json['matchId']! as String,
        kind: MatchKind.values
            .firstWhere((k) => k.name == json['kind'], orElse: () => MatchKind.engine),
        localSide: json['localSide'] == 'black' ? Side.black : Side.white,
        difficulty: json['difficulty'] == null
            ? null
            : DifficultyLevel.fromId(json['difficulty'] as String),
        timeControl: TimeControl.fromId(
            (json['timeControl'] as Map?)?['id'] as String?),
        startingFen: (json['startingFen'] as String?) ?? kInitialFEN,
        opponentName: json['opponentName'] as String?,
      );
}

// ── Uygulamadan taşıma katmanına giden komutlar ──

/// İstemcinin rakibe/sunucuya gönderdiği komut.
sealed class MatchCommand {
  const MatchCommand();

  Map<String, Object?> toJson();

  static MatchCommand fromJson(Map<String, Object?> json) {
    return switch (json['type']) {
      'move' => SubmitMove(
          uci: json['uci']! as String,
          remainingMs: json['remainingMs'] as int?,
        ),
      'resign' => const ResignMatch(),
      'offerDraw' => const OfferDraw(),
      'respondDraw' => RespondToDrawOffer(accept: json['accept']! as bool),
      'takeback' => const RequestTakeback(),
      'rematch' => const RequestRematch(),
      _ => throw FormatException('Bilinmeyen komut: ${json['type']}'),
    };
  }
}

class SubmitMove extends MatchCommand {
  final String uci;

  /// Hamleyi yapan oyuncunun kalan süresi (ms). Sunucu saat doğrulaması için.
  final int? remainingMs;

  const SubmitMove({required this.uci, this.remainingMs});

  @override
  Map<String, Object?> toJson() =>
      {'type': 'move', 'uci': uci, 'remainingMs': remainingMs};
}

class ResignMatch extends MatchCommand {
  const ResignMatch();
  @override
  Map<String, Object?> toJson() => {'type': 'resign'};
}

class OfferDraw extends MatchCommand {
  const OfferDraw();
  @override
  Map<String, Object?> toJson() => {'type': 'offerDraw'};
}

class RespondToDrawOffer extends MatchCommand {
  final bool accept;
  const RespondToDrawOffer({required this.accept});
  @override
  Map<String, Object?> toJson() => {'type': 'respondDraw', 'accept': accept};
}

class RequestTakeback extends MatchCommand {
  const RequestTakeback();
  @override
  Map<String, Object?> toJson() => {'type': 'takeback'};
}

class RequestRematch extends MatchCommand {
  const RequestRematch();
  @override
  Map<String, Object?> toJson() => {'type': 'rematch'};
}

// ── Taşıma katmanından uygulamaya gelen olaylar ──

/// Rakipten/sunucudan uygulamaya ulaşan olay.
sealed class MatchEvent {
  const MatchEvent();

  Map<String, Object?> toJson();

  static MatchEvent fromJson(Map<String, Object?> json) {
    return switch (json['type']) {
      'opened' => MatchOpened(
          MatchConfig.fromJson(json['config']! as Map<String, Object?>)),
      'move' => RemoteMove(
          uci: json['uci']! as String,
          remainingMs: json['remainingMs'] as int?,
        ),
      'thinking' => RemoteThinking(json['value']! as bool),
      'drawOffer' => const RemoteDrawOffer(),
      'takebackAccepted' => RemoteTakebackAccepted(json['plies']! as int),
      'ended' => MatchEnded(
          reason: GameEndReason.values
              .firstWhere((r) => r.name == json['reason']),
          winner: switch (json['winner']) {
            'white' => Side.white,
            'black' => Side.black,
            _ => null,
          },
        ),
      'connection' => MatchConnectionChanged(MatchConnectionState.values
          .firstWhere((s) => s.name == json['state'])),
      _ => throw FormatException('Bilinmeyen olay: ${json['type']}'),
    };
  }
}

class MatchOpened extends MatchEvent {
  final MatchConfig config;
  const MatchOpened(this.config);
  @override
  Map<String, Object?> toJson() =>
      {'type': 'opened', 'config': config.toJson()};
}

/// Rakibin oynadığı hamle.
class RemoteMove extends MatchEvent {
  final String uci;
  final int? remainingMs;
  const RemoteMove({required this.uci, this.remainingMs});
  @override
  Map<String, Object?> toJson() =>
      {'type': 'move', 'uci': uci, 'remainingMs': remainingMs};
}

/// Rakip düşünüyor (motor arıyor / online rakip bağlı ve sırası).
class RemoteThinking extends MatchEvent {
  final bool value;
  const RemoteThinking(this.value);
  @override
  Map<String, Object?> toJson() => {'type': 'thinking', 'value': value};
}

class RemoteDrawOffer extends MatchEvent {
  const RemoteDrawOffer();
  @override
  Map<String, Object?> toJson() => {'type': 'drawOffer'};
}

/// Geri alma isteği kabul edildi; [plies] yarım hamle geri alınacak.
class RemoteTakebackAccepted extends MatchEvent {
  final int plies;
  const RemoteTakebackAccepted(this.plies);
  @override
  Map<String, Object?> toJson() =>
      {'type': 'takebackAccepted', 'plies': plies};
}

class MatchEnded extends MatchEvent {
  final GameEndReason reason;

  /// Kazanan taraf. Beraberlikte `null`.
  final Side? winner;
  const MatchEnded({required this.reason, this.winner});
  @override
  Map<String, Object?> toJson() =>
      {'type': 'ended', 'reason': reason.name, 'winner': winner?.name};
}

class MatchConnectionChanged extends MatchEvent {
  final MatchConnectionState state;
  const MatchConnectionChanged(this.state);
  @override
  Map<String, Object?> toJson() =>
      {'type': 'connection', 'state': state.name};
}

/// Taşıma katmanında kurtarılamayan hata.
class MatchFailure extends MatchEvent {
  final Object error;
  const MatchFailure(this.error);
  @override
  Map<String, Object?> toJson() =>
      {'type': 'failure', 'error': error.toString()};
}
