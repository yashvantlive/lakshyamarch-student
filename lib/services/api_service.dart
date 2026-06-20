import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/student.dart';

class ApiService {
  // 🌐 Local Dev Backend (Physical Phone over Wi-Fi)
  static const String baseUrl = "http://192.168.29.25:3000";
  // static const String baseUrl = "https://erp-lakshyamarch.netlify.app"; // Production
  static const int _maxRetries = 3;
  static const Duration _timeoutDuration = Duration(seconds: 15);

  Map<String, String> _headers(String? token) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  void _logResponse(String endpoint, http.Response response) {
    debugPrint('API $endpoint: Status ${response.statusCode}, Length ${response.body.length}');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('API $endpoint Error: ${response.body}');
    }
  }

  Future<dynamic> _safeRequest(Future<http.Response> Function() requestFn, String endpoint) async {
    int attempts = 0;
    while (attempts < _maxRetries) {
      try {
        final response = await requestFn().timeout(_timeoutDuration);
        _logResponse(endpoint, response);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return jsonDecode(response.body);
        }
        if (response.statusCode >= 400 && response.statusCode < 500) {
          throw Exception('Request Failed: ${response.statusCode}');
        }
        if (response.statusCode >= 500) {
          throw Exception('Server Error: ${response.statusCode}');
        }
        throw Exception('Request Failed: ${response.statusCode}');
      } catch (e) {
        attempts++;
        if (attempts >= _maxRetries) rethrow;
        // Do not retry client side errors (400-499)
        if (e.toString().contains('Request Failed: 4')) {
          rethrow;
        }
        final backoff = Duration(seconds: 2 * attempts);
        debugPrint('API Retry $endpoint ($attempts/$_maxRetries) in ${backoff.inSeconds}s... Error: $e');
        await Future.delayed(backoff);
      }
    }
  }

  Future<dynamic> getRequest(String endpoint, String token) async {
    return _safeRequest(() async {
      return await http.get(Uri.parse('$baseUrl$endpoint'), headers: _headers(token));
    }, 'GET $endpoint');
  }

  Future<dynamic> postRequest(String endpoint, Map<String, dynamic> body, String token) async {
    return _safeRequest(() async {
      return await http.post(Uri.parse('$baseUrl$endpoint'), headers: _headers(token), body: jsonEncode(body));
    }, 'POST $endpoint');
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _safeRequest(() async {
      return await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: _headers(null),
        body: jsonEncode({'email': email, 'password': password}),
      );
    }, 'login');
    return Map<String, dynamic>.from(res as Map);
  }

  Future<List<Student>> getStudentProfiles(String userId, String token) async {
    final resp = await getRequest('/api/students?userId=$userId', token);
    if (resp is List) {
      return resp.map((s) => Student.fromJson(s)).toList();
    }
    throw Exception('Unexpected response format for student profiles');
  }

  Future<List<dynamic>> getAttendance(String studentId, String token) async {
    final resp = await getRequest('/api/attendance?studentId=$studentId', token);
    if (resp is List) return resp;
    throw Exception('Unexpected response format for attendance');
  }

  Future<dynamic> getFees(String studentId, String token) async {
    return await getRequest('/api/fees?studentId=$studentId', token);
  }

  Future<List<dynamic>> getOtherFees(String studentId, String token) async {
    final resp = await getRequest('/api/other-fees?studentId=$studentId', token);
    if (resp != null && resp['records'] != null) {
      return resp['records'] as List<dynamic>;
    }
    return [];
  }

  Future<List<dynamic>> getSchedulesRange(String startDate, String endDate, String token) async {
    final resp = await getRequest('/api/schedules?startDate=$startDate&endDate=$endDate', token);
    if (resp is List) return resp;
    throw Exception('Unexpected response format for schedules range');
  }

  Future<dynamic> getSchedule(String date, String token) async {
    final resp = await getRequest('/api/schedules?date=$date', token);
    if (resp is List) {
      return resp.isNotEmpty ? resp[0] : null;
    }
    throw Exception('Unexpected response format for schedule');
  }

  Future<List<dynamic>> getNotices(String className, String? classId, String? coachingClass, String? coachingClassId, String? wing, String token) async {
    final Map<String, dynamic> queryParams = {'class': className};
    if (classId != null) queryParams['classId'] = classId;
    if (coachingClass != null) queryParams['coachingClass'] = coachingClass;
    if (coachingClassId != null) queryParams['coachingClassId'] = coachingClassId;
    if (wing != null) queryParams['wing'] = wing;

    final uri = Uri.parse('/api/notices').replace(queryParameters: queryParams);
    final resp = await getRequest(uri.toString(), token);
    if (resp is List) return resp;
    throw Exception('Unexpected response format for notices');
  }

  Future<List<dynamic>> getTestsWithResults(String studentId, String className, String? coachingClass, String? wing, String token) async {
    final Map<String, dynamic> queryParams = {'studentId': studentId, 'class': className};
    if (coachingClass != null) queryParams['coachingClass'] = coachingClass;
    if (wing != null) queryParams['wing'] = wing;

    final uri = Uri.parse('/api/tests').replace(queryParameters: queryParams);
    final resp = await getRequest(uri.toString(), token);
    if (resp is List) return resp;
    throw Exception('Unexpected response format for tests');
  }

  Future<List<dynamic>> getSyllabus(String className, String? wing, String token) async {
    final Map<String, dynamic> queryParams = {'class': className};
    if (wing != null) queryParams['wing'] = wing;

    final uri = Uri.parse('/api/syllabus').replace(queryParameters: queryParams);
    final resp = await getRequest(uri.toString(), token);
    if (resp is List) return resp;
    throw Exception('Unexpected response format for syllabus');
  }

  Future<List<dynamic>> getHomeworkHistory({String? startDate, String? endDate, required String token}) async {
    final url = '/api/homework?${startDate != null ? 'startDate=$startDate&' : ''}${endDate != null ? 'endDate=$endDate&' : ''}limit=200';
    final resp = await getRequest(url, token);
    if (resp is List) return resp;
    throw Exception('Unexpected response format for homework history');
  }

  Future<List<dynamic>> getStudentSubmissions(String studentId, String token) async {
    final resp = await getRequest('/api/homework/submissions?studentId=$studentId', token);
    if (resp is List) return resp;
    throw Exception('Unexpected response format for submissions');
  }

  Future<void> registerPushToken(String token, String? fcmToken) async {
    if (fcmToken == null) return;
    try {
      await postRequest('/api/push/subscribe', {'fcmToken': fcmToken}, token);
    } catch (e) {
      debugPrint('Failed to register push token: $e');
    }
  }

  Future<List<dynamic>> getClasses(String token) async {
    final resp = await getRequest('/api/classes', token);
    if (resp is List) return resp;
    throw Exception('Unexpected response format for classes');
  }

  Future<List<dynamic>> getStudyMaterials({String? classId, String? subjectId, String? type, required String token}) async {
    final Map<String, String> queryParams = {};
    if (classId != null) queryParams['classId'] = classId;
    if (subjectId != null) queryParams['subjectId'] = subjectId;
    if (type != null) queryParams['type'] = type;

    final uri = Uri.parse('/api/study-material').replace(queryParameters: queryParams);
    final resp = await getRequest(uri.toString(), token);
    if (resp is List) return resp;
    throw Exception('Unexpected response format for study materials');
  }

  Future<List<dynamic>> getHolidays(String token) async {
    final resp = await getRequest('/api/holidays', token);
    if (resp is List) return resp;
    throw Exception('Unexpected response format for holidays');
  }

  Future<dynamic> getLeaderboard(String classId, String token) async {
    return await getRequest('/api/students/leaderboard?classId=$classId', token);
  }

  Future<List<dynamic>> getTestResults(String testId, String token) async {
    final resp = await getRequest('/api/tests/results?testId=$testId', token);
    if (resp is List) return resp;
    throw Exception('Unexpected response format for test results');
  }

  Future<List<dynamic>> getDoubts(String studentId, String token) async {
    final resp = await getRequest('/api/doubts?studentId=$studentId', token);
    if (resp is List) return resp;
    throw Exception('Unexpected response format for doubts');
  }

  Future<dynamic> createDoubt(Map<String, dynamic> body, String token) async {
    return await postRequest('/api/doubts', body, token);
  }

  Future<dynamic> replyToDoubt(String doubtId, Map<String, dynamic> body, String token) async {
    return await postRequest('/api/doubts/$doubtId/reply', body, token);
  }

  Future<String?> uploadFile(String filePath, String fileName, String token) async {
    try {
      final uri = Uri.parse('$baseUrl/api/upload');
      final request = http.MultipartRequest('POST', uri);
      
      request.headers.addAll(_headers(token));
      request.files.add(
        await http.MultipartFile.fromPath('file', filePath, filename: fileName),
      );
      
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      
      _logResponse('UPLOAD $fileName', response);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        return decoded['url'] as String?;
      }
      throw Exception('Upload failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('File upload error: $e');
      rethrow;
    }
  }

  Future<dynamic> submitHomework({
    required String homeworkId,
    required String studentId,
    required String studentName,
    String? driveLink,
    required String token,
  }) async {
    final body = {
      'homeworkId': homeworkId,
      'studentId': studentId,
      'studentName': studentName,
      'driveLink': driveLink,
      'status': 'submitted',
      'submittedAt': DateTime.now().toIso8601String(),
    };
    return await postRequest('/api/homework/submissions', body, token);
  }

  Future<Map<String, dynamic>> getStudentNotifications(String token) async {
    final headers = _headers(token);
    final res = await _safeRequest(() async {
      return await http.get(Uri.parse('$baseUrl/api/student/notifications'), headers: headers);
    }, 'get_student_notifications');
    return Map<String, dynamic>.from(res as Map);
  }

  Future<List<dynamic>> getVideos(String className, String? wing, String token) async {
    final Map<String, dynamic> queryParams = {'class': className};
    if (wing != null) queryParams['wing'] = wing;

    final uri = Uri.parse('/api/videos').replace(queryParameters: queryParams);
    final resp = await getRequest(uri.toString(), token);
    if (resp is List) return resp;
    throw Exception('Unexpected response format for videos');
  }

  Future<dynamic> submitPracticeTestResult(Map<String, dynamic> body, String token) async {
    return await postRequest('/api/students/practice-tests', body, token);
  }

  Future<Map<String, dynamic>> getPracticeTestAttempts(String studentId, String token) async {
    final resp = await getRequest('/api/students/practice-tests?studentId=$studentId', token);
    return Map<String, dynamic>.from(resp as Map);
  }
}
