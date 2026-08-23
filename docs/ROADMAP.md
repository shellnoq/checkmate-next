# Yol haritası

Bu belge kararlaştırılmış ama henüz yapılmamış işleri tutar. Yapılan işler
depo geçmişinde, mimari kararlar `docs/LICENSING.md` ve `docs/ONLINE.md`
dosyalarındadır.

## Şu anki durum

Android tarafı tamam: uygulama Play Console'da kapalı testte, sürüm yayınlandı.
Üretim erişimi için Play'in şartı 12 test kullanıcısının 14 gün kesintisiz
kayıtlı kalması.

## Ertelenen: iOS

**Karar (23 Ağustos 2026): iOS şimdilik ertelendi.**

Kod zaten çapraz platform; iOS projesi yapılandırılmış durumda
(`com.e2esolutions.chess`, hedef iOS 13.0) ve Stockfish eklentisinin iOS
desteği var. Erteleme sebebi teknik değil:

1. **Apple Developer Program yıllık 99 USD** — Play'in 25 USD tek seferlik
   ücretinin aksine her yıl yenilenir. TestFlight ve App Store için zorunlu.
2. **GPLv3 ile App Store şartları arasında uyuşmazlık.** GPL, dağıtımı alan
   kişiye ek kısıtlama getirilmesini yasaklar; App Store şartları cihaz ve
   yeniden dağıtım kısıtı getirir. Free Software Foundation bu gerekçeyle
   Apple'a başvurup GNU Go'nun kaldırılmasını sağlamıştı. Stockfish tabanlı
   uygulamalar App Store'da yayında, yani Apple kendiliğinden engellemiyor;
   fakat şikâyet hâlinde kaldırılma riski gerçek.

Devam edilmek istendiğinde bu makinede gereken hazırlık:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
brew install cocoapods
```

Ardından `flutter build ipa`. Lisans riski kabul edilmek istenmezse motorun
izin verici lisanslı bir gerçeklemeyle değiştirilmesi gerekir; `ChessEngine`
arayüzü bu değişimi tek dosyaya indirger, ama `dartchess` kural katmanı da
GPL-3.0 olduğu için o da değişmelidir.

## Sıradaki özellikler

Kapalı testin 14 günü boyunca geliştirilecekler. Öncelik sırası henüz
belirlenmedi.

### Taş ve tahta animasyonları
Hamle animasyonu bugün var (taş kimliği izlenerek kaydırma). Eklenecekler:
taş alındığında kısa bir efekt, şah çekildiğinde tahtanın tepki vermesi,
oyun sonunda kutlama. Amaç görsel çekiciliği artırmak, özellikle genç
oyuncular için.

### Yaşa göre görsel zenginlik
Küçük yaş grubunda daha büyük, daha renkli ve daha "canlı" taşlar; ileri
yaşta bugünkü sade takım. Taş takımı altyapısı (`PieceSet` + `PieceSvg`)
buna hazır: yeni bir takım tanımlamak renk ve şekil verisi eklemekten ibaret.

### Ebeveyn kontrolü
Ebeveynin görebileceği bir bölüm: çocuğun hangi zorluk kademesinde ne kadar
süre oynadığı, kaç oyun bitirdiği, galibiyet dağılımı. Oturum süresi sınırı
koyabilme. Bölüme PIN ile giriş.

Veri altyapısı kısmen hazır: oyunlar `AppStorage.archiveGame` ile arşivleniyor
ve kademe bazlı galibiyet sayacı tutuluyor. Eksik olan oynama süresi ölçümü ve
ebeveyn arayüzü.

### Online oyun
Mimari hazır, ayrıntısı `docs/ONLINE.md` dosyasında. Sunucu tarafı yazıldığında
istemcide yapılacak iş bir `MessageChannel` gerçeklemesi ve fabrikadaki tek
dalın açılmasından ibaret.
