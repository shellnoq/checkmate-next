import 'dart:math';

/// Oyun sonunda gösterilen özlü söz.
class EndgameQuote {
  const EndgameQuote(this.tr, this.en, this.author);

  final String tr;
  final String en;
  final String author;

  String text(bool turkish) => turkish ? tr : en;
}

/// Sonuca göre söz havuzu.
///
/// Sözler satranç tarihinin bilinen aforizmalarıdır; kısa alıntı oldukları
/// için kaynak kişinin adıyla birlikte verilir. Kazanana zafer üzerine,
/// kaybedene teselli ve öğrenme üzerine, beraberliğe denge üzerine bir söz
/// düşer.
class EndgameQuotes {
  EndgameQuotes._();

  static const _victory = [
    EndgameQuote(
      'İyi bir hamle bulduğunda, daha iyisini ara.',
      'When you see a good move, look for a better one.',
      'Emanuel Lasker',
    ),
    EndgameQuote(
      'Taktik, ne yapacağını bildiğin anda ne yapacağını bilmektir.',
      'Tactics is knowing what to do when there is something to do.',
      'Savielly Tartakower',
    ),
    EndgameQuote(
      'Satrançta kazanan, sondan bir önceki hatayı yapandır.',
      'The winner is the one who makes the next-to-last mistake.',
      'Savielly Tartakower',
    ),
    EndgameQuote(
      'Sıkı bir oyun, cesur bir fikirle taçlanır.',
      'A sound game is crowned by a brave idea.',
      'Mihail Tal',
    ),
  ];

  static const _defeat = [
    EndgameQuote(
      'Hiç kimse kaybetmeden usta olmadı.',
      'No one ever became a master without losing.',
      'José Raúl Capablanca',
    ),
    EndgameQuote(
      'Kaybettiğim her oyundan, kazandıklarımdan daha çok şey öğrendim.',
      'I learned more from my losses than from my wins.',
      'José Raúl Capablanca',
    ),
    EndgameQuote(
      'Hatalar orada, yapılmayı bekliyor.',
      'The blunders are all there on the board, waiting to be made.',
      'Savielly Tartakower',
    ),
    EndgameQuote(
      'En zor şey, kazanılmış bir oyunu kazanmaktır.',
      'The hardest game to win is a won game.',
      'Emanuel Lasker',
    ),
  ];

  static const _draw = [
    EndgameQuote(
      'Satranç, iki iyi oyuncu arasında adil bir sonuçla biter.',
      'Between two good players, a fair fight ends fairly.',
      'Siegbert Tarrasch',
    ),
    EndgameQuote(
      'Denge de bir sanattır.',
      'Balance, too, is an art.',
      'Anatoli Karpov',
    ),
    EndgameQuote(
      'Satranç, mantığın jimnastiğidir.',
      'Chess is the gymnasium of the mind.',
      'Blaise Pascal',
    ),
  ];

  /// Sonuca uygun havuzdan bir söz seçer.
  ///
  /// [seed] verilirse seçim belirlenimcidir; testler bunu kullanır.
  static EndgameQuote pick({required bool? won, int? seed}) {
    final pool = won == null ? _draw : (won ? _victory : _defeat);
    final random = seed == null ? Random() : Random(seed);
    return pool[random.nextInt(pool.length)];
  }
}
