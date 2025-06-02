import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Replace with your actual server address (use your computer's IP when testing)
  final String baseUrl = 'http://10.0.2.2:5050/api';
  final storage = FlutterSecureStorage();

  // Register a new user
  Future<Map<String, dynamic>> signup(String nomComplet, String email,
      String motDePasse, String telephone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nom_complet': nomComplet,
          'email': email,
          'mot_de_passe': motDePasse,
          'telephone': telephone
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Login user
  Future<Map<String, dynamic>> login(String email, String motDePasse) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'mot_de_passe': motDePasse,
        }),
      );

      final data = jsonDecode(response.body);

      // If login successful, store the token
      if (response.statusCode == 200 && data['token'] != null) {
        await storage.write(key: 'auth_token', value: data['token']);
      }

      return data;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Get authenticated user token
  Future<String?> getToken() async {
    return await storage.read(key: 'auth_token');
  }

  // Logout user by deleting token
  Future<void> logout() async {
    await storage.delete(key: 'auth_token');
  }

  // Example of authenticated request
  Future<Map<String, dynamic>> getProtectedData() async {
    try {
      final token = await getToken();

      if (token == null) {
        return {'error': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/protected-route'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}