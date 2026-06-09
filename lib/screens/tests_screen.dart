import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/academic_provider.dart';
import '../providers/auth_provider.dart';
import '../models/test.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/past_test_results_sheet.dart';

class TestsScreen extends StatefulWidget {
  final String? initialWingFilter;
  const TestsScreen({super.key, this.initialWingFilter});

  @override
  State<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen> with SingleTickerProviderStateMixin {
  int _upcomingLimit = 5;
  int _pastLimit = 5;
  late AnimationController _staggerController;
  String? _selectedWingFilter;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _loadInitialData();
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh(context);
      _staggerController.forward();
    });
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _refresh(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final academic = context.read<AcademicProvider>();
    if (auth.currentStudent != null) {
      await academic.fetchData(
        auth.currentStudent!.id,
        auth.user!['uid'] ?? auth.user!['_id'] ?? '',
        auth.currentStudent!.className,
        auth.currentStudent!.classId,
        auth.currentStudent!.coachingClass,
        auth.currentStudent!.coachingClassId,
        auth.currentStudent!.wing,
        auth.token ?? '',
        forceRefresh: true,
      );
      _staggerController.reset();
      _staggerController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    final auth = context.watch<AuthProvider>();
    
    if (_selectedWingFilter == null) {
      _selectedWingFilter = widget.initialWingFilter ?? auth.activeWingMode ?? 'school';
    }

    final wingColor = AppTheme.getWingColor(_selectedWingFilter);
    final wingGradient = AppTheme.getWingGradient(_selectedWingFilter);

    final filteredTests = academic.tests.where((t) {
      return t.wing == _selectedWingFilter;
    }).toList();

    final upcomingTests = filteredTests.where((t) => t.status == "upcoming").toList();
    upcomingTests.sort((a, b) => a.date.compareTo(b.date));

    final pastTests = filteredTests.where((t) => t.status == "published").toList();
    pastTests.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildCenteredAppBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _refresh(context),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildStaggered(0, _buildPerformanceCard(filteredTests, wingColor, wingGradient)),
                          const SizedBox(height: 24),
                          _buildStaggered(1, _buildSubjectChart(filteredTests, wingColor)),
                          const SizedBox(height: 32),
                          _buildStaggered(2, _SectionHeader(title: 'Upcoming Tests', count: upcomingTests.length, icon: LucideIcons.calendarDays)),
                          const SizedBox(height: 16),
                          ..._buildUpcomingList(academic, upcomingTests),
                          const SizedBox(height: 32),
                          _buildStaggered(5, _SectionHeader(title: 'Past Results', count: pastTests.length, icon: LucideIcons.history)),
                          const SizedBox(height: 16),
                          ..._buildPastList(academic, pastTests),
                          const SizedBox(height: 40),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenteredAppBar() {
    return Container(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      width: double.infinity,
      child: Column(
        children: [
          AnimatedBrandHeader(wingMode: _selectedWingFilter),
          const SizedBox(height: 8),
          Text(
            'Tests & Reports',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textBase,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildWingTab('school', 'School', LucideIcons.school),
                _buildWingTab('coaching', 'Coaching', LucideIcons.bookOpen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWingTab(String wing, String label, IconData icon) {
    final isSelected = _selectedWingFilter == wing;
    final color = AppTheme.getWingColor(wing);
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _selectedWingFilter = wing;
            _staggerController.reset();
            _staggerController.forward();
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? color : AppTheme.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSelected ? color : AppTheme.textMuted,
              ),
            ),
          ],
        ),
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

  List<Widget> _buildUpcomingList(AcademicProvider academic, List<dynamic> tests) {
    if (academic.isLoading && tests.isEmpty) return [const _ShimmerCard()];
    if (tests.isEmpty) return [const EmptyStateWidget(title: 'No upcoming tests', message: 'You are all caught up!', icon: LucideIcons.calendarCheck)];
    
    final displayed = tests.take(_upcomingLimit).toList();
    return displayed.asMap().entries.map((e) => _buildStaggered(3 + e.key, Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _UpcomingTestCard(test: e.value as Test),
    ))).toList();
  }

  List<Widget> _buildPastList(AcademicProvider academic, List<dynamic> tests) {
    if (academic.isLoading && tests.isEmpty) return List.generate(3, (_) => const _ShimmerCard());
    if (tests.isEmpty) return [const EmptyStateWidget(title: 'No test history', message: 'Complete tests to see results.', icon: LucideIcons.clipboardSignature)];
    
    final displayed = tests.take(_pastLimit).toList();
    return displayed.asMap().entries.map((e) {
      final test = e.value;
      final isAbsent = test.result == null;
      return _buildStaggered(6 + e.key, Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _PerformanceCard(
          title: test.title,
          date: test.date,
          score: isAbsent ? 'ABSENT' : '${test.result!.score}/${test.maxMarks}',
          rank: isAbsent ? 'N/A' : '#${test.result!.rank}',
          percent: isAbsent ? 0.0 : (test.result!.score / (test.maxMarks > 0 ? test.maxMarks : 1)),
          isAbsent: isAbsent,
          test: test,
        ),
      ));
    }).toList();
  }

  Widget _buildPerformanceCard(List<Test> filteredTests, Color wingColor, LinearGradient wingGradient) {
    final pastTests = filteredTests.where((t) => t.status == "published" && t.result != null).toList();
    final double totalScores = pastTests.fold(0.0, (sum, t) => sum + ((t.result!.score / (t.maxMarks > 0 ? t.maxMarks : 1)) * 100));
    final double averageScore = pastTests.isEmpty ? 0.0 : (totalScores / pastTests.length);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: wingGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: wingColor.withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 12))],
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 0, left: 0, right: 0, height: 120,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              child: Opacity(
                opacity: 0.3,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: pastTests.isEmpty 
                          ? [const FlSpot(0, 20), const FlSpot(1, 50), const FlSpot(2, 40), const FlSpot(3, 80)]
                          : pastTests.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value.result!.score / (e.value.maxMarks > 0 ? e.value.maxMarks : 1)) * 100)).toList(),
                        isCurved: true, color: Colors.white, barWidth: 4, dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: true, color: Colors.white.withOpacity(0.1)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('PERFORMANCE TREND', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    _buildPulseBadge(),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${averageScore.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: -1)),
                    const Padding(padding: EdgeInsets.only(bottom: 10, left: 6), child: Text('avg', style: TextStyle(color: Colors.white60, fontSize: 16, fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Based on ${pastTests.length} tests session', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
color: Colors.white24, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          const Text('REAL-TIME', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildSubjectChart(List<Test> filteredTests, Color wingColor) {
    final scoredTests = filteredTests.where((t) => t.status == 'published' && t.result != null && t.maxMarks > 0).toList();
    if (scoredTests.isEmpty) return const SizedBox.shrink();
    
    final keywords = ['Math', 'Physics', 'Chemistry', 'Biology', 'Science', 'Social'];
    final Map<String, List<double>> subjectScores = {};
    for (final t in scoredTests) {
      String subject = 'Other';
      for (final kw in keywords) { if (t.title.toLowerCase().contains(kw.toLowerCase())) { subject = kw; break; } }
      subjectScores.putIfAbsent(subject, () => []).add((t.result!.score / t.maxMarks) * 100);
    }

    final subjects = subjectScores.keys.toList();
    final avgScores = subjects.map((s) => subjectScores[s]!.reduce((a, b) => a + b) / subjectScores[s]!.length).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
color: AppTheme.surface, borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.border.withOpacity(0.4), width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SUBJECT ANALYTICS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 1.5)),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: 100, minY: 0, borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 25, getDrawingHorizontalLine: (v) => FlLine(color: AppTheme.border.withOpacity(0.3), strokeWidth: 1, dashArray: [4, 4])),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 25, reservedSize: 35, getTitlesWidget: (v, m) => Text('${v.toInt()}%', style: TextStyle(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.bold)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, m) {
                    final i = v.toInt(); if (i < 0 || i >= subjects.length) return const SizedBox();
                    return Padding(padding: const EdgeInsets.only(top: 8), child: Text(subjects[i].substring(0, subjects[i].length > 4 ? 4 : subjects[i].length), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textMuted)));
                  })),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: List.generate(subjects.length, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: avgScores[i], color: AppTheme.primary, width: 22, borderRadius: BorderRadius.circular(6), backDrawRodData: BackgroundBarChartRodData(show: true, toY: 100, color: AppTheme.primary.withOpacity(0.05)))]))
              )
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title; final int count; final IconData icon;
  const _SectionHeader({required this.title, required this.count, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        SizedBox(width: 12),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textBase, letterSpacing: -0.5)),
        Spacer(),
        if (count > 0) Container(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(count.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary))),
      ],
    );
  }
}

