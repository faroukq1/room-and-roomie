import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isAuthenticated = false;
  Map<String, dynamic>? _userData;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get userData => _userData;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final token = await _apiService.getToken();
    _isAuthenticated = token != null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> signup(String nomComplet, String email,
      String motDePasse, String telephone) async {
    final result = await _apiService.signup(nomComplet, email, motDePasse, telephone);
    return result;
  }

  Future<Map<String, dynamic>> login(String email, String motDePasse) async {
    final result = await _apiService.login(email, motDePasse);

    if (result['token'] != null) {
      _isAuthenticated = true;
      _userData = result['user'];
      notifyListeners();
    }

    return result;
  }

  Future<void> logout() async {
    await _apiService.logout();
    _isAuthenticated = false;
    _userData = null;
    notifyListeners();
  }
}