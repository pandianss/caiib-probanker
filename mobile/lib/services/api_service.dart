import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final String _baseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:8000/api');
  final _storage = const FlutterSecureStorage();

  Future<String?> getToken() async => await _storage.read(key: 'jwt');

  Future<bool> register(String name, String password, String email, String mobile, String elective) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register/'),
        body: {'name': name, 'password': password, 'email': email, 'mobile_number': mobile, 'elective': elective},
      ).timeout(const Duration(seconds: 10));
      // Django DRF response 201 Created or 200 OK.
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true; // Use standard login after this
      }
      return false;
    } catch (e) {
      return false;
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
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProfile(String name) async {
    final token = await getToken();
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
    final token = await getToken();
    if (token == null) return null;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/progress/'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getKnowledgeTracing() async {
     final token = await getToken();
     if (token == null) return null;
     try {
       final response = await http.get(
         Uri.parse('$_baseUrl/knowledge-tracing/'),
         headers: {'Authorization': 'Bearer $token'},
       ).timeout(const Duration(seconds: 10));
       if (response.statusCode == 200) {
          return jsonDecode(response.body);
       }
       return null;
     } catch (e) {
       return null;
     }
  }

  Future<Map<String, dynamic>?> getTodaysBite() async {
    final token = await getToken();
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

  Future<Map<String, dynamic>?> submitBite({
    required String biteId,
    required String answer,
    required int timeTakenSeconds,
  }) async {
    final token = await getToken();
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
    final token = await getToken();
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

  Future<void> clearSession() async {
    await _storage.delete(key: 'jwt');
  }

  Future<bool> updateElective(String elective) async {
    final token = await getToken();
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

  Future<bool> deleteAccount() async {
    final token = await getToken();
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
