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

## Test geri bildirimi birikimi (24 Ağustos 2026)

Kapalı testin ilk turundan üç kullanıcının istekleri; boyuta göre gruplandı.

### Yapıldı
- Hamlesiz terk edilen oyun artık ne mağlubiyet sayılıyor ne arşivde
  görünüyor.
- Saat oyun başında 3 saniye bekliyor; ilk hamle daha erken gelirse o anda
  başlıyor.
- Sürükle-bırak zaten vardı (taşa basılı tutup kaydırınca taşınıyor); kırık
  görünen cihaz olursa ayrıntı istenecek.
- "Try again" karşılığı olan Yeniden Oyna düğmesi zaten mevcut.
- Açılış kütüphanesi (65+ satır, kategorili, tahtada izlenebilir), maç tekrarı
  ekranı ve motorlu hamle kalitesi analizi (kitap/yıldız/tik/soru/çarpı).
  Canlı oyunda da açılış adı gösteriliyor.

### Orta boy
- **Ön hamle (premove):** sıra rakipteyken sonraki hamleyi çizip sıra gelince
  otomatik oynatma.
- **Bulmacalar:** N hamlede mat / kazanç. Veri seti bulunmalı ya da motorla
  üretilmeli.
- **Oyun sonu sözleri ve istatistik:** maç bitiminde satranç/zafer üzerine
  rastgele özlü söz ve kısa istatistik. Söz havuzu metinle başlar,
  seslendirme sonra.
- **Başarımlar ve coin:** oyun sonunda performansa göre puan; temaların
  kilidini açmakta kullanılacak.

### Büyük
- **Tema paketleri:** uzay, dinozor, antik Mısır/Yunan; tahta + taş + arka plan
  + fon müziği birlikte; bir kısmı coin/başarımla açılır. Özel gün temaları.
- **Açılış öğretmeni:** seviyeli ders sistemi, hamleleri açıklayan anlatıcı,
  sesli yönlendirme. İçerik üretimi işin kendisinden büyük.
- **Sesli satranç hikâyeleri:** çocuklara yönelik, altyazılı. İçerik ağırlıklı.

## Sıradaki büyük işler

### Online oyun
Mimari hazır; sunucu tarafı ve barındırma kararı bekliyor.

## Tamamlananlar

### Taş ve tahta animasyonları — yapıldı
Taş alma solması, şah vuruşu, galibiyet patlaması; ayrıca her hamlede görünen
seçim kalkması, hamle noktalarının sırayla açılması, son hamle vurgusunun
yumuşak belirmesi ve tahta açılışındaki sıralı yerleşme.

### Ebeveyn kontrolü — yapıldı
Ayarlar → Ebeveyn Bölümü. PIN ile açılır; bugünkü ve toplam oynama süresi,
kademe başına süre dökümü, son yedi günün grafiği ve günlük süre sınırı
bulunur. Sınır dolduğunda yeni oyun başlatılamaz, süren oyun kesilmez.

### Yaşa göre görsel zenginlik — yapıldı
Ayarlar → Yaş grubu. Küçük yaşta neşeli takım ve coşkulu kutlama, yetişkinde
sade görünüm. Kurallar ve zorluk kademeleri değişmez.

### Online oyun
Mimari hazır, ayrıntısı `docs/ONLINE.md` dosyasında. Sunucu tarafı yazıldığında
istemcide yapılacak iş bir `MessageChannel` gerçeklemesi ve fabrikadaki tek
dalın açılmasından ibaret.
