import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:sefim/servis/kolon_analiz_servisi.dart';

class YapiElemanKontroluEkrani extends StatefulWidget {
  const YapiElemanKontroluEkrani({super.key});

  @override
  State<YapiElemanKontroluEkrani> createState() =>
      _YapiElemanKontroluEkraniState();
}

class _YapiElemanKontroluEkraniState extends State<YapiElemanKontroluEkrani> {
  final KolonAnalizServisi _servis = KolonAnalizServisi();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _referansPx = TextEditingController();
  final TextEditingController _referansMm = TextEditingController();

  String? _fotografYolu;
  Map<String, dynamic>? _sonuc;
  bool _analizYapiliyor = false;

  @override
  void dispose() {
    _referansPx.dispose();
    _referansMm.dispose();
    super.dispose();
  }

  Future<void> _fotografSec() async {
    final foto = await _picker.pickImage(source: ImageSource.gallery);
    final yol = foto?.path;
    if (yol == null || !mounted) return;
    setState(() {
      _fotografYolu = yol;
      _sonuc = null;
    });
  }

  Future<void> _kameradanFotografSec() async {
    final foto = await _picker.pickImage(source: ImageSource.camera);
    final yol = foto?.path;
    if (yol == null || !mounted) return;
    setState(() {
      _fotografYolu = yol;
      _sonuc = null;
    });
  }

  Future<void> _analizBaslat() async {
    final yol = _fotografYolu;
    if (yol == null) return;

    final px = _sayiyiOku(_referansPx.text);
    final mm = _sayiyiOku(_referansMm.text);
    if ((_referansPx.text.isNotEmpty && px == null) ||
        (_referansMm.text.isNotEmpty && mm == null)) {
      _mesajGoster('Referans ölçüleri sayı olarak girin.');
      return;
    }

    setState(() => _analizYapiliyor = true);
    try {
      final sonuc = await _servis.analizEt(
        yol,
        referenceWidthPx: px,
        referenceWidthMm: mm,
      );
      if (!mounted) return;
      setState(() => _sonuc = sonuc);
    } catch (error) {
      if (!mounted) return;
      _mesajGoster('Kolon analizi başarısız: $error');
    } finally {
      if (mounted) setState(() => _analizYapiliyor = false);
    }
  }

  double? _sayiyiOku(String text) {
    if (text.trim().isEmpty) return null;
    return double.tryParse(text.trim().replaceAll(',', '.'));
  }

  void _mesajGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj)));
  }

  @override
  Widget build(BuildContext context) {
    final renkler = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Yapı Eleman Kontrolü')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _fotoAlani(renkler),
              const SizedBox(height: 16),
              Text(
                'Yaklaşık ölçüm için referans bilgisi',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _referansPx,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Referans genişlik (px)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _referansMm,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Referans genişlik (mm)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _fotografYolu == null || _analizYapiliyor
                    ? null
                    : _analizBaslat,
                icon: _analizYapiliyor
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.analytics_outlined),
                label: Text(
                  _analizYapiliyor ? 'Analiz ediliyor...' : 'Kolonu analiz et',
                ),
              ),
              if (_sonuc != null) ...[
                const SizedBox(height: 24),
                _sonucGoster(_sonuc!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _fotoAlani(ColorScheme renkler) {
    final yol = _fotografYolu;
    return InkWell(
      onTap: _fotografSec,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          color: renkler.primaryContainer.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: renkler.outlineVariant, width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (yol == null)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: renkler.primaryContainer,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.photo_library_outlined,
                      size: 42,
                      color: renkler.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Galeriden kolon fotoğrafı seç'),
                  const SizedBox(height: 4),
                  Text(
                    'JPEG, PNG veya WebP',
                    style: TextStyle(color: renkler.onSurfaceVariant),
                  ),
                ],
              )
            else
              Image.file(File(yol), fit: BoxFit.contain),
            Positioned(
              right: 12,
              bottom: 12,
              child: IconButton.filled(
                onPressed: _kameradanFotografSec,
                icon: const Icon(Icons.camera_alt_outlined),
                tooltip: 'Kameradan fotoğraf çek',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sonucGoster(Map<String, dynamic> sonuc) {
    final alanlar = <String, dynamic>{};
    _alanlariTopla(sonuc, alanlar);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Analiz sonucu',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            for (final entry in alanlar.entries)
              _sonucSatiri(entry.key, entry.value),
          ],
        ),
      ),
    );
  }

  void _alanlariTopla(Map<String, dynamic> kaynak, Map<String, dynamic> hedef) {
    for (final entry in kaynak.entries) {
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        _alanlariTopla(value, hedef);
      } else if (value is List) {
        hedef[_baslik(entry.key)] = value
            .map((item) => item.toString())
            .join(', ');
      } else {
        hedef[_baslik(entry.key)] = value;
      }
    }
  }

  String _baslik(String key) {
    final parcalar = key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .split('_');
    return parcalar
        .map((parca) => parca.trim())
        .where((parca) => parca.isNotEmpty)
        .map((parca) => '${parca[0].toUpperCase()}${parca.substring(1)}')
        .join(' ');
  }

  Widget _sonucSatiri(String baslik, dynamic deger) {
    final metin = deger == null ? 'Belirlenemedi' : deger.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              baslik,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(child: Text(metin, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
