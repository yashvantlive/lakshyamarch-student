import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dashboard_screen.dart';
import 'tests_screen.dart';
import 'schedule_screen.dart';
import 'profile_screen.dart';
import 'notice_feed_screen.dart';
import 'study_hub/class_selection_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/academic_provider.dart';
import '../providers/schedule_provider.dart';
import '../providers/notice_provider.dart';
import '../theme/app_theme.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;
  String? _lastStudentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
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
      );
      schedule.fetchSchedule(
        auth.token!,
        auth.activeWingMode == 'school' 
          ? (auth.currentStudent!.classId ?? '') 
          : (auth.currentStudent!.coachingClassId ?? '')
      );
      notice.fetchNotices(
        auth.currentStudent!.className, 
        auth.currentStudent!.classId,
        auth.currentStudent!.coachingClass,
        auth.currentStudent!.coachingClassId,
        auth.currentStudent!.wing,
        auth.token!,
      );
    }
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0: return const DashboardScreen(); // The new Isolated Hub
      case 1: return const ClassSelectionScreen(type: 'NCERT');
      case 2: return const ClassSelectionScreen(type: 'DPP');
      case 3: return const ClassSelectionScreen(type: 'Notes');
      default: return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('MainNavigator: Building...');
    final auth = context.watch<AuthProvider>();
    final activeWing = auth.activeWingMode;
    final wingColor = AppTheme.getWingColor(activeWing);

    // Auto-refresh data if student ID changed (important for siblings)
    if (auth.currentStudent?.id != _lastStudentId) {
      _lastStudentId = auth.currentStudent?.id;
      if (_lastStudentId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
      }
    }

    return Scaffold(
      body: KeyedSubtree(
        key: ValueKey<int>(_currentIndex),
        child: _buildScreen(_currentIndex),
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
