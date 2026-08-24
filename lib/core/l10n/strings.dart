import 'package:flutter/widgets.dart';

/// Uygulama metinleri. İki dil desteklenir: Türkçe (varsayılan) ve İngilizce.
///
/// ARB/codegen yerine düz eşleme kullanılır: sözlük küçük, derleme zinciri
/// sade kalır ve dil değişimi anlıktır.
class S {
  const S(this.locale);

  final Locale locale;

  bool get tr => locale.languageCode == 'tr';

  static S of(BuildContext context) => S(Localizations.localeOf(context));

  String _(String turkish, String english) => tr ? turkish : english;

  // Genel
  String get appName => 'CheckMate Next';
  String get play => _('Oyna', 'Play');
  String get cancel => _('Vazgeç', 'Cancel');
  String get ok => _('Tamam', 'OK');
  String get yes => _('Evet', 'Yes');
  String get no => _('Hayır', 'No');
  String get close => _('Kapat', 'Close');
  String get back => _('Geri', 'Back');
  String get white => _('Beyaz', 'White');
  String get black => _('Siyah', 'Black');
  String get random => _('Rastgele', 'Random');

  // Ana ekran
  String get playVsEngine => _('Bilgisayara Karşı', 'Play vs Computer');
  String get playVsEngineSub => _(
    'Sekiz zorluk kademesi, Stockfish motoru',
    'Eight levels, Stockfish engine',
  );
  String get passAndPlay => _('İki Kişilik', 'Two Players');
  String get passAndPlaySub =>
      _('Aynı cihazda karşılıklı oyun', 'Share one device');
  String get onlinePlay => _('Çevrimiçi', 'Online');
  String get onlineSoon => _('Yakında', 'Coming soon');
  String get onlineSub =>
      _('Gerçek rakiplerle eşleşme', 'Matchmaking with real opponents');
  String get archive => _('Oyunlarım', 'My Games');
  String get archiveSub => _('Geçmiş oyunlar ve PGN', 'Past games and PGN');
  String get settings => _('Ayarlar', 'Settings');
  String get statistics => _('İstatistikler', 'Statistics');

  // Oyun kurulumu
  String get newGame => _('Yeni Oyun', 'New Game');
  String get difficulty => _('Zorluk', 'Difficulty');
  String get yourColor => _('Renginiz', 'Your Colour');
  String get timeControl => _('Süre', 'Time Control');
  String get startGame => _('Oyunu Başlat', 'Start Game');
  String get estimatedElo => _('Yaklaşık Elo', 'Approx. Elo');

  // Oyun ekranı
  String get thinking => _('Düşünüyor…', 'Thinking…');
  String get yourTurn => _('Sıra sizde', 'Your turn');
  String get resign => _('Terk Et', 'Resign');
  String get offerDraw => _('Beraberlik Öner', 'Offer Draw');
  String get takeback => _('Geri Al', 'Take Back');
  String get hint => _('İpucu', 'Hint');
  String get flipBoard => _('Tahtayı Çevir', 'Flip Board');
  String get tiltBoard => _('Masa Görünümü', 'Table View');
  String get moves => _('Hamleler', 'Moves');
  String get analysis => _('Analiz', 'Analysis');
  String get rematch => _('Yeniden Oyna', 'Rematch');
  String get newGameShort => _('Yeni Oyun', 'New Game');
  String get copyPgn => _('PGN Kopyala', 'Copy PGN');
  String get pgnCopied => _('PGN panoya kopyalandı', 'PGN copied to clipboard');
  String get confirmResign =>
      _('Oyunu terk etmek istiyor musunuz?', 'Resign this game?');
  String get drawOffered =>
      _('Rakip beraberlik öneriyor', 'Your opponent offers a draw');
  String get drawDeclined => _('Beraberlik reddedildi', 'Draw declined');
  String get claimDraw => _('Beraberlik Talep Et', 'Claim Draw');
  String get promotion => _('Terfi', 'Promotion');
  String get engineStarting => _('Motor hazırlanıyor…', 'Starting engine…');
  String get engineFailed => _(
    'Motor başlatılamadı. Uygulamayı yeniden açmayı deneyin.',
    'The engine could not start. Try reopening the app.',
  );

