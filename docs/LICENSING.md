# Lisans yükümlülükleri

> **Karar (23 Ağustos 2026):** Stockfish korunur, uygulamanın kaynak kodu
> herkese açık yayınlanır. Aşağıdaki yükümlülükler bu karar doğrultusunda
> yerine getirilecektir.

## Stockfish — GPLv3

Uygulama Stockfish satranç motorunu `stockfish` Flutter eklentisi üzerinden
içerir. Stockfish **GNU General Public License v3** ile lisanslıdır ve bu
lisans "bulaşıcıdır": GPLv3 kodla aynı çalıştırılabilir içinde dağıtılan tüm
uygulama, GPLv3 koşullarına tabi olur.

Bu nedenle proje GPLv3 altında dağıtılır. Google Play'de yayınlamak için
şunlar gerekir:

1. **Uygulamanın kaynak kodu, dağıtımı alan herkese açık olmalıdır.** Yaygın
   uygulama, mağaza listelemesinde herkese açık bir depo bağlantısı vermektir.
2. **Lisans metni uygulama içinde gösterilmelidir.** (Ayarlar → Hakkında
   bölümünde motor ve lisansı belirtilmiştir; tam metin eklenecekse
   `assets/licenses/` altına konulabilir.)
3. **Değişiklikler belirtilmelidir** — motor kaynağında değişiklik yapılmadıysa
   ek yük yoktur.
4. Google Play Geliştirici Dağıtım Sözleşmesi ile GPLv3 arasında uygulamada
   çatışma çıkmaz; GPL'li birçok uygulama mağazada yayındadır.

### Yayın öncesi yapılacaklar

- [ ] Depo herkese açık hâle getirilir (`shellnoq` hesabı altında)
- [ ] Mağaza listelemesinin "Geliştirici web sitesi" alanına depo bağlantısı
      konur
- [ ] GPLv3 tam metni depo kökündeki `LICENSE` dosyasına eklenir
- [ ] Uygulama içi "Lisanslar" ekranı (Ayarlar → Lisanslar) kontrol edilir;
      Stockfish ve tüm bağımlılıklar orada listelenir

### İleride kapalı kaynağa dönülmek istenirse

Stockfish yerine lisansı izin verici bir motor kullanılmalıdır. Uygulamanın
motor katmanı `ChessEngine` arayüzü ile soyutlandığı için bu değişiklik
`lib/engine/` altında tek bir gerçekleme yazmakla sınırlıdır; oyun mantığı ve
arayüz etkilenmez.

Seçenekler:

- **Saf Dart motor** (negamax + alfa-beta, iterative deepening, transposition
  table, quiescence). Yaklaşık 1500-1900 Elo bandına ulaşır; sekiz kademe için
  fazlasıyla yeterlidir, paket boyutunu ~110 MB azaltır ve lisans yükümlülüğü
  doğurmaz.
- **İzin verici lisanslı bir native motor** kullanmak.

## Diğer bileşenler

| Bileşen | Lisans | Yükümlülük |
|---|---|---|
| Flutter, Dart | BSD-3-Clause | Atıf |
| `dartchess` | GPL-3.0 | Stockfish ile aynı kapsamda |
| `flutter_riverpod`, `go_router` | MIT / BSD | Atıf |
| `hive_ce` | Apache-2.0 | Atıf |
| `just_audio` | MIT | Atıf |
| `flutter_svg` | MIT | Atıf |
| Taş çizimleri | Bu depoda üretildi | Yok |
| Ses efektleri | Bu depoda üretildi | Yok |
| Uygulama ikonu | Bu depoda üretildi | Yok |

`dartchess` da GPL-3.0'dır; yani izin verici bir motora geçilse bile kural
katmanının değiştirilmesi gerekir. Kural katmanı `lib/domain/game_controller.dart`
içinde `Position` üzerinden kullanıldığı için değişim yüzeyi dardır.

Bağımlılıkların tam lisans listesi uygulamanın kendi "Lisanslar" ekranından
(`showLicensePage`) alınabilir.
