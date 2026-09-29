import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthServisi {
  AuthServisi({this.baseUrl = 'http://localhost:3000/auth'});

  final String baseUrl;

  static const String _tokenAnahtari = 'sefim_access_token';
  static const String _kullaniciAnahtari = 'sefim_user_json';

  static String? _mevcutToken;
  static Map<String, dynamic>? _mevcutKullanici;

  static String? get mevcutToken => _mevcutToken;
  static Map<String, dynamic>? get mevcutKullanici => _mevcutKullanici;
  static bool get oturumAcik => _mevcutToken != null && _mevcutToken!.isNotEmpty;

  /// Uygulama başlarken SharedPreferences'dan kayıtlı token'ı yükler.
  static Future<void> baslat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _mevcutToken = prefs.getString(_tokenAnahtari);
      final userStr = prefs.getString(_kullaniciAnahtari);
      if (userStr != null && userStr.isNotEmpty) {
        final decoded = jsonDecode(userStr);
        if (decoded is Map<String, dynamic>) {
          _mevcutKullanici = decoded;
        }
      }
    } catch (_) {
      _mevcutToken = null;
      _mevcutKullanici = null;
    }
  }

  static Future<void> _tokenKaydet(
    String token,
    Map<String, dynamic>? user,
  ) async {
    _mevcutToken = token;
    _mevcutKullanici = user;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenAnahtari, token);
      if (user != null) {
        await prefs.setString(_kullaniciAnahtari, jsonEncode(user));
      } else {
        await prefs.remove(_kullaniciAnahtari);
      }
    } catch (_) {}
  }

  static Future<void> oturumuKapat() async {
    _mevcutToken = null;
    _mevcutKullanici = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenAnahtari);
      await prefs.remove(_kullaniciAnahtari);
    } catch (_) {}
  }

  Future<AuthSonucu> login({
    required String email,
    required String password,
  }) async {
    final yanit = await _gonder('/login', {
      'email': email,
      'password': password,
    });
    final sonuc = AuthSonucu.fromJson(yanit);
    await _tokenKaydet(sonuc.accessToken, sonuc.user);
    return sonuc;
  }

  Future<AuthSonucu> signup({
    required String email,
    required String password,
    String? username,
    String? name,
  }) async {
    final yanit = await _gonder('/signup', {
      'email': email,
      'password': password,
      if (username != null && username.trim().isNotEmpty)
        'username': username.trim(),
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
    });
    final sonuc = AuthSonucu.fromJson(yanit);
    await _tokenKaydet(sonuc.accessToken, sonuc.user);
    return sonuc;
  }

  Future<Map<String, dynamic>> _gonder(
    String yol,
    Map<String, dynamic> veri,
  ) async {
    final yanit = await http
        .post(
          Uri.parse('$baseUrl$yol'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(veri),
        )
        .timeout(const Duration(seconds: 30));
    final govde = utf8.decode(yanit.bodyBytes, allowMalformed: true);

    if (yanit.statusCode < 200 || yanit.statusCode >= 300) {
      throw Exception(_hataMesaji(govde, yanit.statusCode));
    }

    final json = jsonDecode(govde);
    if (json is! Map<String, dynamic>) {
      throw Exception('Sunucu geçerli bir kimlik doğrulama yanıtı döndürmedi.');
    }
    return json;
  }

  String _hataMesaji(String govde, int durumKodu) {
    try {
      final json = jsonDecode(govde);
      if (json is Map<String, dynamic>) {
        final mesaj = json['message'] ?? json['error'] ?? json['detail'];
        if (mesaj is List) return mesaj.join(', ');
        if (mesaj != null) return mesaj.toString();
      }
    } on FormatException {
      // JSON olmayan hata gövdeleri aşağıdaki metin olarak gösterilir.
    }
    return govde.trim().isEmpty
        ? 'İşlem başarısız oldu. HTTP $durumKodu'
        : govde.trim();
  }
}

class AuthSonucu {
  const AuthSonucu({required this.accessToken, this.user});

  final String accessToken;
  final Map<String, dynamic>? user;

  factory AuthSonucu.fromJson(Map<String, dynamic> json) {
    final token = json['accessToken'];
    if (token is! String || token.isEmpty) {
      throw Exception('Sunucu accessToken döndürmedi.');
    }
    return AuthSonucu(
      accessToken: token,
      user: json['user'] is Map<String, dynamic>
          ? json['user'] as Map<String, dynamic>
          : null,
    );
  }
}
