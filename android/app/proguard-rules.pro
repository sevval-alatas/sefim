# --- Google ML Kit Metin Tanıma (Latin) — çalışma zamanı koruması ---
# R8, ML Kit'in reflection ile çağırdığı bazı iç sınıfları "kullanılmıyor"
# sanıp küçültme/isim değiştirme sırasında silebiliyor. Bu da release APK'da
# metin tanımanın sessizce boş sonuç dönmesine (hiçbir şey okunmamasına) ya da
# çökmesine yol açar. Bu yüzden gerçekten kullandığımız ML Kit metin tanıma
# paketlerinin tamamını R8'in dokunmasından koruyoruz.
-keep class com.google.mlkit.vision.text.** { *; }
-keep interface com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.common.** { *; }
-keep interface com.google.mlkit.vision.common.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_bundled_common.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }

# Yalnızca Latin alfabesi (TextRecognitionScript.latin) kullanılıyor.
# Eklentinin initialize() metodu Çince/Devanagari/Japonca/Korece tanıyıcı
# seçenek sınıflarına da referans veriyor; bu sınıflar için ayrı ML Kit
# bağımlılıkları projeye eklenmediğinden (gerek yok) R8'in bunları "missing
# class" diye derlemeyi durdurmasını engelliyoruz — hiç çalışmayacak kod
# yolları oldukları için güvenli.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
