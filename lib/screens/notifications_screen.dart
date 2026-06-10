import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';
import 'dart:convert';
import 'homework_history_screen.dart';
import 'tests_screen.dart';
import 'notice_feed_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final String? highlightMessageId;
  final String? highlightUrl;
  const NotificationsScreen({super.key, this.highlightMessageId, this.highlightUrl});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;
  final _apiService = ApiService();
  
  bool _isLoading = true;
  List<dynamic> _alerts = [];
  String? _error;
  int _lastSeenTime = 0;
  String _selectedFilter = 'all'; // all, unread, test, homework, notice

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
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
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    try {
      final auth = context.read<AuthProvider>();
      if (auth.token == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_notifications');
      if (cached != null) {
        try {
          final decoded = jsonDecode(cached);
          if (mounted) {
            setState(() {
              _alerts = decoded['alerts'] ?? [];
              _isLoading = false;
            });
            _staggerController.forward();
          }
        } catch (e) {
          debugPrint("Error parsing cached notifications: $e");
        }
      }

      final data = await _apiService.getStudentNotifications(auth.token!);
      
      prefs.setString('cached_notifications', jsonEncode(data));

      if (mounted) {
        setState(() {
          _alerts = data['alerts'] ?? [];
          _isLoading = false;
        });
        _staggerController.forward();
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

  void _updateFilter(String filter) {
    HapticFeedback.lightImpact();
    setState(() => _selectedFilter = filter);
    _staggerController.reset();
    _staggerController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: AppTheme.surface,
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
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppTheme.primary));
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

    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: _buildFeed(),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      width: double.infinity,
      color: AppTheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _FAANGFilterChip(label: 'All Updates', isSelected: _selectedFilter == 'all', onTap: () => _updateFilter('all')),
            _FAANGFilterChip(label: 'Unread', isSelected: _selectedFilter == 'unread', onTap: () => _updateFilter('unread')),
            _FAANGFilterChip(label: 'Tests', isSelected: _selectedFilter == 'test', onTap: () => _updateFilter('test')),
            _FAANGFilterChip(label: 'Homework', isSelected: _selectedFilter == 'homework', onTap: () => _updateFilter('homework')),
            _FAANGFilterChip(label: 'Broadcasts', isSelected: _selectedFilter == 'notice', onTap: () => _updateFilter('notice')),
          ],
        ),
      ),
    );
  }

  Widget _buildFeed() {
    final filteredAlerts = _alerts.where((item) {
      if (_selectedFilter == 'all') return true;
      
      final int createdAt = item['createdAt'] is int 
          ? item['createdAt'] 
          : (DateTime.tryParse(item['createdAt']?.toString() ?? '')?.millisecondsSinceEpoch ?? 0);
      final bool isNew = createdAt > _lastSeenTime;
      
      if (_selectedFilter == 'unread' && isNew) return true;
      
      final type = item['type']?.toString() ?? '';
      if (_selectedFilter == 'test' && (type == 'test' || type == 'test_result')) return true;
      if (_selectedFilter == 'homework' && type == 'homework') return true;
      if (_selectedFilter == 'notice' && type == 'notice') return true;
      
      return false;
    }).toList();

    if (filteredAlerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.inbox, size: 48, color: AppTheme.border),
            const SizedBox(height: 16),
            Text('No updates here!', style: TextStyle(color: AppTheme.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: filteredAlerts.length,
      itemBuilder: (context, index) {
        final item = filteredAlerts[index];
        return _buildStaggeredNotification(index, item);
      },
    );
  }

  Widget _buildStaggeredNotification(int index, dynamic item) {
    final animation = CurvedAnimation(
      parent: _staggerController,
      curve: Interval((index / 15).clamp(0.0, 0.5), 1.0, curve: Curves.easeOutQuart),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, 30 * (1 - animation.value)),
        child: Opacity(
          opacity: animation.value,
          child: _NotificationCard(
            item: item, 
            lastSeenTime: _lastSeenTime,
            highlightMessageId: widget.highlightMessageId,
            highlightUrl: widget.highlightUrl,
          ),
        ),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border),
          boxShadow: isSelected 
              ? [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textMuted,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final dynamic item;
  final int lastSeenTime;
  final String? highlightMessageId;
  final String? highlightUrl;

  const _NotificationCard({
    required this.item, 
    required this.lastSeenTime,
    this.highlightMessageId,
    this.highlightUrl,
  });

  @override
  Widget build(BuildContext context) {
    final title = item['title'] ?? 'Notice';
    final body = item['body'] ?? 'No details provided.';
    String dateStr = 'Just now';
    String clockStr = '';
    
    if (item['createdAt'] != null) {
      final dt = (item['createdAt'] is int 
          ? DateTime.fromMillisecondsSinceEpoch(item['createdAt'])
          : DateTime.tryParse(item['createdAt'].toString()) ?? DateTime.now()).toLocal();
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
    final bool isNew = createdAt > lastSeenTime;
    
    final itemId = item['_id']?.toString() ?? '';
    final url = item['url']?.toString() ?? '';
    final type = item['type']?.toString() ?? '';
    
    final isHighlighted = (highlightMessageId != null && highlightMessageId == itemId) ||
                          (highlightUrl != null && highlightUrl == url && url.isNotEmpty);
    final bool showNewTag = isNew || isHighlighted;

    // Determine FAANG aesthetics based on type
    Color iconColor = AppTheme.primary;
    Color bgColor = AppTheme.primary.withOpacity(0.1);
    IconData icon = LucideIcons.bell;

    if (type == 'homework') {
      iconColor = const Color(0xFFF59E0B);
      bgColor = const Color(0xFFF59E0B).withOpacity(0.1);
      icon = LucideIcons.clipboardList;
    } else if (type == 'test' || type == 'test_result') {
      iconColor = const Color(0xFF8B5CF6);
      bgColor = const Color(0xFF8B5CF6).withOpacity(0.1);
      icon = LucideIcons.award;
    } else if (type == 'notice') {
      iconColor = const Color(0xFF10B981);
      bgColor = const Color(0xFF10B981).withOpacity(0.1);
      icon = LucideIcons.megaphone;
    }

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
          Navigator.push(context, MaterialPageRoute(builder: (_) => NoticeFeedScreen(forceRefresh: true, highlightNoticeId: itemId)));
        } else if (type == 'schedule') {
          Navigator.pop(context);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isHighlighted ? iconColor.withOpacity(0.05) : AppTheme.surface,
          border: Border.all(color: isHighlighted ? iconColor.withOpacity(0.5) : AppTheme.border.withOpacity(0.5), width: isHighlighted ? 1.5 : 1),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 15,
              offset: const Offset(0, 8)
            )
          ]
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
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
                        child: Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textBase, fontSize: 14, letterSpacing: -0.3)),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (showNewTag)
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.danger,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                            ),
                          if (clockStr.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(clockStr, style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                            ),
                          Text(dateStr, style: TextStyle(fontSize: 9, color: AppTheme.textMuted)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(body, style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.5, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
