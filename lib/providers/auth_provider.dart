import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/student.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  String? _token;
  Map<String, dynamic>? _user;
  List<Student> _allStudents = [];
  Student? _currentStudent;
  String? _error;
  ThemeMode _themeMode = ThemeMode.light;

  AuthProvider() {
    _loadThemeMode();
  }

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  List<Student> get allStudents => _allStudents;
  Student? get currentStudent => _currentStudent;
  String? get activeWingMode => _currentStudent?.wing;
  String? get error => _error;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    AppTheme.isDarkMode = _themeMode == ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', _themeMode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('theme_mode');
    if (mode == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    AppTheme.isDarkMode = _themeMode == ThemeMode.dark;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _apiService.login(email, password);
      _token = res['token'];
      _user = res['user'];
      
      // Fetch linked student profiles
      if (_user != null && _token != null) {
        _allStudents = await _apiService.getStudentProfiles(_user!['uid'], _token!);
        if (_allStudents.isNotEmpty) {
          _currentStudent = _allStudents[0];
        }
      }
      
      _isLoading = false;
      
      // Persist session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('user', jsonEncode(_user));
      if (_allStudents.isNotEmpty) {
        await prefs.setString('cached_students_${_user!['uid']}', jsonEncode(_allStudents.map((s) => s.toJson()).toList()));
      }
      
      notifyListeners();

      // Register Push Token (OneSignal)
      _updateNotificationRegistration();

      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void switchStudent(Student student) {
    if (_allStudents.contains(student)) {
      _currentStudent = student;
      notifyListeners();
      _updateNotificationRegistration();
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _currentStudent = null;
    _allStudents = [];
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    
    notifyListeners();
    NotificationService.removeExternalUserId();
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) return;

    _token = prefs.getString('token');
    final userStr = prefs.getString('user');
    
    if (userStr != null && userStr.isNotEmpty) {
      _user = jsonDecode(userStr);
    }
    
    if (_token != null && _user != null) {
      // 1. Instant Cache Read for 0ms startup delay
      final cachedStudentsStr = prefs.getString('cached_students_${_user!['uid']}');
      if (cachedStudentsStr != null && cachedStudentsStr.isNotEmpty) {
        try {
          final List decoded = jsonDecode(cachedStudentsStr);
          _allStudents = decoded.map((s) => Student.fromJson(s)).toList();
          if (_allStudents.isNotEmpty) {
            _currentStudent = _allStudents[0];
          }
          notifyListeners(); // Instantly displays Home screen
        } catch (_) {}
      }

      // 2. Silent Background Re-fetch
      _apiService.getStudentProfiles(_user!['uid'], _token!).then((profiles) {
        if (profiles.isNotEmpty) {
          _allStudents = profiles;
          // Maintain selected student if valid
          if (_currentStudent == null || !profiles.any((p) => p.id == _currentStudent!.id)) {
            _currentStudent = profiles[0];
          } else {
            _currentStudent = profiles.firstWhere((p) => p.id == _currentStudent!.id);
          }
          prefs.setString('cached_students_${_user!['uid']}', jsonEncode(profiles.map((s) => s.toJson()).toList()));
          notifyListeners();
          _updateNotificationRegistration();
        }
      }).catchError((e) {
        debugPrint("Auto-login profile background fetch failed: $e");
      });
      
      _updateNotificationRegistration();
    }
  }

  Future<void> _updateNotificationRegistration() async {
    if (_token != null && _user != null) {
      final fcmToken = await NotificationService.getFcmToken();
      if (fcmToken != null) {
        await _apiService.registerPushToken(_token!, fcmToken);
      }
    }
  }
}
