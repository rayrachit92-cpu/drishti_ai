import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/user_model.dart';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  String _baseUrl = AppConfig.defaultApiBase();

  String get baseUrl => _baseUrl;

  Future<void> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(AppConfig.prefsApiBaseKey) ?? AppConfig.defaultApiBase();
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url.replaceAll(RegExp(r'/$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.prefsApiBaseKey, _baseUrl);
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      _uri('/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim().toLowerCase(), 'password': password}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 401 || data['ok'] != true) {
      throw ApiException(data['error']?.toString() ?? 'Invalid email or password.');
    }
    final userJson = data['user'] as Map<String, dynamic>?;
    if (userJson?['unverified'] == true) {
      throw ApiException(
        'Email not verified. Check your inbox for the verification link, then try again.',
      );
    }
    return data;
  }

  Future<DrishtiUser> register({
    required String name,
    required String org,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      _uri('/api/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name.trim(),
        'org': org.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['ok'] != true) {
      throw ApiException(data['error']?.toString() ?? 'Registration failed.');
    }
    return DrishtiUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> predict(String city) async {
    final res = await http.post(
      _uri('/api/predict'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'city': city}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw ApiException(data['message']?.toString() ?? 'Prediction failed.');
    }
    return data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> liveAlert(String city) async {
    final res = await http.post(
      _uri('/api/live-alert'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'city': city}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw ApiException(data['message']?.toString() ?? 'Live alert failed.');
    }
    return data;
  }

  Future<List<Map<String, dynamic>>> predictAllCities() async {
    final res = await http.post(
      _uri('/api/predict-all-cities'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw ApiException(data['message']?.toString() ?? 'Map prediction failed.');
    }
    return List<Map<String, dynamic>>.from(data['cities'] as List);
  }

  Future<String> sendSos({
    required double latitude,
    required double longitude,
    required String name,
    String? telegramChatId,
  }) async {
    final res = await http.post(
      _uri('/sos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'name': name,
        if (telegramChatId != null && telegramChatId.isNotEmpty)
          'telegram_chat_id': telegramChatId,
      }),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['status'] == 'sent') {
      return data['message']?.toString() ?? 'SOS sent successfully.';
    }
    throw ApiException(data['message']?.toString() ?? 'SOS failed.');
  }

  Future<Map<String, dynamic>> fetchWeather(String city) async {
    final uri = Uri.parse(
      'https://api.weatherapi.com/v1/current.json'
      '?key=${AppConfig.weatherApiKey}&q=${Uri.encodeComponent(city)}',
    );
    final res = await http.get(uri);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data.containsKey('error')) {
      final err = data['error'] as Map<String, dynamic>;
      throw ApiException(err['message']?.toString() ?? 'Weather lookup failed.');
    }
    return data;
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
