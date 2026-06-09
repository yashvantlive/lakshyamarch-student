import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import '../widgets/premium_widgets.dart';

class TeacherReviewScreen extends StatefulWidget {
  const TeacherReviewScreen({super.key});

  @override
  State<TeacherReviewScreen> createState() => _TeacherReviewScreenState();
}

class _TeacherReviewScreenState extends State<TeacherReviewScreen> {
  int _rating = 0;
  String _feedback = "";
  bool _isLoading = false;
  bool _isFetching = true;
  String? _selectedTeacherId;
  String? _error;
  List<dynamic> _teachers = [];
  List<dynamic> _history = [];
  int _monthOffset = 0;

  String _getMonthString(DateTime d) {
    return DateFormat('yyyy-MMM').format(d).toUpperCase();
  }

  DateTime get _activeDate => DateTime(DateTime.now().year, DateTime.now().month + _monthOffset, 1);
  String get _activeMonthDisplay => _getMonthString(_activeDate);
  String get _activeMonth => DateFormat('yyyy-MM').format(_activeDate);

  bool get _canGoBack {
    final prevDate = DateTime(DateTime.now().year, DateTime.now().month + _monthOffset - 1, 1);
    final minDate = DateTime(2026, 3, 1); // March 2026
    return !prevDate.isBefore(minDate);
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final auth = context.read<AuthProvider>();
    final classId = auth.currentStudent?.classId;
    final coachingClassId = auth.currentStudent?.coachingClassId;
    final studentId = auth.currentStudent?.userId;

    if (classId == null && coachingClassId == null) {
      setState(() => _isFetching = false);
      return;
    }

    try {
      final api = ApiService();
      final token = auth.token ?? "";
      
      // Fetch Teachers for both wings
      List<dynamic> allTeachers = [];
      if (classId != null) {
        final res = await api.getRequest('/api/student/teachers?classId=$classId', token);
        if (res is List) allTeachers.addAll(res);
      }
      if (coachingClassId != null) {
        final res = await api.getRequest('/api/student/teachers?classId=$coachingClassId', token);
        if (res is List) allTeachers.addAll(res);
      }

      // Fetch History
      final historyRes = await api.getRequest('/api/student/reviews?studentId=$studentId', token);
      
      // De-duplicate teachers
      final uniqueTeachersMap = <String, dynamic>{};
      for (var t in allTeachers) {
        uniqueTeachersMap[t['id']] = t;
      }

      setState(() {
        _teachers = uniqueTeachersMap.values.toList();
        _history = historyRes is List ? historyRes : [];
      });
    } catch (e) {
      debugPrint("Error fetching review data: $e");
    } finally {
      setState(() => _isFetching = false);
    }
  }

  bool _isReviewed(String teacherId) {
    if (_history.isEmpty) return false;
    
    return _history.any((h) {
      final hTid = h['teacherId']?.toString().trim();
      final tId = teacherId.trim();
      final hMonth = h['reviewMonth']?.toString().trim();
      final aMonth = _activeMonthDisplay.trim();

      return hTid == tId && hMonth == aMonth;
    });
  }

