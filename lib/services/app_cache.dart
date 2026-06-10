import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CacheEntry {
  final dynamic data;
  final int expiresAt;

  CacheEntry({required this.data, required this.expiresAt});

  Map<String, dynamic> toJson() => {'data': data, 'expiresAt': expiresAt};

  factory CacheEntry.fromJson(Map<dynamic, dynamic> json) {
    return CacheEntry(
      data: json['data'],
      expiresAt: json['expiresAt'] as int? ?? 0,
    );
  }

  bool get isStale => DateTime.now().millisecondsSinceEpoch > expiresAt;
}

class AppCache {
  static const String _boxName = 'lm_champs_cache';
  static final AppCache instance = AppCache._();
  AppCache._();

  late Box _box;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    // Compact box on startup to reclaim space from deleted entries
    await _box.compact();
    _initialized = true;
    debugPrint('📦 AppCache (Hive/Student) initialized. Entries: ${_box.length}');
  }

  dynamic get(String key) {
    if (!_initialized) return null;
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final entry = CacheEntry.fromJson(Map<dynamic, dynamic>.from(raw as Map));
      return entry.data;
    } catch (e) {
      return null;
    }
  }

  bool isStale(String key) {
    if (!_initialized) return true;
    final raw = _box.get(key);
    if (raw == null) return true;
    try {
      final entry = CacheEntry.fromJson(Map<dynamic, dynamic>.from(raw as Map));
      return entry.isStale;
    } catch (_) {
      return true;
    }
  }

  bool has(String key) => _initialized && _box.containsKey(key);

  Future<void> set(String key, dynamic data, {Duration ttl = const Duration(hours: 2)}) async {
    if (!_initialized) return;
    try {
      dynamic storableData = data;
      if (data is! String && data is! num && data is! bool && data is! List && data is! Map) {
        storableData = jsonDecode(jsonEncode(data));
      }
      final expiresAt = DateTime.now().add(ttl).millisecondsSinceEpoch;
      await _box.put(key, CacheEntry(data: storableData, expiresAt: expiresAt).toJson());
    } catch (e) {
      debugPrint('AppCache write error: $e');
    }
  }

  Future<void> remove(String key) async {
    if (!_initialized) return;
    await _box.delete(key);
  }

  Future<void> clear() async {
    if (!_initialized) return;
    await _box.clear();
  }
}
