import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/academic_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> with SingleTickerProviderStateMixin {
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
    final academic = context.watch<AcademicProvider>();
    
    // Using real data from provider
    final double testScore = academic.averageScore / 100;
    final double hwScore = academic.homeworkCompletion / 100;
    final double attScore = academic.attendanceRate / 100;

    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildCenteredAppBar(auth.activeWingMode),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildStaggered(0, _buildOverallCard(testScore, hwScore, attScore)),
                    const SizedBox(height: 32),
                    _buildStaggered(1, _SectionHeader(title: 'Detailed Analytics', icon: LucideIcons.barChart3)),
                    const SizedBox(height: 16),
                    _buildStaggered(2, _buildHorizontalBar(
                      label: 'Test Performance',
                      value: testScore,
                      color: AppTheme.primary,
                      icon: LucideIcons.award,
                      subtitle: academic.tests.isEmpty ? 'No tests recorded yet' : 'Average score across ${academic.tests.length} tests',
                    )),
                    const SizedBox(height: 16),
                    _buildStaggered(3, _buildHorizontalBar(
                      label: 'Homework Completion',
                      value: hwScore,
                      color: Colors.orange,
                      icon: LucideIcons.bookOpen,
                      subtitle: academic.homeworks.isEmpty ? 'No homework assigned yet' : '${academic.submissions.length} out of ${academic.homeworks.length} submitted',
                    )),
                    const SizedBox(height: 16),
                    _buildStaggered(4, _buildHorizontalBar(
                      label: 'Attendance Rate',
                      value: attScore,
                      color: AppTheme.success,
                      icon: LucideIcons.userCheck,
                      subtitle: academic.attendance.isEmpty ? 'No attendance records yet' : 'Records for ${academic.attendance.length} days',
                    )),
                    const SizedBox(height: 32),
                    _buildStaggered(5, _buildInsightsCard(testScore, hwScore, attScore)),
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
            'Performance Hub',
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

  Widget _buildOverallCard(double t, double h, double a) {
    final double overall = (t + h + a) / 3;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.2),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'OVERALL SCORE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${(overall * 100).toInt()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                '%',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
color: AppTheme.surface.withOpacity(0.15),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.trendingUp, color: Colors.white, size: 14),
                const SizedBox(width: 8),
                Text(
                  overall > 0.8 ? 'Top 5% of class' : (overall > 0.6 ? 'Growing Steadier' : 'Keep Pushing Forward'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalBar({
    required String label,
    required double value,
    required Color color,
    required IconData icon,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
color: AppTheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.border.withOpacity(0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: AppTheme.textBase,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              AnimatedBuilder(
                animation: _staggerController,
                builder: (context, _) {
                  final progress = CurvedAnimation(
                    parent: _staggerController,
                    curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack),
                  ).value * value;
                  return FractionallySizedBox(
                    widthFactor: progress.clamp(0.01, 1.0),
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.7)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard(double t, double h, double a) {
    String insightText = "Welcome to your performance hub. Start attending classes and completing tests to see your insights!";
    
    if (t > 0 || h > 0 || a > 0) {
      if (a < 0.75) {
        insightText = "Your attendance is below 75%. Try to be more consistent to ensure you don't miss important concepts.";
      } else if (h < 0.5) {
        insightText = "Focus on submitting your homework on time. It accounts for a major part of your learning journey.";
      } else if (t < 0.6) {
        insightText = "Your test scores need improvement. Review the syllabus and focus on weaker subjects to boost your score.";
      } else if (t > 0.8 && a > 0.9) {
        insightText = "Exceptional work! You are among the top performers. Keep maintaining this consistency.";
      } else {
        insightText = "You're doing well! Maintain your attendance and aim for higher scores in upcoming tests.";
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.lightbulb, color: Colors.orange, size: 20),
              const SizedBox(width: 12),
              Text(
                'AI Insights',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppTheme.textBase,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            insightText,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textBase.withOpacity(0.7),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppTheme.textBase,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