class _UpcomingTestCard extends StatelessWidget {
  final Test test;
  const _UpcomingTestCard({required this.test});

  void _showTestDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 24),
            
            // Header: Subject Badge & Marks Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    test.subjectName?.toUpperCase() ?? 'GENERAL',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'MAX MARKS: ${test.maxMarks.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Test Title
            Text(
              test.title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.textBase,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 24),
            
            Divider(color: AppTheme.border, height: 1),
            SizedBox(height: 24),
            
            // Metadata Grid (Date, Time, Duration, Teacher)
            Row(
              children: [
                Expanded(
                  child: _MetaDetailItem(
                    icon: LucideIcons.calendar,
                    label: 'DATE',
                    value: test.date,
                    iconColor: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _MetaDetailItem(
                    icon: LucideIcons.clock,
                    label: 'TIME',
                    value: test.time ?? '10:00 AM',
                    iconColor: Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _MetaDetailItem(
                    icon: LucideIcons.hourglass,
                    label: 'DURATION',
                    value: test.duration != null && test.duration!.isNotEmpty
                        ? (test.duration!.contains('Min') ? test.duration! : '${test.duration} Mins')
                        : 'N/A',
                    iconColor: Colors.purple,
                  ),
                ),
                Expanded(
                  child: _MetaDetailItem(
                    icon: LucideIcons.user,
                    label: 'CREATOR',
                    value: test.creatorName ?? 'LM Administration',
                    iconColor: Colors.teal,
                  ),
                ),
              ],
            ),
            if (test.assignedTeacherName != null && test.assignedTeacherName!.isNotEmpty && test.assignedTeacherName != test.creatorName) ...[
              const SizedBox(height: 20),
              _MetaDetailItem(
                icon: LucideIcons.userCheck,
                label: 'EVALUATOR',
                value: test.assignedTeacherName!,
                iconColor: Colors.green,
              ),
            ],
            const SizedBox(height: 24),
            
            Divider(color: AppTheme.border, height: 1),
            const SizedBox(height: 24),
            
            // Syllabus Section
            Text(
              'TEST SYLLABUS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppTheme.textMuted,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              test.syllabus != null && test.syllabus!.isNotEmpty 
                  ? test.syllabus! 
                  : 'No specific syllabus details provided.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textBase,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            
            // Description Section (if present)
            if (test.description != null && test.description!.isNotEmpty) ...[
              Text(
                'INSTRUCTIONS / DESCRIPTION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                test.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textBase,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Close Button
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Got it, Thanks!',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
color: AppTheme.surface, 
        borderRadius: BorderRadius.circular(28), 
        border: Border.all(color: AppTheme.border.withOpacity(0.4), width: 1.2), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 20, offset: Offset(0, 10))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6), 
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), 
                child: Row(
                  children: [
                    Icon(LucideIcons.calendar, size: 12, color: Colors.orange), 
                    SizedBox(width: 6), 
                    Text(test.date, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.orange))
                  ]
                )
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  test.subjectName?.toUpperCase() ?? 'GENERAL',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(test.title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textBase, letterSpacing: -0.4)),
          SizedBox(height: 6),
          if (test.assignedTeacherName != null && test.assignedTeacherName!.isNotEmpty && test.assignedTeacherName != test.creatorName) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.shieldCheck, size: 12, color: AppTheme.textMuted),
                    SizedBox(width: 6),
                    Text(
                      'Scheduled by: ${test.creatorName ?? "LM Administration"}',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(LucideIcons.userCheck, size: 12, color: AppTheme.primary),
                    SizedBox(width: 6),
                    Text(
                      'Evaluator: ${test.assignedTeacherName}',
                      style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Icon(LucideIcons.user, size: 12, color: AppTheme.textMuted),
                SizedBox(width: 6),
                Text(
                  'Created by: ${test.creatorName ?? "LM Administration"}',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
          SizedBox(height: 12),
          Text(
            test.syllabus != null && test.syllabus!.isNotEmpty ? test.syllabus! : 'Check syllabus in details.', 
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted.withOpacity(0.8), height: 1.5), 
            maxLines: 2, 
            overflow: TextOverflow.ellipsis
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _showTestDetailsSheet(context), 
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary.withOpacity(0.08), 
              foregroundColor: AppTheme.primary, 
              elevation: 0, 
              minimumSize: const Size(double.infinity, 48), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
            ), 
            child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.w900))
          ),
        ],
      ),
    );
  }
}

