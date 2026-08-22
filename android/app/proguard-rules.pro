# Flutter ve eklentiler için koruma kuralları.
# Varsayılan Android optimizasyon dosyasına ek olarak uygulanır.

# just_audio, arka planda ExoPlayer'ı yansıma ile kurar.
-keep class com.google.android.exoplayer2.** { *; }
-keep class androidx.media3.** { *; }
-dontwarn com.google.android.exoplayer2.**
-dontwarn androidx.media3.**

# Stockfish eklentisi JNI üzerinden çağrılır.
-keep class com.arjanaswal.stockfish.** { *; }
-keep class com.stockfish.** { *; }

# Flutter gömme katmanı ve eklenti kaydı.
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }

# Play Core (ertelenmiş bileşen) sınıfları bu uygulamada kullanılmaz.
-dontwarn com.google.android.play.core.**
