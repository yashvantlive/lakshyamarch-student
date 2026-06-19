import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/schedule_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loadInitialData();
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scheduleProvider = context.read<ScheduleProvider>();
      final auth = context.read<AuthProvider>();
      scheduleProvider.fetchSchedule(
        auth.token!,
        auth.activeWingMode == 'school' 
          ? (auth.currentStudent!.classId ?? '') 
          : (auth.currentStudent!.coachingClassId ?? '')
      );
      _staggerController.forward();
    });
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();
    final auth = context.watch<AuthProvider>();
    final wingColor = AppTheme.getWingColor(auth.activeWingMode);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildCenteredAppBar(auth.activeWingMode),
            _buildDateHeader(context, scheduleProvider, wingColor, auth),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await scheduleProvider.fetchSchedule(
                    auth.token!,
                    auth.activeWingMode == 'school' 
                      ? (auth.currentStudent!.classId ?? '') 
                      : (auth.currentStudent!.coachingClassId ?? '')
                  );
                  _staggerController.reset();
                  _staggerController.forward();
                },
                child: _buildScheduleBody(scheduleProvider, auth),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenteredAppBar(String? wingMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      width: double.infinity,
      child: Column(
        children: [
          AnimatedBrandHeader(wingMode: wingMode),
          const SizedBox(height: 8),
          Text(
            'Daily Schedule',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textBase,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context, ScheduleProvider provider, Color wingColor, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE').format(provider.selectedDate).toUpperCase(),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: wingColor, letterSpacing: 1.5),
              ),
              Text(
                DateFormat('d MMMM, yyyy').format(provider.selectedDate),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textBase),
              ),
            ],
          ),
          _buildCalendarButton(context, provider, auth, wingColor),
        ],
      ),
    );
  }

  Widget _buildCalendarButton(BuildContext context, ScheduleProvider provider, AuthProvider auth, Color wingColor) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.mediumImpact();
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: provider.selectedDate,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: AppTheme.isDarkMode 
                  ? ColorScheme.dark(
                      primary: wingColor, 
                      onPrimary: Colors.white, 
                      onSurface: AppTheme.textBase,
                      surface: AppTheme.surface,
                    )
                  : ColorScheme.light(
                      primary: wingColor, 
                      onPrimary: Colors.white, 
                      onSurface: AppTheme.textBase,
                      surface: AppTheme.surface,
                    ),
              dialogBackgroundColor: AppTheme.surface,
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          provider.selectDate(
            picked, 
            auth.token!, 
            auth.activeWingMode == 'school' 
              ? (auth.currentStudent!.classId ?? '') 
              : (auth.currentStudent!.coachingClassId ?? '')
          );
          _staggerController.reset();
          _staggerController.forward();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border.withOpacity(0.5)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Icon(LucideIcons.calendar, color: wingColor, size: 22),
      ),
    );
  }

  Widget _buildScheduleBody(ScheduleProvider provider, AuthProvider auth) {
    if (provider.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: 3,
        itemBuilder: (context, index) => const _ScheduleShimmer(),
      );
    }

    if (provider.currentSchedule == null || provider.currentSchedule!.slots.isEmpty) {
      return const EmptyStateWidget(
        title: 'No classes scheduled',
        message: 'Take a break! There are no classes for this date.',
        icon: LucideIcons.calendarX,
      );
    }

    final allSlots = provider.currentSchedule!.slots;
    final schoolSlots = allSlots.where((s) => s.wing?.toLowerCase() == 'school').toList();
    final coachingSlots = allSlots.where((s) => s.wing?.toLowerCase() == 'coaching').toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      children: [
        // 1. School Section
        if (auth.currentStudent!.wing?.toLowerCase() == 'school') ...[
          _buildDepartmentHeader('SCHOOL ACADEMIC', Colors.green),
          const SizedBox(height: 16),
          if (schoolSlots.isEmpty)
            _buildMiniStatusCard("Academic Recess")
          else
            ...schoolSlots.asMap().entries.map((entry) => 
              _buildStaggeredScheduleItem(entry.key, entry.value, entry.key == schoolSlots.length - 1)
            ),
          const SizedBox(height: 32),
        ],

        // 2. Coaching Section
        _buildDepartmentHeader('COACHING / INTEGRATED', Colors.orange),
        const SizedBox(height: 16),
        if (coachingSlots.isEmpty)
          _buildMiniStatusCard("Session Break")
        else
          ...coachingSlots.asMap().entries.map((entry) => 
            _buildStaggeredScheduleItem(entry.key + 10, entry.value, entry.key == coachingSlots.length - 1)
          ),
          
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildDepartmentHeader(String title, Color color) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildMiniStatusCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.info, size: 14, color: AppTheme.textMuted),
          const SizedBox(width: 12),
          Text(message, style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStaggeredScheduleItem(int index, dynamic slot, bool isLast) {
    final animation = CurvedAnimation(
      parent: _staggerController,
      curve: Interval((index / 10).clamp(0, 0.5), 1.0, curve: Curves.easeOutQuart),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, 30 * (1 - animation.value)),
        child: Opacity(
          opacity: animation.value,
          child: _ScheduleItem(
            startTime: slot.startTime,
            endTime: slot.endTime,
            subject: slot.subject,
            teacher: slot.teacherName,
            isLast: isLast,
            slotId: slot.id,
            isNow: _isCurrentSlot(slot.startTime, slot.endTime),
            wing: slot.wing,
          ),
        ),
      ),
    );
  }

  bool _isCurrentSlot(String startStr, String endStr) {
    final now = DateTime.now();
    final start = _parseTime(startStr);
    final end = _parseTime(endStr);
    return now.isAfter(start) && now.isBefore(end);
  }

  DateTime _parseTime(String timeStr) {
    final now = DateTime.now();
    try {
      return DateFormat.jm().parse(timeStr.trim());
    } catch (_) {
      try {
        final parts = timeStr.trim().split(':');
        if (parts.length == 2) {
          return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
        }
      } catch (_) {}
    }
    return now;
  }
}

