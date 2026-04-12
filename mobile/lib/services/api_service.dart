import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static String get _defaultUrl {
    if (kIsWeb) return 'http://localhost:8000/api';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000/api';
    } catch (_) {}
    return 'http://localhost:8000/api';
  }

  final String _baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '', 
  ).isEmpty ? _defaultUrl : const String.fromEnvironment('API_BASE_URL');

  final _storage = const FlutterSecureStorage();

  Future<String?> getToken() async => await _storage.read(key: 'jwt');

  Future<String?> _getValidToken() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return token;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final data = jsonDecode(payload);
      final exp = data['exp'] as int;
      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);

      // Refresh if expiring in less than 5 minutes
      if (DateTime.now().isAfter(expiry.subtract(const Duration(minutes: 5)))) {
        return await _refreshToken();
      }
      return token;
    } catch (_) {
      return token;
    }
  }

  Future<String?> _refreshToken() async {
    final refreshToken = await _storage.read(key: 'jwt_refresh');
    if (refreshToken == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'jwt', value: data['access']);
        return data['access'];
      }
    } catch (_) {}

    await clearSession();
    return null;
  }

  Future<Map<String, dynamic>> register(String name, String password, String email, String mobile, String elective) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register/'),
        body: {'name': name, 'password': password, 'email': email, 'mobile_number': mobile, 'elective': elective},
      ).timeout(const Duration(seconds: 10));
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'error': data['error'] ?? 'Registration failed.'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error. Please check your network.'};
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/token/'),
        body: {'username': username, 'password': password},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'jwt', value: data['access']);
        await _storage.write(key: 'jwt_refresh', value: data['refresh']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProfile(String name) async {
    final token = await _getValidToken();
    if (token == null) return false;
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/profile/update/'),
        headers: {'Authorization': 'Bearer $token'},
        body: {'name': name},
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getProgress() async {
    final token = await _getValidToken();
    if (token == null) return null;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/progress/'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getStats() async {
    final token = await _getValidToken();
    if (token == null) return null;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/stats/'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getTodaysBite() async {
    final token = await _getValidToken();
    if (token == null) return null;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/bites/today/'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDueBites() async {
    final token = await _getValidToken();
    if (token == null) return null;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/bites/due/'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<String>?> getMasteredBiteIds() async {
    final token = await _getValidToken();
    if (token == null) return null;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/bites/mastered/'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['mastered_ids']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<dynamic>?> getBiteHistory() async {
    final token = await _getValidToken();
    if (token == null) return null;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/bites/history/'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> submitBite({
    required String biteId,
    required String answer,
    required int timeTakenSeconds,
  }) async {
    final token = await _getValidToken();
    if (token == null) return null;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/bites/submit/'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'bite_id': biteId, 'answer': answer, 'time_taken_seconds': timeTakenSeconds}),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>?> getBitesByPaper(String paperCode) async {
    final token = await _getValidToken();
    if (token == null) return null;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/bites/$paperCode/'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Public wrapper around _getValidToken() for use during app startup.
  Future<String?> getValidTokenForStartup() async => await _getValidToken();

  Future<void> clearSession() async {
    await _storage.delete(key: 'jwt');
    await _storage.delete(key: 'jwt_refresh');
  }

  Future<bool> updateElective(String elective) async {
    final token = await _getValidToken();
    if (token == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/select-elective/'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'elective': elective}),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>?> getMarketplaceBundles() async {
    final token = await _getValidToken();
    if (token == null) return null;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/marketplace/'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> purchaseBundle(int bundleId) async {
    final token = await _getValidToken();
    if (token == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/marketplace/purchase/'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'bundle_id': bundleId}),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<dynamic>?> getMyOwnedBundles() async {
    final token = await _getValidToken();
    if (token == null) return null;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/marketplace/my-bundles/'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<dynamic>?> getBitesByBundle(int bundleId) async {
    final token = await _getValidToken();
    if (token == null) return null;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/marketplace/bundle/$bundleId/bites/'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteAccount() async {
    final token = await _getValidToken();
    if (token == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/delete/'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        await clearSession();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
