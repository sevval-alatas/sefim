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
  bool _donusturuluyor = false;

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

    setState(() {
      _dosyaYolu = yol;
      _dxfYolu = null;
    });

    if (_uzanti == 'dwg' || _uzanti == 'dxf') {
      await _cadDosyasiniDonustur(yol);
    }
  }

  Future<void> _cadDosyasiniDonustur(String yol) async {
    setState(() => _donusturuluyor = true);
    try {
      final dxf = await _cadServisi.dxfyeDonustur(yol);
      if (!mounted) return;
      setState(() {
        _dxfYolu = dxf.path;
        _donusturuluyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dosyaYolu = null;
        _dxfYolu = null;
        _donusturuluyor = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('DWG/DXF dönüşümü başarısız: $e')));
    }
  }

  Widget _bosDurum(ColorScheme renkler) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: renkler.primaryContainer.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Icon(
                Icons.architecture_outlined,
                size: 48,
                color: renkler.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Projenizi açın',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'PDF, görsel veya CAD dosyası seçerek projeyi incelemeye başlayın.',
              textAlign: TextAlign.center,
              style: TextStyle(color: renkler.onSurfaceVariant),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _projeSec,
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('Proje dosyası seç'),
            ),
          ],
        ),
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
          const Text('DWG dosyası DXF’e dönüştürülüyor...'),
        ],
      ),
    );
  }

  Widget _dxfGoruntule(ColorScheme renkler) {
    return FutureBuilder<List<DxfEntity>>(
      future: File(_dxfYolu!).readAsString().then(DxfParser.parse),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
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
        return DxfGoruntuleyici(entities: snapshot.data!);
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
        title: const Text('Proje Okuma'),
        actions: [
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
              onPressed: _projeSec,
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('Başka proje'),
            ),
    );
  }
}
