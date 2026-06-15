import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_cache.dart';
import '../models/test.dart';
import '../models/fee.dart';
import '../models/homework.dart';
import '../models/homework_submission.dart';

class AcademicProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _isRefreshing = false;
  List<dynamic> _attendance = [];
  List<Fee> _fees = [];
  List<Test> _tests = [];
  List<dynamic> _syllabus = [];
  List<Homework> _homeworks = [];
  List<HomeworkSubmission> _submissions = [];
  List<dynamic> _holidays = [];
  List<dynamic> _schedules = [];
  List<dynamic> _otherFees = [];
  List<dynamic> _videos = [];
  Map<String, dynamic>? _leaderboard;
  String? _error;
  double? _totalFee;
  String? _feeRemarks;

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  List<dynamic> get attendance => _attendance;
  List<Fee> get fees => _fees;
  List<Test> get tests => _tests;
  List<dynamic> get syllabus => _syllabus;
  List<Homework> get homeworks => _homeworks;
  List<HomeworkSubmission> get submissions => _submissions;
  List<dynamic> get holidays => _holidays;
  List<dynamic> get schedules => _schedules;
  List<dynamic> get otherFees => _otherFees;
  List<dynamic> get videos => _videos;
  Map<String, dynamic>? get leaderboard => _leaderboard;
  String? get error => _error;
  double? get totalFee => _totalFee;
  String? get feeRemarks => _feeRemarks;

  void clear() {
    _attendance = [];
    _fees = [];
    _tests = [];
    _syllabus = [];
    _homeworks = [];
    _submissions = [];
    _holidays = [];
    _schedules = [];
    _otherFees = [];
    _videos = [];
    _leaderboard = null;
    _totalFee = null;
    _feeRemarks = null;
    _error = null;
    notifyListeners();
  }

  // Derived Stats
  double get attendanceRate {
    if (_attendance.isEmpty) return 0.0;
    int present = _attendance.where((a) => (a['status'] ?? '').toString().toLowerCase() == 'present').length;
    return (present / _attendance.length) * 100;
  }

  double get averageSchoolScore {
    final scoredTests = _tests.where((t) => (t.wing == 'school') && t.status == 'published' && t.maxMarks > 0 && t.result != null).toList();
    if (scoredTests.isEmpty) return 0.0;
    
    double totalPct = 0;
    for (var test in scoredTests) {
      totalPct += (test.result!.score / test.maxMarks) * 100;
    }
    return totalPct / scoredTests.length;
  }

  double get averageCoachingScore {
    final scoredTests = _tests.where((t) => (t.wing == 'coaching') && t.status == 'published' && t.maxMarks > 0 && t.result != null).toList();
    if (scoredTests.isEmpty) return 0.0;
    
    double totalPct = 0;
    for (var test in scoredTests) {
      totalPct += (test.result!.score / test.maxMarks) * 100;
    }
    return totalPct / scoredTests.length;
  }

  double get averageScore {
    final scoredTests = _tests.where((t) => t.status == 'published' && t.maxMarks > 0 && t.result != null).toList();
    if (scoredTests.isEmpty) return 0.0;
    
    double totalPct = 0;
    for (var test in scoredTests) {
      totalPct += (test.result!.score / test.maxMarks) * 100;
    }
    return totalPct / scoredTests.length;
  }

  Future<List<dynamic>> fetchLocalNcertBooks(String wing) async {
    try {
      final fileName = wing == 'school' ? 'ncertschool.json' : 'ncertcoaching.json';
      final String data = await rootBundle.loadString('lib/$fileName');
      return json.decode(data) as List<dynamic>;
    } catch (e) {
      debugPrint("Failed to load local NCERT books: $e");
      return [];
    }
  }

  int get schoolTestsCount {
    return _tests.where((t) => t.wing == 'school' && t.status == 'published' && t.result != null).length;
  }

  int get coachingTestsCount {
    return _tests.where((t) => t.wing == 'coaching' && t.status == 'published' && t.result != null).length;
  }

  double get homeworkCompletion {
    if (_homeworks.isEmpty) return 0.0;
    return (_submissions.length / _homeworks.length).clamp(0.0, 1.0) * 100;
  }

  int get attendanceStreak {
    if (_attendance.isEmpty) return 0;
    final sorted = List<dynamic>.from(_attendance)
      ..sort((a, b) {
        final dateA = a['date'] ?? '';
        final dateB = b['date'] ?? '';
        return dateB.compareTo(dateA);
      });
    int streak = 0;
    for (final day in sorted) {
      if ((day['status'] ?? '').toString().toLowerCase() == 'present') {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  int get pendingHomeworksCount {
    if (_homeworks.isEmpty) return 0;
    final submittedIds = _submissions.map((s) => s.homeworkId).toSet();
    return _homeworks.where((hw) => !submittedIds.contains(hw.id)).length;
  }

  int get upcomingTestsCount {
    if (_tests.isEmpty) return 0;
    return _tests.where((t) => t.status.toLowerCase() == 'upcoming' || t.status.toLowerCase() == 'scheduled').length;
  }

  DateTime? _lastFetchTime;

  Future<void> _executeFetchAndCache({
    required String studentId,
    required String userId,
    required String className,
    required String? classId,
    required String? coachingClass,
    required String? coachingClassId,
    required String? wing,
    required String token,
  }) async {
    final futures = await Future.wait([
      _apiService.getAttendance(studentId, token),
      _apiService.getFees(studentId, token),
      _apiService.getTestsWithResults(userId, className, coachingClass, wing, token),
      _apiService.getSyllabus(classId ?? className, wing, token),
      _apiService.getHomeworkHistory(
        startDate: DateTime.now().subtract(const Duration(days: 45)).toIso8601String().split('T')[0],
        endDate: DateTime.now().add(const Duration(days: 7)).toIso8601String().split('T')[0],
        token: token
      ),
      _apiService.getStudentSubmissions(studentId, token),
      _apiService.getHolidays(token),
      _apiService.getLeaderboard(classId ?? (coachingClassId ?? className), token),
      _apiService.getSchedulesRange(
        DateTime.now().subtract(const Duration(days: 45)).toIso8601String().split('T')[0],
        DateTime.now().add(const Duration(days: 7)).toIso8601String().split('T')[0],
        token
      ),
      _apiService.getOtherFees(studentId, token),
      _apiService.getVideos((wing == 'coaching' ? coachingClassId : classId) ?? (wing == 'coaching' ? coachingClass : className) ?? className, wing, token),
    ]);

    final keyAtt = 'att_$studentId';
    final keyFee = 'fee_$studentId';
    final keyTst = 'tst_$studentId';
    final keySyl = 'syl_$className';
    final keyHw  = 'hw_univ';
    final keySub = 'sub_$studentId';
    final keyHol = 'holidays_univ';
    final keyLdb = 'ldb_${classId ?? className}';
    final keySch = 'sch_$studentId';
    final keyOth = 'oth_$studentId';
    final keyVid = 'vid_$className';

    _attendance = futures[0] is List ? (futures[0] as List<dynamic>) : [];
    
    // Handle structured fee response robustly (List or Map fallback)
    final feeData = futures[1];
    if (feeData is Map) {
      final feeList = feeData['fees'] as List? ?? [];
      _fees = feeList.map((f) => Fee.fromJson(Map<String, dynamic>.from(f as Map))).toList();
      _totalFee = (feeData['student']?['totalFee'] ?? 0).toDouble();
      _feeRemarks = feeData['student']?['feeRemarks'] ?? "";
    } else if (feeData is List) {
      _fees = feeData.map((f) => Fee.fromJson(Map<String, dynamic>.from(f as Map))).toList();
      _totalFee = 0.0;
      _feeRemarks = "";
    } else {
      _fees = [];
      _totalFee = 0.0;
      _feeRemarks = "";
    }

    _tests = futures[2] is List 
        ? (futures[2] as List).map((t) => Test.fromJson(Map<String, dynamic>.from(t as Map))).toList() 
        : [];
    _syllabus = futures[3] is List ? (futures[3] as List<dynamic>) : [];
    _homeworks = futures[4] is List 
        ? (futures[4] as List).map((h) => Homework.fromJson(Map<String, dynamic>.from(h as Map))).toList() 
        : [];
    _submissions = futures[5] is List 
        ? (futures[5] as List).map((s) => HomeworkSubmission.fromJson(Map<String, dynamic>.from(s as Map))).toList() 
        : [];
    _holidays = futures[6] is List ? (futures[6] as List<dynamic>) : [];

    // Handle leaderboard robustly (Map vs List fallback)
    final ldbData = futures[7];
    if (ldbData is Map) {
      _leaderboard = Map<String, dynamic>.from(ldbData);
    } else {
      _leaderboard = {};
    }
    
    _schedules = futures[8] is List ? (futures[8] as List<dynamic>) : [];
    _otherFees = futures.length > 9 && futures[9] is List ? (futures[9] as List<dynamic>) : [];
    _videos = futures.length > 10 && futures[10] is List ? (futures[10] as List<dynamic>) : [];

    // Cache all results
    AppCache.instance.set(keyAtt, futures[0], ttl: const Duration(hours: 2));
    AppCache.instance.set(keyFee, futures[1], ttl: const Duration(hours: 6));
    AppCache.instance.set(keyTst, futures[2], ttl: const Duration(hours: 2));
    AppCache.instance.set(keySyl, futures[3], ttl: const Duration(hours: 24));
    AppCache.instance.set(keyHw,  futures[4], ttl: const Duration(hours: 1));
    AppCache.instance.set(keySub, futures[5], ttl: const Duration(hours: 1));
    AppCache.instance.set(keyHol, futures[6], ttl: const Duration(days: 7));
    AppCache.instance.set(keyLdb, futures[7], ttl: const Duration(hours: 2));
    AppCache.instance.set(keySch, futures[8], ttl: const Duration(hours: 4));
    if (futures.length > 9) AppCache.instance.set(keyOth, futures[9], ttl: const Duration(hours: 4));
    if (futures.length > 10) AppCache.instance.set(keyVid, futures[10], ttl: const Duration(hours: 24));
  }

  // Stores last fetch params to allow refreshWithLastParams() from any screen
  String? _lastStudentId;
  String? _lastUserId;
  String? _lastClassName;
  String? _lastClassId;
  String? _lastCoachingClass;
  String? _lastCoachingClassId;
  String? _lastWing;
  String? _lastToken;

  /// Convenience refresh — any screen can call this without re-passing all params.
  /// No-op if fetchData was never called before.
  Future<void> refreshWithLastParams() async {
    if (_lastStudentId == null || _lastToken == null) return;
    await fetchData(
      _lastStudentId!,
      _lastUserId!,
      _lastClassName!,
      _lastClassId,
      _lastCoachingClass,
      _lastCoachingClassId,
      _lastWing,
      _lastToken!,
      forceRefresh: true,
    );
  }

  Future<void> fetchData(
    String studentId, 
    String userId, 
    String className, 
    String? classId, 
    String? coachingClass, 
    String? coachingClassId, 
    String? wing, 
    String token,
    {bool forceRefresh = false}
  ) async {
    // Throttle short repeat triggers unless manual pull-to-refresh
    if (!forceRefresh && _lastFetchTime != null && DateTime.now().difference(_lastFetchTime!).inSeconds < 5) {
      return;
    }
    _lastFetchTime = DateTime.now();

    final keyAtt = 'att_$studentId';
    final keyFee = 'fee_$studentId';
    final keyTst = 'tst_$studentId';
    final keySyl = 'syl_$className';
    final keyHw  = 'hw_$studentId';
    final keySub = 'sub_$studentId';
    final keyHol = 'holidays_univ';
    final keyLdb = 'ldb_${classId ?? className}';
    final keySch = 'sch_$studentId';
    final keyOth = 'oth_$studentId';
    final keyVid = 'vid_$className';

    // Store params for refreshWithLastParams() convenience method
    _lastStudentId = studentId;
    _lastUserId = userId;
    _lastClassName = className;
    _lastClassId = classId;
    _lastCoachingClass = coachingClass;
    _lastCoachingClassId = coachingClassId;
    _lastWing = wing;
    _lastToken = token;

    // 1. Instant Zero-Loading Cache Render
    final cAtt = AppCache.instance.get(keyAtt);
    final cFee = AppCache.instance.get(keyFee);
    final cTst = AppCache.instance.get(keyTst);
    final cSyl = AppCache.instance.get(keySyl);
    final cHw  = AppCache.instance.get(keyHw);
    final cSub = AppCache.instance.get(keySub);
    final cHol = AppCache.instance.get(keyHol);
    final cLdb = AppCache.instance.get(keyLdb);
    final cSch = AppCache.instance.get(keySch);
    final cOth = AppCache.instance.get(keyOth);
    final cVid = AppCache.instance.get(keyVid);

    bool hasAnyCache = false;
    if (cAtt is List) { _attendance = cAtt; hasAnyCache = true; }
    if (cFee is List) { 
      _fees = cFee.map((f) => Fee.fromJson(Map<String, dynamic>.from(f as Map))).toList(); 
      hasAnyCache = true; 
    } else if (cFee is Map) {
      final feeList = cFee['fees'] as List?;
      if (feeList != null) {
        _fees = feeList.map((f) => Fee.fromJson(Map<String, dynamic>.from(f as Map))).toList();
        _totalFee = (cFee['student']?['totalFee'] ?? 0).toDouble();
        _feeRemarks = cFee['student']?['feeRemarks'] ?? "";
        hasAnyCache = true;
      }
    }
    if (cTst is List) { _tests = cTst.map((t) => Test.fromJson(Map<String, dynamic>.from(t as Map))).toList(); hasAnyCache = true; }
    if (cSyl is List) { _syllabus = cSyl; hasAnyCache = true; }
    if (cHw is List)  { _homeworks = cHw.map((h) => Homework.fromJson(Map<String, dynamic>.from(h as Map))).toList(); hasAnyCache = true; }
    if (cSub is List) { _submissions = cSub.map((s) => HomeworkSubmission.fromJson(Map<String, dynamic>.from(s as Map))).toList(); hasAnyCache = true; }
    if (cHol is List) { _holidays = cHol; hasAnyCache = true; }
    if (cLdb is Map)  { _leaderboard = Map<String, dynamic>.from(cLdb); hasAnyCache = true; }
    if (cSch is List) { _schedules = cSch; hasAnyCache = true; }
    if (cOth is List) { _otherFees = cOth; hasAnyCache = true; }
    if (cVid is List) { _videos = cVid; hasAnyCache = true; }

    if (hasAnyCache) {
      _isLoading = false;
      notifyListeners(); // Instantly displays pre-loaded layout
    }

    // CRITICAL: Only skip network fetch if BOTH Attendance and Schedules are present and fresh.
    // If schedules are missing (e.g. after update), we MUST fetch.
    bool canSkip = hasAnyCache && 
                   !forceRefresh && 
                   !AppCache.instance.isStale(keyAtt) && 
                   _schedules.isNotEmpty;

    if (canSkip) {
      // Trigger a silent background update to ensure real-time sync with backend
      _silentRevalidate(studentId, userId, className, classId, coachingClass, coachingClassId, wing, token);
      return;
    }

    // 2. Silent Network SWR Refresh
    if (!hasAnyCache || forceRefresh) {
      _isLoading = true;
    } else {
      _isRefreshing = true;
    }
    _error = null;
    notifyListeners();

    try {
      await _executeFetchAndCache(
        studentId: studentId,
        userId: userId,
        className: className,
        classId: classId,
        coachingClass: coachingClass,
        coachingClassId: coachingClassId,
        wing: wing,
        token: token,
      );
    } catch (e, stack) {
      debugPrint("[AcademicProvider_Error] fetchData error: $e");
      debugPrint("[AcademicProvider_Error] StackTrace: $stack");
      if (!hasAnyCache) {
        _error = 'Offline Mode. Connect to internet for live data.';
      }
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> _silentRevalidate(
    String studentId, 
    String userId, 
    String className, 
    String? classId, 
    String? coachingClass, 
    String? coachingClassId, 
    String? wing, 
    String token,
  ) async {
    try {
      await _executeFetchAndCache(
        studentId: studentId,
        userId: userId,
        className: className,
        classId: classId,
        coachingClass: coachingClass,
        coachingClassId: coachingClassId,
        wing: wing,
        token: token,
      );
      notifyListeners();
    } catch (e) {
      debugPrint("[AcademicProvider_SilentError] silent Revalidation failed: $e");
    }
  }

  Future<List<dynamic>> fetchStudyMaterials(String classId, String type, String token) async {
    final keyMat = 'mat_${classId}_$type';
    final cached = AppCache.instance.get(keyMat);
    if (cached is List && !AppCache.instance.isStale(keyMat)) {
      return cached;
    }

    try {
      final fresh = await _apiService.getStudyMaterials(
        classId: classId,
        type: type.toLowerCase(),
        token: token
      );
      AppCache.instance.set(keyMat, fresh, ttl: const Duration(hours: 24));
      return fresh;
    } catch (e) {
      return cached is List ? cached : [];
    }
  }
}