class _MetaDetailItem extends StatelessWidget {
  final IconData icon; final String label; final String value; final Color iconColor;
  const _MetaDetailItem({required this.icon, required this.label, required this.value, required this.iconColor});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.textBase), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  final String title; final String date; final String score; final String rank; final double percent; final bool isAbsent; final Test test;
  const _PerformanceCard({required this.title, required this.date, required this.score, required this.rank, required this.percent, this.isAbsent = false, required this.test});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
color: AppTheme.surface, borderRadius: BorderRadius.circular(28), border: Border.all(color: isAbsent ? AppTheme.danger.withOpacity(0.2) : AppTheme.border.withOpacity(0.4), width: 1.2)),
      child: Column(children: [
        Row(children: [
          Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: (isAbsent ? AppTheme.danger : AppTheme.primary).withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Icon(isAbsent ? LucideIcons.userX : LucideIcons.fileText, color: isAbsent ? AppTheme.danger : AppTheme.primary, size: 20)),
          SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.textBase, letterSpacing: -0.3)), SizedBox(height: 4), Text(date, style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.bold))])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(score, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isAbsent ? AppTheme.danger : AppTheme.textBase)), SizedBox(height: 4), Text(isAbsent ? 'ABSENT' : 'RANK $rank', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isAbsent ? AppTheme.danger : AppTheme.primary))]),
        ]),
        if (!isAbsent) ...[SizedBox(height: 20), ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: percent, backgroundColor: AppTheme.background, color: percent > 0.8 ? AppTheme.success : AppTheme.primary, minHeight: 8))],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => PastTestResultsSheet(test: test),
              );
            },
            icon: Icon(LucideIcons.barChart2, size: 16),
            label: Text('View Full Leaderboard', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ]),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
color: AppTheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 100, height: 20),
          SizedBox(height: 16),
          ShimmerBox(width: double.infinity, height: 20),
          SizedBox(height: 12),
          ShimmerBox(width: 150, height: 16),
        ],
      ),
    );
  }
}
