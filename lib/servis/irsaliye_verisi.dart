/// Bir beton irsaliyesi fotoğrafından OCR ile çıkarılan (veya kullanıcının
/// elle düzenlediği) alanları tutan basit veri modeli.
class IrsaliyeVerisi {
  String tarih;
  String zaman;
  String irsaliyeNo;
  String plaka;
  String dayanim;
  String uretimMiktari;
  String siparisMiktari;

  IrsaliyeVerisi({
    this.tarih = '',
    this.zaman = '',
    this.irsaliyeNo = '',
    this.plaka = '',
    this.dayanim = '',
    this.uretimMiktari = '',
    this.siparisMiktari = '-',
  });
}
