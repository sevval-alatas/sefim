import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:share_plus/share_plus.dart';

import 'package:sefim/ekran/kayit_ekle_ekrani.dart';
import 'package:sefim/servis/excel_servisi.dart';
import 'package:sefim/servis/irsaliye_kaydi.dart';

/// Excel'e kaydedilmiş tüm irsaliyeleri liste halinde gösteren; arama,
/// düzenleme, silme ve elle yeni kayıt eklemeyi destekleyen ekran.
class KayitlarEkrani extends StatefulWidget {
  const KayitlarEkrani({super.key});

  @override
  State<KayitlarEkrani> createState() => _KayitlarEkraniState();
}

class _KayitlarEkraniState extends State<KayitlarEkrani> {
  late Future<List<IrsaliyeKaydi>> _kayitlarFuture;
  final _aramaCtrl = TextEditingController();
  String _arama = '';
  bool _eksikAlanlariGoster = false;
  DateTimeRange? _tarihAraligi;
  int _siralama = 0;

  @override
  void initState() {
    super.initState();
    _kayitlarFuture = ExcelServisi.tumKayitlariOku();
    _aramaCtrl.addListener(() {
      setState(() {
        _arama = _aramaCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _aramaCtrl.dispose();
    super.dispose();
  }

  Future<void> _yenile() async {
    final yeniFuture = ExcelServisi.tumKayitlariOku();
    setState(() {
      _kayitlarFuture = yeniFuture;
    });
    await yeniFuture;
  }

  Future<void> _paylas() async {
    final dosya = await ExcelServisi.excelDosyasi();
    if (!mounted) return;
    await SharePlus.instance.share(
      ShareParams(files: [XFile(dosya.path)], text: 'İrsaliye Excel Dosyası'),
    );
  }

  Future<void> _yedekle() async {
    try {
      final dosya = await ExcelServisi.yedekOlustur();
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(files: [XFile(dosya.path)], text: 'İrsaliye Excel yedeği'),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Yedek oluşturulamadı: $e')));
    }
  }

  Future<void> _kaydiAc({IrsaliyeKaydi? kayit}) async {
    final degisti = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => KayitEkleEkrani(duzenlenecekKayit: kayit),
      ),
    );
    if (degisti == true) {
      await _yenile();
    }
  }

  List<IrsaliyeKaydi> _filtrele(List<IrsaliyeKaydi> kayitlar) {
    final filtreli = kayitlar.where((k) {
      final v = k.veri;
      final aramaEslesiyor =
          _arama.isEmpty ||
          v.irsaliyeNo.toLowerCase().contains(_arama) ||
          v.plaka.toLowerCase().contains(_arama) ||
          v.tarih.toLowerCase().contains(_arama) ||
          v.dayanim.toLowerCase().contains(_arama);
      final tarihEslesiyor =
          _tarihAraligi == null || _tarihiAraliktaMi(v.tarih);
      final eksikEslesiyor =
          !_eksikAlanlariGoster || v.kontrolUyarilari.isNotEmpty;
      return aramaEslesiyor && tarihEslesiyor && eksikEslesiyor;
    }).toList();

    filtreli.sort((a, b) {
      if (_siralama == 1) return a.veri.tarih.compareTo(b.veri.tarih);
      if (_siralama == 2) {
        final aMiktar =
            double.tryParse(a.veri.uretimMiktari.replaceAll(',', '.')) ?? 0;
        final bMiktar =
            double.tryParse(b.veri.uretimMiktari.replaceAll(',', '.')) ?? 0;
        return bMiktar.compareTo(aMiktar);
      }
      return b.sheetSatirIndeksi.compareTo(a.sheetSatirIndeksi);
    });
    return filtreli;
  }

  bool _tarihiAraliktaMi(String tarih) {
    final parcalar = tarih.split('-');
    if (parcalar.length != 3) return false;
    final tarihDegeri = DateTime.tryParse(
      '${parcalar[2]}-${parcalar[1]}-${parcalar[0]}',
    );
    if (tarihDegeri == null || _tarihAraligi == null) return false;
    final baslangic = DateTime(
      _tarihAraligi!.start.year,
      _tarihAraligi!.start.month,
      _tarihAraligi!.start.day,
    );
    final bitis = DateTime(
      _tarihAraligi!.end.year,
      _tarihAraligi!.end.month,
      _tarihAraligi!.end.day,
      23,
      59,
      59,
    );
    return !tarihDegeri.isBefore(baslangic) && !tarihDegeri.isAfter(bitis);
  }

  Future<void> _filtreleriAc() async {
    var eksik = _eksikAlanlariGoster;
    var siralama = _siralama;
    var tarihAraligi = _tarihAraligi;

    final uygulandi = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Listeyi düzenle',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: eksik,
                  title: const Text('Kontrol bekleyenleri göster'),
                  subtitle: const Text('Eksik veya biçimi şüpheli kayıtlar'),
                  onChanged: (value) =>
                      setSheetState(() => eksik = value ?? false),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tarih aralığı'),
                  subtitle: Text(
                    tarihAraligi == null
                        ? 'Tüm tarihler'
                        : '${_tarihYaz(tarihAraligi!.start)} - ${_tarihYaz(tarihAraligi!.end)}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Tarih seç',
                    icon: const Icon(Icons.date_range_outlined),
                    onPressed: () async {
                      final secilen = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2015),
                        lastDate: DateTime(2100),
                        initialDateRange: tarihAraligi,
                      );
                      if (secilen != null) {
                        setSheetState(() => tarihAraligi = secilen);
                      }
                    },
                  ),
                ),
                DropdownButtonFormField<int>(
                  value: siralama,
                  decoration: const InputDecoration(labelText: 'Sıralama'),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('En yeni kayıtlar')),
                    DropdownMenuItem(value: 1, child: Text('Tarihe göre')),
                    DropdownMenuItem(
                      value: 2,
                      child: Text('Üretim miktarına göre'),
                    ),
                  ],
                  onChanged: (value) =>
                      setSheetState(() => siralama = value ?? 0),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Vazgeç'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Uygula'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (uygulandi == true && mounted) {
      setState(() {
        _eksikAlanlariGoster = eksik;
        _siralama = siralama;
        _tarihAraligi = tarihAraligi;
      });
    }
  }

  String _tarihYaz(DateTime tarih) =>
      '${tarih.day.toString().padLeft(2, '0')}.${tarih.month.toString().padLeft(2, '0')}.${tarih.year}';

  Widget _bosDurum({required bool aramaYapiliyor}) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              Icon(
                aramaYapiliyor
                    ? Icons.search_off_rounded
                    : Icons.inbox_outlined,
                size: 52,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 14),
              Text(
                aramaYapiliyor ? 'Sonuç bulunamadı' : 'Henüz kayıt yok',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                aramaYapiliyor ? 'Farklı bir arama terimi dene.' : 'Bir irsaliye fotoğrafı kaydettiğinde ya da elle\nyeni kayıt eklediğinde burada görünecek.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _etiketCipi(String metin, IconData ikon, ColorScheme renkler) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: renkler.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 13, color: renkler.primary.withValues(alpha: 0.8)),
          const SizedBox(width: 4),
          Text(
            metin,
            style: TextStyle(
              fontSize: 11.5,
              color: renkler.primary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kayitKarti(IrsaliyeKaydi kayit, ColorScheme renkler) {
    final v = kayit.veri;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _kaydiAc(kayit: kayit),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: renkler.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: renkler.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.irsaliyeNo.isEmpty ? 'İrsaliye No yok' : v.irsaliyeNo,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (v.tarih.isNotEmpty) v.tarih,
                        if (v.zaman.isNotEmpty) v.zaman,
                      ].join('  •  '),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (v.plaka.isNotEmpty)
                          _etiketCipi(
                            v.plaka,
                            Icons.local_shipping_outlined,
                            renkler,
                          ),
                        if (v.dayanim.isNotEmpty)
                          _etiketCipi(
                            v.dayanim,
                            Icons.foundation_outlined,
                            renkler,
                          ),
                        if (v.uretimMiktari.isNotEmpty)
                          _etiketCipi(
                            '${v.uretimMiktari} m³',
                            Icons.water_drop_outlined,
                            renkler,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ozet(List<IrsaliyeKaydi> kayitlar, ColorScheme renkler) {
    final toplam = kayitlar.fold<double>(
      0,
      (deger, kayit) =>
          deger +
          (double.tryParse(kayit.veri.uretimMiktari.replaceAll(',', '.')) ?? 0),
    );
    final kontrolBekleyen = kayitlar
        .where((kayit) => kayit.veri.kontrolUyarilari.isNotEmpty)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: _ozetKutusu(
              '${kayitlar.length}',
              'Kayıt',
              Icons.receipt_long_outlined,
              renkler,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ozetKutusu(
              '${toplam.toStringAsFixed(1)} m³',
              'Toplam üretim',
              Icons.water_drop_outlined,
              renkler,
            ),
          ),
          if (kontrolBekleyen > 0) ...[
            const SizedBox(width: 8),
            Expanded(
              child: _ozetKutusu(
                '$kontrolBekleyen',
                'Kontrol',
                Icons.warning_amber_outlined,
                renkler,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _ozetKutusu(
    String deger,
    String etiket,
    IconData ikon,
    ColorScheme renkler,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: renkler.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(ikon, size: 18, color: renkler.primary),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deger,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  etiket,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final renkler = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıtlı İrsaliyeler'),
        actions: [
          IconButton(
            onPressed: _paylas,
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Excel Dosyasını Paylaş',
          ),
          IconButton(
            onPressed: _yedekle,
            icon: const Icon(Icons.backup_outlined),
            tooltip: 'Excel yedeği oluştur',
          ),
          IconButton(
            onPressed: _filtreleriAc,
            icon: Badge(
              isLabelVisible:
                  _eksikAlanlariGoster ||
                  _tarihAraligi != null ||
                  _siralama != 0,
              child: const Icon(Icons.tune_outlined),
            ),
            tooltip: 'Filtreleri düzenle',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _kaydiAc(),
        icon: const Icon(Icons.add),
        label: const Text('Elle Ekle'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: TextField(
                controller: _aramaCtrl,
                decoration: InputDecoration(
                  hintText: 'İrsaliye no, plaka, tarih veya dayanım ara...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  suffixIcon: _arama.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: _aramaCtrl.clear,
                        ),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _yenile,
                child: FutureBuilder<List<IrsaliyeKaydi>>(
                  future: _kayitlarFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return ListView(
                        children: [
                          const SizedBox(height: 80),
                          Center(
                            child: Text(
                              'Kayıtlar okunamadı:\n${snapshot.error}',
                            ),
                          ),
                        ],
                      );
                    }

                    final tumKayitlar = snapshot.data ?? [];
                    final kayitlar = _filtrele(tumKayitlar);

                    if (kayitlar.isEmpty) {
                      return _bosDurum(aramaYapiliyor: _arama.isNotEmpty);
                    }

                    return ListView(
                      padding: const EdgeInsets.only(top: 4, bottom: 90),
                      children: [
                        _ozet(kayitlar, renkler),
                        ...kayitlar.map(
                          (kayit) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _kayitKarti(kayit, renkler),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          if (index == 0 && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
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
