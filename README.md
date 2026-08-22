# Satranç Ustası · Chess Master

[![CI](https://github.com/shellnoq/chess-master/actions/workflows/ci.yml/badge.svg)](https://github.com/shellnoq/chess-master/actions/workflows/ci.yml)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.41-blue.svg)](https://flutter.dev)
[![Engine](https://img.shields.io/badge/engine-Stockfish-green.svg)](https://stockfishchess.org)

Stockfish motoruyla çalışan, sekiz zorluk kademeli profesyonel satranç
uygulaması. Flutter ile yazılmıştır; Android ve iOS hedeflenir. Motor cihazda
çalışır, internet bağlantısı gerekmez.

*A chess app powered by Stockfish running fully on-device, with eight
difficulty levels from ~600 Elo to full engine strength. Turkish and English.*

| Ana ekran | Oyun ekranı |
|---|---|
| <img src="docs/screenshots/home.png" width="270"> | <img src="docs/screenshots/game.png" width="270"> |

## Öne çıkanlar

- **Tam FIDE kuralları** — rok, geçerken alma, terfi, elli hamle, üç ve beş kez
  tekrar, yetersiz materyal. Kural katmanı Lichess'in `dartchess` kütüphanesidir.
- **Stockfish** — cihaz üzerinde, native (FFI) çalışır. İnternet gerekmez.
- **Sekiz zorluk kademesi** — ~600 Elo'dan tam güce kadar. Alt kademeler
  `Skill Level` + MultiPV tabanlı hata payıyla, üst kademeler `UCI_Elo` ile
  ayarlanır.
- **Süre kontrolü** — süresiz, bullet, blitz, hızlı ve klasik hazır ayarları;
  Fischer artışı desteklenir.
- **Değerlendirme çubuğu, ipucu oku, geri alma, PGN dışa aktarma, oyun arşivi.**
- **İki dil** — Türkçe ve İngilizce, uygulama içinden değiştirilebilir.
- **Online'a hazır mimari** — bkz. `docs/ONLINE.md`.

## Komutlar

```bash
flutter pub get          # bağımlılıklar
flutter analyze          # statik çözümleme
flutter test             # birim ve altın görüntü testleri
flutter test --exclude-tags golden   # altın görüntüler hariç (CI'ın koştuğu)
flutter run              # cihaz/emülatörde çalıştır
flutter build appbundle --release   # Play Store paketi
dart run flutter_launcher_icons     # uygulama ikonlarını üret

# Gerçek cihazda motoru doğrula (cihaz bağlıyken)
flutter test integration_test/engine_test.dart -d <cihaz-id>
```

Altın görüntü testleri macOS'ta üretilmiş referanslara dayanır; referansları
yenilemek için `flutter test --update-goldens`.

## Katman düzeni

```
lib/
├── app/                 Uygulama kabuğu: tema, yönlendirme, sağlayıcılar
├── core/                Depolama, ses, yerelleştirme
├── engine/              Motor sözleşmesi ve Stockfish (UCI) gerçeklemesi
├── domain/              Kurallar, saat, oyun durumu, maç protokolü
│   ├── match/           Taşıma katmanı: motor / iki kişilik / uzak sunucu
│   └── model/           Zorluk, süre kontrolü, hamle kaydı, sonuç
└── features/            Ekranlar ve bileşenler
    ├── board/           Tahta, taş takımı, taş çizimleri
    ├── game/            Oyun ekranı ve bileşenleri
    ├── home/ play/ history/ settings/
```

Tasarımın iki taşıyıcı fikri var:

1. **`ChessEngine` arayüzü** motoru soyutlar. Stockfish yerine başka bir motor
   ya da sunucu tarafı analiz servisi takmak tek sınıf yazmakla mümkündür.
2. **`MatchTransport` arayüzü** rakibi soyutlar. `GameController` rakibin motor
   mu, aynı cihazdaki ikinci oyuncu mu, yoksa uzaktaki bir insan mı olduğunu
   bilmez.

## Lisans

Copyright (C) 2026 Aleaddin Özer

Bu program özgür yazılımdır: Free Software Foundation tarafından yayımlanan GNU
Genel Kamu Lisansı'nın 3. sürümü ya da (tercihinize bağlı olarak) daha sonraki
herhangi bir sürümü koşulları altında yeniden dağıtabilir ve/veya
değiştirebilirsiniz.

Bu program faydalı olacağı umuduyla dağıtılmaktadır, ancak HİÇBİR GARANTİ
VERİLMEZ; SATILABİLİRLİK ya da BELİRLİ BİR AMACA UYGUNLUK zımni garantileri de
dâhil olmak üzere. Ayrıntılar için GNU Genel Kamu Lisansı'na bakınız.

Lisansın bir kopyası depo kökündeki `LICENSE` dosyasındadır; ayrıca
<https://www.gnu.org/licenses/> adresinden edinilebilir.

Uygulama Stockfish satranç motorunu içerir; Stockfish de GPLv3 ile lisanslıdır
ve bu lisans tüm dağıtımı kapsar. Yükümlülüklerin ayrıntısı:
`docs/LICENSING.md`.

## Belgeler

| Dosya | İçerik |
|---|---|
| `docs/RELEASE.md` | Play Store yayın adımları ve kontrol listesi |
| `docs/ONLINE.md` | Online moda geçiş mimarisi ve sunucu sözleşmesi |
| `docs/LICENSING.md` | Stockfish GPLv3 yükümlülüğü |
| `docs/PRIVACY.md` | Gizlilik politikası metni |
| `docs/store/` | Mağaza listeleme metinleri (tr-TR, en-US) |
