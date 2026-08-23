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

  // İstatistik
  String get wins => _('Galibiyet', 'Wins');
  String get losses => _('Mağlubiyet', 'Losses');
  String get draws => _('Beraberlik', 'Draws');
  String get gamesPlayed => _('Oynanan oyun', 'Games played');
  String get noGamesYet => _('Henüz oyun yok', 'No games yet');
}
