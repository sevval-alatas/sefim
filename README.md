# Sefim

Beton irsaliyelerini mobil cihazdan okuyup Excel'e aktaran Flutter uygulaması.

## Akış

- Kamerayla irsaliye fotoğrafı çekilir.
- Galeriden veya cihazın Dosyalar uygulamasından görsel belge seçilir.
- Türkçe/Latin OCR ile metin okunur ve irsaliye alanları ayıklanır.
- Alanlar kaydetmeden önce düzenlenebilir.
- Kayıtlar uygulamanın belgeler klasöründeki `irsaliyeler.xlsx` dosyasına yazılır.
- Excel dosyası paylaşım menüsüyle dışarı aktarılabilir.

Dosya seçimi JPG, JPEG, PNG, HEIC, HEIF ve WEBP görsellerini destekler. PDF desteği eklenmemiştir. iOS'ta Apple Vision, Android'de Google ML Kit OCR kullanılır.

## Çalıştırma

```bash
flutter pub get
flutter run
```

Uygulama iOS ve Android cihaz hedefleri için hazırlanmıştır. iOS'ta kamera ve fotoğraf izin açıklamaları `ios/Runner/Info.plist` içinde tanımlıdır.
