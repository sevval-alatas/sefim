import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

/// DWG/CAD'den dönüştürülen vektörel PDF çizimlerini 60 FPS, sonsuz zoom ve
/// ekran üzeri yakınlaştırma/uzaklaştırma butonları ile görüntüleyen bileşen.
class ProjePdfGoruntuleyici extends StatefulWidget {
  final String pdfPath;
  final String? baslik;
  final bool embedded;

  const ProjePdfGoruntuleyici({
    required this.pdfPath,
    this.baslik,
    this.embedded = false,
    super.key,
  });

  @override
  State<ProjePdfGoruntuleyici> createState() => _ProjePdfGoruntuleyiciState();
}

class _ProjePdfGoruntuleyiciState extends State<ProjePdfGoruntuleyici>
    with SingleTickerProviderStateMixin {
  late PdfControllerPinch _pdfController;
  int _sayfaSayisi = 0;
  int _aktifSayfa = 1;
  bool _yukleniyor = true;
  String? _hata;
  Size _gorunumBoyutu = const Size(800, 600);

  late final AnimationController _animController;
  Animation<Matrix4>? _zoomAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        if (_zoomAnimation != null) {
          _pdfController.value = _zoomAnimation!.value;
        }
      });
    _controlleriBaslat();
  }

  void _controlleriBaslat() {
    _yukleniyor = true;
    _hata = null;
    try {
      final dosya = File(widget.pdfPath);
      if (!dosya.existsSync()) {
        setState(() {
          _hata = 'Çizim dosyası bulunamadı: ${widget.pdfPath}';
          _yukleniyor = false;
        });
        return;
      }

      _pdfController = PdfControllerPinch(
        document: PdfDocument.openFile(widget.pdfPath),
      );
      _pdfController.addListener(_onControllerChanged);
    } catch (e) {
      _hata = 'Çizim yükleme hatası: $e';
      _yukleniyor = false;
    }
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant ProjePdfGoruntuleyici oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pdfPath != widget.pdfPath) {
      _pdfController.removeListener(_onControllerChanged);
      _pdfController.dispose();
      _controlleriBaslat();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    if (_hata == null) {
      _pdfController.removeListener(_onControllerChanged);
      _pdfController.dispose();
    }
    super.dispose();
  }

  int get _zoomYuzdesi {
    try {
      final scale = _pdfController.value.getMaxScaleOnAxis();
      return (scale * 100).round();
    } catch (_) {
      return 100;
    }
  }

  void _zoomAnimasyonlu(Matrix4 targetMatrix) {
    _animController.stop();
    _zoomAnimation = Matrix4Tween(
      begin: _pdfController.value,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward(from: 0.0);
  }

  void _yaklastir([double carpan = 1.35]) {
    final currentMatrix = _pdfController.value.clone();
    final center = Offset(_gorunumBoyutu.width / 2, _gorunumBoyutu.height / 2);

    final transform = Matrix4.translationValues(center.dx, center.dy, 0.0)
      ..multiply(Matrix4.diagonal3Values(carpan, carpan, 1.0))
      ..multiply(Matrix4.translationValues(-center.dx, -center.dy, 0.0));

    final target = transform * currentMatrix;
    _zoomAnimasyonlu(target);
  }

  void _uzaklastir([double carpan = 1 / 1.35]) {
    _yaklastir(carpan);
  }

  void _gorunumuSifirla() {
    final fitMatrix =
        _pdfController.calculatePageFitMatrix(pageNumber: _aktifSayfa);
    final target = fitMatrix ?? Matrix4.identity();
    _zoomAnimasyonlu(target);
  }

  Widget _buildPdfIcerik() {
    if (_hata != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                _hata!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final appBgColor = theme.scaffoldBackgroundColor;
        final isDark = theme.brightness == Brightness.dark;

        _gorunumBoyutu = Size(
          constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width,
          constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.of(context).size.height,
        );

        ColorFilter filter;
        if (isDark) {
          final rBg = (appBgColor.toARGB32() >> 16) & 0xFF;
          final gBg = (appBgColor.toARGB32() >> 8) & 0xFF;
          final bBg = appBgColor.toARGB32() & 0xFF;

          final rFactor = -(255.0 - rBg) / 255.0;
          final gFactor = -(255.0 - gBg) / 255.0;
          final bFactor = -(255.0 - bBg) / 255.0;

          filter = ColorFilter.matrix([
            rFactor, 0, 0, 0, 255,
            0, gFactor, 0, 0, 255,
            0, 0, bFactor, 0, 255,
            0, 0, 0, 1, 0,
          ]);
        } else {
          // Açık temada: Beyaz sayfayı uygulama arka planına (appBgColor) eşitle,
          // sarı ve açık renkli çizim/metin katmanlarını okunabilir koyu tonlara (koyu kehribar/kahve) dönüştür.
          final rBgNorm = ((appBgColor.toARGB32() >> 16) & 0xFF) / 255.0;
          final gBgNorm = ((appBgColor.toARGB32() >> 8) & 0xFF) / 255.0;
          final bBgNorm = (appBgColor.toARGB32() & 0xFF) / 255.0;

          const yellowRed = 0.46;
          const yellowGreen = 0.32;
          final blueCompR = rBgNorm - yellowRed;
          final blueCompG = gBgNorm - yellowGreen;

          filter = ColorFilter.matrix([
            yellowRed, 0, blueCompR, 0, 0,
            0, yellowGreen, blueCompG, 0, 0,
            0, 0, bBgNorm, 0, 0,
            0, 0, 0, 1, 0,
          ]);
        }

        return Container(
          color: appBgColor,
          child: Stack(
            children: [
              // Vektörel CAD Çizim Katmanı (PDF sınırları gizlenmiş, uygulama rengine birebir gömülü)
              Positioned.fill(
                child: ColorFiltered(
                  colorFilter: filter,
                  child: Container(
                    color: Colors.white,
                    child: PdfViewPinch(
                      controller: _pdfController,
                      minScale: 0.5,
                      maxScale: 30.0,
                      padding: 0,
                      backgroundDecoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      onDocumentLoaded: (doc) {
                        setState(() {
                          _sayfaSayisi = doc.pagesCount;
                          _yukleniyor = false;
                        });
                      },
                      onPageChanged: (page) {
                        setState(() {
                          _aktifSayfa = page;
                        });
                      },
                    ),
                  ),
                ),
              ),

              if (_yukleniyor)
                Center(
                  child: CircularProgressIndicator(color: colorScheme.primary),
                ),

              // Sağ üstte yüzen CAD Yakınlaştırma / Uzaklaştırma / Sıfırlama Butonları
              Positioned(
                right: 16,
                top: 16,
                child: Material(
                  color: colorScheme.surface,
                  elevation: 4,
                  shadowColor: colorScheme.shadow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _yaklastir(1.35),
                          icon: Icon(Icons.add, color: colorScheme.onSurface),
                          tooltip: 'Yaklaştır (+)',
                        ),
                        InkWell(
                          onTap: _gorunumuSifirla,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            child: Text(
                              '%$_zoomYuzdesi',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _uzaklastir(),
                          icon: Icon(Icons.remove, color: colorScheme.onSurface),
                          tooltip: 'Uzaklaştır (-)',
                        ),
                        Divider(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                          height: 1,
                          indent: 6,
                          endIndent: 6,
                        ),
                        IconButton(
                          onPressed: _gorunumuSifirla,
                          icon: Icon(Icons.fit_screen_outlined,
                              color: colorScheme.primary),
                          tooltip: 'Ekrana Sığdır (Sıfırla)',
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Çok paftalı projeler için gezinme çubuğu
              if (!_yukleniyor && _sayfaSayisi > 1)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Material(
                      color: colorScheme.surface,
                      elevation: 4,
                      shadowColor: colorScheme.shadow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 32, minHeight: 32),
                              onPressed: _aktifSayfa > 1
                                  ? () => _pdfController.previousPage(
                                        duration:
                                            const Duration(milliseconds: 250),
                                        curve: Curves.easeInOut,
                                      )
                                  : null,
                              icon: Icon(
                                Icons.chevron_left,
                                color: _aktifSayfa > 1
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurface.withValues(alpha: 0.38),
                              ),
                              tooltip: 'Önceki Çizim',
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'Pafta $_aktifSayfa / $_sayfaSayisi',
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            IconButton(
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 32, minHeight: 32),
                              onPressed: _aktifSayfa < _sayfaSayisi
                                  ? () => _pdfController.nextPage(
                                        duration:
                                            const Duration(milliseconds: 250),
                                        curve: Curves.easeInOut,
                                      )
                                  : null,
                              icon: Icon(
                                Icons.chevron_right,
                                color: _aktifSayfa < _sayfaSayisi
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurface.withValues(alpha: 0.38),
                              ),
                              tooltip: 'Sonraki Çizim',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _buildPdfIcerik();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.baslik ?? 'Statik Proje Çizimi'),
        actions: [
          IconButton(
            onPressed: () => _yaklastir(1.35),
            icon: const Icon(Icons.zoom_in),
            tooltip: 'Yaklaştır',
          ),
          IconButton(
            onPressed: () => _uzaklastir(),
            icon: const Icon(Icons.zoom_out),
            tooltip: 'Uzaklaştır',
          ),
          IconButton(
            onPressed: _gorunumuSifirla,
            icon: const Icon(Icons.fit_screen_outlined),
            tooltip: 'Sıfırla',
          ),
        ],
      ),
      body: _buildPdfIcerik(),
    );
  }
}
