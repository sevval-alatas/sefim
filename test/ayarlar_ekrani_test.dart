import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sefim/ekran/ayarlar_ekrani.dart';
import 'package:sefim/servis/tema_servisi.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TemaServisi.instance.value = ThemeMode.system;
  });

  testWidgets('tema seçimi uygulamaya ve tercihlere kaydedilir', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AyarlarEkrani()));

    await tester.tap(find.text('Koyu'));
    await tester.pumpAndSettle();

    expect(TemaServisi.instance.value, ThemeMode.dark);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('sefim_theme_mode'), 'dark');
  });
}
