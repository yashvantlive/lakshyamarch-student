import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/academic_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';
import '../widgets/shimmer_skeleton.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final academic = context.watch<AcademicProvider>();
    final attendance = academic.attendance;
    final isLoading = academic.isLoading && attendance.isEmpty;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildCenteredAppBar(auth.activeWingMode),
            Expanded(
              child: isLoading
                ? SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Shimmer Stats
                        Row(
                          children: List.generate(3, (index) => Expanded(
                            child: Container(
                              margin: EdgeInsets.only(right: index == 2 ? 0 : 12),
                              height: 90,
                              decoration: BoxDecoration(
color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: AppTheme.border.withOpacity(0.4), width: 1.2),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ShimmerBox(width: 24, height: 24, radius: 12),
                                  SizedBox(height: 8),
                                  ShimmerBox(width: 30, height: 20),
                                  SizedBox(height: 4),
                                  ShimmerBox(width: 40, height: 10),
                                ],
                              ),
                            ),
                          )),
                        ),
                        const SizedBox(height: 32),
                        // Shimmer Calendar Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: AppTheme.border.withOpacity(0.4), width: 1.2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  ShimmerBox(width: 120, height: 24),
                                  ShimmerBox(width: 24, height: 24, radius: 12),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: List.generate(7, (index) => const Expanded(
                                  child: Center(child: ShimmerBox(width: 20, height: 10)),
                                )),
                              ),
                              const SizedBox(height: 24),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                ),
                                itemCount: 28,
                                itemBuilder: (context, index) => const ShimmerBox(radius: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildStaggered(0, _buildStatsRow(attendance)),
                        const SizedBox(height: 32),
                        _buildStaggered(1, _buildCalendarCard(attendance, academic.holidays)),
                        const SizedBox(height: 40),
                      ],
                    ),
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
            'Attendance Report',
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

  Widget _buildStaggered(int index, Widget child) {
    final animation = CurvedAnimation(
      parent: _staggerController,
      curve: Interval((index / 10).clamp(0, 0.5), 1.0, curve: Curves.easeOutQuart),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Transform.translate(
        offset: Offset(0, 30 * (1 - animation.value)),
        child: Opacity(opacity: animation.value, child: child),
      ),
    );
  }

  Widget _buildStatsRow(List<dynamic> attendance) {
    final pCount = attendance.where((a) => a['status'] == 'present').length;
    final aCount = attendance.where((a) => a['status'] == 'absent').length;
    final lCount = attendance.where((a) => a['status'] == 'leave').length;

    return Row(
      children: [
        Expanded(child: _FAANGStatTile(label: 'Present', value: pCount.toString(), color: AppTheme.success, icon: LucideIcons.checkCircle2)),
        const SizedBox(width: 12),
        Expanded(child: _FAANGStatTile(label: 'Absent', value: aCount.toString(), color: AppTheme.danger, icon: LucideIcons.xCircle)),
        const SizedBox(width: 12),
        Expanded(child: _FAANGStatTile(label: 'Leaves', value: lCount.toString(), color: Colors.orange, icon: LucideIcons.clock)),
      ],
    );
  }

  Widget _buildCalendarCard(List<dynamic> attendance, List<dynamic> holidays) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
