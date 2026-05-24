import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/app_cache.dart';
import '../models/doubt.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';
import '../widgets/shimmer_skeleton.dart';

class DoubtRoomScreen extends StatefulWidget {
  const DoubtRoomScreen({super.key});

  @override
  State<DoubtRoomScreen> createState() => _DoubtRoomScreenState();
}

class _DoubtRoomScreenState extends State<DoubtRoomScreen> {
  final ApiService _apiService = ApiService();
  List<Doubt> _doubts = [];
  bool _isLoading = true;
  String _selectedFilter = 'All'; // 'All', 'Pending', 'Answered'

  @override
  void initState() {
    super.initState();
    _loadDoubts();
  }

  Future<void> _loadDoubts() async {
    final auth = context.read<AuthProvider>();
    if (auth.currentStudent == null) return;

    // Zero-loading cache render
    final cacheKey = 'doubts_${auth.currentStudent!.id}';
    final cachedData = AppCache.instance.get(cacheKey);
    if (cachedData is List) {
      setState(() {
        _doubts = cachedData.map((d) => Doubt.fromJson(Map<String, dynamic>.from(d as Map))).toList();
        _isLoading = false;
      });
    }

    try {
      final data = await _apiService.getDoubts(auth.currentStudent!.id, auth.token!);
      final list = data.map((d) => Doubt.fromJson(Map<String, dynamic>.from(d as Map))).toList();
      setState(() {
        _doubts = list;
        _isLoading = false;
      });
      // Save to cache
      await AppCache.instance.set(cacheKey, data);
    } catch (e) {
      if (_doubts.isEmpty) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error loading doubts: $e');
    }
  }

  List<Doubt> get _filteredDoubts {
    if (_selectedFilter == 'Pending') {
      return _doubts.where((d) => d.replies.isEmpty).toList();
    } else if (_selectedFilter == 'Answered') {
      return _doubts.where((d) => d.replies.isNotEmpty).toList();
    }
    return _doubts;
  }

  void _showAskDoubtSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AskDoubtSheet(onPost: () {
        Navigator.pop(context);
        _loadDoubts();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final activeWing = auth.activeWingMode;
    final primaryColor = AppTheme.getWingColor(activeWing);

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAskDoubtSheet,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(LucideIcons.plus),
        label: const Text('Ask a Doubt', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildCenteredAppBar(activeWing),
            _buildFilterChips(primaryColor),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadDoubts,
                child: _isLoading && _doubts.isEmpty
                    ? _buildShimmerList()
                    : _filteredDoubts.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            itemCount: _filteredDoubts.length,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final doubt = _filteredDoubts[index];
                              return _DoubtCard(
                                doubt: doubt,
                                primaryColor: primaryColor,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => _DoubtDetailsScreen(doubt: doubt, primaryColor: primaryColor),
                                    ),
                                  );
                                  _loadDoubts();
                                },
                              );
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
            'Doubt Room',
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