  Future<void> _submitReview() async {
    if (_selectedTeacherId == null || _rating == 0) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final teacher = _teachers.firstWhere((t) => t['id'] == _selectedTeacherId);

      final api = ApiService();
      final response = await api.postRequest('/api/student/reviews', {
        "studentId": auth.currentStudent?.userId,
        "teacherId": _selectedTeacherId,
        "classId": auth.currentStudent?.classId ?? "unknown",
        "subject": teacher['subject'],
        "rating": _rating,
        "feedback": _feedback,
        "reviewPeriod": _activeMonth,
        "reviewMonth": _activeMonthDisplay,
      }, auth.token ?? "");

      if (response != null && !response.containsKey('error')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Review submitted successfully!"),
            backgroundColor: Colors.green,
          ));
          _fetchData(); // Refresh history
          setState(() {
            _selectedTeacherId = null;
            _rating = 0;
            _feedback = "";
          });
        }
      } else {
        setState(() => _error = response?['error'] ?? "Failed to submit review");
      }
    } catch (e) {
      setState(() => _error = "A network error occurred.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        toolbarHeight: 70,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedBrandHeader(wingMode: auth.activeWingMode),
            const SizedBox(height: 4),
            Text(
              'Monthly Evaluation',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textBase,
              ),
            ),
          ],
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: null,
        elevation: 0,
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textBase,
      ),
      body: _isFetching 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeekNavigator(),
            const SizedBox(height: 24),
            _buildSectionHeader("FACULTY LIST", LucideIcons.user),
            const SizedBox(height: 16),
            
            if (_teachers.isEmpty)
              _buildEmptyState("No assigned teachers found.")
            else
              ..._teachers.map((t) => _buildTeacherCard(t)).toList(),
            
            const SizedBox(height: 32),
            
            if (_selectedTeacherId != null) _buildEvaluationForm(),

            const SizedBox(height: 32),
            _buildSectionHeader("PAST HISTORY", LucideIcons.history),
            const SizedBox(height: 16),
            if (_history.isEmpty)
              _buildEmptyState("No past evaluations yet.")
            else
              ..._history.map((h) => _buildHistoryItem(h)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekNavigator() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _canGoBack
              ? IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.blue),
                  onPressed: () => setState(() {
                    _monthOffset--;
                    _selectedTeacherId = null;
                  }),
                )
              : const SizedBox(width: 48),
          Column(
            children: [
              Text("TARGET MONTH", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
              Text(_activeMonthDisplay, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blue, fontSize: 16)),
            ],
          ),
          _monthOffset < 0
            ? IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.blue),
                onPressed: () => setState(() {
                  _monthOffset++;
                  _selectedTeacherId = null;
                }),
              )
            : const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text(msg, textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
      ),
    );
  }

  Widget _buildTeacherCard(Map<String, dynamic> teacher) {
    final reviewed = _isReviewed(teacher['id']);
    final isSelected = _selectedTeacherId == teacher['id'];
    
    return GestureDetector(
      onTap: reviewed ? null : () => setState(() {
        _selectedTeacherId = teacher['id'];
        _rating = 0;
        _error = null;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: reviewed ? Colors.grey.withOpacity(0.05) : isSelected ? Colors.blue.withOpacity(0.05) : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: reviewed ? AppTheme.border : isSelected ? Colors.blue : AppTheme.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: reviewed ? Colors.green.withOpacity(0.1) : AppTheme.background,
              child: Icon(reviewed ? Icons.check_circle : LucideIcons.user, color: reviewed ? Colors.green : AppTheme.textMuted),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(teacher['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(teacher['subject'], style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            ),
            if (reviewed)
              const Badge(label: Text("DONE"), backgroundColor: Colors.green)
            else
              const Badge(label: Text("PENDING"), backgroundColor: Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluationForm() {
    final teacher = _teachers.firstWhere((t) => t['id'] == _selectedTeacherId);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("EVALUATING: ${teacher['name']}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) => IconButton(
              icon: Icon(
                index < _rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 40,
              ),
              onPressed: () => setState(() => _rating = index + 1),
            )),
          ),
          const SizedBox(height: 24),
          TextField(
            decoration: InputDecoration(
              hintText: "Detailed feedback for this month...",
              hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14),
              filled: true,
              fillColor: AppTheme.background.withOpacity(0.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(20),
            ),
            maxLines: 4,
            onChanged: (val) => _feedback = val,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading || _rating == 0 ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("FINALIZE & SUBMIT", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item['subject'] ?? "General", style: const TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: List.generate(5, (index) => Icon(
                  index < (item['rating'] ?? 0) ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 12,
                )),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item['reviewMonth'] ?? item['reviewPeriod'], style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
              Text(DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(item['createdAt'])), style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }
}
