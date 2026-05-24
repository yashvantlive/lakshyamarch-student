import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';
import 'homework_history_screen.dart';
import 'tests_screen.dart';
import 'notice_feed_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  final String? highlightMessageId;
  final String? highlightUrl;
  const NotificationsScreen({super.key, this.highlightMessageId, this.highlightUrl});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _apiService = ApiService();
  
  bool _isLoading = true;
  List<dynamic> _announcements = [];
  List<dynamic> _alerts = [];
  String? _error;
  int _lastSeenTime = 0;

  @override
  void initState() {
    super.initState();
    int initialIndex = (widget.highlightMessageId != null || widget.highlightUrl != null) ? 1 : 0;
    _tabController = TabController(length: 2, vsync: this, initialIndex: initialIndex);
    _initSeenTime();
    _fetchNotifications();
  }

  Future<void> _initSeenTime() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _lastSeenTime = prefs.getInt('lastSeenNotificationsTime') ?? 0;
    });
    // Update the time so next visits consider current ones as seen
    await prefs.setInt('lastSeenNotificationsTime', now);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    try {
      final auth = context.read<AuthProvider>();
      if (auth.token == null) return;
      final data = await _apiService.getStudentNotifications(auth.token!);
      if (mounted) {
        setState(() {
          _announcements = data['announcements'] ?? [];
          _alerts = data['alerts'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: AppTheme.textBase),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Notifications Center',
            style: TextStyle(color: AppTheme.textBase, fontWeight: FontWeight.w900, fontSize: 18),
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textMuted,
            indicatorColor: AppTheme.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(text: "Announcements"),
              Tab(text: "Alerts"),
            ],
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertTriangle, size: 48, color: AppTheme.danger),
            const SizedBox(height: 16),
            Text('Failed to load notifications', style: TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchNotifications, child: const Text('Retry'))
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildList(_announcements, isAnnouncement: true),
        _buildList(_alerts, isAnnouncement: false),
      ],
    );
  }

  Widget _buildList(List<dynamic> items, {required bool isAnnouncement}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isAnnouncement ? LucideIcons.bellOff : LucideIcons.inbox, size: 48, color: AppTheme.border),
            const SizedBox(height: 16),
            Text(isAnnouncement ? 'No recent announcements' : 'No new alerts', style: TextStyle(color: AppTheme.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildNotificationCard(item, isAnnouncement);
      },
    );
  }

  Widget _buildNotificationCard(dynamic item, bool isAnnouncement) {
    final title = item['title'] ?? 'Notice';
    final body = item['body'] ?? 'No details provided.';
    String dateStr = 'Just now';
    String clockStr = '';
    if (item['createdAt'] != null) {
      final dt = item['createdAt'] is int 
          ? DateTime.fromMillisecondsSinceEpoch(item['createdAt'])
          : DateTime.tryParse(item['createdAt'].toString()) ?? DateTime.now();
      dateStr = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
      int hour = dt.hour;
      String ampm = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      clockStr = "${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $ampm";
    }

    final int createdAt = item['createdAt'] is int 
        ? item['createdAt'] 
        : (DateTime.tryParse(item['createdAt']?.toString() ?? '')?.millisecondsSinceEpoch ?? 0);
    final bool isNew = createdAt > _lastSeenTime;
    
    final itemId = item['_id']?.toString() ?? '';
    final url = item['url']?.toString() ?? '';
    final type = item['type']?.toString() ?? '';
    
    final isHighlighted = (widget.highlightMessageId != null && widget.highlightMessageId == itemId) ||
                          (widget.highlightUrl != null && widget.highlightUrl == url && url.isNotEmpty);
    final bool showNewTag = isNew || isHighlighted;

    return InkWell(
      onTap: () {
        if (url.contains('/student/homework') || type == 'homework') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeworkHistoryScreen()));
        } else if (url.contains('/student/tests') || type == 'test' || type == 'test_result') {
          String? initialWing;
          try {
             if (url.contains('wing=coaching') || title.toUpperCase().contains('COACHING') || body.toUpperCase().contains('COACHING')) {
                initialWing = 'coaching';
             } else if (url.contains('wing=school') || title.toUpperCase().contains('SCHOOL') || body.toUpperCase().contains('SCHOOL')) {
                initialWing = 'school';
             }
          } catch(e) {}
          Navigator.push(context, MaterialPageRoute(builder: (_) => TestsScreen(initialWingFilter: initialWing)));
        } else if (url.contains('/notices') || type == 'notice') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticeFeedScreen()));
        } else if (type == 'schedule') {
          // Stay on dashboard or pop
          Navigator.pop(context);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted ? AppTheme.primary.withOpacity(0.05) : Colors.white,
        border: Border.all(color: isHighlighted ? AppTheme.primary : AppTheme.border, width: isHighlighted ? 2 : 1),
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isAnnouncement ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isAnnouncement ? LucideIcons.megaphone : LucideIcons.bellRing, 
              color: isAnnouncement ? Colors.blue : Colors.orange, 
              size: 20
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textBase, fontSize: 14)),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (showNewTag)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.danger,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        if (clockStr.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(clockStr, style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                          ),
                        Text(dateStr, style: TextStyle(fontSize: 9, color: AppTheme.textMuted)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(body, style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
