import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sefim/servis/tema_servisi.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('TemaServisi tema modunu değiştirir ve kaydeder', () async {
    final servis = TemaServisi.instance;

    await servis.temayiDegistir(ThemeMode.dark);
    expect(servis.value, ThemeMode.dark);

    await servis.temayiDegistir(ThemeMode.light);
    expect(servis.value, ThemeMode.light);

    await servis.temayiDegistir(ThemeMode.system);
    expect(servis.value, ThemeMode.system);
  });
}
