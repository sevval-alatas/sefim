import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import 'package:sefim/servis/cad_donusum_servisi.dart';
import 'package:sefim/widget/dxf_goruntuleyici.dart';

class ProjeOkumaEkrani extends StatefulWidget {
  const ProjeOkumaEkrani({super.key});

  @override
  State<ProjeOkumaEkrani> createState() => _ProjeOkumaEkraniState();
}

class _ProjeOkumaEkraniState extends State<ProjeOkumaEkrani> {
  final CadDonusumServisi _cadServisi = CadDonusumServisi();
  String? _dosyaYolu;
  String? _dxfYolu;
  String? _aktifProjeAdi;
  bool _donusturuluyor = false;
  List<KayitliProje> _kayitliProjeler = [];
  bool _projelerYukleniyor = false;

  @override
  void initState() {
    super.initState();
    _kayitliProjeleriYukle();
  }

  Future<void> _kayitliProjeleriYukle() async {
    setState(() => _projelerYukleniyor = true);
    final projeler = await _cadServisi.kayitliProjeleriGetir();
    if (!mounted) return;
    setState(() {
      _kayitliProjeler = projeler;
      _projelerYukleniyor = false;
    });
  }

  String? get _uzanti {
    final yol = _dosyaYolu;
    if (yol == null || !yol.contains('.')) return null;
    return yol.split('.').last.toLowerCase();
  }

