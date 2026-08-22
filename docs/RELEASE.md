# Google Play yayın süreci

## 1. İmza anahtarı

Anahtar bir kez üretilir ve **kaybedilirse uygulamanın güncellenmesi mümkün
olmaz**. Yedeğini parola yöneticisinde ya da şifreli bir yedekte saklayın.

```bash
keytool -genkey -v -keystore ~/satranc-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias satranc
```

Ardından `android/key.properties` dosyasını oluşturun (şablon:
`android/key.properties.example`):

```properties
storePassword=...
keyPassword=...
keyAlias=satranc
storeFile=/Users/KULLANICI/satranc-release.jks
```

`key.properties` ve `*.jks` `.gitignore` kapsamındadır; depoya girmez.
Dosya yoksa yayın derlemesi hata ver­mez, hata ayıklama anahtarıyla imzalar —
bu paket **Play'e yüklenemez**, yalnızca yerel denemeler içindir.

Play App Signing kullanılacaksa (önerilir) yükleme anahtarı budur; dağıtım
anahtarını Google yönetir.

## 2. Sürüm numarası

`pubspec.yaml` içindeki `version: 1.0.0+1` alanı hem `versionName` (1.0.0) hem
`versionCode` (1) üretir. **Her Play yüklemesinde `+` sonrası sayı artmalıdır.**

## 3. Paketi üret

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

Çıktı: `build/app/outputs/bundle/release/app-release.aab`

Beklenen ölçüler:

| Ölçü | Değer |
|---|---|
| Paket (.aab) dosyası | ~172 MB |
| arm64-v8a cihaz indirmesi | ~83 MB |
| armeabi-v7a cihaz indirmesi | ~82 MB |

Boyutun tamamına yakını Stockfish'in gömülü NNUE ağlarından gelir
(`libstockfish.so`, ABI başına ~114 MB açılmış). Play'in 200 MB'lık temel
modül indirme sınırının altındadır.

Yayın öncesi paketi cihazda denemek için:

```bash
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## 4. Play Console kaydı

| Alan | Değer |
|---|---|
| Paket adı | `com.e2esolutions.satranc` |
| Uygulama adı (tr) | Satranç Ustası |
| Uygulama adı (en) | Chess Master |
| Kategori | Oyunlar → Tahta oyunu |
| Hedef API | Flutter'ın güncel varsayılanı (`targetSdk`) |
| Minimum API | 24 (Android 7.0) |

Mağaza metinleri `docs/store/` altındadır. Gereken görseller:

- Uygulama ikonu 512×512 PNG — `assets/icon/play_store_512.png`
- Öne çıkan görsel 1024×500
- En az 2 telefon ekran görüntüsü (16:9 ya da 9:16, kısa kenar ≥ 320 px)

## 5. Veri güvenliği formu

Uygulama şu an ağ üzerinden **hiçbir veri toplamaz ve göndermez**:

- Toplanan veri: yok
- Paylaşılan veri: yok
- Veriler cihazda mı: evet (ayarlar, oyun arşivi, istatistikler — Hive)
- Veri silme talebi: uygulama içinden arşiv ve istatistikler silinebilir
- Şifreleme: aktarım yok, dolayısıyla uygulanamaz

`AndroidManifest.xml` içinde `INTERNET` izni **tanımlı değildir**. Online mod
etkinleştirildiğinde bu form yeniden doldurulmalıdır.

## 6. İçerik derecelendirmesi

Şiddet, kumar, kullanıcı etkileşimi ve reklam içermez. Beklenen sonuç: 3+ /
Everyone.

## 7. Gizlilik politikası

Play Console gizlilik politikası için erişilebilir bir URL ister. Metin
`docs/PRIVACY.md` içindedir; bir web adresinde yayınlanıp bağlantısı verilir.

## 8. Lisans

Stockfish GPLv3'tür. Yayından önce `docs/LICENSING.md` okunmalı ve kaynak kodun
erişilebilirliği konusunda karar verilmelidir.

## Yayın öncesi kontrol listesi

- [ ] `flutter analyze` temiz
- [ ] `flutter test` geçiyor
- [ ] Gerçek cihazda motor açılıyor, sekiz kademe de hamle üretiyor
- [ ] Rok, geçerken alma ve terfi cihazda deneniyor
- [ ] Süreli oyunda bayrak düşüşü doğru sonuç veriyor
- [ ] Arka plan / ön plan geçişinde saat kaymıyor
- [ ] `versionCode` bir önceki yüklemeden büyük
- [ ] `key.properties` yerinde ve paket yayın anahtarıyla imzalı
- [ ] Gizlilik politikası URL'i yayında
- [ ] `docs/LICENSING.md` kararı verilmiş