  // Ayarlar
  String get language => _('Dil', 'Language');
  String get ageGroup => _('Yaş grubu', 'Age group');
  String get ageGroupHint => _(
    'Taş takımını ve kutlama yoğunluğunu belirler. Kuralları ve zorluğu '
        'değiştirmez.',
    'Sets the piece style and how lively the celebrations are. It does not '
        'change the rules or the difficulty.',
  );
  String get boardTheme => _('Tahta Teması', 'Board Theme');
  String get pieceSet => _('Taş Takımı', 'Piece Set');
  String get sound => _('Ses', 'Sound');
  String get haptics => _('Titreşim', 'Haptics');
  String get showCoordinates => _('Koordinatlar', 'Coordinates');
  String get showLegalMoves =>
      _('Geçerli hamleleri göster', 'Show legal moves');
  String get showEvaluation => _('Değerlendirme çubuğu', 'Evaluation bar');
  String get autoQueen => _('Otomatik vezir terfisi', 'Auto-promote to queen');
  String get about => _('Hakkında', 'About');
  String get resetStats => _('İstatistikleri sıfırla', 'Reset statistics');

  // Tekrar ve analiz
  String get replay => _('Maç Tekrarı', 'Replay');
  String get analyze => _('Analiz Et', 'Analyse');
  String get qualityBook => _('Kitap hamlesi', 'Book move');
  String get qualityBrilliant => _('Çok iyi', 'Excellent');
  String get qualityGood => _('İyi', 'Good');
  String get qualityDubious => _('Şüpheli', 'Dubious');
  String get qualityBad => _('Kötü', 'Mistake');
  String get noReplayData =>
      _('Bu oyunda tekrar kaydı yok', 'This game has no replay data');
  String get openingLibrary => _('Açılış Kütüphanesi', 'Opening Library');
  String get categoryOpen => _('Açık Oyunlar', 'Open Games');
  String get categorySemiOpen => _('Yarı Açık Oyunlar', 'Semi-Open Games');
  String get categoryClosed => _('Kapalı Oyunlar', 'Closed Games');
  String get categoryFlank => _('Kanat Açılışları', 'Flank Openings');

  // Ana ekran kısa gezinme etiketleri: dar kutulara sığacak tek kelimeler.
  String get navSchool => _('Okul', 'School');
  String get navOpenings => _('Açılışlar', 'Openings');
  String get navPuzzles => _('Bulmacalar', 'Puzzles');
  String get navStories => _('Hikâyeler', 'Stories');
  String get navAwards => _('Başarımlar', 'Awards');
  String get navThemes => _('Temalar', 'Themes');
  String get navGames => _('Oyunlarım', 'My Games');
  String get navSettings => _('Ayarlar', 'Settings');
  String get resumeGame => _('Devam Et', 'Resume');
  String get saveAndExit => _('Kaydet ve Çık', 'Save & Exit');
  String get leaveGameTitle => _('Oyundan çıkılsın mı?', 'Leave the game?');
  String get leaveGameHint => _(
    'Kaydedersen kaldığın yerden devam edebilirsin. Terk edersen oyun '
        'mağlubiyet sayılır.',
    'Save it and you can pick up where you left off. Resigning counts '
        'as a loss.',
  );
  String get gameSaved => _('Oyun kaydedildi', 'Game saved');
  String savedMovesAt(int moves) => _('$moves hamle', '$moves moves');

  // Hikâyeler
  String get stories => _('Hikâyeler', 'Stories');
  String get storyListen => _('Dinle', 'Listen');
  String get storyStop => _('Durdur', 'Stop');

  // Dersler
  String get lessons => _('Açılış Okulu', 'Opening School');
  String get lessonYourTurn => _('Sıra sende, göster kendini', 'Your move');
  String get lessonWrong => _(
    'Olmadı; ipucu okuna bak ve yeniden dene',
    'Not quite; follow the hint arrow and try again',
  );
  String get lessonDone => _('Ders tamamlandı', 'Lesson complete');
  String get teacherVoice => _('Öğretmen sesi', 'Teacher voice');
  String get completedTag => _('Tamamlandı', 'Completed');

