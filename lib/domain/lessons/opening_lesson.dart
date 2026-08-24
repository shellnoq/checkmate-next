import '../openings/opening_book.dart' show compileSanLine;

/// Bir dersteki tek yarım hamle.
class LessonPly {
  const LessonPly({
    required this.san,
    required this.isStudent,
    required this.tr,
    required this.en,
  });

  final String san;

  /// Öğrencinin oynaması mı bekleniyor, öğretmen mi oynuyor?
  final bool isStudent;

  final String tr;
  final String en;

  String text(bool turkish) => turkish ? tr : en;
}

/// Adım adım oynanan bir açılış dersi.
///
/// Öğrenci beyazı oynar; siyahın yanıtlarını öğretmen kendisi oynayıp kısa
/// bir notla açıklar. Satırların yasallığı testte, tümü baştan oynanarak
/// kanıtlanır.
class OpeningLesson {
  OpeningLesson({
    required this.id,
    required this.trName,
    required this.enName,
    required this.plies,
  });

  final String id;
  final String trName;
  final String enName;
  final List<LessonPly> plies;

  String label(bool turkish) => turkish ? trName : enName;

  /// SAN dizisinin UCI karşılığı; ilk erişimde oynanarak üretilir.
  late final List<String> uci = compileSanLine(
    plies.map((p) => p.san).join(' '),
  );
}

class LessonSet {
  LessonSet._();

