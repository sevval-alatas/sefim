import 'dart:io';

import 'package:flutter/material.dart';

import 'package:sefim/servis/excel_servisi.dart';
import 'package:sefim/servis/irsaliye_kaydi.dart';
import 'package:sefim/servis/irsaliye_verisi.dart';
import 'package:sefim/widget/irsaliye_alan.dart';

/// Var olan bir kaydı düzenlemek ya da fotoğrafsız yeni bir kayıt elle
/// eklemek için kullanılan ortak ekran.
class KayitEkleEkrani extends StatefulWidget {
  const KayitEkleEkrani({super.key, this.duzenlenecekKayit});

  /// null ise "yeni kayıt", dolu ise "düzenleme" modunda açılır.
  final IrsaliyeKaydi? duzenlenecekKayit;

  @override
  State<KayitEkleEkrani> createState() => _KayitEkleEkraniState();
}

class _KayitEkleEkraniState extends State<KayitEkleEkrani> {
  late final TextEditingController _tarihCtrl;
  late final TextEditingController _zamanCtrl;
  late final TextEditingController _irsaliyeNoCtrl;
  late final TextEditingController _plakaCtrl;
  late final TextEditingController _dayanimCtrl;
  late final TextEditingController _uretimCtrl;
  late final TextEditingController _siparisCtrl;

  bool _kaydediliyor = false;
  File? _gorsel;

  bool get _duzenlemeModu => widget.duzenlenecekKayit != null;

  @override
  void initState() {
    super.initState();
    final veri = widget.duzenlenecekKayit?.veri ?? IrsaliyeVerisi();

    _tarihCtrl = TextEditingController(text: veri.tarih);
    _zamanCtrl = TextEditingController(text: veri.zaman);
    _irsaliyeNoCtrl = TextEditingController(text: veri.irsaliyeNo);
    _plakaCtrl = TextEditingController(text: veri.plaka);
    _dayanimCtrl = TextEditingController(text: veri.dayanim);
    _uretimCtrl = TextEditingController(text: veri.uretimMiktari);
    _siparisCtrl = TextEditingController(
      text: veri.siparisMiktari == '-' ? '' : veri.siparisMiktari,
    );

    if (_duzenlemeModu) {
      _fotografiYukle();
    }
  }

  Future<void> _fotografiYukle() async {
    final gorselAdi = widget.duzenlenecekKayit!.gorselDosyasi;
    final dosya = await ExcelServisi.gorselDosyasiniBul(gorselAdi);
    if (mounted) {
      setState(() => _gorsel = dosya);
    }
  }

  @override
  void dispose() {
    _tarihCtrl.dispose();
    _zamanCtrl.dispose();
    _irsaliyeNoCtrl.dispose();
    _plakaCtrl.dispose();
    _dayanimCtrl.dispose();
    _uretimCtrl.dispose();
    _siparisCtrl.dispose();
    super.dispose();
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

    final secilen = await showTimePicker(context: context, initialTime: baslangic);

    if (secilen != null) {
      final ss = secilen.hour.toString().padLeft(2, '0');
      final dd = secilen.minute.toString().padLeft(2, '0');
      setState(() => _zamanCtrl.text = '$ss:$dd');
    }
  }

  IrsaliyeVerisi _formdanVeriOlustur() {
    return IrsaliyeVerisi(
      tarih: _tarihCtrl.text.trim(),
      zaman: _zamanCtrl.text.trim(),
      irsaliyeNo: _irsaliyeNoCtrl.text.trim().toUpperCase(),
      plaka: _plakaCtrl.text.trim(),
      dayanim: _dayanimCtrl.text.trim(),
      uretimMiktari: _uretimCtrl.text.trim(),
      siparisMiktari:
          _siparisCtrl.text.trim().isEmpty ? '-' : _siparisCtrl.text.trim(),
    );
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

  Future<void> _kaydet() async {
    final veri = _formdanVeriOlustur();

    final onaylandi = await _eksikAlanlariOnayla(veri);
    if (!onaylandi) return;

    setState(() => _kaydediliyor = true);

    try {
      if (_duzenlemeModu) {
        await ExcelServisi.kaydiGuncelle(
          widget.duzenlenecekKayit!.sheetSatirIndeksi,
          veri,
        );
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        final (eklendi, mesaj) = await ExcelServisi.exceleEkle(veri, '');
        if (!mounted) return;
        if (eklendi) {
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj)));
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kaydedilirken hata oluştu: $e')),
      );
    } finally {
      if (mounted) setState(() => _kaydediliyor = false);
    }
  }

  Future<void> _sil() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kaydı sil'),
        content: const Text(
          'Bu irsaliye kaydını silmek istediğine emin misin? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (onay != true) return;

    setState(() => _kaydediliyor = true);
    try {
      await ExcelServisi.kaydiSil(widget.duzenlenecekKayit!.sheetSatirIndeksi);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silinirken hata oluştu: $e')),
      );
      setState(() => _kaydediliyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_duzenlemeModu ? 'Kaydı Düzenle' : 'Yeni Kayıt Ekle'),
        actions: [
          if (_duzenlemeModu)
            IconButton(
              onPressed: _kaydediliyor ? null : _sil,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Kaydı Sil',
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            if (_gorsel != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.file(_gorsel!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 20),
            ] else if (!_duzenlemeModu) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Bu kayıt fotoğrafsız, elle giriliyor. İstersen ana ekrandan fotoğraf çekip OCR ile de ekleyebilirsin.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            IrsaliyeAlan(
              etiket: 'Sipariş Miktarı (m³)',
              controller: _siparisCtrl,
              ikon: Icons.inventory_2_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _kaydediliyor ? null : _kaydet,
              icon: _kaydediliyor
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _kaydediliyor
                    ? 'Kaydediliyor...'
                    : (_duzenlemeModu ? 'Değişiklikleri Kaydet' : "Excel'e Kaydet"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
