/*
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sefim/servis/auth_servisi.dart';

/// Şantiye yönetimi ve üyelik işlemleri servisi.
class SantiyeServisi {
  SantiyeServisi({this.baseUrl = 'http://localhost:3000/santiye'});

  final String baseUrl;

  Map<String, String> get _headers {
    final token = AuthServisi.mevcutToken;
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<dynamic>> santiyeListele() async {
    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: _headers,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);
      if (json is List) return json;
      if (json is Map && json['data'] is List) return json['data'] as List;
      return [];
    }
    throw Exception('Şantiyeler yüklenemedi: ${response.body}');
  }

  Future<Map<String, dynamic>> santiyeOlustur({required String name}) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: _headers,
      body: jsonEncode({'name': name.trim()}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);
      if (json is Map<String, dynamic>) return json;
      return {'data': json};
    }
    throw Exception('Şantiye oluşturulamadı: ${response.body}');
  }

  Future<Map<String, dynamic>> katilimBasvurusuYap({required String code}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/join-requests'),
      headers: _headers,
      body: jsonEncode({'code': code.trim().toUpperCase()}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);
      if (json is Map<String, dynamic>) return json;
      return {'message': 'Başvuru gönderildi'};
    }
    throw Exception('Katılım başvurusu başarısız: ${response.body}');
  }

  Future<List<dynamic>> bildirimleriGetir() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: _headers,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);
      if (json is List) return json;
      if (json is Map && json['data'] is List) return json['data'] as List;
      return [];
    }
    throw Exception('Bildirimler yüklenemedi: ${response.body}');
  }

  Future<List<dynamic>> bekleyenBasvurulariGetir(int projectId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$projectId/join-requests'),
      headers: _headers,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);
      if (json is List) return json;
      return [];
    }
    throw Exception('Başvurular yüklenemedi: ${response.body}');
  }

  Future<void> basvuruSonuclandir({
    required String projectId,
    required String memberId,
    required String status,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/$projectId/join-requests/$memberId'),
      headers: _headers,
      body: jsonEncode({
        'status': status,
        'decision': status,
        'karar': status,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Başvuru sonuçlandırılamadı: ${response.body}');
    }
  }
}
*/