color: AppTheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.border.withOpacity(0.4), width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('MMMM yyyy').format(DateTime.now()), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppTheme.textBase)),
              Icon(LucideIcons.calendar, color: AppTheme.primary, size: 20),
            ],
          ),
          const SizedBox(height: 24),
          _buildDayHeaders(),
          const SizedBox(height: 16),
          _buildCalendarGrid(attendance, holidays),
          const SizedBox(height: 24),
          Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 20),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildDayHeaders() {
    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return Row(
      children: days.map((d) => Expanded(
        child: Center(
          child: Text(
            d,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppTheme.textMuted.withOpacity(0.8),
              letterSpacing: 0.5,
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildCalendarGrid(List<dynamic> attendance, List<dynamic> holidays) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    
    // weekday: 1 (Mon) to 7 (Sun)
    // We want Monday to be 0
    final offset = (firstDayOfMonth.weekday - 1);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: daysInMonth + offset,
      itemBuilder: (context, index) {
        if (index < offset) {
          return const SizedBox.shrink();
        }
        
        final day = index - offset + 1;
        final status = _getStatusForDay(day, attendance, holidays);
        final color = _getColorForStatus(status);
        
        return InkWell(
          onTap: () => _showDayDetails(day, status, attendance, holidays),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: status == null ? AppTheme.background : color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: status == null ? Colors.transparent : color.withOpacity(0.3), width: 1.2),
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  color: status == null ? AppTheme.textBase.withOpacity(0.5) : color,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDayDetails(int day, String? status, List<dynamic> attendance, List<dynamic> holidays) {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, day);
    final dateStr = DateFormat('EEEE, d MMMM').format(date);
    
    String? holidayTitle;
    if (status == 'holiday') {
      final targetStr = DateFormat('yyyy-MM-dd').format(date);
      for (var h in holidays) {
        if (h['date'] == targetStr) {
          holidayTitle = h['title'];
          break;
        }
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateStr.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 1)),
                    SizedBox(height: 4),
                    Text('Day Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.textBase)),
                  ],
                ),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(16)),
                  child: Icon(LucideIcons.calendarDays, color: AppTheme.primary.withOpacity(0.5), size: 24),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildDetailRow(
              icon: LucideIcons.info,
              label: 'Status',
              value: status?.replaceAll('_', ' ').toUpperCase() ?? 'NO RECORD',
              color: _getColorForStatus(status),
            ),
            if (holidayTitle != null) ...[
              const SizedBox(height: 16),
              _buildDetailRow(
                icon: LucideIcons.partyPopper,
                label: 'Holiday',
                value: holidayTitle,
                color: Colors.purple,
              ),
            ],
            if (status == 'weekly_off') ...[
              const SizedBox(height: 16),
              _buildDetailRow(
                icon: LucideIcons.coffee,
                label: 'Reason',
                value: 'Standard Weekly Holiday',
                color: Colors.blueGrey,
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  static Widget _buildDetailRow({required IconData icon, required String label, required String value, required Color color}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.textMuted.withOpacity(0.6), letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.textBase)),
          ],
        ),
      ],
    );
  }


  Widget _buildLegend() {
    return const Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _LegendItem(color: AppTheme.success, label: 'Present'),
        _LegendItem(color: AppTheme.danger, label: 'Absent'),
        _LegendItem(color: Colors.orange, label: 'Leave'),
        _LegendItem(color: Colors.purple, label: 'Holiday'),
        _LegendItem(color: Colors.blueGrey, label: 'Weekly Off'),
      ],
    );
  }

  String? _getStatusForDay(int day, List<dynamic> attendance, List<dynamic> holidays) {
    // 1. Check Attendance Records
    for (var a in attendance) {
      final date = DateTime.parse(a['date']);
      if (date.day == day) return a['status'];
    }
    
    // 2. Check Holidays (Matching YYYY-MM-DD)
    final now = DateTime.now();
    final dateStr = "${now.year}-${String.fromCharCodes([now.month < 10 ? 48 : 0]).replaceAll('\x00', '')}${now.month}-${day < 10 ? '0' : ''}$day";
    // Safer check:
    final targetDate = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, day));
    
    for (var h in holidays) {
      if (h['date'] == targetDate) return 'holiday';
    }

    // 3. Check if it's Monday (Weekly Off)
    if (DateTime(now.year, now.month, day).weekday == DateTime.monday) return 'weekly_off';
    
    return null;
  }

  Color _getColorForStatus(String? status) {
    switch (status) {
      case 'present': return AppTheme.success;
      case 'absent': return AppTheme.danger;
      case 'leave': return Colors.orange;
      case 'holiday': return Colors.purple;
      case 'weekly_off': return Colors.blueGrey;
      default: return AppTheme.background;
    }
  }
}

class _FAANGStatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _FAANGStatTile({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2), width: 1.2),
        boxShadow: [BoxShadow(color: color.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
          Text(label.toUpperCase(), style: TextStyle(color: color.withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textMuted)),
      ],
    );
  }
}
