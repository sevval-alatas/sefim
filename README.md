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
- DWG dosyaları CAD backend'ine JSON sahne formatında gönderilir; uygulama sahne bağlantısını indirip çizgi, daire, yay, polyline ve metinleri Flutter `CustomPainter` ile gösterir. DXF çıktısı ayrıca indirilerek çevrimdışı kullanım için saklanır.
- Kayıt ekranında arama, tarih aralığı, eksik alan filtresi ve sıralama kullanılabilir.
- Toplam kayıt ve üretim özeti görüntülenebilir; tarih damgalı Excel yedeği paylaşılabilir.

İrsaliye dosya seçimi JPG, JPEG, PNG, HEIC, HEIF ve WEBP görsellerini destekler. Proje Okuma ekranı PDF, görsel, DWG ve DXF dosyalarını destekler. DWG sahne akışı, `/api/cad/convert?format=json` yanıtında `mobileSceneUrl` ve `downloadUrl` sağlayan bir CAD API bekler; URL'ler `API_BASE_URL` ayarına göre çözülür. Sahne yanıtındaki `warnings` ve `unsupportedEntities` görüntüleyicide gösterilir; bu nedenle JSON önizlemesi tüm DWG nesnelerini kapsamayabilir. DXF indirme bağlantısı daha kapsamlı görüntüleme ve çevrimdışı kullanım için korunur. `backend/` altındaki CLI dönüştürücü bu HTTP sözleşmesini sağlamaz; çalışan bir CAD API adresi uygulamanın API ayarlarında yapılandırılmalıdır. iOS'ta Apple Vision, Android'de Google ML Kit OCR kullanılır.

## Çalıştırma

```bash
flutter pub get
flutter run
```

Uygulama iOS ve Android cihaz hedefleri için hazırlanmıştır. iOS'ta kamera ve fotoğraf izin açıklamaları `ios/Runner/Info.plist` içinde tanımlıdır.

Excel yazmaları geçici dosyaya yazılıp atomik olarak değiştirilir ve eşzamanlı kayıt işlemleri sıraya alınır. İlerideki veritabanı geçişinde mevcut Excel dosyası ilk açılışta içe aktarılmalıdır.
