import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

import 'irsaliye_kaydi.dart';
import 'irsaliye_verisi.dart';

/// İrsaliye kayıtlarını `irsaliyeler.xlsx` dosyasına yazan servis.
///
/// Masaüstü Python aracındaki `excel_hazirla` / `excele_ekle`
/// fonksiyonlarının telefon tarafındaki karşılığıdır. Dosya, uygulamanın
/// kendi belgeler klasöründe tutulur ve "Excel Dosyasını Paylaş" butonuyla
/// dışarı aktarılabilir.
class ExcelServisi {
  static const String _dosyaAdi = 'irsaliyeler.xlsx';
  static const String _sayfaAdi = 'Beton İrsaliyeleri';
  static const String _noKayitDosyasi = '.irsaliye_no_kayitlari.json';
  static Future<void> _yazmaZinciri = Future<void>.value();

  static const List<String> sutunlar = [
    'İrsaliye Tarihi',
    'İrsaliye Zamanı',
    'İrsaliye No',
    'Araç Plakası',
    'Basınç Dayanımı',
    'Üretim Miktarı (m³)',
    'Sipariş Miktarı (m³)',
    'Görsel Dosyası',
  ];

  static Future<Directory> _belgeDizini() => getApplicationDocumentsDirectory();

  static Future<File> _dosyaYolu() async {
    final dizin = await _belgeDizini();
    return File('${dizin.path}/$_dosyaAdi');
  }

  static Future<File> _numaralarDosyasi() async {
    final dizin = await _belgeDizini();
    return File('${dizin.path}/$_noKayitDosyasi');
  }

