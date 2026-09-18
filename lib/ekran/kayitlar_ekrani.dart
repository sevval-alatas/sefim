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

  @override
  void initState() {
    super.initState();
    _kayitlarFuture = ExcelServisi.tumKayitlariOku();
    _aramaCtrl.addListener(() {
      setState(() => _arama = _aramaCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _aramaCtrl.dispose();
    super.dispose();
  }

  Future<void> _yenile() async {
    final yeniFuture = ExcelServisi.tumKayitlariOku();
    setState(() => _kayitlarFuture = yeniFuture);
    await yeniFuture;
  }

  Future<void> _paylas() async {
    final dosya = await ExcelServisi.excelDosyasi();
    if (!mounted) return;
    await SharePlus.instance.share(
      ShareParams(files: [XFile(dosya.path)], text: 'İrsaliye Excel Dosyası'),
    );
  }

  Future<void> _kaydiAc({IrsaliyeKaydi? kayit}) async {
    final degisti = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => KayitEkleEkrani(duzenlenecekKayit: kayit)),
    );
    if (degisti == true) {
      await _yenile();
    }
  }

  List<IrsaliyeKaydi> _filtrele(List<IrsaliyeKaydi> kayitlar) {
    if (_arama.isEmpty) return kayitlar;
    return kayitlar.where((k) {
      final v = k.veri;
      return v.irsaliyeNo.toLowerCase().contains(_arama) ||
          v.plaka.toLowerCase().contains(_arama) ||
          v.tarih.toLowerCase().contains(_arama) ||
          v.dayanim.toLowerCase().contains(_arama);
    }).toList();
  }

  Widget _bosDurum({required bool aramaYapiliyor}) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              Icon(
                aramaYapiliyor ? Icons.search_off_rounded : Icons.inbox_outlined,
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
                aramaYapiliyor
                    ? 'Farklı bir arama terimi dene.'
                    : 'Bir irsaliye fotoğrafı kaydettiğinde ya da elle\nyeni kayıt eklediğinde burada görünecek.',
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
            style: TextStyle(fontSize: 11.5, color: renkler.primary.withValues(alpha: 0.9)),
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
                child: Icon(Icons.receipt_long_outlined, color: renkler.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.irsaliyeNo.isEmpty ? 'İrsaliye No yok' : v.irsaliyeNo,
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (v.tarih.isNotEmpty) v.tarih,
                        if (v.zaman.isNotEmpty) v.zaman,
                      ].join('  •  '),
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (v.plaka.isNotEmpty)
                          _etiketCipi(v.plaka, Icons.local_shipping_outlined, renkler),
                        if (v.dayanim.isNotEmpty)
                          _etiketCipi(v.dayanim, Icons.foundation_outlined, renkler),
                        if (v.uretimMiktari.isNotEmpty)
                          _etiketCipi('${v.uretimMiktari} m³', Icons.water_drop_outlined, renkler),
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
                          Center(child: Text('Kayıtlar okunamadı:\n${snapshot.error}')),
                        ],
                      );
                    }

                    final tumKayitlar = snapshot.data ?? [];
                    final kayitlar = _filtrele(tumKayitlar);

                    if (kayitlar.isEmpty) {
                      return _bosDurum(aramaYapiliyor: _arama.isNotEmpty);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                      itemCount: kayitlar.length,
                      itemBuilder: (context, index) => _kayitKarti(kayitlar[index], renkler),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
