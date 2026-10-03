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
import 'package:sefim/servis/tema_servisi.dart';
import 'package:sefim/ekran/kayitlar_ekrani.dart';
import 'package:sefim/router/app_router.dart';
import 'package:sefim/widget/irsaliye_alan.dart';

const Color _anaRenk = Color(0xFF1F497D);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IrsaliyeApp());
}

class IrsaliyeApp extends StatelessWidget {
  const IrsaliyeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: _anaRenk,
      brightness: Brightness.light,
    );

    final darkScheme = ColorScheme.fromSeed(
      seedColor: _anaRenk,
      brightness: Brightness.dark,
    );

    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: lightScheme,
      scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1B2430),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1B2430),
        ),
        iconTheme: IconThemeData(color: Color(0xFF1B2430)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightScheme.surfaceContainerHighest.withValues(
          alpha: 0.38,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: lightScheme.primary, width: 1.6),
        ),
        labelStyle: const TextStyle(color: Color(0xFF475569)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shadowColor: lightScheme.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: lightScheme.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: lightScheme.onSurface,
          ),
        ),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: lightScheme.onSurfaceVariant),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1F2937),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: lightScheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: darkScheme,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B),
        foregroundColor: Color(0xFFF8FAFC),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF8FAFC),
        ),
        iconTheme: IconThemeData(color: Color(0xFFF8FAFC)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: darkScheme.primary, width: 1.6),
        ),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E293B),
        shadowColor: Colors.black.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1E293B),
        indicatorColor: darkScheme.primary.withValues(alpha: 0.25),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: darkScheme.onSurface,
          ),
        ),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: darkScheme.onSurfaceVariant),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF334155),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkScheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: TemaServisi.instance,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Sefim',
          themeMode: themeMode,
          theme: lightTheme,
          darkTheme: darkTheme,
          initialRoute: AppRouter.homeRoute,
          routes: AppRouter.routes(
            home: const UygulamaMenu(),
            irsaliyeOcr: const AnaSayfa(),
            onAuthenticated: (context) {
              AppRouter.goHome(context);
            },
          ),
        );
      },
    );
  }
}

