import 'dart:async';

import 'package:dartchess/dartchess.dart';

import 'model/time_control.dart';

/// Fischer artışlı satranç saati.
///
/// Saat gerçek zamanı `Stopwatch` ile ölçer; periyodik atım yalnızca arayüzü
/// tazelemek içindir. Böylece uygulama arka plana alınıp geri gelse de kalan
/// süre kaymaz.
class ChessClock {
  ChessClock(this.timeControl)
    : _remaining = {
        Side.white: timeControl.initial,
        Side.black: timeControl.initial,
      };

  final TimeControl timeControl;
  final Map<Side, Duration> _remaining;

  Side? _active;
  Stopwatch? _sinceMove;
  Timer? _ticker;

  /// Arayüzün tazelenmesi için her atımda çağrılır.
  void Function()? onTick;

  /// Bir tarafın süresi bittiğinde çağrılır.
  void Function(Side loser)? onFlag;

  bool get isRunning => _active != null;
  Side? get activeSide => _active;

  Duration remainingOf(Side side) {
    var value = _remaining[side]!;
    if (_active == side && _sinceMove != null) {
      value -= _sinceMove!.elapsed;
    }
    return value < Duration.zero ? Duration.zero : value;
  }

  /// Süresiz oyunda saat hiç çalışmaz.
  void start(Side side) {
    if (timeControl.isUnlimited) return;
    _commitElapsed();
    _active = side;
    _sinceMove = Stopwatch()..start();
    _ticker ??= Timer.periodic(const Duration(milliseconds: 200), (_) {
      onTick?.call();
      final active = _active;
      if (active != null && remainingOf(active) <= Duration.zero) {
        stop();
        onFlag?.call(active);
      }
    });
  }

  /// Sıradaki tarafa geçer, biten hamle için artışı ekler.
  void switchTo(Side side) {
    if (timeControl.isUnlimited) return;
    final previous = _active;
    _commitElapsed();
    if (previous != null) {
      _remaining[previous] = _remaining[previous]! + timeControl.increment;
    }
    start(side);
  }

  void pause() {
    if (timeControl.isUnlimited) return;
    _commitElapsed();
    _active = null;
    _sinceMove = null;
  }

  void stop() {
    _commitElapsed();
    _active = null;
    _sinceMove = null;
    _ticker?.cancel();
    _ticker = null;
  }

  void _commitElapsed() {
    final active = _active;
    final sw = _sinceMove;
    if (active != null && sw != null) {
      var value = _remaining[active]! - sw.elapsed;
      if (value < Duration.zero) value = Duration.zero;
      _remaining[active] = value;
    }
    _sinceMove = null;
  }

  void dispose() {
    _ticker?.cancel();
    _ticker = null;
  }
}