  /// Daha önce kaydedilmiş irsaliye numaralarını döndürür (mükerrer kontrolü
  /// için). Excel hücrelerini tekrar okumak yerine küçük bir JSON kayıt
  /// dosyası kullanılır; bu, kütüphane sürümünden bağımsız ve güvenilirdir.
  static Future<List<String>> _kayitliNolar() async {
    final dosya = await _numaralarDosyasi();
    if (!await dosya.exists()) return [];
    try {
      final icerik = await dosya.readAsString();
      final liste = jsonDecode(icerik) as List;
      return liste.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _nolariKaydet(List<String> nolar) async {
    final dosya = await _numaralarDosyasi();
    await dosya.writeAsString(jsonEncode(nolar));
  }

  static Future<void> _noEkle(String no) async {
    if (no.isEmpty) return;
    final nolar = await _kayitliNolar();
    if (!nolar.contains(no)) {
      nolar.add(no);
      await _nolariKaydet(nolar);
    }
  }

  static Future<void> _noSil(String no) async {
    if (no.isEmpty) return;
    final nolar = await _kayitliNolar();
    if (nolar.remove(no)) {
      await _nolariKaydet(nolar);
    }
  }

  static CellStyle? _baslikStili() {
    try {
      return CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('FF1F497D'),
        fontColorHex: ExcelColor.fromHexString('FFFFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
    } catch (_) {
      return null;
    }
  }

  static CellStyle? _hucreStili() {
    try {
      return CellStyle(
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
    } catch (_) {
      return null;
    }
  }

  /// Dosya varsa açar, yoksa başlık satırıyla birlikte yeni bir çalışma
  /// kitabı oluşturur.
  static Future<Excel> _calismaKitabiAc(File dosya) async {
    if (await dosya.exists()) {
      final bytes = await dosya.readAsBytes();
      return Excel.decodeBytes(bytes);
    }

    final excel = Excel.createExcel();
    final sheet = excel[_sayfaAdi];

    sheet.appendRow(sutunlar.map((s) => TextCellValue(s)).toList());

    final stil = _baslikStili();
    if (stil != null) {
      for (var i = 0; i < sutunlar.length; i++) {
        sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
                .cellStyle =
            stil;
      }
    }

    if (excel.sheets.containsKey('Sheet1') && _sayfaAdi != 'Sheet1') {
      excel.delete('Sheet1');
    }

    return excel;
  }

  static Future<void> _kaydetVeYaz(Excel excel, File dosya) async {
    final bytes = excel.save();
    if (bytes != null) {
      final geciciDosya = File('${dosya.path}.tmp');
      await geciciDosya.writeAsBytes(bytes, flush: true);
      await geciciDosya.rename(dosya.path);
    }
  }

  static Future<T> _yazmayiSirala<T>(Future<T> Function() islem) {
    final onceki = _yazmaZinciri;
    final sonraki = onceki.then((_) => islem());
    _yazmaZinciri = sonraki.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return sonraki;
  }

  /// Var olan (veya yeni oluşturulan) xlsx dosyasının File referansını verir.
  static Future<File> excelDosyasi() async {
    final dosya = await _dosyaYolu();
    if (!await dosya.exists()) {
      final excel = await _calismaKitabiAc(dosya);
      await _kaydetVeYaz(excel, dosya);
    }
    return dosya;
  }

  static Future<File> yedekOlustur() async {
    final kaynak = await excelDosyasi();
    final dizin = await _belgeDizini();
    final yedekDizini = Directory('${dizin.path}/yedekler');
    await yedekDizini.create(recursive: true);
    final damga = DateTime.now().toIso8601String().replaceAll(':', '-');
    return kaynak.copy('${yedekDizini.path}/irsaliyeler_$damga.xlsx');
  }

  /// Çekilen fotoğrafı, kayıtla birlikte kalıcı olması için uygulamanın
  /// belgeler klasöründeki `gorseller` alt klasörüne kopyalar ve yeni
  /// dosyanın adını döndürür.
  static Future<String> fotografiSakla(File kaynak, String uzanti) async {
    final gorselDizin = await _gorselDizini();
    final temizUzanti = uzanti.replaceAll('.', '').isEmpty
        ? 'jpg'
        : uzanti.replaceAll('.', '');
    final ad = 'irsaliye_${DateTime.now().millisecondsSinceEpoch}.$temizUzanti';
    final hedef = File('${gorselDizin.path}/$ad');
    await kaynak.copy(hedef.path);
    return ad;
  }

  static Future<Directory> _gorselDizini() async {
    final dizin = await _belgeDizini();
    final gorselDizin = Directory('${dizin.path}/gorseller');
    if (!await gorselDizin.exists()) {
      await gorselDizin.create(recursive: true);
    }
    return gorselDizin;
  }

  /// Bir kaydın fotoğraf dosyasını döndürür; dosya adı boşsa veya dosya
  /// artık diskte yoksa null döner.
  static Future<File?> gorselDosyasiniBul(String gorselAdi) async {
    if (gorselAdi.trim().isEmpty) return null;
    final gorselDizin = await _gorselDizini();
    final dosya = File('${gorselDizin.path}/$gorselAdi');
    return await dosya.exists() ? dosya : null;
  }

  /// Veriyi Excel dosyasına yeni satır olarak ekler.
  ///
  /// Dönen kayıt: (eklendiMi, mesaj). `eklendiMi` false ise aynı irsaliye
  /// numarası zaten kayıtlıdır ve satır eklenmemiştir.
  static Future<(bool, String)> exceleEkle(
    IrsaliyeVerisi veri,
    String gorselAdi,
  ) => _yazmayiSirala(() => _exceleEkle(veri, gorselAdi));

  static Future<(bool, String)> _exceleEkle(
    IrsaliyeVerisi veri,
    String gorselAdi,
  ) async {
    if (veri.irsaliyeNo.isNotEmpty) {
      final mevcutNolar = await _kayitliNolar();
      if (mevcutNolar.contains(veri.irsaliyeNo)) {
        return (
          false,
          "'${veri.irsaliyeNo}' numaralı irsaliye zaten kayıtlı, atlandı.",
        );
      }
    }

    final dosya = await _dosyaYolu();
    final excel = await _calismaKitabiAc(dosya);
    final sheet = excel[_sayfaAdi];

    final yeniSatir = [
      TextCellValue(veri.tarih),
      TextCellValue(veri.zaman),
      TextCellValue(veri.irsaliyeNo),
      TextCellValue(veri.plaka),
      TextCellValue(veri.dayanim),
      TextCellValue(veri.uretimMiktari),
      TextCellValue(veri.siparisMiktari),
      TextCellValue(gorselAdi),
    ];
    sheet.appendRow(yeniSatir);
    final sonSatirIndeks = sheet.maxRows - 2;

    final stil = _hucreStili();
    if (stil != null) {
      for (var i = 0; i < yeniSatir.length; i++) {
        sheet
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: i,
                    rowIndex: sonSatirIndeks,
                  ),
                )
                .cellStyle =
            stil;
      }
    }

    await _kaydetVeYaz(excel, dosya);
    await _noEkle(veri.irsaliyeNo);

    return (true, "Excel'e kaydedildi -> Satır: ${sonSatirIndeks + 1}");
  }

  /// Kayıtlı tüm irsaliye satırlarını (başlık hariç) okur; en son eklenen
  /// kayıt listenin başında olacak şekilde döner. Her kayıt, Excel'deki
  /// gerçek satır konumunu da taşır (güncelleme/silme için gereklidir).
  static Future<List<IrsaliyeKaydi>> tumKayitlariOku() async {
    final dosya = await _dosyaYolu();
    if (!await dosya.exists()) return [];

    final bytes = await dosya.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    if (!excel.sheets.containsKey(_sayfaAdi)) return [];
    final sheet = excel[_sayfaAdi];

    final kayitlar = <IrsaliyeKaydi>[];
    for (var r = 1; r < sheet.maxRows; r++) {
      final satir = <String>[];
      for (var c = 0; c < sutunlar.length; c++) {
        final hucre = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r),
        );
        satir.add(_hucreMetni(hucre.value));
      }
      if (satir.any((deger) => deger.trim().isNotEmpty)) {
        kayitlar.add(
          IrsaliyeKaydi(
            sheetSatirIndeksi: r,
            veri: IrsaliyeVerisi(
              tarih: satir[0],
              zaman: satir[1],
              irsaliyeNo: satir[2],
              plaka: satir[3],
              dayanim: satir[4],
              uretimMiktari: satir[5],
              siparisMiktari: satir[6],
            ),
            gorselDosyasi: satir[7],
          ),
        );
      }
    }

    return kayitlar.reversed.toList();
  }

