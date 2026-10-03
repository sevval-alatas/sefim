/*
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:sefim/servis/auth_servisi.dart';

class DeliveryNoteServisi {
  DeliveryNoteServisi({this.baseUrl = 'http://localhost:3000'});

  final String baseUrl;

  Future<DeliveryNoteYanit> uploadDeliveryNote({
    required File image,
    String? token,
    Map<String, String>? ekAlanlar,
  }) async {
    final uri = Uri.parse('$baseUrl/delivery-notes');
    final request = http.MultipartRequest('POST', uri);

    final authToken = token ?? AuthServisi.mevcutToken;
    if (authToken != null && authToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $authToken';
    }

    final uzanti = image.path.split('.').last.toLowerCase();
    MediaType medyaTuru;
    if (uzanti == 'png') {
      medyaTuru = MediaType('image', 'png');
    } else if (uzanti == 'webp') {
      medyaTuru = MediaType('image', 'webp');
    } else if (uzanti == 'heic' || uzanti == 'heif') {
      medyaTuru = MediaType('image', 'heic');
    } else {
      medyaTuru = MediaType('image', 'jpeg');
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'photo',
        image.path,
        contentType: medyaTuru,
      ),
    );

    if (ekAlanlar != null) {
      request.fields.addAll(ekAlanlar);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return DeliveryNoteYanit(
      statusCode: response.statusCode,
      body: response.body,
      basarili: response.statusCode >= 200 && response.statusCode < 300,
    );
  }
}

class DeliveryNoteYanit {
  const DeliveryNoteYanit({
    required this.statusCode,
    required this.body,
    required this.basarili,
  });

  final int statusCode;
  final String body;
  final bool basarili;
}
*/
