// lib/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this URL if your backend is hosted elsewhere
  static const String baseUrl = 'http://localhost:3000/api';

  /// Sends email/password registration data to your Node.js backend.
  static Future<http.Response> registerWithEmail({
    required String email,
    required String password,
  }) {
    final url = Uri.parse('$baseUrl/register');
    return http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
  }

   /// Sends an SMS or WhatsApp via your backend
  static Future<http.Response> notify({
    required String to,
    required String text,
    required String channel, // 'sms' or 'whatsapp'
  }) {
    return http.post(
      Uri.parse('$baseUrl/notify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'to': to,
        'text': text,
        'channel': channel,
      }),
    );
  }
}
