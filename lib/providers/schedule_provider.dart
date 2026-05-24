import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/app_cache.dart';
import '../models/schedule.dart';
import '../models/homework.dart';

class ScheduleProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _isRefreshing = false;
  DateTime _selectedDate = DateTime.now();
  Schedule? _currentSchedule;
  List<Homework> _homeworks = [];
  String? _error;

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  DateTime get selectedDate => _selectedDate;
  Schedule? get currentSchedule => _currentSchedule;
  List<Homework> get homeworks => _homeworks;
  String? get error => _error;

  void selectDate(DateTime date, String token, String classId) {
    _selectedDate = date;
    fetchSchedule(token, classId);
  }

  Future<void> fetchSchedule(String token, String classId, {bool forceRefresh = false}) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final cacheKeySc = 'sched_${classId}_$dateStr';
    final cacheKeyHw = 'hw_${classId}_$dateStr';

    // 1. Instant Cache Read
    final cachedSc = AppCache.instance.get(cacheKeySc);
    final cachedHw = AppCache.instance.get(cacheKeyHw);

    bool hasCache = false;
    if (cachedSc != null && cachedSc is Map) {
      _currentSchedule = Schedule.fromJson(Map<String, dynamic>.from(cachedSc));
      hasCache = true;
    }
    if (cachedHw != null && cachedHw is List) {
      _homeworks = cachedHw.map((h) => Homework.fromJson(Map<String, dynamic>.from(h as Map))).toList();
      hasCache = true;
    }

    if (hasCache) {
      _isLoading = false;
      notifyListeners();
    }

    if (hasCache && !forceRefresh && !AppCache.instance.isStale(cacheKeySc)) {
      return;
    }

    // 2. Silent Network Refresh
    if (!hasCache || forceRefresh) {
      _isLoading = true;
    } else {
      _isRefreshing = true;
    }
    _error = null;
    notifyListeners();

    try {
      final Future scFuture = _apiService.getSchedule(dateStr, token);
      final Future hwFuture = _apiService.getRequest('/api/homework?date=$dateStr&classId=$classId', token);

      final results = await Future.wait<dynamic>([scFuture, hwFuture]);

      final data = results[0];
      final homeworkData = results[1];
      
      if (data != null) {
        _currentSchedule = Schedule.fromJson(data as Map<String, dynamic>);
        AppCache.instance.set(cacheKeySc, data, ttl: const Duration(hours: 12));
      } else {
        _currentSchedule = null;
      }

      if (homeworkData is List) {
        _homeworks = homeworkData.map((h) => Homework.fromJson(h as Map<String, dynamic>)).toList();
        AppCache.instance.set(cacheKeyHw, homeworkData, ttl: const Duration(hours: 2));
      }
    } catch (e) {
      if (!hasCache) {
        _error = 'Failed to load schedule offline.';
      }
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }
}
