import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'package:sefim/servis/excel_servisi.dart';
import 'package:sefim/servis/irsaliye_verisi.dart';
import 'package:sefim/servis/ocr_ayiklama_servisi.dart';
import 'package:sefim/servis/ocr_service.dart';
import 'package:sefim/ekran/kayitlar_ekrani.dart';
import 'package:sefim/widget/irsaliye_alan.dart';

// Excel başlıklarıyla aynı kurumsal mavi — uygulamanın kimliğini
// ürettiği tabloyla görsel olarak eşleştiriyor.
const Color _anaRenk = Color(0xFF1F497D);

void main() {
  runApp(const IrsaliyeApp());
}

class IrsaliyeApp extends StatelessWidget {
  const IrsaliyeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: _anaRenk);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'İrsaliye OCR',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.35,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      home: const AnaSayfa(),
    );
  }
}

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();

  File? _secilenFoto;

  bool _ocrYapiliyor = false;
  bool _kaydediliyor = false;
  bool _topluIsleniyor = false;

  // OCR'dan ayıklanan alanları kullanıcı düzenleyebilsin diye
  // TextEditingController'larda tutuyoruz.
  final _tarihCtrl = TextEditingController();
  final _zamanCtrl = TextEditingController();
  final _irsaliyeNoCtrl = TextEditingController();
  final _plakaCtrl = TextEditingController();
  final _dayanimCtrl = TextEditingController();
  final _uretimCtrl = TextEditingController();
  final _siparisCtrl = TextEditingController();
  bool get _veriVarMi => _secilenFoto != null;
  bool get _herhangiBirIslemSuruyor =>
      _ocrYapiliyor || _kaydediliyor || _topluIsleniyor;

  Future<void> kamerayiAc() async {
    final XFile? foto = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (foto == null) {
      return;
    }

    await _fotografiIsle(foto);
  }

  Future<void> galeriyiAc() async {
    final XFile? foto = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (foto == null) {
      return;
    }

    await _fotografiIsle(foto);
  }

  Future<void> belgeSec() async {
    final sonuc = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'heic', 'heif', 'webp'],
    );

    final yol = sonuc.isEmpty ? null : sonuc.single.path;
    if (yol == null) return;

    await _fotografiIsle(XFile(yol));
  }

  Future<void> _fotografiIsle(XFile foto) async {
    setState(() {
      _secilenFoto = File(foto.path);
      _ocrYapiliyor = true;
      _tumAlanlariTemizle();
    });

    try {
      final metin = await _ocrService.metniOku(foto.path);
      final veri = OcrAyiklamaServisi.metindenVerileriAyikla(metin);

      if (!mounted) return;

      setState(() {
        _alanlariDoldur(veri);
        _ocrYapiliyor = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _ocrYapiliyor = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            'Metin okunamadı, alanları elle doldurabilirsiniz. ($e)',
          ),
        ),
      );
    }
  }

  void _tumAlanlariTemizle() {
    _tarihCtrl.clear();
    _zamanCtrl.clear();
    _irsaliyeNoCtrl.clear();
    _plakaCtrl.clear();
    _dayanimCtrl.clear();
    _uretimCtrl.clear();
    _siparisCtrl.clear();
  }

  void _alanlariDoldur(IrsaliyeVerisi v) {
    _tarihCtrl.text = v.tarih;
    _zamanCtrl.text = v.zaman;
    _irsaliyeNoCtrl.text = v.irsaliyeNo;
    _plakaCtrl.text = v.plaka;
    _dayanimCtrl.text = v.dayanim;
    _uretimCtrl.text = v.uretimMiktari;
    _siparisCtrl.text = v.siparisMiktari == '-' ? '' : v.siparisMiktari;
  }

  Future<void> _tarihSec() async {
    DateTime baslangic = DateTime.now();
    final parcalar = _tarihCtrl.text.trim().split('-');
    if (parcalar.length == 3) {
      final gun = int.tryParse(parcalar[0]);
      final ay = int.tryParse(parcalar[1]);
      final yil = int.tryParse(parcalar[2]);
      if (gun != null && ay != null && yil != null) {
        baslangic = DateTime(yil, ay, gun);
      }
    }

    final secilen = await showDatePicker(
      context: context,
      initialDate: baslangic,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );

    if (secilen != null) {
      final gg = secilen.day.toString().padLeft(2, '0');
      final aa = secilen.month.toString().padLeft(2, '0');
      setState(() => _tarihCtrl.text = '$gg-$aa-${secilen.year}');
    }
  }

  Future<void> _zamanSec() async {
    TimeOfDay baslangic = TimeOfDay.now();
    final parcalar = _zamanCtrl.text.trim().split(':');
    if (parcalar.length == 2) {
      final saat = int.tryParse(parcalar[0]);
      final dakika = int.tryParse(parcalar[1]);
      if (saat != null && dakika != null) {
        baslangic = TimeOfDay(hour: saat, minute: dakika);
      }
    }

    final secilen = await showTimePicker(
      context: context,
      initialTime: baslangic,
    );

    if (secilen != null) {
      final ss = secilen.hour.toString().padLeft(2, '0');
      final dd = secilen.minute.toString().padLeft(2, '0');
      setState(() => _zamanCtrl.text = '$ss:$dd');
    }
  }

  Future<bool> _eksikAlanlariOnayla(IrsaliyeVerisi veri) async {
    final eksikler = <String>[];
    if (veri.irsaliyeNo.isEmpty) eksikler.add('İrsaliye No');
    if (veri.tarih.isEmpty) eksikler.add('İrsaliye Tarihi');

    if (eksikler.isEmpty) return true;

    final devamEt = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eksik bilgi var'),
        content: Text(
          '${eksikler.join(', ')} alanı boş. Yine de kaydetmek istiyor musun?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yine de Kaydet'),
          ),
        ],
      ),
    );

    return devamEt ?? false;
  }

  Future<void> _exceleKaydet() async {
    if (_secilenFoto == null) return;

    final veri = IrsaliyeVerisi(
      tarih: _tarihCtrl.text.trim(),
      zaman: _zamanCtrl.text.trim(),
      irsaliyeNo: _irsaliyeNoCtrl.text.trim().toUpperCase(),
      plaka: _plakaCtrl.text.trim(),
      dayanim: _dayanimCtrl.text.trim(),
      uretimMiktari: _uretimCtrl.text.trim(),
      siparisMiktari: _siparisCtrl.text.trim().isEmpty
          ? '-'
          : _siparisCtrl.text.trim(),
    );

    final onaylandi = await _eksikAlanlariOnayla(veri);
    if (!onaylandi) return;

    setState(() => _kaydediliyor = true);

    try {
      final uzanti = _secilenFoto!.path.contains('.')
          ? _secilenFoto!.path.split('.').last
          : 'jpg';
      final gorselAdi = await ExcelServisi.fotografiSakla(
        _secilenFoto!,
        uzanti,
      );

      final (eklendi, mesaj) = await ExcelServisi.exceleEkle(veri, gorselAdi);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: eklendi ? Colors.green.shade700 : null,
          content: Row(
            children: [
              Icon(
                eklendi ? Icons.check_circle_outline : Icons.info_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(mesaj)),
            ],
          ),
        ),
      );

      if (eklendi) {
        setState(() {
          _secilenFoto = null;
          _tumAlanlariTemizle();
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kaydedilirken hata oluştu: $e')));
    } finally {
      if (mounted) {
        setState(() => _kaydediliyor = false);
      }
    }
  }

  Future<void> _topluFotografSec() async {
    final List<XFile> fotolar = await _picker.pickMultiImage(imageQuality: 90);
    if (fotolar.isEmpty) return;

    setState(() => _topluIsleniyor = true);

    int eklenen = 0;
    int atlanan = 0;
    final List<String> notlar = [];

    for (final foto in fotolar) {
      try {
        final metin = await _ocrService.metniOku(foto.path);
        final veri = OcrAyiklamaServisi.metindenVerileriAyikla(metin);
        final dosya = File(foto.path);
        final uzanti = dosya.path.contains('.')
            ? dosya.path.split('.').last
            : 'jpg';
        final gorselAdi = await ExcelServisi.fotografiSakla(dosya, uzanti);
        final (eklendi, mesaj) = await ExcelServisi.exceleEkle(veri, gorselAdi);
        if (eklendi) {
          eklenen++;
        } else {
          atlanan++;
          notlar.add(mesaj);
        }
      } catch (e) {
        atlanan++;
        notlar.add('Bir fotoğraf işlenemedi: $e');
      }
    }

    if (!mounted) return;
    setState(() => _topluIsleniyor = false);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Toplu İşlem Tamamlandı'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${fotolar.length} fotoğraf işlendi.'),
              const SizedBox(height: 8),
              Text(
                '✓ $eklenen kayıt eklendi',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (atlanan > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '⚠ $atlanan kayıt atlandı',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...notlar.map(
                  (n) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('• $n', style: const TextStyle(fontSize: 12.5)),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Future<void> _excelPaylas() async {
    final dosya = await ExcelServisi.excelDosyasi();
    if (!mounted) return;
    await SharePlus.instance.share(
      ShareParams(files: [XFile(dosya.path)], text: 'İrsaliye Excel Dosyası'),
    );
  }

  @override
  void dispose() {
    _ocrService.dispose();
    _tarihCtrl.dispose();
    _zamanCtrl.dispose();
    _irsaliyeNoCtrl.dispose();
    _plakaCtrl.dispose();
    _dayanimCtrl.dispose();
    _uretimCtrl.dispose();
    _siparisCtrl.dispose();
    super.dispose();
  }

  Widget _fotoKarti(ColorScheme renkler) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: renkler.primary.withValues(alpha: 0.06),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_secilenFoto == null)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: renkler.primary.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.receipt_long_outlined,
                        size: 40,
                        color: renkler.primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Henüz fotoğraf seçilmedi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: renkler.primary.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'İrsaliyeyi tara ya da galeriden seç',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: renkler.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              )
            else
              Image.file(_secilenFoto!, fit: BoxFit.cover),
            if (_ocrYapiliyor)
              Container(
                color: Colors.black.withValues(alpha: 0.55),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 34,
                        height: 34,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Belge okunuyor...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final renkler = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('İrsaliye OCR'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const KayitlarEkrani()));
            },
            icon: const Icon(Icons.table_chart_outlined),
            tooltip: 'Kayıtları Gör',
          ),
          IconButton(
            onPressed: _excelPaylas,
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Excel Dosyasını Paylaş',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              children: [
                _fotoKarti(renkler),

                const SizedBox(height: 20),

                // OKUNAN / ELLE DÜZENLENEBİLEN ALANLAR
                if (_veriVarMi && !_ocrYapiliyor) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.fact_check_outlined,
                                size: 20,
                                color: renkler.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Okunan Bilgiler',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: renkler.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kaydetmeden önce kontrol edip gerekirse düzelt.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          IrsaliyeAlan(
                            etiket: 'İrsaliye Tarihi (GG-AA-YYYY)',
                            controller: _tarihCtrl,
                            ikon: Icons.calendar_today_outlined,
                            zorunlu: true,
                            readOnly: true,
                            onTap: _tarihSec,
                          ),
                          IrsaliyeAlan(
                            etiket: 'İrsaliye Zamanı (SS:DD)',
                            controller: _zamanCtrl,
                            ikon: Icons.schedule_outlined,
                            readOnly: true,
                            onTap: _zamanSec,
                          ),
                          IrsaliyeAlan(
                            etiket: 'İrsaliye No',
                            controller: _irsaliyeNoCtrl,
                            ikon: Icons.confirmation_number_outlined,
                            zorunlu: true,
                            textCapitalization: TextCapitalization.characters,
                          ),
                          IrsaliyeAlan(
                            etiket: 'Araç Plakası',
                            controller: _plakaCtrl,
                            ikon: Icons.local_shipping_outlined,
                            textCapitalization: TextCapitalization.characters,
                          ),
                          DayanimAlani(controller: _dayanimCtrl),
                          IrsaliyeAlan(
                            etiket: 'Üretim Miktarı (m³)',
                            controller: _uretimCtrl,
                            ikon: Icons.water_drop_outlined,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          IrsaliyeAlan(
                            etiket: 'Sipariş Miktarı (m³)',
                            controller: _siparisCtrl,
                            ikon: Icons.inventory_2_outlined,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FilledButton.icon(
                            onPressed: _kaydediliyor ? null : _exceleKaydet,
                            icon: _kaydediliyor
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              _kaydediliyor
                                  ? 'Kaydediliyor...'
                                  : "Excel'e Kaydet",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // KAMERA / GALERİ
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _herhangiBirIslemSuruyor ? null : kamerayiAc,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Fotoğraf Çek'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _herhangiBirIslemSuruyor ? null : galeriyiAc,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Galeriden Seç'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _herhangiBirIslemSuruyor ? null : belgeSec,
                  icon: const Icon(Icons.insert_drive_file_outlined),
                  label: const Text('Dosyalardan Belge Seç'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _herhangiBirIslemSuruyor
                      ? null
                      : _topluFotografSec,
                  icon: const Icon(Icons.collections_outlined),
                  label: const Text('Galeriden Çoklu Seç (Toplu İşle)'),
                ),
              ],
            ),
            if (_topluIsleniyor)
              Container(
                color: Colors.black.withValues(alpha: 0.45),
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Fotoğraflar işleniyor...',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: renkler.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
