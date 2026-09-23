import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'package:sefim/servis/excel_servisi.dart';
import 'package:sefim/servis/irsaliye_kaydi.dart';
import 'package:sefim/servis/irsaliye_verisi.dart';
import 'package:sefim/servis/ocr_ayiklama_servisi.dart';
import 'package:sefim/servis/ocr_service.dart';
import 'package:sefim/ekran/kayitlar_ekrani.dart';
import 'package:sefim/router/app_router.dart';
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
      title: 'Sefim',
      initialRoute: AppRouter.authRoute,
      routes: AppRouter.routes(
        home: const UygulamaMenu(),
        irsaliyeOcr: const AnaSayfa(),
        onAuthenticated: (context) {
          AppRouter.goHome(context);
        },
      ),
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
    );
  }
}

class UygulamaMenu extends StatelessWidget {
  const UygulamaMenu({super.key});

  void _rotaAc(BuildContext context, String rota) {
    Navigator.of(context).pop();
    AppRouter.push(context, rota);
  }

  void _cikisYap(BuildContext context) {
    Navigator.of(context).pop();
    AppRouter.goAuth(context);
  }

  void _irsaliyeOcrAc(BuildContext context) {
    AppRouter.push(context, AppRouter.irsaliyeRoute);
  }

  void _yapiElemanKontrolunuAc(BuildContext context) {
    AppRouter.push(context, AppRouter.yapiElemaniRoute);
  }

  void _projeOkumayiAc(BuildContext context) {
    AppRouter.push(context, AppRouter.projeOkumaRoute);
  }

