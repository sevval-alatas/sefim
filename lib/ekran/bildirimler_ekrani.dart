/*
import 'package:flutter/material.dart';

import 'package:sefim/servis/santiye_servisi.dart';

class BildirimlerEkrani extends StatefulWidget {
  const BildirimlerEkrani({super.key});

  @override
  State<BildirimlerEkrani> createState() => _BildirimlerEkraniState();
}

class _BildirimlerEkraniState extends State<BildirimlerEkrani> {
  final SantiyeServisi _santiyeServisi = SantiyeServisi();
  late Future<List<dynamic>> _bildirimlerFuture;
  bool _islemSuruyor = false;

  @override
  void initState() {
    super.initState();
    _bildirimlerFuture = _santiyeServisi.bildirimleriGetir();
  }

  Future<void> _yenile() async {
    setState(() {
      _bildirimlerFuture = _santiyeServisi.bildirimleriGetir();
    });
  }

  Future<void> _sonuclandir(
    String projectId,
    String memberId,
    String status,
  ) async {
    setState(() => _islemSuruyor = true);
    try {
      await _santiyeServisi.basvuruSonuclandir(
        projectId: projectId,
        memberId: memberId,
        status: status,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'ACTIVE' ? 'Başvuru onaylandı.' : 'Başvuru reddedildi.',
          ),
          backgroundColor: status == 'ACTIVE' ? Colors.green : Colors.red.shade700,
        ),
      );

      await _yenile();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İşlem başarısız: $e')),
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
        title: const Text('Şantiye Katılım İstekleri'),
        actions: [
          IconButton(
            onPressed: _yenile,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _yenile,
              child: FutureBuilder<List<dynamic>>(
                future: _bildirimlerFuture,
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
                              'Bildirimler yüklenemedi:\n${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  final bildirimler = snapshot.data ?? [];

                  if (bildirimler.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: renkler.primary.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.notifications_none_outlined,
                                  size: 48,
                                  color: renkler.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Bekleyen katılım isteği yok',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Yöneticisi olduğunuz şantiyelere gelen\nbaşvurular burada görünecektir.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ...bildirimler.map((item) {
                        final project = item['project'] ?? item['santiye'] ?? {};
                        final user = item['applicant'] ?? item['user'] ?? {};

                        final projectId = (project['id'] ?? '').toString();
                        final memberId = (item['id'] ?? '').toString();

                        final santiyeAdi = project['name'] ?? project['adi'] ?? 'Şantiye';
                        final basvuranAdi = user['name'] ?? user['username'] ?? user['email'] ?? 'Kullanıcı';
                        final basvuranEposta = user['email'] ?? '';
                        final tarih = item['createdAt'] ?? item['date'] ?? item['tarih'] ?? '';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: renkler.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.person_add_outlined,
                                          color: renkler.primary,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              basvuranAdi.toString(),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            if (basvuranEposta.toString().isNotEmpty)
                                              Text(
                                                basvuranEposta.toString(),
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    children: [
                                      const Icon(Icons.business_outlined, size: 16, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Şantiye: ',
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                      ),
                                      Expanded(
                                        child: Text(
                                          santiyeAdi.toString(),
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (tarih.toString().isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.schedule_outlined, size: 16, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Tarih: $tarih',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: _islemSuruyor
                                              ? null
                                              : () => _sonuclandir(projectId, memberId, 'REJECTED'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red.shade700,
                                            side: BorderSide(color: Colors.red.shade300),
                                            minimumSize: const Size.fromHeight(44),
                                          ),
                                          child: const Text('Reddet'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: FilledButton(
                                          onPressed: _islemSuruyor
                                              ? null
                                              : () => _sonuclandir(projectId, memberId, 'ACTIVE'),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.green.shade700,
                                            minimumSize: const Size.fromHeight(44),
                                          ),
                                          child: const Text('Onayla'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
