import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String? _token;
  String? _userId;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get token => _token;
  String? get userId => _userId;
  
  bool get isAuthenticated => _token != null && _userId != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.69:5000/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        _token = data['token'];
        if (_token != null) {
          // Decode the token to get user ID
          try {
            final decodedToken = JwtDecoder.decode(_token!);
            _userId = decodedToken['_id'] as String?;
          } catch (e) {
            print('Error decoding token: $e');
            _userId = null;
          }
          
          // Store token in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', _token!);
          if (_userId != null) {
            await prefs.setString('userId', _userId!);
          }
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = data['error'] ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.69:5000/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = data['error'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Clear all user data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('userId');
      
      // Clear in-memory data
      _token = null;
      _userId = null;
      _error = null;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (_token != null) {
      try {
        final decodedToken = JwtDecoder.decode(_token!);
        _userId = decodedToken['_id'] as String?;
      } catch (e) {
        print('Error decoding token: $e');
        _userId = null;
      }
    }
    return _token != null && _userId != null;
  }
} 