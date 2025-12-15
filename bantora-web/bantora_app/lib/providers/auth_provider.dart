import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  static const String _keyAccessToken = 'auth.accessToken';
  static const String _keyRefreshToken = 'auth.refreshToken';

  final ApiService apiService;

  bool _isAuthenticated = false;
  bool _isInitialized = false;

  String? _accessToken;
  String? _refreshToken;

  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  AuthProvider({required this.apiService}) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_keyAccessToken);
    _refreshToken = prefs.getString(_keyRefreshToken);

    if (_accessToken != null && _accessToken!.isNotEmpty) {
      _isAuthenticated = true;
      apiService.setAccessToken(_accessToken!);
      apiService.setRefreshToken(_refreshToken);
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();

    if (_accessToken == null || _accessToken!.isEmpty) {
      throw StateError('Attempted to persist missing access token');
    }

    await prefs.setString(_keyAccessToken, _accessToken!);

    if (_refreshToken != null && _refreshToken!.isNotEmpty) {
      await prefs.setString(_keyRefreshToken, _refreshToken!);
    }
  }

  Future<String?> login({required String phoneNumber, required String password}) async {
    try {
      final auth = await apiService.login(phoneNumber: phoneNumber, password: password);

      final access = auth['accessToken'] as String?;
      if (access == null || access.isEmpty) {
        throw StateError('Missing accessToken in login response');
      }

      _accessToken = access;
      _refreshToken = auth['refreshToken'] as String?;

      apiService.setAccessToken(_accessToken!);
      apiService.setRefreshToken(_refreshToken);

      _isAuthenticated = true;
      await _saveToStorage();
      notifyListeners();

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> register({
    required String phoneNumber,
    required String password,
    required String countryCode,
    String? fullName,
    String? email,
  }) async {
    try {
      final auth = await apiService.register(
        phoneNumber: phoneNumber,
        password: password,
        countryCode: countryCode,
        fullName: fullName,
        email: email,
      );

      final access = auth['accessToken'] as String?;
      if (access == null || access.isEmpty) {
        throw StateError('Missing accessToken in register response');
      }

      _accessToken = access;
      _refreshToken = auth['refreshToken'] as String?;

      apiService.setAccessToken(_accessToken!);
      apiService.setRefreshToken(_refreshToken);

      _isAuthenticated = true;
      await _saveToStorage();
      notifyListeners();

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    try {
      if (_refreshToken != null && _refreshToken!.isNotEmpty) {
        await apiService.logout(refreshToken: _refreshToken!);
      }
    } catch (_) {
      // Ignore errors
    }

    _accessToken = null;
    _refreshToken = null;
    _isAuthenticated = false;

    apiService.clearAuth();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);

    notifyListeners();
  }
}