  /// [sheetSatirIndeksi] konumundaki satırı verilen değerlerle günceller.
  /// Satırın irsaliye numarası değiştiyse mükerrer-kontrol listesi de
  /// buna göre güncellenir.
  static Future<void> kaydiGuncelle(
    int sheetSatirIndeksi,
    IrsaliyeVerisi veri,
  ) => _yazmayiSirala(() => _kaydiGuncelle(sheetSatirIndeksi, veri));

  static Future<void> _kaydiGuncelle(
    int sheetSatirIndeksi,
    IrsaliyeVerisi veri,
  ) async {
    final dosya = await _dosyaYolu();
    if (!await dosya.exists()) return;

    final bytes = await dosya.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    if (!excel.sheets.containsKey(_sayfaAdi)) return;
    final sheet = excel[_sayfaAdi];

    final eskiNoHucresi = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: sheetSatirIndeksi),
    );
    final eskiNo = _hucreMetni(eskiNoHucresi.value);

    final degerler = [
      veri.tarih,
      veri.zaman,
      veri.irsaliyeNo,
      veri.plaka,
      veri.dayanim,
      veri.uretimMiktari,
      veri.siparisMiktari,
    ];

    for (var c = 0; c < degerler.length; c++) {
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: sheetSatirIndeksi),
        TextCellValue(degerler[c]),
      );
    }

    await _kaydetVeYaz(excel, dosya);

    if (eskiNo != veri.irsaliyeNo) {
      await _noSil(eskiNo);
      await _noEkle(veri.irsaliyeNo);
    }
  }

  /// [sheetSatirIndeksi] konumundaki satırı Excel'den tamamen siler.
  static Future<void> kaydiSil(int sheetSatirIndeksi) =>
      _yazmayiSirala(() => _kaydiSil(sheetSatirIndeksi));

  static Future<void> _kaydiSil(int sheetSatirIndeksi) async {
    final dosya = await _dosyaYolu();
    if (!await dosya.exists()) return;

    final bytes = await dosya.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    if (!excel.sheets.containsKey(_sayfaAdi)) return;
    final sheet = excel[_sayfaAdi];

    final noHucresi = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: sheetSatirIndeksi),
    );
    final no = _hucreMetni(noHucresi.value);

    sheet.removeRow(sheetSatirIndeksi);

    await _kaydetVeYaz(excel, dosya);
    await _noSil(no);
  }

  static String _hucreMetni(CellValue? deger) {
    if (deger == null) return '';
    if (deger is TextCellValue) return deger.value.text ?? '';
    if (deger is IntCellValue) return deger.value.toString();
    if (deger is DoubleCellValue) return deger.value.toString();
    if (deger is BoolCellValue) return deger.value.toString();
    return deger.toString();
  }
}
