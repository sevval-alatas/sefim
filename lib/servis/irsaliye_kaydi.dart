
import 'irsaliye_verisi.dart';

/// Excel'deki tek bir satırı, o satırın sayfadaki gerçek konumuyla birlikte
/// tutar. Güncelleme/silme işlemlerinde doğru satırı hedefleyebilmek için
/// bu konum bilgisi gereklidir.
class IrsaliyeKaydi {
  final int sheetSatirIndeksi;
  final IrsaliyeVerisi veri;
  final String gorselDosyasi;

  IrsaliyeKaydi({
    required this.sheetSatirIndeksi,
    required this.veri,
    required this.gorselDosyasi,
  });
}
