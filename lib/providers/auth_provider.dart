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

  // Multi-Account Support
  List<Map<String, dynamic>> _savedAccounts = [];

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
  
  List<Map<String, dynamic>> get savedAccounts => _savedAccounts;

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
      
      if (res['user'] != null && res['user']['role'] != 'student') {
        throw Exception('Access denied: Student account required.');
      }
      
      _token = res['token'];
      _user = res['user'];
      
      // Update Saved Accounts
      if (_user != null && _token != null) {
        final uid = _user!['uid'];
        final existingIndex = _savedAccounts.indexWhere((acc) => acc['user']['uid'] == uid);
        if (existingIndex >= 0) {
          _savedAccounts[existingIndex] = {'token': _token, 'user': _user};
        } else {
          _savedAccounts.add({'token': _token, 'user': _user});
        }
      }
      
      // Fetch linked student profiles
      if (_user != null && _token != null) {
        _allStudents = await _apiService.getStudentProfiles(_user!['uid'], _token!);
        if (_allStudents.isNotEmpty) {
          _currentStudent = _allStudents[0];
        }
      }
      
      _isLoading = false;
      
      await _persistState();
      notifyListeners();

      // Register Push Token for all saved accounts
      await _updateNotificationRegistration();

      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> switchAccount(String uid) async {
    final account = _savedAccounts.firstWhere((acc) => acc['user']['uid'] == uid, orElse: () => {});
    if (account.isEmpty) return false;

    _token = account['token'];
    _user = account['user'];
    _currentStudent = null;
    _allStudents = [];
    
    notifyListeners(); // Trigger UI loading states if needed
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
    await prefs.setString('user', jsonEncode(_user));
    
    // Quick load from cache for the switched account
    final cachedStudentsStr = prefs.getString('cached_students_${_user!['uid']}');
    if (cachedStudentsStr != null && cachedStudentsStr.isNotEmpty) {
      try {
        final List decoded = jsonDecode(cachedStudentsStr);
        _allStudents = decoded.map((s) => Student.fromJson(s)).toList();
        if (_allStudents.isNotEmpty) {
          _currentStudent = _allStudents[0];
        }
      } catch (_) {}
    }
    notifyListeners();

    // Background fetch to ensure fresh profiles
    try {
      final profiles = await _apiService.getStudentProfiles(_user!['uid'], _token!);
      if (profiles.isNotEmpty) {
        _allStudents = profiles;
        _currentStudent = profiles[0];
        prefs.setString('cached_students_${_user!['uid']}', jsonEncode(profiles.map((s) => s.toJson()).toList()));
      }
    } catch (_) {}
    
    notifyListeners();
    return true;
  }

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      await prefs.setString('token', _token!);
    }
    if (_user != null) {
      await prefs.setString('user', jsonEncode(_user));
      if (_allStudents.isNotEmpty) {
        await prefs.setString('cached_students_${_user!['uid']}', jsonEncode(_allStudents.map((s) => s.toJson()).toList()));
      }
    }
    await prefs.setString('saved_accounts', jsonEncode(_savedAccounts));
  }

  void switchStudent(Student student) {
    if (_allStudents.contains(student)) {
      _currentStudent = student;
      notifyListeners();
      _updateNotificationRegistration();
    }
  }

  /// Refreshes the current student profiles from the API and updates cache.
  /// Safe to call from any screen (no-op if not authenticated).
  Future<void> fetchProfile({bool forceRefresh = false}) async {
    if (_token == null || _user == null) return;
    try {
      final profiles = await _apiService.getStudentProfiles(_user!['uid'], _token!);
      if (profiles.isNotEmpty) {
        _allStudents = profiles;
        if (_currentStudent == null || !profiles.any((p) => p.id == _currentStudent!.id)) {
          _currentStudent = profiles[0];
        } else {
          _currentStudent = profiles.firstWhere((p) => p.id == _currentStudent!.id);
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_students_${_user!['uid']}', jsonEncode(profiles.map((s) => s.toJson()).toList()));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AuthProvider] fetchProfile error: $e');
    }
  }

  Future<void> logout() async {
    // If we want logout to just remove the current account:
    if (_user != null) {
      _savedAccounts.removeWhere((acc) => acc['user']['uid'] == _user!['uid']);
    }
    
    _token = null;
    _user = null;
    _currentStudent = null;
    _allStudents = [];
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_accounts', jsonEncode(_savedAccounts));
    
    if (_savedAccounts.isNotEmpty) {
      // Just switch to the first available account
      await switchAccount(_savedAccounts.first['user']['uid']);
    } else {
      // Full logout
      await prefs.remove('token');
      await prefs.remove('user');
      await prefs.remove('saved_accounts');
      NotificationService.removeExternalUserId();
      notifyListeners();
    }
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Migrate or load saved accounts
    final savedAccountsStr = prefs.getString('saved_accounts');
    if (savedAccountsStr != null && savedAccountsStr.isNotEmpty) {
      try {
        final List decoded = jsonDecode(savedAccountsStr);
        _savedAccounts = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {}
    }

    if (!prefs.containsKey('token')) return;

    _token = prefs.getString('token');
    final userStr = prefs.getString('user');
    
    if (userStr != null && userStr.isNotEmpty) {
      _user = jsonDecode(userStr);
    }
    
    if (_token != null && _user != null) {
      // Backwards compatibility migration
      if (_savedAccounts.isEmpty) {
        _savedAccounts.add({'token': _token, 'user': _user});
        await prefs.setString('saved_accounts', jsonEncode(_savedAccounts));
      }

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
        }
      }).catchError((e) {
        debugPrint("Auto-login profile background fetch failed: $e");
      });
      
      _updateNotificationRegistration();
    }
  }

  Future<void> _updateNotificationRegistration() async {
    final fcmToken = await NotificationService.getFcmToken();
    if (fcmToken != null) {
      // Register token for ALL saved accounts so device gets notifications for all
      for (var acc in _savedAccounts) {
        if (acc['token'] != null) {
          try {
             await _apiService.registerPushToken(acc['token'], fcmToken);
          } catch(e) {
             debugPrint("Push register failed for ${acc['user']['uid']}: $e");
          }
        }
      }
    }
  }
}
