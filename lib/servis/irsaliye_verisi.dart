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
  Map<String, double> guvenSkorlari;

  IrsaliyeVerisi({
    this.tarih = '',
    this.zaman = '',
    this.irsaliyeNo = '',
    this.plaka = '',
    this.dayanim = '',
    this.uretimMiktari = '',
    this.siparisMiktari = '-',
    Map<String, double>? guvenSkorlari,
  }) : guvenSkorlari = guvenSkorlari ?? {};

  List<String> get kontrolUyarilari {
    final uyarilar = <String>[];
    if (irsaliyeNo.trim().isEmpty) uyarilar.add('İrsaliye No okunamadı');
    if (tarih.trim().isEmpty) uyarilar.add('Tarih okunamadı');
    if (plaka.isNotEmpty &&
        !RegExp(r'^\d{2}\s+[A-Z]{1,3}\s+\d{2,4}$').hasMatch(plaka)) {
      uyarilar.add('Plaka biçimini kontrol edin');
    }
    if (uretimMiktari.isNotEmpty) {
      final miktar = double.tryParse(uretimMiktari.replaceAll(',', '.'));
      if (miktar == null || miktar <= 0 || miktar > 100) {
        uyarilar.add('Üretim miktarını kontrol edin');
      }
    }
    return uyarilar;
  }
}
