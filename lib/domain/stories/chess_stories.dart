/// Bir hikâyenin tek paragrafı.
class StoryParagraph {
  const StoryParagraph(this.tr, this.en);

  final String tr;
  final String en;

  String text(bool turkish) => turkish ? tr : en;
}

/// Çocuklara yönelik, sesli okunabilen satranç hikâyesi.
class ChessStory {
  const ChessStory({
    required this.id,
    required this.trTitle,
    required this.enTitle,
    required this.paragraphs,
  });

  final String id;
  final String trTitle;
  final String enTitle;
  final List<StoryParagraph> paragraphs;

  String title(bool turkish) => turkish ? trTitle : enTitle;
}

class StorySet {
  StorySet._();

  static const all = [
    ChessStory(
      id: 'wheat',
      trTitle: 'Satranç ve Buğday Taneleri',
      enTitle: 'Chess and the Grains of Wheat',
      paragraphs: [
        StoryParagraph(
          'Çok eski zamanlarda bir bilge, kralına yepyeni bir oyun getirdi: '
              'altmış dört kareli bir tahta ve üzerinde küçük bir ordu.',
          'Long ago, a wise man brought his king a brand-new game: a board '
              'of sixty-four squares and a little army upon it.',
        ),
        StoryParagraph(
          'Kral oyunu o kadar sevdi ki, "Dile benden ne dilersen!" dedi.',
          'The king loved the game so much that he said, "Ask of me '
              'whatever you wish!"',
        ),
        StoryParagraph(
          'Bilge gülümsedi: "Yalnızca buğday isterim. İlk kareye bir tane, '
              'ikinciye iki, üçüncüye dört... Her karede bir öncekinin iki katı."',
          'The wise man smiled: "Only wheat. One grain on the first '
              'square, two on the second, four on the third... each square '
              'double the one before."',
        ),
        StoryParagraph(
          'Kral güldü: "Bu kadar azı mı?" Ama saymaya başlayınca yüzü '
              'değişti. Sayı büyüdükçe büyüdü; krallığın bütün ambarları bile '
              'yetmezdi.',
          'The king laughed: "So little?" But as the counting began his '
              'face changed. The number grew and grew; every granary in the '
              'kingdom would not suffice.',
        ),
        StoryParagraph(
          'Son karedeki buğday, dünyadaki tüm buğdaydan fazlaydı. Kral o '
              'gün iki şey öğrendi: satrancı ve küçük görünen şeylerin nasıl '
              'dev olabileceğini.',
          'The wheat on the last square was more than all the wheat on '
              'earth. That day the king learned two things: chess, and how '
              'small things can grow into giants.',
        ),
        StoryParagraph(
          'Sen de tahtadaki küçük bir piyonu unutma: doğru beslenirse '
              'vezire dönüşür.',
          'So never overlook a little pawn: nurtured well, it becomes '
              'a queen.',
        ),
      ],
    ),
    ChessStory(
      id: 'opera',
      trTitle: 'Operadaki Maç',
      enTitle: 'The Opera Game',
      paragraphs: [
        StoryParagraph(
          'Yıl 1858. Paris Operasında ışıklar söndü, sahne perdesi açıldı. '
              'Ama en heyecanlı oyun sahnede değildi.',
          'The year is 1858. The lights dim at the Paris Opera and the '
              'curtain rises. But the most thrilling play was not on stage.',
        ),
        StoryParagraph(
          'Bir locada, Amerikalı genç Paul Morphy iki rakibe karşı '
              'oynuyordu. Rakipleri uzun uzun düşünüyor, Morphy ise operayı '
              'izlemek istiyordu.',
          'In a box seat, young Paul Morphy of America faced two '
              'opponents at once. They pondered endlessly; Morphy just '
              'wanted to watch the opera.',
        ),
        StoryParagraph(
          'Bu yüzden hızlı ve cesur oynadı: taşlarını hızla geliştirdi, '
              'atını, filini, vezirini birer birer savaşa sürdü.',
          'So he played fast and brave: he developed quickly, sending '
              'knight, bishop and queen into battle one by one.',
        ),
        StoryParagraph(
          'Sonra en güzel fikrini gösterdi: vezirini feda etti! Herkes '
              'şaşırdı. Ama bir hamle sonra kalesi ve fili matı ördü.',
          'Then came his most beautiful idea: he sacrificed his queen! '
              'Everyone gasped. One move later his rook and bishop wove the '
              'mate.',
        ),
        StoryParagraph(
          'O kısa oyun, bugün bile dünyanın en ünlü satranç partisidir. '
              'Adı: Opera Maçı.',
          'That short game is still the most famous chess game in the '
              'world. Its name: the Opera Game.',
        ),
        StoryParagraph(
          'Ders basit: taşlarını geliştir, şahını koru, fırsat gelince '
              'korkma.',
          'The lesson is simple: develop your pieces, keep your king '
              'safe, and when the chance comes, do not be afraid.',
        ),
      ],
    ),
    ChessStory(
      id: 'machine',
      trTitle: 'Makineye Karşı',
      enTitle: 'Against the Machine',
      paragraphs: [
        StoryParagraph(
          'Bir zamanlar dünyanın en iyi satranç oyuncusu Garry Kasparov, '
              'bambaşka bir rakiple karşılaştı: kocaman bir bilgisayar.',
          'Once, the best chess player in the world, Garry Kasparov, met '
              'a very different opponent: a giant computer.',
        ),
        StoryParagraph(
          'Adı Deep Blue idi. Saniyede iki yüz milyon konumu '
              'hesaplayabiliyordu. Yorulmuyor, heyecanlanmıyor, korkmuyordu.',
          'Its name was Deep Blue. It could weigh two hundred million '
              'positions every second. It never tired, never trembled, '
              'never feared.',
        ),
        StoryParagraph(
          'İlk karşılaşmayı 1996 yılında Kasparov kazandı. Ama makine '
              'öğrenmeye devam etti ve ertesi yıl yeniden geldi.',
          'Kasparov won their first match in 1996. But the machine kept '
              'learning and returned the next year.',
        ),
        StoryParagraph(
          '1997 baharında Deep Blue maçı kazandı. Tarihte ilk kez bir '
              'bilgisayar, dünya şampiyonunu bir maçta yenmişti.',
          'In the spring of 1997 Deep Blue won the match. For the first '
              'time in history, a computer had beaten the world champion.',
        ),
        StoryParagraph(
          'Peki satranç bitti mi? Tam tersi! İnsanlar makinelerden '
              'öğrenmeye başladı. Bu uygulamadaki motor da o makinelerin '
              'torunudur.',
          'Did chess end there? Quite the opposite! People began to '
              'learn from the machines. The engine in this app is their '
              'grandchild.',
        ),
        StoryParagraph(
          'Artık en güçlü oyuncu, makineyle birlikte çalışmayı bilen '
              'insandır.',
          'Today the strongest player is the human who knows how to '
              'work with the machine.',
        ),
      ],
    ),
    ChessStory(
      id: 'polgar',
      trTitle: 'Üç Kız Kardeş',
      enTitle: 'The Three Sisters',
      paragraphs: [
        StoryParagraph(
          'Macaristanda üç kız kardeş yaşardı: Susan, Sofia ve Judit '
              'Polgár. Evlerinde oyuncaklardan çok satranç tahtası vardı.',
          'In Hungary lived three sisters: Susan, Sofia and Judit '
              'Polgár. Their home held more chessboards than toys.',
        ),
        StoryParagraph(
          'O zamanlar herkes "satranç erkek oyunudur" derdi. Kardeşler '
              'buna hiç aldırmadı.',
          'Back then everyone said chess was a game for boys. The '
              'sisters paid no attention at all.',
        ),
        StoryParagraph(
          'En küçükleri Judit, on iki yaşında dünyanın en iyi '
              'oyuncularını yenmeye başladı.',
          'Judit, the youngest, began beating some of the best players '
              'in the world at twelve.',
        ),
        StoryParagraph(
          'On beş yaşında, tarihin en genç büyükustası oldu; bu rekoru '
              'Bobby Fischerdan almıştı.',
          'At fifteen she became the youngest grandmaster in history, '
              'taking the record from Bobby Fischer.',
        ),
        StoryParagraph(
          'Judit kariyeri boyunca on bir dünya şampiyonunu yendi ve '
              'yirmi beş yıl dünyanın bir numaralı kadın oyuncusu kaldı.',
          'Across her career Judit defeated eleven world champions and '
              'stayed the world number one among women for twenty-five '
              'years.',
        ),
        StoryParagraph(
          'Tahtanın kuralı tektir: taşlar kim olduğuna bakmaz, yalnızca '
              'nasıl oynadığına bakar.',
          'The board has one rule: the pieces never ask who you are, '
              'only how you play.',
        ),
      ],
    ),
    ChessStory(
      id: 'losing',
      trTitle: 'Kaybetmeyi Bilen Kazanır',
      enTitle: 'Who Knows How to Lose, Wins',
      paragraphs: [
        StoryParagraph(
          'Küçük Ali turnuvadaki ilk maçını kaybetti ve gözleri doldu. '
              '"Ben satranç bilmiyorum," dedi.',
          'Little Ali lost his first tournament game and his eyes '
              'welled up. "I do not know chess," he said.',
        ),
        StoryParagraph(
          'Antrenörü tahtayı yeniden dizdi: "Bana kaybettiğin anı '
              'göster." Ali hamleleri tek tek oynadı.',
          'His coach set the board again: "Show me the moment you lost." '
              'Ali replayed the moves one by one.',
        ),
        StoryParagraph(
          '"İşte burada filimi unuttum," dedi Ali. Antrenör gülümsedi: '
              '"Gördün mü? Az önce satranç öğrendin."',
          '"Here - I forgot my bishop," said Ali. The coach smiled: '
              '"See? You just learned some chess."',
        ),
        StoryParagraph(
          'O gün Ali her kayıptan sonra aynı şeyi yaptı: tahtayı kurdu, '
              'hatasını buldu, bir daha yapmamaya çalıştı.',
          'From that day, after every loss Ali did the same: set the '
              'board, find the mistake, try not to repeat it.',
        ),
        StoryParagraph(
          'Bir yıl sonra aynı turnuvada kupayı kaldırdı. Kupadan çok, '
              'kaybettiği maçların defterine sevindi.',
          'A year later he lifted the cup at the same tournament. He '
              'was prouder of his notebook of lost games than of the cup.',
        ),
        StoryParagraph(
          'Bu uygulamadaki analiz düğmesi, işte o defterdir. Her '
              'oyundan sonra bir kez bak; hatan sana en iyi öğretmendir.',
          'The analyse button in this app is that notebook. Look once '
              'after every game; your mistake is your best teacher.',
        ),
      ],
    ),
  ];
}
