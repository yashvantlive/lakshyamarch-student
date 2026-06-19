import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/academic_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';
import 'schedule_screen.dart';
import 'notice_feed_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'tests_screen.dart';
import 'attendance_screen.dart';
import 'syllabus_screen.dart';
import 'homework_history_screen.dart';
import 'performance_screen.dart';
import 'online_test_screen.dart';
import 'support_screen.dart';
import 'doubt_room_screen.dart';
import 'study_hub/video_library_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  Future<void> _refreshAll(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final academic = context.read<AcademicProvider>();
    final student = auth.currentStudent;
    if (student == null || auth.token == null) return;
    await Future.wait([
      academic.fetchData(
        student.id,
        auth.user?['uid'] ?? auth.user?['_id'] ?? '',
        student.className,
        student.classId,
        student.coachingClass,
        student.coachingClassId,
        student.wing,
        auth.token!,
        forceRefresh: true,
      ),
      auth.fetchProfile(forceRefresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final studentName = auth.currentStudent?.name ?? 'Student';
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: _buildHubTab(context, studentName),
      ),
    );
  }

  Widget _buildHubTab(BuildContext context, String studentName) {
    final auth = context.watch<AuthProvider>();
    final academic = context.watch<AcademicProvider>();
    // Badges & Subtitles logic
    final pendingHW = academic.pendingHomeworksCount;
    final hwBadge = pendingHW > 0 ? '$pendingHW' : null;
    final hwSubtitle = pendingHW > 0 ? '$pendingHW Pending' : 'Completed';

    final upcomingT = academic.upcomingTestsCount;
    final testsBadge = upcomingT > 0 ? '$upcomingT' : null;
    final testsSubtitle = upcomingT > 0 ? '$upcomingT Upcoming' : 'No tests';

    final attStreak = academic.attendanceStreak;
    final attBadge = attStreak > 0 ? '$attStreak' : null; // Streak value as badge
    final attSubtitle = academic.attendance.isNotEmpty ? '${academic.attendanceRate.toStringAsFixed(1)}%' : null;

    final avgScore = academic.averageScore;
    final perfSubtitle = avgScore > 0 ? '${avgScore.toStringAsFixed(1)}% Avg' : null;

    return Column(
      children: [
        _buildCenteredAppBar(studentName, auth.activeWingMode),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _refreshAll(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.02,
                children: [
                  _buildHubTile(context, title: 'Schedule', icon: LucideIcons.calendar, color: Colors.blue, targetScreen: ScheduleScreen()),
                  _buildHubTile(context, title: 'Homework', icon: LucideIcons.clipboardList, color: Colors.orange, targetScreen: HomeworkHistoryScreen(), badgeText: hwBadge, subtitle: hwSubtitle),
                  _buildHubTile(context, title: 'Syllabus', icon: LucideIcons.bookOpen, color: Colors.teal, targetScreen: SyllabusScreen()),
                  _buildHubTile(context, title: 'Doubt Room', icon: LucideIcons.messageSquare, color: Colors.cyan, targetScreen: DoubtRoomScreen()),
                  _buildHubTile(context, title: 'Tests Hub', icon: LucideIcons.award, color: Colors.indigo, targetScreen: const TestsScreen(), badgeText: testsBadge, subtitle: testsSubtitle),
                  _buildHubTile(context, title: 'Notice Board', icon: LucideIcons.megaphone, color: Colors.purple, targetScreen: const NoticeFeedScreen()),
                  _buildHubTile(context, title: 'Notifications', icon: LucideIcons.bellRing, color: Colors.deepOrange, targetScreen: const NotificationsScreen()),
                  _buildHubTile(context, title: 'Attendance', icon: LucideIcons.trendingUp, color: Colors.green, targetScreen: const AttendanceScreen(), badgeText: attBadge, subtitle: attSubtitle),
                  _buildHubTile(context, title: 'Performance', icon: LucideIcons.barChart, color: Colors.pink, targetScreen: const PerformanceScreen(), subtitle: perfSubtitle),
                  _buildHubTile(context, title: 'Video Library', icon: LucideIcons.playCircle, color: Colors.red, targetScreen: const VideoLibraryScreen()),
                  _buildHubTile(context, title: 'Online Test', icon: LucideIcons.monitorPlay, color: Colors.indigo, targetScreen: const OnlineTestScreen()),
                  _buildHubTile(context, title: 'Suggestion & Complain', icon: LucideIcons.helpCircle, color: Colors.indigo, targetScreen: const SupportScreen()),
                  _buildHubTile(context, title: 'My Profile', icon: LucideIcons.user, color: AppTheme.primary, targetScreen: const ProfileScreen()),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCenteredAppBar(String name, String? wingMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      width: double.infinity,
      child: Column(
        children: [
          AnimatedBrandHeader(wingMode: wingMode),
          const SizedBox(height: 8),
          Text(
            'Welcome, $name',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textBase.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildHubTile(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget targetScreen,
    String? badgeText,
    String? subtitle,
  }) {
    return _FAANGTile(
      title: title,
      icon: icon,
      color: color,
      onTap: () => _navigateTo(context, targetScreen),
      badgeText: badgeText,
      subtitle: subtitle,
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.05);
        const end = Offset.zero;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeOutQuart));
        return FadeTransition(opacity: animation.drive(Tween(begin: 0.0, end: 1.0)), child: SlideTransition(position: animation.drive(tween), child: child));
      },
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }
}

class _FAANGTile extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badgeText;
  final String? subtitle;

  const _FAANGTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badgeText,
    this.subtitle,
  });

  @override
  State<_FAANGTile> createState() => _FAANGTileState();
}

class _FAANGTileState extends State<_FAANGTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
color: AppTheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.border.withOpacity(0.4), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTapDown: (_) => _controller.forward(),
            onTapUp: (_) => _controller.reverse(),
            onTapCancel: () => _controller.reverse(),
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onTap();
            },
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: widget.color.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.icon, color: widget.color, size: 24),
                      ),
                      if (widget.badgeText != null)
                        Positioned(
                          right: -10,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.danger,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              widget.badgeText!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textBase,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted.withOpacity(0.85),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