  Widget _buildFilterChips(Color primaryColor) {
    final filters = ['All', 'Pending', 'Answered'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f, style: TextStyle(fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, fontSize: 12)),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilter = f),
              selectedColor: primaryColor.withOpacity(0.12),
              disabledColor: Colors.transparent,
              checkmarkColor: primaryColor,
              labelStyle: TextStyle(color: isSelected ? primaryColor : AppTheme.textMuted),
              backgroundColor: AppTheme.surface,
              side: BorderSide(color: isSelected ? primaryColor : AppTheme.border, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: List.generate(4, (index) => Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 80, height: 16),
                ShimmerBox(width: 50, height: 16),
              ],
            ),
            SizedBox(height: 16),
            ShimmerBox(width: 180, height: 20),
            SizedBox(height: 10),
            ShimmerBox(width: double.infinity, height: 14),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 100, height: 12),
                ShimmerBox(width: 70, height: 14),
              ],
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.messageSquareDashed, size: 64, color: AppTheme.textMuted.withOpacity(0.2)),
          const SizedBox(height: 20),
          Text('No Doubts Found', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textBase)),
          const SizedBox(height: 6),
          Text('Need help? Ask a doubt to get reply from teachers.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DoubtCard extends StatelessWidget {
  final Doubt doubt;
  final Color primaryColor;
  final VoidCallback onTap;

  const _DoubtCard({required this.doubt, required this.primaryColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasReplies = doubt.replies.isNotEmpty;
    final dateStr = DateFormat('dd MMM, hh:mm a').format(doubt.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
color: AppTheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.border.withOpacity(0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      doubt.subject.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (hasReplies ? AppTheme.success : AppTheme.warning).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      hasReplies ? 'ANSWERED' : 'PENDING',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: hasReplies ? AppTheme.success : AppTheme.warning,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                doubt.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textBase,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              // Question preview
              Text(
                doubt.question,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppTheme.textMuted.withOpacity(0.85),
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              Divider(color: AppTheme.border, height: 1),
              const SizedBox(height: 12),
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(LucideIcons.messageSquare, size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        '${doubt.replies.length} replies',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AskDoubtSheet extends StatefulWidget {
  final VoidCallback onPost;

  const _AskDoubtSheet({required this.onPost});

  @override
  State<_AskDoubtSheet> createState() => _AskDoubtSheetState();
}

class _AskDoubtSheetState extends State<_AskDoubtSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _questionController = TextEditingController();
  String _selectedSubject = 'Physics';
  bool _isPosting = false;

  final List<String> _subjects = ['Physics', 'Chemistry', 'Mathematics', 'Biology', 'English', 'Other'];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isPosting = true);

    try {
      final auth = context.read<AuthProvider>();
      final apiService = ApiService();

      final body = {
        'studentId': auth.currentStudent!.id,
        'studentName': auth.currentStudent!.name,
        'subject': _selectedSubject,
        'title': _titleController.text.trim(),
        'question': _questionController.text.trim(),
        'createdAt': DateTime.now().toIso8601String(),
        'replies': [],
      };

      await apiService.createDoubt(body, auth.token!);
      HapticFeedback.mediumImpact();
      widget.onPost();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post doubt: $e')),
      );
    } finally {
      setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wingColor = AppTheme.getWingColor(auth.activeWingMode);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 48, height: 5, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 24),
              Text('Ask a New Doubt', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTheme.textBase)),
              const SizedBox(height: 20),
              
              // Subject Selection Chips
              Text('SELECT SUBJECT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: AppTheme.textMuted, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _subjects.map((sub) {
                  final isSel = _selectedSubject == sub;
                  return ChoiceChip(
                    label: Text(sub, style: TextStyle(fontWeight: isSel ? FontWeight.w900 : FontWeight.w600, fontSize: 11.5)),
                    selected: isSel,
                    onSelected: (_) => setState(() => _selectedSubject = sub),
                    selectedColor: wingColor.withOpacity(0.12),
                    checkmarkColor: wingColor,
                    labelStyle: TextStyle(color: isSel ? wingColor : AppTheme.textMuted),
                    backgroundColor: AppTheme.background,
                    side: BorderSide(color: isSel ? wingColor : AppTheme.border, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Title input
              TextFormField(
                controller: _titleController,
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textBase),
                decoration: const InputDecoration(
                  labelText: 'Topic / Short Title',
                  hintText: 'e.g., Integration problem in Q.5',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 20),

              // Question input
              TextFormField(
                controller: _questionController,
                maxLines: 5,
                style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textBase),
                decoration: const InputDecoration(
                  labelText: 'Explain your doubt',
                  hintText: 'Describe exactly what you are finding difficult...',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please describe your question' : null,
              ),
              const SizedBox(height: 28),

              // Submit Button
              ElevatedButton(
                onPressed: _isPosting ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: wingColor),
                child: _isPosting
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Post Doubt', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoubtDetailsScreen extends StatefulWidget {
  final Doubt doubt;
  final Color primaryColor;

  const _DoubtDetailsScreen({required this.doubt, required this.primaryColor});

  @override
  State<_DoubtDetailsScreen> createState() => _DoubtDetailsScreenState();
}

class _DoubtDetailsScreenState extends State<_DoubtDetailsScreen> {
  final _replyController = TextEditingController();
  late Doubt _doubt;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _doubt = widget.doubt;
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);

    try {
      final auth = context.read<AuthProvider>();
      final apiService = ApiService();

      final body = {
        'authorId': auth.currentStudent!.id,
        'authorName': auth.currentStudent!.name,
        'authorRole': 'student',
        'reply': text,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final data = await apiService.replyToDoubt(_doubt.id, body, auth.token!);
      HapticFeedback.mediumImpact();
      _replyController.clear();
      setState(() {
        _doubt = Doubt.fromJson(Map<String, dynamic>.from(data as Map));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post reply: $e')));
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(_doubt.createdAt);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Doubt Discussion', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  // Main Question Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppTheme.border.withOpacity(0.4), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: widget.primaryColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _doubt.subject.toUpperCase(),
                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: widget.primaryColor, letterSpacing: 0.5),
                              ),
                            ),
                            Text(dateStr, style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _doubt.title,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textBase, letterSpacing: -0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _doubt.question,
                          style: TextStyle(fontSize: 14.5, color: AppTheme.textBase, height: 1.5, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Reply Section Header
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 16),
                    child: Text('Discussion Thread', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.textBase)),
                  ),

                  // Replies List
                  if (_doubt.replies.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          'No replies yet. Your teachers will reply shortly!',
                          style: TextStyle(color: AppTheme.textMuted.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                  else
                    ..._doubt.replies.map((reply) => _ReplyBubble(reply: reply)),
                ],
              ),
            ),
            
            // Bottom Message Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
color: AppTheme.surface,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textBase),
                      decoration: InputDecoration(
                        hintText: 'Add a reply...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        fillColor: AppTheme.background,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isSending ? null : _sendReply,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(LucideIcons.send, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplyBubble extends StatelessWidget {
  final DoubtReply reply;

  const _ReplyBubble({required this.reply});

  @override
  Widget build(BuildContext context) {
    final isTeacher = reply.authorRole == 'teacher';
    final dateStr = DateFormat('dd MMM, hh:mm a').format(reply.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isTeacher ? AppTheme.primary.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isTeacher ? AppTheme.primary.withOpacity(0.2) : AppTheme.border.withOpacity(0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: isTeacher ? AppTheme.primary : AppTheme.textMuted.withOpacity(0.2),
                    child: Icon(
                      isTeacher ? LucideIcons.shieldAlert : LucideIcons.user,
                      size: 12,
                      color: isTeacher ? Colors.white : AppTheme.textBase,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    reply.authorName,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: isTeacher ? AppTheme.primary : AppTheme.textBase,
                    ),
                  ),
                  if (isTeacher) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(6)),
                      child: const Text('TEACHER', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
              Text(dateStr, style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            reply.reply,
            style: TextStyle(fontSize: 13.5, color: AppTheme.textBase, height: 1.45, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
