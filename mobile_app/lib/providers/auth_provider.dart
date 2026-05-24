import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user_model.dart';
import '../core/constants/app_constants.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  String get token => _user?.token ?? '';

  AuthProvider() {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyToken);
    final userId = prefs.getString(AppConstants.keyUserId);
    final username = prefs.getString(AppConstants.keyUsername);
    final displayName = prefs.getString(AppConstants.keyDisplayName);
    final srcLang = prefs.getString(AppConstants.keySrcLang) ?? 'en';
    final tgtLang = prefs.getString(AppConstants.keyTgtLang) ?? 'ar';

    if (token != null && userId != null) {
      _user = UserModel(
        id: userId,
        username: username ?? '',
        email: '',
        displayName: displayName,
        preferredLanguage: srcLang,
        targetLanguage: tgtLang,
        token: token,
      );
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
    required String phone,
    String? displayName,
    String preferredLanguage = 'en',
    String targetLanguage = 'ar',
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final resp = await http.post(
        Uri.parse(AppConstants.registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': email,
          'email': email,
          'phone': phone,
          'password': password,
          'display_name': displayName ?? email.split('@')[0],
          'preferred_language': preferredLanguage,
          'target_language': targetLanguage,
        }),
      );

      if (resp.statusCode == 201) {
        final data = jsonDecode(resp.body);
        await _saveSession(data);
        return true;
      } else {
        final err = jsonDecode(resp.body);
        _error = err['detail'] ?? 'Registration failed';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error. Please check your connection.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final resp = await http.post(
        Uri.parse(AppConstants.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': email, 'password': password}),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        await _saveSession(data);
        return true;
      } else {
        final err = jsonDecode(resp.body);
        _error = err['detail'] ?? 'Invalid credentials';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error. Please check your connection.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    _user = UserModel.fromJson(data);
    _status = AuthStatus.authenticated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyToken, _user!.token ?? '');
    await prefs.setString(AppConstants.keyUserId, _user!.id);
    await prefs.setString(AppConstants.keyUsername, _user!.username);
    await prefs.setString(AppConstants.keyDisplayName, _user!.displayTitle);
    await prefs.setString(AppConstants.keySrcLang, _user!.preferredLanguage);
    await prefs.setString(AppConstants.keyTgtLang, _user!.targetLanguage);
    notifyListeners();
  }

  Future<void> updateLanguages(String src, String tgt) async {
    if (_user == null) return;
    _user = _user!.copyWith(preferredLanguage: src, targetLanguage: tgt);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keySrcLang, src);
    await prefs.setString(AppConstants.keyTgtLang, tgt);
    notifyListeners();
    // Sync to server
    try {
      await http.put(
        Uri.parse(AppConstants.profileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'preferred_language': src, 'target_language': tgt}),
      );
    } catch (_) {}
  }

  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse(AppConstants.logoutUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Map<String, String> get authHeaders => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
}
