import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthServisi {
  AuthServisi({this.baseUrl = 'http://localhost:3000/auth'});

  final String baseUrl;

  Future<AuthSonucu> login({
    required String email,
    required String password,
  }) async {
    final yanit = await _gonder('/login', {
      'email': email,
      'password': password,
    });
    return AuthSonucu.fromJson(yanit);
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
    return AuthSonucu.fromJson(yanit);
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
