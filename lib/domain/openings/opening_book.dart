import 'package:dartchess/dartchess.dart';

import '../model/uci_standard.dart';

/// Açılış ailesi.
enum OpeningCategory { open, semiOpen, closed, flank }

/// Tek bir açılış satırı.
///
/// Hamleler SAN olarak yazılır; okunması ve elle doğrulanması kolaydır.
/// UCI karşılığı ilk erişimde başlangıç konumundan oynanarak üretilir, bu
/// yüzden tablodaki her satırın yasal olduğu çalışma anında da garantidir
/// (testler ayrıca tümünü doğrular).
class Opening {
  Opening(this.eco, this.trName, this.enName, this.category, this.san);

  final String eco;
  final String trName;
  final String enName;
  final OpeningCategory category;
  final String san;

  late final List<String> uci = compileSanLine(san);

  String label(bool turkish) => turkish ? trName : enName;
}

/// SAN dizisini başlangıç konumundan oynayarak standart UCI listesine çevirir.
List<String> compileSanLine(String sanLine) {
  Position position = Chess.initial;
  final result = <String>[];
  for (final san in sanLine.split(' ')) {
    final move = position.parseSan(san);
    if (move == null) {
      throw StateError('Geçersiz SAN: "$san" ($sanLine)');
    }
    result.add(
      move is NormalMove ? standardizeCastlingUci(position, move) : move.uci,
    );
    position = position.play(move);
  }
  return result;
}

/// Dünya açılış ve savunmalarının derlemesi.
class OpeningBook {
  OpeningBook._();

