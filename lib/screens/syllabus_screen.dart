import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/academic_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';
import 'syllabus_detail_screen.dart';

class SyllabusScreen extends StatefulWidget {
  const SyllabusScreen({super.key});

  @override
  State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen> with SingleTickerProviderStateMixin {
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
    final auth = context.watch<AuthProvider>();
    final syllabus = academic.syllabus;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildCenteredAppBar(auth.activeWingMode),
            Expanded(
              child: academic.isLoading
                  ? _buildShimmerList()
                  : RefreshIndicator(
                      onRefresh: () async {
                        await context.read<AcademicProvider>().refreshWithLastParams();
                      },
                      child: syllabus.isEmpty
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                              child: Container(
                                height: 400,
                                alignment: Alignment.center,
                                child: const EmptyStateWidget(title: 'No Syllabus', message: 'No syllabus data found', icon: LucideIcons.bookOpen),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                              itemCount: syllabus.length,
                              itemBuilder: (context, index) {
                                final item = syllabus[index];
                                final topics = item['topics'] as List;
                                final completed = topics.where((t) => t['status'] == 'completed').length;
                                final progress = topics.isEmpty ? 0.0 : completed / topics.length;
                                return _buildStaggeredItem(index, item, topics, progress);
                              },
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
            'Academic Syllabus',
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

  Widget _buildStaggeredItem(int index, dynamic item, List topics, double progress) {
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
          child: _FAANGSyllabusCard(
            subject: item['subject'],
            topics: topics.map((t) => t['name']).join(', '),
            progress: progress,
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SyllabusDetailScreen(
                    subject: item['subject'],
                    sections: item['sections'] as Map<String, dynamic>?,
                    topics: topics,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 3,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
color: AppTheme.surface, borderRadius: BorderRadius.circular(28), border: Border.all(color: AppTheme.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            ShimmerLoading(width: 120, height: 22),
            SizedBox(height: 16),
            ShimmerLoading(width: double.infinity, height: 10),
            SizedBox(height: 12),
            ShimmerLoading(width: 200, height: 14),
          ],
        ),
      ),
    );
  }
}

class _FAANGSyllabusCard extends StatelessWidget {
  final String subject;
  final String topics;
  final double progress;
  final VoidCallback onTap;

  const _FAANGSyllabusCard({required this.subject, required this.topics, required this.progress, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
color: AppTheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.border.withOpacity(0.4), width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(subject, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textBase, letterSpacing: -0.5)),
                    _buildStatusBadge(),
                  ],
                ),
                const SizedBox(height: 20),
                _buildProgressBar(),
                const SizedBox(height: 16),
                Text(
                  topics.isEmpty ? 'No topics defined' : topics,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppTheme.textMuted.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final color = progress == 1.0 ? AppTheme.success : AppTheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(
        progress == 1.0 ? 'COMPLETED' : 'IN PROGRESS',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildProgressBar() {
    final color = progress == 1.0 ? AppTheme.success : AppTheme.primary;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 10,
            decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(10)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color.withOpacity(0.7), color]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text('${(progress * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: color)),
      ],
    );
  }
}
