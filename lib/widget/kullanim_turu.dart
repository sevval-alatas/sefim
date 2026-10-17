import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KullanimTuru extends StatefulWidget {
  const KullanimTuru({super.key});

  static const _tamamlandiAnahtari = 'sefim_walkthrough_completed';

  static Future<void> goster(BuildContext context, {bool zorla = false}) async {
    final preferences = await SharedPreferences.getInstance();
    if (!context.mounted) return;
    if (!zorla && preferences.getBool(_tamamlandiAnahtari) == true) return;

    final tamamlandi = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const KullanimTuru(),
    );
    if (tamamlandi == true) {
      await preferences.setBool(_tamamlandiAnahtari, true);
    }
  }

  @override
  State<KullanimTuru> createState() => _KullanimTuruState();
}

class _KullanimTuruState extends State<KullanimTuru> {
  static const _adimlar = [
    _KullanimAdimi(
      icon: Icons.dashboard_outlined,
      title: 'Şefim’e hoş geldiniz',
      description: 'Ana sayfada irsaliye özetinizi ve uygulamadaki aktif modülleri görebilirsiniz. Başlamak için bir modül kartına dokunun.',
    ),
    _KullanimAdimi(
      icon: Icons.document_scanner_outlined,
      title: 'İrsaliye tarayın ve kaydedin',
      description: 'İrsaliye OCR ekranında kamera veya galeriden bir belge seçin. Okunan alanları kontrol edip gerekirse düzeltin, ardından Excel’e kaydedin.',
    ),
    _KullanimAdimi(
      icon: Icons.table_chart_outlined,
      title: 'Kayıtları yönetin',
      description: 'Kayıtlı İrsaliyeler ekranında arama ve filtreleme yapabilir, kayıtları düzenleyebilir, Excel dosyasını paylaşabilir veya yedek oluşturabilirsiniz.',
    ),
    _KullanimAdimi(
      icon: Icons.architecture_outlined,
      title: 'Projelerinize çevrimdışı erişin',
      description: 'Proje Okuma ekranından DWG, DXF, PDF veya görsel seçin. Seçilen dosyalar bu cihazda kalıcı saklanır; dönüştürülmüş çizimleri daha sonra internet olmadan açabilirsiniz.',
    ),
    _KullanimAdimi(
      icon: Icons.settings_outlined,
      title: 'Görünümü kişiselleştirin',
      description: 'Ayarlar’dan sistem temasını kullanın veya açık/koyu temayı seçin. Bu kullanım turunu ana sayfadaki yardım düğmesinden tekrar açabilirsiniz.',
    ),
  ];

  int _aktifAdim = 0;

  void _bitir() => Navigator.of(context).pop(true);

  @override
  Widget build(BuildContext context) {
    final adim = _adimlar[_aktifAdim];
    final renkler = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        icon: Icon(adim.icon, size: 36, color: renkler.primary),
        title: Text(adim.title, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(adim.description, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _adimlar.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: index == _aktifAdim ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: index == _aktifAdim
                        ? renkler.primary
                        : renkler.outlineVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: _bitir, child: const Text('Atla')),
          if (_aktifAdim > 0)
            TextButton(
              onPressed: () => setState(() => _aktifAdim--),
              child: const Text('Geri'),
            ),
          FilledButton(
            onPressed: () {
              if (_aktifAdim == _adimlar.length - 1) {
                _bitir();
              } else {
                setState(() => _aktifAdim++);
              }
            },
            child: Text(_aktifAdim == _adimlar.length - 1 ? 'Başla' : 'İleri'),
          ),
        ],
      ),
    );
  }
}

class _KullanimAdimi {
  const _KullanimAdimi({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