  static final List<Opening> all = [
    // ── Açık oyunlar (1.e4 e5) ──
    Opening('C20', 'Açık Oyun', 'Open Game', OpeningCategory.open, 'e4 e5'),
    Opening(
      'C25',
      'Viyana Açılışı',
      'Vienna Game',
      OpeningCategory.open,
      'e4 e5 Nc3',
    ),
    Opening(
      'C30',
      'Şah Gambiti',
      "King's Gambit",
      OpeningCategory.open,
      'e4 e5 f4',
    ),
    Opening(
      'C33',
      'Şah Gambiti Kabul',
      "King's Gambit Accepted",
      OpeningCategory.open,
      'e4 e5 f4 exf4',
    ),
    Opening(
      'C21',
      'Merkez Açılışı',
      'Center Game',
      OpeningCategory.open,
      'e4 e5 d4 exd4',
    ),
    Opening(
      'C23',
      'Fil Açılışı',
      "Bishop's Opening",
      OpeningCategory.open,
      'e4 e5 Bc4',
    ),
    Opening(
      'C40',
      'Letonya Gambiti',
      'Latvian Gambit',
      OpeningCategory.open,
      'e4 e5 Nf3 f5',
    ),
    Opening(
      'C41',
      'Philidor Savunması',
      'Philidor Defence',
      OpeningCategory.open,
      'e4 e5 Nf3 d6',
    ),
    Opening(
      'C42',
      'Petrov Savunması',
      'Petroff Defence',
      OpeningCategory.open,
      'e4 e5 Nf3 Nf6',
    ),
    Opening(
      'C44',
      'Ponziani Açılışı',
      'Ponziani Opening',
      OpeningCategory.open,
      'e4 e5 Nf3 Nc6 c3',
    ),
    Opening(
      'C45',
      'İskoç Açılışı',
      'Scotch Game',
      OpeningCategory.open,
      'e4 e5 Nf3 Nc6 d4 exd4 Nxd4',
    ),
    Opening(
      'C47',
      'Dört At Açılışı',
      'Four Knights Game',
      OpeningCategory.open,
      'e4 e5 Nf3 Nc6 Nc3 Nf6',
    ),
    Opening(
      'C50',
      'İtalyan Açılışı',
      'Italian Game',
      OpeningCategory.open,
      'e4 e5 Nf3 Nc6 Bc4',
    ),
    Opening(
      'C53',
      'Giuoco Piano',
      'Giuoco Piano',
      OpeningCategory.open,
      'e4 e5 Nf3 Nc6 Bc4 Bc5 c3',
    ),
    Opening(
      'C51',
      'Evans Gambiti',
      'Evans Gambit',
      OpeningCategory.open,
      'e4 e5 Nf3 Nc6 Bc4 Bc5 b4',
    ),
    Opening(
      'C55',
      'İki At Savunması',
      'Two Knights Defence',
      OpeningCategory.open,
      'e4 e5 Nf3 Nc6 Bc4 Nf6',
    ),
    Opening(
      'C60',
      'İspanyol Açılışı',
      'Ruy Lopez',
      OpeningCategory.open,
      'e4 e5 Nf3 Nc6 Bb5',
    ),
    Opening(
      'C65',
      'İspanyol, Berlin Savunması',
      'Ruy Lopez, Berlin Defence',
      OpeningCategory.open,
      'e4 e5 Nf3 Nc6 Bb5 Nf6',
    ),
    Opening(
      'C68',
      'İspanyol, Değişim Varyantı',
      'Ruy Lopez, Exchange',
      OpeningCategory.open,
      'e4 e5 Nf3 Nc6 Bb5 a6 Bxc6',
    ),
    Opening(
      'C84',
      'İspanyol, Kapalı',
      'Ruy Lopez, Closed',
      OpeningCategory.open,
      'e4 e5 Nf3 Nc6 Bb5 a6 Ba4 Nf6 O-O Be7',
    ),

    // ── Yarı açık oyunlar (1.e4 diğer) ──
    Opening(
      'B00',
      'Nimzowitsch Savunması',
      'Nimzowitsch Defence',
      OpeningCategory.semiOpen,
      'e4 Nc6',
    ),
    Opening(
      'B01',
      'İskandinav Savunması',
      'Scandinavian Defence',
      OpeningCategory.semiOpen,
      'e4 d5',
    ),
    Opening(
      'B02',
      'Alekhine Savunması',
      "Alekhine's Defence",
      OpeningCategory.semiOpen,
      'e4 Nf6',
    ),
    Opening(
      'B06',
      'Modern Savunma',
      'Modern Defence',
      OpeningCategory.semiOpen,
      'e4 g6',
    ),
    Opening(
      'B07',
      'Pirc Savunması',
      'Pirc Defence',
      OpeningCategory.semiOpen,
      'e4 d6 d4 Nf6 Nc3 g6',
    ),
    Opening(
      'B10',
      'Caro-Kann Savunması',
      'Caro-Kann Defence',
      OpeningCategory.semiOpen,
      'e4 c6',
    ),
    Opening(
      'B12',
      'Caro-Kann, İlerleme',
      'Caro-Kann, Advance',
      OpeningCategory.semiOpen,
      'e4 c6 d4 d5 e5',
    ),
    Opening(
      'B18',
      'Caro-Kann, Klasik',
      'Caro-Kann, Classical',
      OpeningCategory.semiOpen,
      'e4 c6 d4 d5 Nc3 dxe4 Nxe4 Bf5',
    ),
    Opening(
      'B20',
      'Sicilya Savunması',
      'Sicilian Defence',
      OpeningCategory.semiOpen,
      'e4 c5',
    ),
    Opening(
      'B22',
      'Sicilya, Alapin',
      'Sicilian, Alapin',
      OpeningCategory.semiOpen,
      'e4 c5 c3',
    ),
    Opening(
      'B23',
      'Sicilya, Kapalı',
      'Sicilian, Closed',
      OpeningCategory.semiOpen,
      'e4 c5 Nc3',
    ),
    Opening(
      'B33',
      'Sicilya, Sveshnikov',
      'Sicilian, Sveshnikov',
      OpeningCategory.semiOpen,
      'e4 c5 Nf3 Nc6 d4 cxd4 Nxd4 Nf6 Nc3 e5',
    ),
    Opening(
      'B70',
      'Sicilya, Ejderha',
      'Sicilian, Dragon',
      OpeningCategory.semiOpen,
      'e4 c5 Nf3 d6 d4 cxd4 Nxd4 Nf6 Nc3 g6',
    ),
    Opening(
      'B90',
      'Sicilya, Najdorf',
      'Sicilian, Najdorf',
      OpeningCategory.semiOpen,
      'e4 c5 Nf3 d6 d4 cxd4 Nxd4 Nf6 Nc3 a6',
    ),
    Opening(
      'C00',
      'Fransız Savunması',
      'French Defence',
      OpeningCategory.semiOpen,
      'e4 e6',
    ),
    Opening(
      'C02',
      'Fransız, İlerleme',
      'French, Advance',
      OpeningCategory.semiOpen,
      'e4 e6 d4 d5 e5',
    ),
    Opening(
      'C11',
      'Fransız, Klasik',
      'French, Classical',
      OpeningCategory.semiOpen,
      'e4 e6 d4 d5 Nc3 Nf6',
    ),
    Opening(
      'C15',
      'Fransız, Winawer',
      'French, Winawer',
      OpeningCategory.semiOpen,
      'e4 e6 d4 d5 Nc3 Bb4',
    ),

    // ── Kapalı oyunlar (1.d4) ──
    Opening(
      'A40',
      'Vezir Piyonu Açılışı',
      "Queen's Pawn Opening",
      OpeningCategory.closed,
      'd4',
    ),
    Opening(
      'D00',
      'Kapalı Oyun',
      'Closed Game',
      OpeningCategory.closed,
      'd4 d5',
    ),
    Opening(
      'A45',
      'Trompowsky Atağı',
      'Trompowsky Attack',
      OpeningCategory.closed,
      'd4 Nf6 Bg5',
    ),
    Opening(
      'A52',
      'Budapeşte Gambiti',
      'Budapest Gambit',
      OpeningCategory.closed,
      'd4 Nf6 c4 e5',
    ),
    Opening(
      'A57',
      'Benko Gambiti',
      'Benko Gambit',
      OpeningCategory.closed,
      'd4 Nf6 c4 c5 d5 b5',
    ),
    Opening(
      'A60',
      'Modern Benoni',
      'Modern Benoni',
      OpeningCategory.closed,
      'd4 Nf6 c4 c5 d5 e6',
    ),
    Opening(
      'A80',
      'Hollanda Savunması',
      'Dutch Defence',
      OpeningCategory.closed,
      'd4 f5',
    ),
    Opening(
      'D02',
      'Londra Sistemi',
      'London System',
      OpeningCategory.closed,
      'd4 d5 Nf3 Nf6 Bf4',
    ),
    Opening(
      'D05',
      'Colle Sistemi',
      'Colle System',
      OpeningCategory.closed,
      'd4 d5 Nf3 Nf6 e3',
    ),
    Opening(
      'D06',
      'Vezir Gambiti',
      "Queen's Gambit",
      OpeningCategory.closed,
      'd4 d5 c4',
    ),
    Opening(
      'D20',
      'Vezir Gambiti Kabul',
      "Queen's Gambit Accepted",
      OpeningCategory.closed,
      'd4 d5 c4 dxc4',
    ),
    Opening(
      'D30',
      'Vezir Gambiti Reddi',
      "Queen's Gambit Declined",
      OpeningCategory.closed,
      'd4 d5 c4 e6',
    ),
    Opening(
      'D10',
      'Slav Savunması',
      'Slav Defence',
      OpeningCategory.closed,
      'd4 d5 c4 c6',
    ),
    Opening(
      'D43',
      'Yarı-Slav Savunması',
      'Semi-Slav Defence',
      OpeningCategory.closed,
      'd4 d5 c4 c6 Nf3 Nf6 Nc3 e6',
    ),
    Opening(
      'D80',
      'Grünfeld Savunması',
      'Grünfeld Defence',
      OpeningCategory.closed,
      'd4 Nf6 c4 g6 Nc3 d5',
    ),
    Opening(
      'E00',
      'Katalan Açılışı',
      'Catalan Opening',
      OpeningCategory.closed,
      'd4 Nf6 c4 e6 g3',
    ),
    Opening(
      'E12',
      'Vezir Hindi Savunması',
      "Queen's Indian Defence",
      OpeningCategory.closed,
      'd4 Nf6 c4 e6 Nf3 b6',
    ),
    Opening(
      'E20',
      'Nimzo-Hint Savunması',
      'Nimzo-Indian Defence',
      OpeningCategory.closed,
      'd4 Nf6 c4 e6 Nc3 Bb4',
    ),
    Opening(
      'E60',
      'Şah Hindi Savunması',
      "King's Indian Defence",
      OpeningCategory.closed,
      'd4 Nf6 c4 g6',
    ),
    Opening(
      'E90',
      'Şah Hindi, Klasik',
      "King's Indian, Classical",
      OpeningCategory.closed,
      'd4 Nf6 c4 g6 Nc3 Bg7 e4 d6 Nf3',
    ),

    // ── Kanat açılışları ──
    Opening(
      'A00',
      'Sokolsky Açılışı',
      'Sokolsky Opening',
      OpeningCategory.flank,
      'b4',
    ),
    Opening(
      'A01',
      'Larsen Açılışı',
      "Larsen's Opening",
      OpeningCategory.flank,
      'b3',
    ),
    Opening(
      'A02',
      'Bird Açılışı',
      "Bird's Opening",
      OpeningCategory.flank,
      'f4',
    ),
    Opening(
      'A04',
      'Réti Açılışı',
      'Réti Opening',
      OpeningCategory.flank,
      'Nf3',
    ),
    Opening(
      'A07',
      'Şah Hindi Atağı',
      "King's Indian Attack",
      OpeningCategory.flank,
      'Nf3 d5 g3',
    ),
    Opening(
      'A09',
      'Réti Gambiti',
      'Réti Gambit',
      OpeningCategory.flank,
      'Nf3 d5 c4',
    ),
    Opening(
      'A10',
      'İngiliz Açılışı',
      'English Opening',
      OpeningCategory.flank,
      'c4',
    ),
    Opening(
      'A20',
      'İngiliz, Ters Sicilya',
      'English, Reversed Sicilian',
      OpeningCategory.flank,
      'c4 e5',
    ),
    Opening(
      'A30',
      'İngiliz, Simetrik',
      'English, Symmetrical',
      OpeningCategory.flank,
      'c4 c5',
    ),
  ];

  /// Oyunun tamamen içinden geçtiği en derin satır; yoksa `null`.
  static Opening? identify(List<String> uciMoves) {
    Opening? best;
    for (final opening in all) {
      final line = opening.uci;
      if (line.length > uciMoves.length) continue;
      if (line.length <= (best?.uci.length ?? 0)) continue;
      var matches = true;
      for (int i = 0; i < line.length; i++) {
        if (line[i] != uciMoves[i]) {
          matches = false;
          break;
        }
      }
      if (matches) best = opening;
    }
    return best;
  }

  /// Oyunun başından itibaren kitap içinde kalan yarım hamle sayısı:
  /// ilk `k` hamlenin herhangi bir satırın öneki olduğu en büyük `k`.
  static int bookPlies(List<String> uciMoves) {
    var best = 0;
    for (final opening in all) {
      final line = opening.uci;
      var common = 0;
      final limit = line.length < uciMoves.length
          ? line.length
          : uciMoves.length;
      while (common < limit && line[common] == uciMoves[common]) {
        common++;
      }
      if (common > best) best = common;
    }
    return best;
  }
}