void _temaSecimDiyalogu(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) {
      return ValueListenableBuilder<ThemeMode>(
        valueListenable: TemaServisi.instance,
        builder: (context, mevcutMod, _) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.palette_outlined),
                SizedBox(width: 8),
                Text('Tema Seçimi'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ThemeMode>(
                  title: const Row(
                    children: [
                      Icon(Icons.light_mode_outlined, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Açık Tema'),
                    ],
                  ),
                  value: ThemeMode.light,
                  groupValue: mevcutMod,
                  onChanged: (val) {
                    if (val != null) TemaServisi.instance.temayiDegistir(val);
                    Navigator.of(ctx).pop();
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Row(
                    children: [
                      Icon(Icons.dark_mode_outlined, color: Colors.indigoAccent),
                      SizedBox(width: 8),
                      Text('Koyu Tema'),
                    ],
                  ),
                  value: ThemeMode.dark,
                  groupValue: mevcutMod,
                  onChanged: (val) {
                    if (val != null) TemaServisi.instance.temayiDegistir(val);
                    Navigator.of(ctx).pop();
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Row(
                    children: [
                      Icon(Icons.brightness_auto_outlined, color: Colors.teal),
                      SizedBox(width: 8),
                      Text('Sistem Varsayılanı'),
                    ],
                  ),
                  value: ThemeMode.system,
                  groupValue: mevcutMod,
                  onChanged: (val) {
                    if (val != null) TemaServisi.instance.temayiDegistir(val);
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class UygulamaMenu extends StatefulWidget {
  const UygulamaMenu({super.key});

  @override
  State<UygulamaMenu> createState() => _UygulamaMenuState();
}

class _UygulamaMenuState extends State<UygulamaMenu> {
  late Future<List<IrsaliyeKaydi>> _kayitlarFuture;

  @override
  void initState() {
    super.initState();
    _kayitlarFuture = ExcelServisi.tumKayitlariOku();
  }

  Future<void> _yenile() async {
    setState(() {
      _kayitlarFuture = ExcelServisi.tumKayitlariOku();
    });
  }

  void _rotaAc(BuildContext context, String rota) {
    AppRouter.push(context, rota).then((_) => _yenile());
  }

  void _kayitlariAc(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const KayitlarEkrani()))
        .then((_) => _yenile());
  }

  @override
  Widget build(BuildContext context) {
    final renkler = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sefim • Şantiye Yönetim Paneli'),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: TemaServisi.instance,
            builder: (context, mode, _) {
              IconData icon;
              switch (mode) {
                case ThemeMode.light:
                  icon = Icons.light_mode_outlined;
                  break;
                case ThemeMode.dark:
                  icon = Icons.dark_mode_outlined;
                  break;
                case ThemeMode.system:
                  icon = Icons.brightness_auto_outlined;
                  break;
              }
              return IconButton(
                icon: Icon(icon),
                tooltip: 'Tema Değiştir',
                onPressed: () => _temaSecimDiyalogu(context),
              );
            },
          ),
          IconButton(
            onPressed: () => _kayitlariAc(context),
            icon: const Icon(Icons.table_chart_outlined),
            tooltip: 'Kayıtlar',
          ),
          IconButton(
            onPressed: _yenile,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yenile',
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
                onTap: () {
                  Navigator.of(context).pop();
                  _rotaAc(context, AppRouter.irsaliyeRoute);
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: const Text('Kayıtlar & Raporlar'),
                onTap: () {
                  Navigator.of(context).pop();
                  _kayitlariAc(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.architecture_outlined),
                title: const Text('Proje okuma (DWG/DXF)'),
                onTap: () {
                  Navigator.of(context).pop();
                  _rotaAc(context, AppRouter.projeOkumaRoute);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: const Text('Tema Değiştir (Açık/Koyu)'),
                onTap: () {
                  Navigator.of(context).pop();
                  _temaSecimDiyalogu(context);
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _yenile,
          child: FutureBuilder<List<IrsaliyeKaydi>>(
            future: _kayitlarFuture,
            builder: (context, snapshot) {
              final kayitlar = snapshot.data ?? [];
              final toplamMiktar = kayitlar.fold<double>(
                0,
                (deger, k) =>
                    deger +
                    (double.tryParse(
                          k.veri.uretimMiktari.replaceAll(',', '.'),
                        ) ??
                        0),
              );
              final kontrolBekleyen = kayitlar
                  .where((k) => k.veri.kontrolUyarilari.isNotEmpty)
                  .length;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          renkler.primary,
                          Color.lerp(
                            renkler.primary,
                            const Color(0xFF0E7490),
                            0.55,
                          )!,
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
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.asset(
                                'assets/sefim_logo.jpeg',
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hoş geldiniz, Şefim',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Beton irsaliyeleri ve şantiye süreçleri',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12.5,
                                    ),
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
                              child: _bannerIstatistik(
                                '${kayitlar.length}',
                                'Toplam İrsaliye',
                                Icons.receipt_long_outlined,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _bannerIstatistik(
                                '${toplamMiktar.toStringAsFixed(1)} m³',
                                'Toplam Üretim',
                                Icons.water_drop_outlined,
                              ),
                            ),
                            if (kontrolBekleyen > 0) ...[
                              const SizedBox(width: 10),
                              Expanded(
                                child: _bannerIstatistik(
                                  '$kontrolBekleyen',
                                  'Kontrol',
                                  Icons.warning_amber_outlined,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () =>
                                _rotaAc(context, AppRouter.irsaliyeRoute),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: renkler.primary,
                            ),
                            icon: const Icon(Icons.document_scanner_outlined),
                            label: const Text('Hızlı İrsaliye Tara (OCR)'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Aktif Modüller',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _ModulKarti(
                    ikon: Icons.document_scanner_outlined,
                    baslik: 'İrsaliye OCR & Yönetimi',
                    aciklama:
                        'Kameradan veya galeriden irsaliye tara, otomatik Excel’e kaydet',
                    renk: renkler.primary,
                    onPressed: () =>
                        _rotaAc(context, AppRouter.irsaliyeRoute),
                  ),
                  const SizedBox(height: 10),
                  _ModulKarti(
                    ikon: Icons.table_chart_outlined,
                    baslik: 'Kayıtlı İrsaliyeler & Raporlar',
                    aciklama:
                        'Tüm kayıtları listele, ar filtrele, Excel paylaş ve yedekle',
                    renk: const Color(0xFF0284C7),
                    onPressed: () => _kayitlariAc(context),
                  ),
                  const SizedBox(height: 10),
                  _ModulKarti(
                    ikon: Icons.architecture_outlined,
                    baslik: 'Proje Okuma & CAD Görüntüleyici (DWG/DXF)',
                    aciklama:
                        'DWG/DXF projelerini dönüştür, PDF ve görselleri aç ve incele',
                    renk: const Color(0xFF7C3AED),
                    onPressed: () =>
                        _rotaAc(context, AppRouter.projeOkumaRoute),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Son İrsaliye İşlemleri',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _kayitlariAc(context),
                        child: const Text('Tümünü gör'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (kayitlar.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: renkler.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            color: renkler.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Henüz kayıt bulunmuyor. İrsaliye tarayarak başlayın.',
                              style: TextStyle(fontSize: 13.5),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...kayitlar.take(3).map((kayit) {
                      final v = kayit.veri;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _kayitlariAc(context),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: renkler.primary.withValues(
                                        alpha: 0.08,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.receipt_long_outlined,
                                      color: renkler.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          v.irsaliyeNo.isEmpty
                                              ? 'İrsaliye No yok'
                                              : v.irsaliyeNo,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          [
                                            if (v.tarih.isNotEmpty) v.tarih,
                                            if (v.plaka.isNotEmpty) v.plaka,
                                          ].join('  •  '),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: renkler.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (v.uretimMiktari.isNotEmpty)
                                    Text(
                                      '${v.uretimMiktari} m³',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: renkler.primary,
                                      ),
                                    ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: renkler.onSurfaceVariant,
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
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) _kayitlariAc(context);
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

  Widget _bannerIstatistik(String deger, String etiket, IconData ikon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ikon, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  etiket,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            deger,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModulKarti extends StatelessWidget {
  const _ModulKarti({
    required this.ikon,
    required this.baslik,
    required this.aciklama,
    required this.renk,
    required this.onPressed,
  });

  final IconData ikon;
  final String baslik;
  final String aciklama;
  final Color renk;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final renkler = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: renk.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(ikon, color: renk, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      baslik,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      aciklama,
                      style: TextStyle(
                        fontSize: 12,
                        color: renkler.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: renkler.onSurfaceVariant),
            ],
          ),
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
  List<String> _ocrUyarilari = [];
  late Future<List<IrsaliyeKaydi>> _sonKayitlarFuture;

  final _tarihCtrl = TextEditingController();
  final _zamanCtrl = TextEditingController();
  final _irsaliyeNoCtrl = TextEditingController();
  final _plakaCtrl = TextEditingController();
  final _dayanimCtrl = TextEditingController();
  final _uretimCtrl = TextEditingController();
  final _siparisCtrl = TextEditingController();
  bool get _veriVarMi => _secilenFoto != null;
  bool get _herhangiBirIslemSuruyor =>
      _ocrYapiliyor || _kaydediliyor;

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
              const Expanded(
                child: Text('Excel’e başarıyla kaydedildi!'),
              ),
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
                  color: Theme.of(context).cardColor,
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
                    color: Theme.of(context).cardColor,
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
                                      color: renkler.onSurfaceVariant,
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
                              color: renkler.onSurfaceVariant,
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
            onPressed: () => _temaSecimDiyalogu(context),
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Tema Değiştir',
          ),
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
                              color: renkler.onSurfaceVariant,
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
