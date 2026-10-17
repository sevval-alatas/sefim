import 'package:flutter/material.dart';
import 'package:sefim/servis/tema_servisi.dart';
import 'package:sefim/widget/kullanim_turu.dart';

class AyarlarEkrani extends StatelessWidget {
  const AyarlarEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final renkler = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Görünüm',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Uygulamanın temasını seçin.',
                    style: TextStyle(color: renkler.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: TemaServisi.instance,
                    builder: (context, mode, _) => SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto_outlined),
                          label: Text('Sistem'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_outlined),
                          label: Text('Açık'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_outlined),
                          label: Text('Koyu'),
                        ),
                      ],
                      selected: {mode},
                      onSelectionChanged: (selection) {
                        TemaServisi.instance.temayiDegistir(selection.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.document_scanner_outlined),
                  title: Text('İrsaliye OCR'),
                  subtitle: Text('İrsaliye tarama ve Excel kayıtları'),
                ),
                const Divider(height: 1, indent: 72),
                const ListTile(
                  leading: Icon(Icons.architecture_outlined),
                  title: Text('Proje görüntüleme'),
                  subtitle: Text('DWG, DXF, PDF ve görsel dosyaları'),
                ),
                const Divider(height: 1, indent: 72),
                const ListTile(
                  leading: Icon(Icons.offline_pin_outlined),
                  title: Text('Yerel depolama'),
                  subtitle: Text('Kayıtlarınız bu cihazda saklanır'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Kullanım turunu göster'),
              subtitle: const Text('Uygulamanın temel özelliklerini öğrenin'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => KullanimTuru.goster(context, zorla: true),
            ),
          ),
        ],
      ),
    );
  }
}
