import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sefim/servis/cad_donusum_servisi.dart';
import 'package:sefim/servis/cad_mobil_sahnesi.dart';
import 'package:sefim/widget/cad_sahne_goruntuleyici.dart';
import 'package:sefim/widget/dxf_goruntuleyici.dart';
import 'package:sefim/widget/proje_pdf_goruntuleyici.dart';

class ProjeOkumaEkrani extends StatefulWidget {
  const ProjeOkumaEkrani({super.key});

  @override
  State<ProjeOkumaEkrani> createState() => _ProjeOkumaEkraniState();
}

class _ProjeOkumaEkraniState extends State<ProjeOkumaEkrani> {
  final CadDonusumServisi _cadServisi = CadDonusumServisi();
  String? _dosyaYolu;
  String? _dxfYolu;
  String? _pdfYolu;
  String? _aktifProjeAdi;
  String? _dxfParseYolu;
  Future<List<DxfEntity>>? _dxfEntityleriFuture;
  CadMobileScene? _mobileScene;
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
    final String? yol;
    if (Platform.isAndroid) {
      yol = await const MethodChannel('sefim/file_picker')
          .invokeMethod<String>('pickDocument');
    } else {
      final sonuc = await FilePicker.pickFile(
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
      yol = sonuc?.path;
    }
    if (yol == null || !mounted) return;

    const desteklenenUzantilar = {
      'pdf',
      'jpg',
      'jpeg',
      'png',
      'heic',
      'webp',
      'dwg',
      'dxf',
    };
    final secilenUzanti = yol.split('.').last.toLowerCase();
    if (!desteklenenUzantilar.contains(secilenUzanti)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Yalnızca DWG, DXF, PDF veya görsel dosyaları açılabilir.',
          ),
        ),
      );
      return;
    }

    late final KayitliProje proje;
    try {
      proje = await _cadServisi.projeyiKaliciKaydet(yol);
    } catch (e, stackTrace) {
      debugPrint('Proje kalıcı olarak kaydedilemedi: $e\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Proje kaydedilemedi: $e')));
      return;
    }
    final kaliciYol = proje.goruntulemeYolu;
    final uzanti = kaliciYol.split('.').last.toLowerCase();
    setState(() {
      _dxfParseYolu = null;
      _dxfEntityleriFuture = null;
      _mobileScene = null;
      _dosyaYolu = kaliciYol;
      _dxfYolu = null;
      _pdfYolu = null;
      _aktifProjeAdi = proje.ad;
    });

    if (uzanti == 'dwg' || uzanti == 'dxf') {
      await _cadDosyasiniDonustur(
        kaliciYol,
        zorlaReconvert: uzanti == 'dxf',
        projeId: proje.id,
      );
    } else {
      final isPdf = uzanti == 'pdf';
      setState(() {
        _pdfYolu = isPdf ? kaliciYol : null;
        _dxfYolu = uzanti == 'dxf' ? kaliciYol : null;
      });
      await _kayitliProjeleriYukle();
    }
  }

  Future<void> _cadDosyasiniDonustur(
    String yol, {
    bool zorlaReconvert = false,
    String hedefFormat = 'dxf',
    String? projeId,
  }) async {
    setState(() => _donusturuluyor = true);
    try {
      CadMobileScene? mobileScene;
      late final File sonuc;
      if (hedefFormat == 'dxf' && yol.toLowerCase().endsWith('.dwg')) {
        try {
          final sceneResult = await _cadServisi
              .dwgDosyasiniMobilSahneyeDonustur(yol, projeId: projeId);
          sonuc = sceneResult.dxfFile;
          mobileScene = sceneResult.scene;
        } catch (error, stackTrace) {
          debugPrint(
            'JSON CAD sahnesi alınamadı; DXF yedeği deneniyor: '
            '$error\n$stackTrace',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'JSON önizleme alınamadı; DXF dönüştürme yedeği deneniyor.',
                ),
              ),
            );
          }
          sonuc = await _cadServisi.dxfyeDonustur(
            yol,
            zorlaYenidenDonustur: zorlaReconvert,
            format: hedefFormat,
            projeId: projeId,
          );
        }
      } else {
        sonuc = await _cadServisi.dxfyeDonustur(
          yol,
          zorlaYenidenDonustur: zorlaReconvert,
          format: hedefFormat,
          projeId: projeId,
        );
      }
      if (!mounted) return;
      final isPdf = sonuc.path.toLowerCase().endsWith('.pdf');
      setState(() {
        _dxfParseYolu = null;
        _dxfEntityleriFuture = null;
        _mobileScene = mobileScene;
        if (isPdf) {
          _pdfYolu = sonuc.path;
          _dxfYolu = null;
        } else {
          _dxfYolu = sonuc.path;
          _pdfYolu = null;
        }
        _donusturuluyor = false;
      });
      await _kayitliProjeleriYukle();
    } catch (e, stackTrace) {
      debugPrint('CAD dönüşüm hatası: $e\n$stackTrace');
      await _kayitliProjeleriYukle();
      if (!mounted) return;
      setState(() {
        _dosyaYolu = null;
        _dxfYolu = null;
        _pdfYolu = null;
        _donusturuluyor = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dönüştürme Hatası: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _gorunumModunuDegistir() async {
    final suAnkiPdf = _pdfYolu != null;
    final hedefFormat = suAnkiPdf ? 'dxf' : 'pdf';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          suAnkiPdf
              ? 'CAD DXF Moduna geçiliyor...'
              : 'Vektörel PDF Moduna geçiliyor...',
        ),
        duration: const Duration(milliseconds: 900),
      ),
    );

    final aktifAd = _aktifProjeAdi;
    final aktifProje = _kayitliProjeler.cast<KayitliProje?>().firstWhere(
      (proje) => proje?.ad == aktifAd,
      orElse: () => null,
    );

    // Aktif dosya DWG ise hedef formatta dönüştür veya önbellekten al
    final aktifDwg =
        _dosyaYolu != null && _dosyaYolu!.toLowerCase().endsWith('.dwg')
        ? _dosyaYolu!
        : null;

    if (aktifDwg != null) {
      await _cadDosyasiniDonustur(
        aktifDwg,
        hedefFormat: hedefFormat,
        projeId: aktifProje?.id,
      );
      return;
    }

    // Kayıtlı proje içindeki diğer dosya yolunu kontrol et
    if (aktifProje != null) {
      final dwgYolu = aktifProje.dwgYolu;
      if (dwgYolu != null && File(dwgYolu).existsSync()) {
        await _cadDosyasiniDonustur(
          dwgYolu,
          hedefFormat: hedefFormat,
          projeId: aktifProje.id,
        );
        return;
      }
    }

    if (suAnkiPdf && _dxfYolu != null && File(_dxfYolu!).existsSync()) {
      setState(() => _pdfYolu = null);
    } else if (!suAnkiPdf && _pdfYolu != null && File(_pdfYolu!).existsSync()) {
      setState(() => _dxfYolu = null);
    }
  }

  Future<void> _kayitliProjeyiAc(KayitliProje proje) async {
    final hedefYol = proje.goruntulemeYolu;
    final uzanti = hedefYol.split('.').last.toLowerCase();
    final kayitliSahne = await _cadServisi.kayitliMobilSahneyiGetir(proje.id);
    if (!mounted) return;

    if (uzanti == 'dwg') {
      if (kayitliSahne != null) {
        setState(() {
          _dosyaYolu = hedefYol;
          _pdfYolu = null;
          _dxfYolu = proje.dxfYolu;
          _mobileScene = kayitliSahne;
          _aktifProjeAdi = proje.ad;
          _donusturuluyor = false;
        });
        return;
      }
      setState(() {
        _dosyaYolu = hedefYol;
        _aktifProjeAdi = proje.ad;
      });
      await _cadDosyasiniDonustur(hedefYol, projeId: proje.id);
      return;
    }
    final isPdf = proje.pdfMi || uzanti == 'pdf';
    final isDxf = uzanti == 'dxf';
    setState(() {
      _dosyaYolu = hedefYol;
      _pdfYolu = isPdf ? hedefYol : null;
      _dxfYolu = isDxf ? hedefYol : null;
      _mobileScene = isDxf ? kayitliSahne : null;
      _aktifProjeAdi = proje.ad;
      _donusturuluyor = false;
    });
  }

  Future<void> _kayitliProjeyiSil(KayitliProje proje) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Projeyi Sil'),
        content: Text(
          '"${proje.ad}" isimli kayıtlı proje yerel depolamadan silinsin mi?',
        ),
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
      if (_dosyaYolu == proje.goruntulemeYolu) {
        setState(() {
          _dosyaYolu = null;
          _dxfYolu = null;
          _pdfYolu = null;
          _mobileScene = null;
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
                  Text('CAD API Ayarları'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DWG dosyalarını DXF\'e dönüştürmek için kullanılan CAD servis adresi:',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'API Sunucu URL',
                      hintText: CadDonusumServisi.varsayilanApiUrl(),
                      prefixIcon: const Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      await _cadServisi.apiAdresiniSifirla();
                      controller.text = CadDonusumServisi.varsayilanApiUrl();
                      setDialogState(() {
                        testSonucu =
                            '✅ Varsayılan adrese (${CadDonusumServisi.varsayilanApiUrl()}) sıfırlandı.';
                      });
                    },
                    icon: const Icon(Icons.restore, size: 16),
                    label: const Text(
                      'Varsayılan sunucuya sıfırla',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
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
                        color:
                            testSonucu!.contains('başarılı') ||
                                testSonucu!.contains('sıfırlandı')
                            ? Colors.green
                            : Colors.red,
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
                          final basarili = await _cadServisi.apiSunucusuTestEt(
                            controller.text.trim(),
                          );
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
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    await _cadServisi.apiAdresiniGuncelle(
                      controller.text.trim(),
                    );
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('API adresi güncellendi.'),
                        ),
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
                    'DWG, DXF veya CAD çizim dosyalarınızı açabilir, kayıtlı projelerinize çevrimdışı erişebilirsiniz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: renkler.onSurfaceVariant,
                      fontSize: 13,
                    ),
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
                    const Icon(
                      Icons.offline_pin,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kayıtlı Projeler (Çevrimdışı Erişilebilir)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
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
                    Icon(
                      Icons.cloud_done_outlined,
                      size: 40,
                      color: renkler.outline,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Henüz kaydedilmiş bir proje yok.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dönüştürülen veya açılan DWG/DXF projeleriniz buraya otomatik kaydedilir ve internet olmadan açılabilir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: renkler.onSurfaceVariant,
                      ),
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
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final p = _kayitliProjeler[index];
                final kb = (p.dosyaBoyutu / 1024).toStringAsFixed(1);
                final tarihStr =
                    '${p.kayitTarihi.day}.${p.kayitTarihi.month}.${p.kayitTarihi.year} ${p.kayitTarihi.hour.toString().padLeft(2, '0')}:${p.kayitTarihi.minute.toString().padLeft(2, '0')}';

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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
                      style: TextStyle(
                        fontSize: 12,
                        color: renkler.onSurfaceVariant,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
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

    // 1. DXF formatı ise -> DXF Görüntüleyici ile açın (yazılar temiz, çizgiler ince)
    if (_dxfYolu != null && _pdfYolu == null) {
      return _dxfGoruntule(renkler);
    }

    // 2. PDF formatı ise -> Fallback PDF Görüntüleyici ile açın (A0 Vektörel PDF, sonsuz zoom imkanı)
    if (_pdfYolu != null || _uzanti == 'pdf') {
      final gosterilecekPdf = _pdfYolu ?? yol;
      return ProjePdfGoruntuleyici(
        pdfPath: gosterilecekPdf,
        baslik: _aktifProjeAdi,
        embedded: true,
      );
    }

    // 2. Diğer dosya formatları
    switch (_uzanti) {
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
        if (_dxfYolu == null && _pdfYolu == null) {
          return _donusumDurumu(renkler);
        }
        if (_pdfYolu != null) {
          return ProjePdfGoruntuleyici(
            pdfPath: _pdfYolu!,
            baslik: _aktifProjeAdi,
            embedded: true,
          );
        }
        return _dxfGoruntule(renkler);
      case 'dxf':
        if (_pdfYolu != null) {
          return ProjePdfGoruntuleyici(
            pdfPath: _pdfYolu!,
            baslik: _aktifProjeAdi,
            embedded: true,
          );
        }
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
            'Çizim hazırlanıyor...',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'CAD çizimi işleniyor ve optimize ediliyor. Tamamlandığında yüksek çözünürlüklü vektörel çizim olarak açılacaktır.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dxfGoruntule(ColorScheme renkler) {
    final scene = _mobileScene;
    if (scene != null) {
      return CadSahneGoruntuleyici(scene: scene);
    }
    final dxfYolu = _dxfYolu!;
    return FutureBuilder<List<DxfEntity>>(
      future: _dxfEntityleriniGetir(dxfYolu),
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

  Future<List<DxfEntity>> _dxfEntityleriniGetir(String yol) {
    if (_dxfParseYolu != yol || _dxfEntityleriFuture == null) {
      _dxfParseYolu = yol;
      _dxfEntityleriFuture = File(yol).readAsBytes().then((bytes) {
        final content = utf8.decode(bytes, allowMalformed: true);
        debugPrint('DXF dosya yolu: $yol');
        debugPrint('DXF içerik uzunluğu: ${content.length}');
        final entities = DxfParser.parse(content);
        debugPrint('Parse edilen toplam entity sayısı: ${entities.length}');
        return entities;
      });
    }
    return _dxfEntityleriFuture!;
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
              'DWG, DXF ve CAD çizim dosyaları kullanılabilir.',
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
    final compactAppBar = MediaQuery.sizeOf(context).width < 400;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _aktifProjeAdi ?? 'Proje Okuma',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_dxfYolu != null)
              const Row(
                children: [
                  Icon(Icons.offline_pin, size: 12, color: Colors.green),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Kayıtlı Proje • Çevrimdışı Erişilebilir',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        actions: [
          if (_dosyaYolu != null)
            compactAppBar
                ? IconButton(
                    onPressed: _donusturuluyor ? null : _gorunumModunuDegistir,
                    tooltip: _pdfYolu != null
                        ? 'DXF çizime geç'
                        : 'Vektörel PDF’ye geç',
                    icon: Icon(
                      _pdfYolu != null
                          ? Icons.architecture_outlined
                          : Icons.picture_as_pdf_outlined,
                    ),
                  )
                : TextButton.icon(
                    onPressed: _donusturuluyor ? null : _gorunumModunuDegistir,
                    icon: Icon(
                      _pdfYolu != null
                          ? Icons.architecture_outlined
                          : Icons.picture_as_pdf_outlined,
                      size: 18,
                    ),
                    label: Text(
                      _pdfYolu != null ? 'DXF Çizim' : 'Vektörel PDF',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          IconButton(
            onPressed: _apiAyarlariniGoster,
            icon: const Icon(Icons.dns_outlined),
            tooltip: 'CAD API Ayarları',
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
                  _dxfParseYolu = null;
                  _dxfEntityleriFuture = null;
                  _dosyaYolu = null;
                  _dxfYolu = null;
                  _pdfYolu = null;
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
