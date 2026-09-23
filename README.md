# Sefim

Beton irsaliyelerini mobil cihazdan okuyup Excel'e aktaran Flutter uygulaması.

## Akış

- Kamerayla irsaliye fotoğrafı çekilir.
- Galeriden veya cihazın Dosyalar uygulamasından görsel belge seçilir.
- Türkçe/Latin OCR ile metin okunur ve irsaliye alanları ayıklanır.
- OCR sonucu eksik veya şüpheli alanlar kaydetmeden önce uyarı olarak gösterilir.
- Alanlar kaydetmeden önce düzenlenebilir.
- Kayıtlar uygulamanın belgeler klasöründeki `irsaliyeler.xlsx` dosyasına yazılır.
- Excel dosyası paylaşım menüsüyle dışarı aktarılabilir.
- Proje Okuma ekranında PDF ve görsel proje dosyaları açılıp yakınlaştırılabilir.
- DWG/DXF dosyaları backend'e gönderilip PDF'e dönüştürüldükten sonra uygulama içinde açılabilir.
- Kayıt ekranında arama, tarih aralığı, eksik alan filtresi ve sıralama kullanılabilir.
- Toplam kayıt ve üretim özeti görüntülenebilir; tarih damgalı Excel yedeği paylaşılabilir.

İrsaliye dosya seçimi JPG, JPEG, PNG, HEIC, HEIF ve WEBP görsellerini destekler. Proje Okuma ekranı PDF, görsel, DWG ve DXF dosyalarını destekler. DWG/DXF için `backend/` altındaki converter servisi ve lisanslı bir DWG/PDF converter gerekir. iOS'ta Apple Vision, Android'de Google ML Kit OCR kullanılır.

## Çalıştırma

```bash
flutter pub get
flutter run
```

Uygulama iOS ve Android cihaz hedefleri için hazırlanmıştır. iOS'ta kamera ve fotoğraf izin açıklamaları `ios/Runner/Info.plist` içinde tanımlıdır.

Excel yazmaları geçici dosyaya yazılıp atomik olarak değiştirilir ve eşzamanlı kayıt işlemleri sıraya alınır. İlerideki veritabanı geçişinde mevcut Excel dosyası ilk açılışta içe aktarılmalıdır.
