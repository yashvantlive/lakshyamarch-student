import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_cache.dart';

class Notice {
  final String id;
  final String title;
  final String content;
  final String type; // 'homework', 'circular', 'event'
  final String date;
  final String? attachmentUrl;
  final String author;
  final String? wing; // 'school' or 'coaching'

  Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.date,
    this.attachmentUrl,
    required this.author,
    this.wing,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'circular',
      date: json['date'] ?? '',
      attachmentUrl: json['attachmentUrl'],
      author: json['author'] ?? 'School Admin',
      wing: json['wing'] ?? 'school',
    );
  }
}

class NoticeProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Notice> _notices = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;

  List<Notice> get notices => _notices;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;

  Future<void> fetchNotices(
    String className, 
    String? classId, 
    String? coachingClass, 
    String? coachingClassId, 
    String? wing, 
    String token,
    {bool forceRefresh = false}
  ) async {
    final cacheKey = 'notices_$className';

    // 1. Instant Cache Read
    final cached = AppCache.instance.get(cacheKey);
    bool hasCache = false;
    if (cached != null && cached is List) {
      _notices = cached.map((n) => Notice.fromJson(Map<String, dynamic>.from(n as Map))).toList();
      hasCache = true;
      _isLoading = false;
      notifyListeners();
    }

    if (hasCache && !forceRefresh && !AppCache.instance.isStale(cacheKey)) {
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
      final List<dynamic> data = await _apiService.getNotices(className, classId, coachingClass, coachingClassId, wing, token);
      
      _notices = data.map((n) => Notice.fromJson(n)).toList();
      AppCache.instance.set(cacheKey, data, ttl: const Duration(minutes: 30));
    } catch (e) {
      if (!hasCache) {
        _error = 'Failed to fetch notices offline.';
      }
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }
}