  @override
  Widget build(BuildContext context) {
    final renkler = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sefim'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_outlined),
            tooltip: 'Bildirimler',
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                color: renkler.primary,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/sefim_logo.jpeg',
                        width: 58,
                        height: 58,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sefim',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'İş yönetim paneli',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Ana sayfa'),
                selected: true,
                onTap: () => Navigator.of(context).pop(),
              ),
              ListTile(
                leading: const Icon(Icons.document_scanner_outlined),
                title: const Text('İrsaliye OCR'),
                onTap: () => _rotaAc(context, AppRouter.irsaliyeRoute),
              ),
              ListTile(
                leading: const Icon(Icons.construction_outlined),
                title: const Text('Yapı eleman kontrolü'),
                onTap: () => _rotaAc(context, AppRouter.yapiElemaniRoute),
              ),
              ListTile(
                leading: const Icon(Icons.architecture_outlined),
                title: const Text('Proje okuma'),
                onTap: () => _rotaAc(context, AppRouter.projeOkumaRoute),
              ),
              const Spacer(),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout_outlined),
                title: const Text('Çıkış yap'),
                onTap: () => _cikisYap(context),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: renkler.primary.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/sefim_logo.jpeg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Sefim',
                    style: TextStyle(
                      color: renkler.primary,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'İş süreçlerinizi tek yerden yönetin',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  ),
                  const SizedBox(height: 42),
                  _MenuSecenegi(
                    ikon: Icons.document_scanner_outlined,
                    baslik: 'İrsaliye OCR',
                    aciklama:
                        'İrsaliyeleri tara, bilgileri kontrol et ve kaydet',
                    onPressed: () => _irsaliyeOcrAc(context),
                  ),
                  const SizedBox(height: 14),
                  _MenuSecenegi(
                    ikon: Icons.construction_outlined,
                    baslik: 'Yapı Eleman Kontrolü',
                    aciklama: 'Yapı elemanlarını kontrol etmek için yakında',
                    onPressed: () => _yapiElemanKontrolunuAc(context),
                    ikincil: true,
                  ),
                  const SizedBox(height: 14),
                  _MenuSecenegi(
                    ikon: Icons.architecture_outlined,
                    baslik: 'Proje Okuma',
                    aciklama: 'PDF ve proje dosyalarını aç ve incele',
                    onPressed: () => _projeOkumayiAc(context),
                    ikincil: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuSecenegi extends StatelessWidget {
  const _MenuSecenegi({
    required this.ikon,
    required this.baslik,
    required this.aciklama,
    required this.onPressed,
    this.ikincil = false,
  });

  final IconData ikon;
  final String baslik;
  final String aciklama;
  final VoidCallback onPressed;
  final bool ikincil;

  @override
  Widget build(BuildContext context) {
    final renkler = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: ikincil ? Colors.white : renkler.primary,
          foregroundColor: ikincil ? renkler.primary : Colors.white,
          side: ikincil
              ? BorderSide(color: renkler.primary.withValues(alpha: 0.28))
              : null,
          padding: const EdgeInsets.all(20),
          alignment: Alignment.centerLeft,
        ),
        child: Row(
          children: [
            Icon(ikon, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(baslik, style: const TextStyle(fontSize: 17)),
                  const SizedBox(height: 4),
                  Text(
                    aciklama,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: ikincil ? Colors.grey.shade600 : Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, size: 17),
          ],
        ),
      ),
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
  List<String> _ocrUyarilari = [];
  late Future<List<IrsaliyeKaydi>> _sonKayitlarFuture;

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

  @override
  void initState() {
    super.initState();
    _sonKayitlarFuture = ExcelServisi.tumKayitlariOku();
  }

  Future<void> _kayitlariAc() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const KayitlarEkrani()));
    if (mounted) {
      setState(() {
        _sonKayitlarFuture = ExcelServisi.tumKayitlariOku();
      });
    }
  }

  Future<void> kamerayiAc() async {
    final XFile? foto = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      maxWidth: 2400,
      maxHeight: 3200,
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
      maxWidth: 2400,
      maxHeight: 3200,
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
      _ocrUyarilari = [];
      _tumAlanlariTemizle();
    });

    try {
      final metin = await _ocrService.metniOku(foto.path);
      final veri = OcrAyiklamaServisi.metindenVerileriAyikla(metin);

      if (!mounted) return;

      setState(() {
        _alanlariDoldur(veri);
        _ocrUyarilari = veri.kontrolUyarilari;
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
          _ocrUyarilari = [];
          _tumAlanlariTemizle();
          _sonKayitlarFuture = ExcelServisi.tumKayitlariOku();
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

    for (var baslangic = 0; baslangic < fotolar.length; baslangic += 2) {
      final grup = fotolar.skip(baslangic).take(2);
      await Future.wait(
        grup.map((foto) async {
          try {
            final metin = await _ocrService.metniOku(foto.path);
            final veri = OcrAyiklamaServisi.metindenVerileriAyikla(metin);
            final dosya = File(foto.path);
            final uzanti = dosya.path.contains('.')
                ? dosya.path.split('.').last
                : 'jpg';
            final gorselAdi = await ExcelServisi.fotografiSakla(dosya, uzanti);
            final (eklendi, mesaj) = await ExcelServisi.exceleEkle(
              veri,
              gorselAdi,
            );
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
        }),
      );
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

  Widget _baslangicPanel(ColorScheme renkler) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            renkler.primary,
            Color.lerp(renkler.primary, const Color(0xFF0E7490), 0.55)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.document_scanner_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yeni irsaliye',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Belgeyi seç, bilgileri kontrol et, Excel\'e kaydet.',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 14),
                    SizedBox(width: 5),
                    Text(
                      'Hazır',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _hizliAksiyon(
                  ikon: Icons.camera_alt_outlined,
                  etiket: 'Kamera',
                  aktif: !_herhangiBirIslemSuruyor,
                  onPressed: kamerayiAc,
                  filled: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _hizliAksiyon(
                  ikon: Icons.photo_library_outlined,
                  etiket: 'Galeri',
                  aktif: !_herhangiBirIslemSuruyor,
                  onPressed: galeriyiAc,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _hizliAksiyon(
                  ikon: Icons.folder_open_outlined,
                  etiket: 'Dosya',
                  aktif: !_herhangiBirIslemSuruyor,
                  onPressed: belgeSec,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hizliAksiyon({
    required IconData ikon,
    required String etiket,
    required bool aktif,
    required VoidCallback onPressed,
    bool filled = false,
  }) {
    final arkaPlan = filled
        ? Colors.white
        : Colors.white.withValues(alpha: 0.12);
    final onPlan = filled ? _anaRenk : Colors.white;
    return SizedBox(
      height: 68,
      child: FilledButton(
        onPressed: aktif ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: arkaPlan,
          foregroundColor: onPlan,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
          disabledForegroundColor: Colors.white54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(ikon, size: 21),
            const SizedBox(height: 4),
            Text(etiket, style: const TextStyle(fontSize: 11.5)),
          ],
        ),
      ),
    );
  }

  Widget _sonKayitlar(ColorScheme renkler) {
    return FutureBuilder<List<IrsaliyeKaydi>>(
      future: _sonKayitlarFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 88,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final kayitlar = (snapshot.data ?? []).take(3).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Son kayıtlar',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton.icon(
                  onPressed: _kayitlariAc,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('Tümünü gör'),
                ),
              ],
            ),
            if (kayitlar.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: renkler.primary.withValues(alpha: 0.10),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.inbox_outlined, color: renkler.primary),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'İlk irsaliye kaydını oluşturduğunda burada görünecek.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...kayitlar.asMap().entries.map((entry) {
                final kayit = entry.value;
                final veri = kayit.veri;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _kayitlariAc,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: renkler.primary.withValues(alpha: 0.09),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${entry.key + 1}',
                                style: TextStyle(
                                  color: renkler.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    veri.irsaliyeNo.isEmpty
                                        ? 'İrsaliye No yok'
                                        : veri.irsaliyeNo,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    [
                                      if (veri.tarih.isNotEmpty) veri.tarih,
                                      if (veri.plaka.isNotEmpty) veri.plaka,
                                    ].join('  •  '),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (veri.uretimMiktari.isNotEmpty)
                              Text(
                                '${veri.uretimMiktari} m³',
                                style: TextStyle(
                                  color: renkler.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
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
            onPressed: _kayitlariAc,
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
                _baslangicPanel(renkler),
                const SizedBox(height: 18),
                _fotoKarti(renkler),
                const SizedBox(height: 18),
                _sonKayitlar(renkler),
                const SizedBox(height: 20),

                // OutlinedButton.icon(
                //   onPressed: _herhangiBirIslemSuruyor
                //       ? null
                //       : _topluFotografSec,
                //   icon: const Icon(Icons.collections_outlined),
                //   label: const Text('Birden fazla irsaliyeyi toplu işle'),
                // ),
                // const SizedBox(height: 16),
                if (_ocrUyarilari.isNotEmpty && !_ocrYapiliyor) ...[
                  Card(
                    color: Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.fact_check_outlined,
                            color: Colors.amber.shade800,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kaydetmeden önce kontrol edin',
                                  style: TextStyle(
                                    color: Colors.amber.shade900,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ..._ocrUyarilari.map(
                                  (uyari) => Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      '• $uyari',
                                      style: TextStyle(
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

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
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) _kayitlariAc();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.table_chart_outlined),
            selectedIcon: Icon(Icons.table_chart_rounded),
            label: 'Kayıtlar',
          ),
        ],
      ),
    );
  }
}
