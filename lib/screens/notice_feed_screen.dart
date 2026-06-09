import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/notice_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';
import 'notice_detail_screen.dart';

class NoticeFeedScreen extends StatefulWidget {
  final bool forceRefresh;
  final String? highlightNoticeId;
  const NoticeFeedScreen({super.key, this.forceRefresh = false, this.highlightNoticeId});

  @override
  State<NoticeFeedScreen> createState() => _NoticeFeedScreenState();
}

class _NoticeFeedScreenState extends State<NoticeFeedScreen> with SingleTickerProviderStateMixin {
  String _selectedFilter = 'all';
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loadNotices();
  }

  void _loadNotices() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentStudent != null) {
        context.read<NoticeProvider>().fetchNotices(
          auth.currentStudent!.className,
          auth.currentStudent!.classId,
          auth.currentStudent!.coachingClass,
          auth.currentStudent!.coachingClassId,
          auth.currentStudent!.wing,
          auth.token ?? '',
          forceRefresh: widget.forceRefresh,
        );
      }
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
    final noticeProvider = context.watch<NoticeProvider>();
    final auth = context.watch<AuthProvider>();
    final wingColor = AppTheme.getWingColor(auth.activeWingMode);
    
    final filteredNotices = noticeProvider.notices.where((n) {
      if (auth.activeWingMode == 'coaching') {
        if (n.wing != 'coaching') return false;
      }
      if (_selectedFilter != 'all' && n.type != _selectedFilter) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildCenteredAppBar(auth.activeWingMode),
            _buildFilterChips(wingColor),
            Expanded(
              child: noticeProvider.isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: 3,
                    itemBuilder: (context, index) => const _NoticeShimmer(),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await noticeProvider.fetchNotices(
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
                    },
                    child: filteredNotices.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredNotices.length,
                          itemBuilder: (context, index) {
                            return _buildStaggeredNotice(index, filteredNotices[index], wingColor);
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
            'Notice Board',
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

  Widget _buildFilterChips(Color wingColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: [
          _FAANGFilterChip(label: 'All Updates', isSelected: _selectedFilter == 'all', onTap: () => _updateFilter('all')),
          _FAANGFilterChip(label: 'Notices', isSelected: _selectedFilter == 'notice', onTap: () => _updateFilter('notice')),
          _FAANGFilterChip(label: 'Circulars', isSelected: _selectedFilter == 'circular', onTap: () => _updateFilter('circular')),
          _FAANGFilterChip(label: 'Events', isSelected: _selectedFilter == 'event', onTap: () => _updateFilter('event')),
        ],
      ),
    );
  }

  void _updateFilter(String filter) {
    setState(() => _selectedFilter = filter);
    _staggerController.reset();
    _staggerController.forward();
  }

  Widget _buildStaggeredNotice(int index, Notice notice, Color wingColor) {
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
          child: _NoticeCard(
            notice: notice, 
            wingColor: wingColor,
            isHighlighted: widget.highlightNoticeId != null && widget.highlightNoticeId == notice.id,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        children: [
          Container(
            constraints: BoxConstraints(minHeight: constraints.maxHeight > 0 ? constraints.maxHeight : 400),
            child: const EmptyStateWidget(
              title: 'No updates yet',
              message: 'Any circulars or events will appear here.',
              icon: LucideIcons.bookOpen,
            ),
          ),
        ],
      ),
    );
  }
}

class _FAANGFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FAANGFilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wingColor = AppTheme.getWingColor(auth.activeWingMode);
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? wingColor : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? wingColor : AppTheme.border.withOpacity(0.5)),
          boxShadow: isSelected 
            ? [BoxShadow(color: wingColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
            : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final Notice notice;
  final Color wingColor;
  final bool isHighlighted;
  const _NoticeCard({required this.notice, required this.wingColor, this.isHighlighted = false});

  @override
  Widget build(BuildContext context) {
    final Color typeColor = notice.type == 'notice' ? const Color(0xFF3B82F6) : (notice.type == 'circular' ? const Color(0xFF10B981) : const Color(0xFFF59E0B));
    final IconData typeIcon = notice.type == 'notice' ? LucideIcons.bell : (notice.type == 'circular' ? LucideIcons.megaphone : LucideIcons.calendarDays);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isHighlighted ? typeColor.withOpacity(0.05) : AppTheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isHighlighted ? typeColor : AppTheme.border.withOpacity(0.4), width: isHighlighted ? 2.0 : 1.2),
        boxShadow: isHighlighted ? [BoxShadow(color: typeColor.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NoticeDetailScreen(notice: notice, wingColor: wingColor))),
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTypeBadge(typeColor, typeIcon),
                    Text(notice.date, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(notice.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textBase, letterSpacing: -0.3)),
                const SizedBox(height: 12),
                Text(notice.content, style: TextStyle(fontSize: 14, color: AppTheme.textMuted.withOpacity(0.8), height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 20),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(notice.type.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(radius: 12, backgroundColor: AppTheme.background, child: Icon(LucideIcons.user, size: 12, color: AppTheme.textMuted)),
            const SizedBox(width: 8),
            Text(notice.author, style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
          ],
        ),
        Icon(LucideIcons.arrowRight, size: 18, color: wingColor.withOpacity(0.5)),
      ],
    );
  }
}

class _NoticeShimmer extends StatelessWidget {
  const _NoticeShimmer();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
color: AppTheme.surface, borderRadius: BorderRadius.circular(28), border: Border.all(color: AppTheme.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ShimmerLoading(width: 80, height: 20, borderRadius: 10),
          SizedBox(height: 16),
          ShimmerLoading(width: 200, height: 22),
          SizedBox(height: 12),
          ShimmerLoading(width: double.infinity, height: 16),
          SizedBox(height: 8),
          ShimmerLoading(width: 150, height: 16),
        ],
      ),
    );
  }
}
