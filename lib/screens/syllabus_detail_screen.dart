import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';

class SyllabusDetailScreen extends StatefulWidget {
  final String subject;
  final Map<String, dynamic>? sections;
  final List<dynamic> topics;

  const SyllabusDetailScreen({
    super.key, 
    required this.subject, 
    this.sections,
    required this.topics,
  });

  @override
  State<SyllabusDetailScreen> createState() => _SyllabusDetailScreenState();
}

class _SyllabusDetailScreenState extends State<SyllabusDetailScreen> {
  final List<Map<String, dynamic>> terms = [
    {'name': 'Pre-Mid Term', 'color': Colors.blue},
    {'name': 'Mid Term', 'color': Colors.orange},
    {'name': 'Post-Mid Term', 'color': Colors.purple},
    {'name': 'Final Term', 'color': Colors.green},
  ];

  @override
  Widget build(BuildContext context) {
    final hasSections = widget.sections != null && widget.sections!.isNotEmpty;

    List<Widget> slivers = [
      SliverAppBar(
        expandedHeight: 220,
        pinned: true,
        stretch: true,
        backgroundColor: AppTheme.primary,
        flexibleSpace: FlexibleSpaceBar(
          title: Text(
            widget.subject,
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 22),
          ),
          background: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(LucideIcons.graduationCap, size: 180, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
    ];

    if (hasSections) {
      for (final term in terms) {
        final termName = term['name'] as String;
        final termColor = term['color'] as Color;
        final topics = widget.sections![termName] as List<dynamic>? ?? [];

        if (topics.isNotEmpty) {
          // Add Term Header
          slivers.add(
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: termColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: termColor.withOpacity(0.3), width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: termColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            termName,
                            style: TextStyle(
                              color: termColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: AppTheme.border,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          // Add Topic Cards for this Term
          slivers.add(
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final topic = topics[index];
                    return _buildTopicCard(topic, termColor, index);
                  },
                  childCount: topics.length,
                ),
              ),
            ),
          );
        }
      }
    } else {
      // Basic syllabus with no sections
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final topic = widget.topics[index];
                return _buildTopicCard(topic, AppTheme.primary, index);
              },
              childCount: widget.topics.length,
            ),
          ),
        ),
      );
    }

    // Safety padding at bottom
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 40)));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: slivers,
      ),
    );
  }

  Widget _buildTopicCard(dynamic topic, Color accentColor, int index) {
    final isDone = topic['status'] == 'completed';

    return FadeInAnimation(
      delay: index * 50,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDone ? Colors.green.withOpacity(0.2) : accentColor.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(color: accentColor.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(20),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isDone ? Colors.green : accentColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              isDone ? LucideIcons.checkCircle2 : LucideIcons.target,
              color: isDone ? Colors.green : accentColor,
              size: 24,
            ),
          ),
          title: Text(
            topic['name'],
            style: TextStyle(
              fontSize: 16,
              fontWeight: isDone ? FontWeight.bold : FontWeight.w700,
              color: isDone ? Colors.green.shade700 : AppTheme.textBase,
              decoration: isDone ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Icon(LucideIcons.calendar, size: 10, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  isDone ? 'Finished and verified' : 'Upcoming in current plan',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          trailing: isDone 
            ? const Icon(LucideIcons.badgeCheck, color: Colors.green, size: 24)
            : Icon(LucideIcons.arrowRight, size: 16, color: accentColor.withOpacity(0.3)),
        ),
      ),
    );
  }
}
