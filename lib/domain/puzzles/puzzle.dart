/// Tek bir mat bulmacası.
class Puzzle {
  const Puzzle({
    required this.id,
    required this.fen,
    required this.mateIn,
    required this.trName,
    required this.enName,
  });

  final String id;
  final String fen;

  /// Sıradaki tarafın kaç kendi hamlesinde mat etmesi gerektiği.
  final int mateIn;

  final String trName;
  final String enName;

  String label(bool turkish) => turkish ? trName : enName;
}

/// Gönderilen bulmaca seti.
///
/// Her konumun tam olarak `mateIn` hamlede zorunlu mat olduğu testlerde
/// [MateSolver] ile kanıtlanır; çözücüden onay almayan konum sete giremez.
class PuzzleSet {
  PuzzleSet._();

  static const all = [
    // ── 1 hamlede mat ──
    Puzzle(
      id: 'm1-backrank',
      fen: '6k1/5ppp/8/8/8/8/8/R3K3 w - - 0 1',
      mateIn: 1,
      trName: 'Arka sıra matı',
      enName: 'Back-rank mate',
    ),
    Puzzle(
      id: 'm1-queen-file',
      fen: '7k/6pp/8/8/8/8/5PPP/3Q3K w - - 0 1',
      mateIn: 1,
      trName: 'Vezir arka sıraya iner',
      enName: 'Queen to the back rank',
    ),
    Puzzle(
      id: 'm1-two-rooks',
      fen: '4k3/R7/8/8/8/8/8/1R2K3 w - - 0 1',
      mateIn: 1,
      trName: 'İki kale merdiveni',
      enName: 'Two-rook ladder',
    ),
    Puzzle(
      id: 'm1-queen-support',
      fen: '7k/8/6K1/8/8/8/8/4Q3 w - - 0 1',
      mateIn: 1,
      trName: 'Şah destekli vezir',
      enName: 'Queen with king support',
    ),
    Puzzle(
      id: 'm1-black-backrank',
      fen: '3r2k1/8/8/8/8/8/5PPP/6K1 b - - 0 1',
      mateIn: 1,
      trName: 'Siyahla arka sıra matı',
      enName: 'Back-rank mate as Black',
    ),
    Puzzle(
      id: 'm1-rook-corner',
      fen: 'k7/8/1K6/8/8/8/8/7R w - - 0 1',
      mateIn: 1,
      trName: 'Köşedeki şah',
      enName: 'King in the corner',
    ),

    // ── 2 hamlede mat ──
    Puzzle(
      id: 'm2-ladder',
      fen: '7k/8/8/8/8/8/R7/1R4K1 w - - 0 1',
      mateIn: 2,
      trName: 'Merdiven kur',
      enName: 'Build the ladder',
    ),
    Puzzle(
      id: 'm2-black-ladder',
      fen: '1r4k1/r7/8/8/8/8/8/7K b - - 0 1',
      mateIn: 2,
      trName: 'Siyahla merdiven',
      enName: 'Ladder as Black',
    ),
    Puzzle(
      id: 'm2-queen-box',
      fen: '6k1/8/5K2/8/8/8/8/4Q3 w - - 0 1',
      mateIn: 2,
      trName: 'Veziri yanaştır',
      enName: 'Walk the queen in',
    ),
    Puzzle(
      id: 'm2-two-rooks-close',
      fen: '6k1/8/8/8/8/8/8/R1R3K1 w - - 0 1',
      mateIn: 2,
      trName: 'Kaleler el ele',
      enName: 'Rooks hand in hand',
    ),

    // ── 3 hamlede mat ──
    Puzzle(
      id: 'm3-rook-pair',
      fen: '7k/5R2/6R1/8/8/8/8/K7 w - - 0 1',
      mateIn: 3,
      trName: 'Kale ikilisi',
      enName: 'The rook pair',
    ),
    Puzzle(
      id: 'm3-ladder-far',
      fen: '8/7k/8/8/8/8/R7/1R4K1 w - - 0 1',
      mateIn: 3,
      trName: 'Uzaktan merdiven',
      enName: 'Ladder from afar',
    ),
    Puzzle(
      id: 'm3-ladder-center',
      fen: '8/8/7k/8/8/8/R7/1R4K1 w - - 0 1',
      mateIn: 3,
      trName: 'Şahı kenara sür',
      enName: 'Drive the king to the edge',
    ),
  ];
}
