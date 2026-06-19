import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dashboard_screen.dart';
import 'study_hub/subject_selection_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/academic_provider.dart';
import '../providers/schedule_provider.dart';
import '../providers/notice_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/fee_block_screen.dart';
import 'fees_screen.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;
  String? _lastStudentId;
  Timer? _autoRefreshTimer;
  bool _hasShownFeePopup = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    _startAutoRefreshTimer();
  }

  void _startAutoRefreshTimer() {
    // Silently auto-refresh essential data every 1 hour
    _autoRefreshTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      if (mounted) {
        _loadData(forceRefresh: true);
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _loadData({bool forceRefresh = false}) {
    final auth = context.read<AuthProvider>();
    final academic = context.read<AcademicProvider>();
    final schedule = context.read<ScheduleProvider>();
    final notice = context.read<NoticeProvider>();

    if (auth.currentStudent != null && auth.token != null) {
      academic.fetchData(
        auth.currentStudent!.id,
        auth.user!['uid'] ?? auth.user!['_id'] ?? '',
        auth.currentStudent!.className,
        auth.currentStudent!.classId,
        auth.currentStudent!.coachingClass,
        auth.currentStudent!.coachingClassId,
        auth.currentStudent!.wing,
        auth.token!,
        forceRefresh: forceRefresh,
      );
      schedule.fetchSchedule(
        auth.token!,
        auth.activeWingMode == 'school' 
          ? (auth.currentStudent!.classId ?? '') 
          : (auth.currentStudent!.coachingClassId ?? ''),
        forceRefresh: forceRefresh,
      );
      notice.fetchNotices(
        auth.currentStudent!.className, 
        auth.currentStudent!.classId,
        auth.currentStudent!.coachingClass,
        auth.currentStudent!.coachingClassId,
        auth.currentStudent!.wing,
        auth.token!,
        forceRefresh: forceRefresh,
      );
    }
  }

  bool _isDefaulter(AcademicProvider academic) {
    if (DateTime.now().day <= 5) return false;
    final totalDue = academic.fees.where((f) => f.status.toLowerCase() != 'paid').fold(0.0, (sum, item) => sum + item.amount);
    return totalDue > 0;
  }

  void _showFeeReminderPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.alertCircle, color: Colors.orange),
            SizedBox(width: 8),
            Text('Fee Reminder', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: Text(
          'Your fee payment is due. Please inform your parents to complete the payment as soon as possible.',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textBase),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FeesScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('View Fees', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildScreen(int index, AuthProvider auth, AcademicProvider academic) {
    if (index == 0) return const DashboardScreen(); // The new Isolated Hub
    
    if (index > 0 && _isDefaulter(academic)) {
      return const FeeBlockScreen();
    }
    
    final student = auth.currentStudent;
    if (student == null) {
      return const Scaffold(body: Center(child: Text('Student profile not found')));
    }

    final isCoaching = auth.activeWingMode == 'coaching';
    final cId = isCoaching ? (student.coachingClassId?.isNotEmpty == true ? student.coachingClassId : student.classId) : student.classId;
    final cName = isCoaching ? (student.coachingClass?.isNotEmpty == true ? student.coachingClass : student.className) : student.className;
    
    if (cId == null || cId.isEmpty) {
      return const Scaffold(body: Center(child: Text('No class assigned to you for this wing.')));
    }

    switch (index) {
      case 1: return SubjectSelectionScreen(classId: cId, className: cName ?? 'Your Class', materialType: 'NCERT');
      case 2: return SubjectSelectionScreen(classId: cId, className: cName ?? 'Your Class', materialType: 'DPP');
      case 3: return SubjectSelectionScreen(classId: cId, className: cName ?? 'Your Class', materialType: 'Notes');
      default: return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('MainNavigator: Building...');
    final auth = context.watch<AuthProvider>();
    final academic = context.watch<AcademicProvider>();
    final activeWing = auth.activeWingMode;
    final wingColor = AppTheme.getWingColor(activeWing);

    if (!_hasShownFeePopup && !academic.isLoading && academic.fees.isNotEmpty && _isDefaulter(academic)) {
      _hasShownFeePopup = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showFeeReminderPopup(context);
      });
    }

    // Auto-refresh data if student ID changed (important for siblings)
    if (auth.currentStudent?.id != _lastStudentId) {
      _lastStudentId = auth.currentStudent?.id;
      if (_lastStudentId != null) {
        _hasShownFeePopup = false; // Reset popup flag for new student
        WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
      }
    }

    return Scaffold(
      body: KeyedSubtree(
        key: ValueKey<int>(_currentIndex),
        child: _buildScreen(_currentIndex, auth, academic),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border.withOpacity(0.5))),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          backgroundColor: AppTheme.surface,
          indicatorColor: wingColor.withOpacity(0.1),
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: const Icon(LucideIcons.layoutGrid, size: 20),
              selectedIcon: Icon(LucideIcons.layoutGrid, color: wingColor, size: 20),
              label: 'Hub',
            ),
            NavigationDestination(
              icon: const Icon(LucideIcons.book, size: 20),
              selectedIcon: Icon(LucideIcons.book, color: wingColor, size: 20),
              label: 'NCERT',
            ),
            NavigationDestination(
              icon: const Icon(LucideIcons.fileText, size: 20),
              selectedIcon: Icon(LucideIcons.fileText, color: wingColor, size: 20),
              label: 'DPP',
            ),
            NavigationDestination(
              icon: const Icon(LucideIcons.penTool, size: 20),
              selectedIcon: Icon(LucideIcons.penTool, color: wingColor, size: 20),
              label: 'Notes',
            ),
          ],
        ),
      ),
    );
  }
}