class _ScheduleItem extends StatelessWidget {
  final String startTime;
  final String endTime;
  final String subject;
  final String teacher;
  final bool isLast;
  final bool isNow;
  final String? wing;
  final String slotId;

  const _ScheduleItem({
    required this.startTime, required this.endTime, required this.subject, 
    required this.teacher, required this.isLast, required this.slotId, 
    this.isNow = false, this.wing,
  });

  @override
  Widget build(BuildContext context) {
    final wingColor = AppTheme.getWingColor(wing);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              _buildTimelineNode(wingColor),
              if (!isLast) Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: AppTheme.border.withOpacity(0.3))),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$startTime - $endTime', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isNow ? wingColor : AppTheme.textMuted, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  _buildContentCard(context, wingColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineNode(Color color) {
    return Container(
      width: 14, height: 14,
      decoration: BoxDecoration(
        color: isNow ? color : AppTheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
        boxShadow: isNow ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)] : null,
      ),
    );
  }

  Widget _buildContentCard(BuildContext context, Color wingColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isNow ? wingColor.withOpacity(0.3) : AppTheme.border.withOpacity(0.4), width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(subject, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textBase))),
              if (isNow) _buildLiveBadge(wingColor),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(LucideIcons.user, size: 12, color: wingColor),
              const SizedBox(width: 8),
              Text(teacher, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
            ],
          ),
          // Homework Panel
          Consumer<ScheduleProvider>(
            builder: (context, provider, _) {
              final hws = provider.homeworks.where((h) => h.slotId == slotId).toList();
              if (hws.isEmpty) return const SizedBox();
              final hw = hws.first;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: const Text('HOMEWORK', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.orange))),
                      const Spacer(),
                      Icon(hw.status == 'submitted' ? LucideIcons.checkCircle2 : LucideIcons.circle, size: 12, color: hw.status == 'submitted' ? Colors.green : Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(hw.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLiveBadge(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text('LIVE NOW', style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _ScheduleShimmer extends StatelessWidget {
  const _ScheduleShimmer();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          const ShimmerLoading(width: 14, height: 14, borderRadius: 7),
          const SizedBox(width: 20),
          Expanded(child: ShimmerLoading(width: double.infinity, height: 100, borderRadius: 20)),
        ],
      ),
    );
  }
}