  static final all = <OpeningLesson>[
    OpeningLesson(
      id: 'italian',
      trName: 'İtalyan Açılışı',
      enName: 'Italian Game',
      plies: const [
        LessonPly(
          san: 'e4',
          isStudent: true,
          tr:
              'Merkez piyonunu iki kare sür. Merkezi tutan taraf '
              'taşlarına en iyi kareleri verir.',
          en:
              'Push the king pawn two squares. Whoever holds the centre '
              'gives their pieces the best squares.',
        ),
        LessonPly(
          san: 'e5',
          isStudent: false,
          tr: 'Siyah da aynı hakkı istiyor ve merkezden karşılık veriyor.',
          en: 'Black claims the same right and answers in the centre.',
        ),
        LessonPly(
          san: 'Nf3',
          isStudent: true,
          tr:
              'Atı geliştir ve e5 piyonuna saldır. Açılışta önce hafif '
              'taşlar çıkar.',
          en:
              'Develop the knight and attack the e5 pawn. Minor pieces '
              'come out first in the opening.',
        ),
        LessonPly(
          san: 'Nc6',
          isStudent: false,
          tr: 'Siyah piyonunu en doğal yolla savunuyor: atını geliştirerek.',
          en:
              'Black defends the pawn the most natural way: by developing '
              'a knight.',
        ),
        LessonPly(
          san: 'Bc4',
          isStudent: true,
          tr:
              'Fili en zayıf noktaya, f7 karesine bakan çapraza koy. '
              'Bu diziliş İtalyan Açılışıdır.',
          en:
              'Place the bishop on the diagonal eyeing f7, the weakest '
              'square. This setup is the Italian Game.',
        ),
        LessonPly(
          san: 'Bc5',
          isStudent: false,
          tr: 'Siyah aynayı tutuyor; iki taraf da hızlı gelişiyor.',
          en: 'Black mirrors; both sides develop quickly.',
        ),
        LessonPly(
          san: 'O-O',
          isStudent: true,
          tr:
              'Kısa rok yap: şahını güvene al, kaleni oyuna kat. '
              'Gelişimini bitirmeden saldırıya kalkma.',
          en:
              'Castle short: tuck the king away and connect the rook. '
              'Do not attack before finishing development.',
        ),
        LessonPly(
          san: 'Nf6',
          isStudent: false,
          tr:
              'Siyah da gelişimini sürdürüyor. Ders tamam: merkez, '
              'gelişim, rok.',
          en:
              'Black keeps developing. Lesson learned: centre, '
              'development, castle.',
        ),
      ],
    ),
    OpeningLesson(
      id: 'queens-gambit',
      trName: 'Vezir Gambiti',
      enName: "Queen's Gambit",
      plies: const [
        LessonPly(
          san: 'd4',
          isStudent: true,
          tr:
              'Bu kez vezir piyonuyla başla. Aynı fikir, öteki kanat: '
              'merkezi tut.',
          en:
              'Start with the queen pawn this time. Same idea, other '
              'wing: hold the centre.',
        ),
        LessonPly(
          san: 'd5',
          isStudent: false,
          tr: 'Siyah simetriyle yanıtlıyor.',
          en: 'Black answers symmetrically.',
        ),
        LessonPly(
          san: 'c4',
          isStudent: true,
          tr:
              'Gambit! Piyonu feda ediyor gibisin ama alırsa merkezi '
              'sana bırakır. Bu, Vezir Gambitidir.',
          en:
              'The gambit! It looks like a sacrifice, but taking it '
              "hands you the centre. This is the Queen's Gambit.",
        ),
        LessonPly(
          san: 'e6',
          isStudent: false,
          tr:
              'Siyah piyonu almak yerine d5 karesini sağlamlaştırdı: '
              'Gambit Reddedildi.',
          en:
              'Black declines and shores up d5 instead: the Gambit '
              'Declined.',
        ),
        LessonPly(
          san: 'Nc3',
          isStudent: true,
          tr: 'Atı geliştir ve d5 üzerindeki baskıyı artır.',
          en: 'Develop the knight and add pressure on d5.',
        ),
        LessonPly(
          san: 'Nf6',
          isStudent: false,
          tr: 'Siyah savunan taş sayısını artırıyor.',
          en: 'Black adds a defender.',
        ),
        LessonPly(
          san: 'Nf3',
          isStudent: true,
          tr:
              'İkinci atı da çıkar. Planın: gelişimi bitir, rok yap, '
              'sonra merkezde patlat.',
          en:
              'Bring out the second knight. The plan: finish developing, '
              'castle, then break in the centre.',
        ),
        LessonPly(
          san: 'Be7',
          isStudent: false,
          tr:
              'Siyah rok hazırlığı yapıyor. Bu kurulum yüz yıldır üst '
              'düzey satrancın temel taşıdır.',
          en:
              'Black prepares to castle. This structure has anchored top '
              'chess for a century.',
        ),
      ],
    ),
    OpeningLesson(
      id: 'london',
      trName: 'Londra Sistemi',
      enName: 'London System',
      plies: const [
        LessonPly(
          san: 'd4',
          isStudent: true,
          tr:
              'Londra Sistemi ezber değil düzen ister: hemen her siyah '
              'kuruluşuna karşı aynı dizilişi kurarsın.',
          en:
              'The London is a setup, not a memorised line: you build '
              'the same structure against almost anything.',
        ),
        LessonPly(
          san: 'd5',
          isStudent: false,
          tr: 'Siyah merkezden karşılık veriyor.',
          en: 'Black answers in the centre.',
        ),
        LessonPly(
          san: 'Nf3',
          isStudent: true,
          tr: 'Önce at: fili çıkarmadan e3 oynarsan fil içeride kalır.',
          en:
              'Knight first: play e3 too early and the bishop is '
              'locked in.',
        ),
        LessonPly(
          san: 'Nf6',
          isStudent: false,
          tr: 'Siyah da doğal gelişiyor.',
          en: 'Black develops naturally.',
        ),
        LessonPly(
          san: 'Bf4',
          isStudent: true,
          tr:
              'Sistemin imzası: fil piyon zincirinin dışına, f4 '
              'karesine. Şimdi e3 ile arkasını kapatabilirsin.',
          en:
              "The system's signature: the bishop outside the pawn "
              'chain to f4. Now e3 can close the door behind it.',
        ),
        LessonPly(
          san: 'e6',
          isStudent: false,
          tr: 'Siyah kendi filine yol açıyor.',
          en: 'Black opens a path for its own bishop.',
        ),
        LessonPly(
          san: 'e3',
          isStudent: true,
          tr:
              'Piyon üçgeni tamam: d4-e3 sağlam, fil dışarıda. Kolay '
              'kurulan, zor yıkılan bir düzen.',
          en:
              'The pawn triangle is done: d4-e3 solid, bishop outside. '
              'Easy to build, hard to break.',
        ),
        LessonPly(
          san: 'c5',
          isStudent: false,
          tr: 'Siyah merkeze kanattan vuruyor; Londra buna hazırdır.',
          en:
              'Black strikes the centre from the wing; the London is '
              'ready for it.',
        ),
      ],
    ),
    OpeningLesson(
      id: 'open-sicilian',
      trName: 'Sicilyaya Karşı',
      enName: 'Against the Sicilian',
      plies: const [
        LessonPly(
          san: 'e4',
          isStudent: true,
          tr: 'En sık karşılaşacağın savunmaya hazırlan: Sicilya.',
          en: 'Prepare for the defence you will meet most: the Sicilian.',
        ),
        LessonPly(
          san: 'c5',
          isStudent: false,
          tr:
              'Siyah merkezi kanattan tartışıyor; simetriden kaçıp '
              'kazanç şansı arıyor.',
          en:
              'Black contests the centre from the side, avoiding '
              'symmetry to play for a win.',
        ),
        LessonPly(
          san: 'Nf3',
          isStudent: true,
          tr: 'Gelişim önce: atı çıkar ve d4 kırılımını hazırla.',
          en: 'Development first: bring the knight out and prepare d4.',
        ),
        LessonPly(
          san: 'd6',
          isStudent: false,
          tr: 'Siyah e5 karesini tutuyor ve filine yol açıyor.',
          en: 'Black covers e5 and frees the bishop.',
        ),
        LessonPly(
          san: 'd4',
          isStudent: true,
          tr:
              'Kırılım! Merkezi aç; buna Açık Sicilya denir ve beyazın '
              'en ilkeli yoludur.',
          en:
              'The break! Open the centre; this is the Open Sicilian, '
              "White's most principled path.",
        ),
        LessonPly(
          san: 'cxd4',
          isStudent: false,
          tr: 'Siyah almak zorunda; yoksa merkez beyaza kalır.',
          en: 'Black must take, or the centre falls to White.',
        ),
        LessonPly(
          san: 'Nxd4',
          isStudent: true,
          tr:
              'Atla geri al: at merkezde hüküm sürüyor. Açık hatlar '
              'senin, uzun oyun siyahın.',
          en:
              'Recapture with the knight: it rules the centre. Open '
              'lines are yours, the long game is theirs.',
        ),
        LessonPly(
          san: 'Nf6',
          isStudent: false,
          tr:
              'Siyah e4 piyonuna saldırıyor. Buradan Najdorf ve Ejderha '
              'gibi dev sistemler doğar.',
          en:
              'Black hits e4. From here grow giants like the Najdorf '
              'and the Dragon.',
        ),
      ],
    ),
  ];
}