  // Tema paketleri
  String get themePacks => _('Tema Paketleri', 'Theme Packs');
  String get owned => _('Sahipsin', 'Owned');
  String get active => _('Etkin', 'Active');
  String get select => _('Seç', 'Select');
  String buyFor(int price) =>
      _('$price coin ile aç', 'Unlock for $price coins');
  String get notEnoughCoins => _('Yeterli coin yok', 'Not enough coins');
  String get musicVolume => _('Fon müziği', 'Background music');

  // Başarımlar ve coin
  String get achievements => _('Başarımlar', 'Achievements');
  String get coins => _('Coin', 'Coins');
  String achievementUnlocked(String name, int coins) =>
      _('Başarım: $name (+$coins coin)', 'Achievement: $name (+$coins coins)');
  String coinsEarned(int coins) => _('+$coins coin', '+$coins coins');
  String get lockedTag => _('Kilitli', 'Locked');

  // Bulmacalar
  String get puzzles => _('Bulmacalar', 'Puzzles');
  String mateInN(int n) => _('$n hamlede mat', 'Mate in $n');
  String get whiteToPlay => _('Beyaz oynar', 'White to play');
  String get blackToPlay => _('Siyah oynar', 'Black to play');
  String get wrongMove =>
      _('Bu hamle matı kaçırıyor', 'That move lets the mate slip');
  String get tryAgain => _('Tekrar Dene', 'Try Again');
  String get puzzleSolvedTitle => _('Aferin!', 'Well done!');
  String get nextPuzzle => _('Sonraki', 'Next');
  String get backToList => _('Listeye Dön', 'Back to List');
  String get solvedTag => _('Çözüldü', 'Solved');

  // Ebeveyn bölümü
  String get parentArea => _('Ebeveyn Bölümü', 'Parent Area');
  String get parentAreaSub =>
      _('Oynama süresi ve günlük sınır', 'Time played and daily limit');
  String get pinCreate => _('Bir PIN belirleyin', 'Choose a PIN');
  String get pinCreateHint => _(
    'Bu bölüme yalnızca siz girebilesiniz diye dört haneli bir sayı seçin.',
    'Pick a four-digit number so only you can open this section.',
  );
  String get pinEnter => _('PIN girin', 'Enter your PIN');
  String get pinEnterHint =>
      _('Ebeveyn bölümüne girmek için', 'To open the parent area');
  String get pinSave => _('Kaydet', 'Save');
  String get pinUnlock => _('Aç', 'Unlock');
  String get pinFourDigits => _('Dört hane girin', 'Enter four digits');
  String get pinWrong => _('PIN yanlış', 'Wrong PIN');
  String get dailyLimit => _('Günlük süre sınırı', 'Daily time limit');
  String get dailyLimitHint => _(
    'Sınır dolduğunda yeni oyun başlatılamaz. Süren oyun yarıda kesilmez.',
    'When the limit is reached no new game can be started. A game in '
        'progress is never interrupted.',
  );
  String get noLimit => _('Sınırsız', 'No limit');
  String get minutesShort => _('dk', 'min');
  String get timePerLevel => _('Kademeye göre süre', 'Time per level');
  String get lastSevenDays => _('Son 7 gün', 'Last 7 days');
  String get today => _('Bugün', 'Today');
  String get overall => _('Toplam', 'Overall');
  String get limitReached =>
      _('Bugünlük oyun süresi doldu', 'Time is up for today');
  String get limitReachedHint => _(
    'Günlük sınıra ulaşıldı. Yarın yeniden oynayabilirsin.',
    'The daily limit has been reached. You can play again tomorrow.',
  );

  // İstatistik
  String get wins => _('Galibiyet', 'Wins');
  String get losses => _('Mağlubiyet', 'Losses');
  String get draws => _('Beraberlik', 'Draws');
  String get gamesPlayed => _('Oynanan oyun', 'Games played');
  String get noGamesYet => _('Henüz oyun yok', 'No games yet');
}
