/*
import 'package:flutter/material.dart';

import 'package:sefim/router/app_router.dart';
import 'package:sefim/servis/auth_servisi.dart';
import 'package:sefim/servis/santiye_servisi.dart';

class SantiyeSecimEkrani extends StatefulWidget {
  const SantiyeSecimEkrani({super.key});

  @override
  State<SantiyeSecimEkrani> createState() => _SantiyeSecimEkraniState();
}

class _SantiyeSecimEkraniState extends State<SantiyeSecimEkrani> {
  final SantiyeServisi _santiyeServisi = SantiyeServisi();
  late Future<List<dynamic>> _santiyelerFuture;
  bool _islemSuruyor = false;

  @override
  void initState() {
    super.initState();
    _santiyelerFuture = _santiyeServisi.santiyeListele();
  }

  Future<void> _yenile() async {
    setState(() {
      _santiyelerFuture = _santiyeServisi.santiyeListele();
    });
  }

  void _cikisYap() {
    AuthServisi.oturumuKapat();
    AppRouter.goAuth(context);
  }

  Future<void> _santiyeOlusturDialog() async {
    final nameCtrl = TextEditingController();
    final sonuc = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Şantiye Oluştur'),
        content: TextField(
          controller: nameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Şantiye Adı',
            hintText: 'Örn: Merkez Konutları Şantiyesi',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );

    if (sonuc != true || nameCtrl.text.trim().isEmpty) return;

    setState(() => _islemSuruyor = true);
    try {
      final yeniSantiye = await _santiyeServisi.santiyeOlustur(
        name: nameCtrl.text.trim(),
      );
      if (!mounted) return;

      final kayitKodu = yeniSantiye['code'] ?? yeniSantiye['joinCode'] ?? '';

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Şantiye Başarıyla Oluşturuldu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Şantiye: ${nameCtrl.text.trim()}'),
              if (kayitKodu.toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Kayıt Kodu (Ekip arkadaşlarınıza verebilirsiniz):',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    kayitKodu.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );

      await _yenile();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Şantiye oluşturulamadı: $e')),
      );
    } finally {
      if (mounted) setState(() => _islemSuruyor = false);
    }
  }

  Future<void> _kodlaKatilDialog() async {
    final kodCtrl = TextEditingController();
    final sonuc = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kayıt Kodu ile Katıl'),
        content: TextField(
          controller: kodCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Kayıt Kodu',
            hintText: 'Örn: ABC123XYZ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Başvur'),
          ),
        ],
      ),
    );

    if (sonuc != true || kodCtrl.text.trim().isEmpty) return;

    setState(() => _islemSuruyor = true);
    try {
      await _santiyeServisi.katilimBasvurusuYap(code: kodCtrl.text.trim());
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Katılım başvurunuz gönderildi. Yönetici onayı bekleniyor.'),
          backgroundColor: Colors.green,
        ),
      );

      await _yenile();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Başvuru başarısız: $e')),
      );
    } finally {
      if (mounted) setState(() => _islemSuruyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final renkler = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Şantiye Seçimi'),
        actions: [
          IconButton(
            onPressed: () => AppRouter.push(context, AppRouter.bildirimlerRoute),
            icon: const Icon(Icons.notifications_none_outlined),
            tooltip: 'Katılım İstekleri / Bildirimler',
          ),
          IconButton(
            onPressed: _yenile,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yenile',
          ),
          IconButton(
            onPressed: _cikisYap,
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _yenile,
              child: FutureBuilder<List<dynamic>>(
                future: _santiyelerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return ListView(
                      children: [
                        const SizedBox(height: 100),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Şantiyeler yüklenemedi:\n${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  final santiyeler = snapshot.data ?? [];

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
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
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Şantiye Yönetimi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Çalışmak istediğiniz şantiyeyi seçin veya yeni bir şantiye oluşturarak ekip kodunu paylaşın.',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _santiyeOlusturDialog,
                              icon: const Icon(Icons.add_business_outlined),
                              label: const Text('Şantiye Oluştur'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _kodlaKatilDialog,
                              icon: const Icon(Icons.login_rounded),
                              label: const Text('Kodla Katıl'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Şantiyeleriniz',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      if (santiyeler.isNotEmpty &&
                          !santiyeler.any(
                            (item) =>
                                ((item['status'] ?? item['durum'] ?? 'ACTIVE')
                                        .toString()
                                        .toUpperCase()) ==
                                    'ACTIVE',
                          ))
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange.shade800,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Aktif durumda olan şantiyeniz bulunmuyor. Başvurularınız onay bekliyor veya reddedilmiş olabilir.',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (santiyeler.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.amber.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 54,
                                color: Colors.amber.shade800,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Şantiye Bulunamadı',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sefim uygulamasını kullanabilmek ve irsaliye yönetimi yapabilmek için aktif bir şantiyeye dahil olmanız gerekmektedir.\n\nHemen yeni bir şantiye oluşturun veya yöneticinizden aldığınız kayıt koduyla katılın.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: Colors.amber.shade900,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...santiyeler.map((item) {
                          final santiye = item['santiye'] ?? item['project'] ?? item;
                          final ad = santiye['name'] ?? santiye['adi'] ?? 'Şantiye';
                          final durum = (item['status'] ?? item['durum'] ?? 'ACTIVE').toString().toUpperCase();
                          final rol = (item['role'] ?? item['rol'] ?? '').toString().toUpperCase();
                          final kod = santiye['code'] ?? santiye['joinCode'] ?? '';

                          final aktifMi = durum == 'ACTIVE';

                          Color durumRengi = Colors.green;
                          String durumMetni = 'Aktif';
                          if (durum == 'PENDING') {
                            durumRengi = Colors.orange;
                            durumMetni = 'Onay Bekliyor';
                          } else if (durum == 'REJECTED') {
                            durumRengi = Colors.red;
                            durumMetni = 'Reddedildi';
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: aktifMi
                                    ? () => AppRouter.goHome(context)
                                    : () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Bu şantiye için yönetici onayı bekleniyor veya reddedildi.'),
                                          ),
                                        );
                                      },
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
                                        child: Icon(Icons.business, color: renkler.primary),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              ad.toString(),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: durumRengi.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    durumMetni,
                                                    style: TextStyle(
                                                      color: durumRengi,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                if (rol.isNotEmpty) ...[
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '•  $rol',
                                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            if (kod.toString().isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'Kayıt Kodu: $kod',
                                                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        aktifMi ? Icons.chevron_right_rounded : Icons.lock_outline,
                                        color: aktifMi ? Colors.grey.shade400 : Colors.orange,
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
            if (_islemSuruyor)
              Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
*/
