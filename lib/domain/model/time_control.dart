/// Süre kontrolü tanımı. `initial` sıfırsa oyun süresizdir.
class TimeControl {
  /// Oyuncu başına başlangıç süresi.
  final Duration initial;

  /// Her hamleden sonra eklenen süre (Fischer artışı).
  final Duration increment;

  final String id;
  final String trName;
  final String enName;

  const TimeControl({
    required this.id,
    required this.trName,
    required this.enName,
    required this.initial,
    this.increment = Duration.zero,
  });

  bool get isUnlimited => initial == Duration.zero;

  String label(bool turkish) => turkish ? trName : enName;

  /// `5+3` biçiminde kısa gösterim.
  String get shortLabel => isUnlimited
      ? '∞'
      : '${initial.inMinutes}+${increment.inSeconds}';

  static const unlimited = TimeControl(
    id: 'unlimited',
    trName: 'Süresiz',
    enName: 'Unlimited',
    initial: Duration.zero,
  );

  static const bullet1 = TimeControl(
    id: 'bullet1',
    trName: 'Bullet',
    enName: 'Bullet',
    initial: Duration(minutes: 1),
  );

  static const blitz3plus2 = TimeControl(
    id: 'blitz3plus2',
    trName: 'Blitz',
    enName: 'Blitz',
    initial: Duration(minutes: 3),
    increment: Duration(seconds: 2),
  );

  static const blitz5 = TimeControl(
    id: 'blitz5',
    trName: 'Blitz',
    enName: 'Blitz',
    initial: Duration(minutes: 5),
  );

  static const rapid10 = TimeControl(
    id: 'rapid10',
    trName: 'Hızlı',
    enName: 'Rapid',
    initial: Duration(minutes: 10),
  );

  static const rapid15plus10 = TimeControl(
    id: 'rapid15plus10',
    trName: 'Hızlı',
    enName: 'Rapid',
    initial: Duration(minutes: 15),
    increment: Duration(seconds: 10),
  );

  static const classical30 = TimeControl(
    id: 'classical30',
    trName: 'Klasik',
    enName: 'Classical',
    initial: Duration(minutes: 30),
    increment: Duration(seconds: 20),
  );

  static const presets = <TimeControl>[
    unlimited,
    bullet1,
    blitz3plus2,
    blitz5,
    rapid10,
    rapid15plus10,
    classical30,
  ];

  static TimeControl fromId(String? id) =>
      presets.firstWhere((t) => t.id == id, orElse: () => rapid10);
}
