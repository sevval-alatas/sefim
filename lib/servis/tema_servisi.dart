import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama genelinde Tema (Açık, Koyu, Sistem) yönetimi sağlayan dinamik servis.
class TemaServisi extends ValueNotifier<ThemeMode> {
  static const String _prefKey = 'sefim_theme_mode';
  static final TemaServisi instance = TemaServisi._();

  TemaServisi._() : super(ThemeMode.system) {
    _temayiYukle();
  }

  Future<void> _temayiYukle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final kayitli = prefs.getString(_prefKey);
      if (kayitli == 'light') {
        value = ThemeMode.light;
      } else if (kayitli == 'dark') {
        value = ThemeMode.dark;
      } else if (kayitli == 'system') {
        value = ThemeMode.system;
      }
    } catch (e) {
      debugPrint('Tema yükleme hatası: $e');
    }
  }

  Future<void> temayiDegistir(ThemeMode yeniMod) async {
    value = yeniMod;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, yeniMod.name);
    } catch (e) {
      debugPrint('Tema kaydetme hatası: $e');
    }
  }
}