  Future<void> _projeSec() async {
    final sonuc = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'jpg',
        'jpeg',
        'png',
        'heic',
        'webp',
        'dwg',
        'dxf',
      ],
    );
    final yol = sonuc.isEmpty ? null : sonuc.single.path;
    if (yol == null || !mounted) return;

    final ad = yol.split(Platform.pathSeparator).last;
    setState(() {
      _dosyaYolu = yol;
      _dxfYolu = null;
      _aktifProjeAdi = ad;
    });

    if (_uzanti == 'dwg' || _uzanti == 'dxf') {
      await _cadDosyasiniDonustur(yol);
    }
  }

  Future<void> _cadDosyasiniDonustur(String yol, {bool zorlaReconvert = false}) async {
    setState(() => _donusturuluyor = true);
    try {
      final dxf = await _cadServisi.dxfyeDonustur(yol, zorlaYenidenDonustur: zorlaReconvert);
      if (!mounted) return;
      setState(() {
        _dxfYolu = dxf.path;
        _donusturuluyor = false;
      });
      await _kayitliProjeleriYukle();
    } catch (e, stackTrace) {
      debugPrint('CAD dönüşüm hatası: $e\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _dosyaYolu = null;
        _dxfYolu = null;
        _donusturuluyor = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
        content: Text('Dönüştürme Hatası: $e'),
        duration: const Duration(seconds: 5),
      ));
    }
  }

  void _kayitliProjeyiAc(KayitliProje proje) {
    setState(() {
      _dosyaYolu = proje.dxfYolu;
      _dxfYolu = proje.dxfYolu;
      _aktifProjeAdi = proje.ad;
      _donusturuluyor = false;
    });
  }

  Future<void> _kayitliProjeyiSil(KayitliProje proje) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Projeyi Sil'),
        content: Text('"${proje.ad}" isimli kayıtlı proje yerel depolamadan silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (onay == true) {
      await _cadServisi.kayitliProjeyiSil(proje.id);
      if (_dxfYolu == proje.dxfYolu) {
        setState(() {
          _dosyaYolu = null;
          _dxfYolu = null;
          _aktifProjeAdi = null;
        });
      }
      await _kayitliProjeleriYukle();
    }
  }

  Future<void> _apiAyarlariniGoster() async {
    final mevcutUrl = await _cadServisi.apiAdresiniGetir();
    final controller = TextEditingController(text: mevcutUrl);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        bool testEdiliyor = false;
        String? testSonucu;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.dns_outlined),
                  SizedBox(width: 8),
                  Text('Python API Ayarları'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DWG dosyalarını DXF\'e dönüştürmek için kullanılan Python FastAPI servis adresi:',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'API Sunucu URL',
                      hintText: 'http://localhost:8000',
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (testEdiliyor)
                    const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Sunucu bağlantısı test ediliyor...'),
                      ],
                    )
                  else if (testSonucu != null)
                    Text(
                      testSonucu!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: testSonucu!.contains('başarılı') ? Colors.green : Colors.red,
                      ),
                    ),
                ],
              ),
              actions: [
                OutlinedButton(
                  onPressed: testEdiliyor
                      ? null
                      : () async {
                          setDialogState(() {
                            testEdiliyor = true;
                            testSonucu = null;
                          });
                          final basarili = await _cadServisi.apiSunucusuTestEt(controller.text.trim());
                          setDialogState(() {
                            testEdiliyor = false;
                            testSonucu = basarili
                                ? '✅ Sunucu bağlantısı başarılı!'
                                : '❌ Sunucuya erişilemedi. Sunucunun çalıştığından emin olun.';
                          });
                        },
                  child: const Text('Bağlantıyı Test Et'),
                ),
                FilledButton(
                  onPressed: () async {
                    await _cadServisi.apiAdresiniGuncelle(controller.text.trim());
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('API adresi güncellendi.')),
                      );
                    }
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _bosDurum(ColorScheme renkler) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: renkler.primaryContainer.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.architecture_outlined,
                      size: 38,
                      color: renkler.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Projenizi Açın veya Seçin',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'DWG, DXF, PDF veya görsel dosyalarınızı açabilir, dönüştürülmüş projelerinize internet olmadan erişebilirsiniz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: renkler.onSurfaceVariant, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _projeSec,
                    icon: const Icon(Icons.folder_open_outlined),
                    label: const Text('Cihazdan Dosya Seç (DWG / DXF)'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.offline_pin, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kayıtlı Projeler (Çevrimdışı Erişilebilir)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _kayitliProjeleriYukle,
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Yenile',
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_projelerYukleniyor)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_kayitliProjeler.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.cloud_done_outlined, size: 40, color: renkler.outline),
                    const SizedBox(height: 8),
                    const Text(
                      'Henüz kaydedilmiş bir proje yok.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dönüştürülen veya açılan DWG/DXF projeleriniz buraya otomatik kaydedilir ve internet olmadan açılabilir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: renkler.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _kayitliProjeler.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final p = _kayitliProjeler[index];
                final kb = (p.dosyaBoyutu / 1024).toStringAsFixed(1);
                final tarihStr =
                    '${p.kayitTarihi.day}.${p.kayitTarihi.month}.${p.kayitTarihi.year} ${p.kayitTarihi.hour.toString().padLeft(2, '0')}:${p.kayitTarihi.minute.toString().padLeft(2, '0')}';

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.withValues(alpha: 0.15),
                      child: const Icon(Icons.offline_pin, color: Colors.green),
                    ),
                    title: Text(
                      p.ad,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Kayıt: $tarihStr • $kb KB • Çevrimdışı Hazır',
                      style: TextStyle(fontSize: 12, color: renkler.onSurfaceVariant),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          tooltip: 'Sil',
                          onPressed: () => _kayitliProjeyiSil(p),
                        ),
                        FilledButton.tonal(
                          onPressed: () => _kayitliProjeyiAc(p),
                          child: const Text('Aç'),
                        ),
                      ],
                    ),
                    onTap: () => _kayitliProjeyiAc(p),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _dosyaGoruntule(ColorScheme renkler) {
    final yol = _dosyaYolu!;
    if (_donusturuluyor) return _donusumDurumu(renkler);
    switch (_uzanti) {
      case 'pdf':
        return PdfViewPinch(
          controller: PdfControllerPinch(document: PdfDocument.openFile(yol)),
        );
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'heic':
      case 'webp':
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 8,
          child: Center(child: Image.file(File(yol))),
        );
      case 'dwg':
      case 'dxf':
        if (_dxfYolu == null) return _donusumDurumu(renkler);
        return _dxfGoruntule(renkler);
      default:
        return _cadBeklemeDurumu(renkler, 'DOSYA');
    }
  }

  Widget _donusumDurumu(ColorScheme renkler) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: renkler.primary),
          const SizedBox(height: 18),
          const Text(
            'DWG dosyası dönüştürülüyor...',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Python API veya yerel kütüphaneler kullanılarak DXF oluşturuluyor. Tamamlandığında uygulama içine kaydedilecektir.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dxfGoruntule(ColorScheme renkler) {
    return FutureBuilder<List<DxfEntity>>(
      future: File(_dxfYolu!).readAsBytes().then((bytes) {
        final content = utf8.decode(bytes, allowMalformed: true);
        debugPrint('DXF dosya yolu: $_dxfYolu');
        debugPrint('DXF içerik uzunluğu: ${content.length}');
        final entities = DxfParser.parse(content);
        debugPrint('Parse edilen toplam entity sayısı: ${entities.length}');
        return entities;
      }),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('DXF parse hatası: ${snapshot.error}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'DXF dosyası okunamadı: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: renkler.primary),
          );
        }
        final entities = snapshot.data!;
        if (entities.isEmpty) {
          return const Center(
            child: Text('DXF içinde görüntülenebilir öğe bulunamadı.'),
          );
        }
        return DxfGoruntuleyici(entities: entities);
      },
    );
  }

  Widget _cadBeklemeDurumu(ColorScheme renkler, String uzanti) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.layers_outlined, size: 64, color: renkler.primary),
            const SizedBox(height: 16),
            Text(
              '$uzanti görüntüleyici hazır değil',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'PDF, görsel ve DXF dosyaları kullanılabilir.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _projeSec,
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('Başka dosya seç'),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_aktifProjeAdi ?? 'Proje Okuma'),
            if (_dxfYolu != null)
              const Row(
                children: [
                  Icon(Icons.offline_pin, size: 12, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    'Kayıtlı Proje • Çevrimdışı Erişilebilir',
                    style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _apiAyarlariniGoster,
            icon: const Icon(Icons.dns_outlined),
            tooltip: 'Python API Ayarları',
          ),
          IconButton(
            onPressed: _projeSec,
            icon: const Icon(Icons.folder_open_outlined),
            tooltip: 'Proje aç',
          ),
        ],
      ),
      body: _dosyaYolu == null ? _bosDurum(renkler) : _dosyaGoruntule(renkler),
      floatingActionButton: _dosyaYolu == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  _dosyaYolu = null;
                  _dxfYolu = null;
                  _aktifProjeAdi = null;
                });
                _kayitliProjeleriYukle();
              },
              icon: const Icon(Icons.list_alt),
              label: const Text('Projeler Listesi'),
            ),
    );
  }
}
