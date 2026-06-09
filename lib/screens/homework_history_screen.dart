import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/academic_provider.dart';
import '../providers/auth_provider.dart';
import '../models/homework.dart';
import '../models/homework_submission.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/homework_submit_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeworkHistoryScreen extends StatefulWidget {
  const HomeworkHistoryScreen({super.key});

  @override
  State<HomeworkHistoryScreen> createState() => _HomeworkHistoryScreenState();
}

class _HomeworkHistoryScreenState extends State<HomeworkHistoryScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final academic = context.watch<AcademicProvider>();
    
    final items = _buildAuditList(academic, auth);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => academic.fetchData(
            auth.currentStudent!.id,
            auth.user!['uid'],
            auth.currentStudent!.className,
            auth.currentStudent!.classId,
            auth.currentStudent!.coachingClass,
            auth.currentStudent!.coachingClassId,
            auth.currentStudent!.wing,
            auth.token!,
            forceRefresh: true
          ),
          child: Column(
            children: [
              _buildCenteredAppBar(auth.activeWingMode),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Day Navigation
                      FadeInAnimation(
                        delay: 100,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () => setState(() => _selectedDate = _selectedDate.subtract(Duration(days: 1))),
                                icon: Icon(LucideIcons.chevronLeft, size: 20, color: AppTheme.primary),
                              ),
                              Column(
                                children: [
                                  Text(DateFormat('EEEE').format(_selectedDate), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.primary)),
                                  Text(DateFormat('dd MMM yyyy').format(_selectedDate), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textMuted)),
                                ],
                              ),
                              IconButton(
                                onPressed: () => setState(() => _selectedDate = _selectedDate.add(Duration(days: 1))),
                                icon: Icon(LucideIcons.chevronRight, size: 20, color: AppTheme.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),

                      // Audit List
                      FadeInAnimation(
                        delay: 200,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 16),
                              child: Text('Daily Audit Agenda', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textBase)),
                            ),
                            if (academic.isLoading)
                              Column(
                                children: List.generate(3, (index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
color: AppTheme.surface,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppTheme.border),
                                    ),
                                    child: const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            ShimmerBox(width: 80, height: 16, radius: 4),
                                            ShimmerBox(width: 60, height: 16, radius: 4),
                                          ],
                                        ),
                                        SizedBox(height: 12),
                                        ShimmerBox(width: 140, height: 20, radius: 4),
                                        SizedBox(height: 8),
                                        ShimmerBox(width: double.infinity, height: 14, radius: 4),
                                        SizedBox(height: 6),
                                        ShimmerBox(width: 180, height: 14, radius: 4),
                                      ],
                                    ),
                                  ),
                                )),
                              )
                            else if (items.isEmpty)
                              Center(
                                child: Column(
                                  children: [
                                    const SizedBox(height: 40),
                                    Icon(LucideIcons.clipboardList, size: 48, color: AppTheme.textMuted.withOpacity(0.2)),
                                    const SizedBox(height: 16),
                                    Text('No classes or homework for this day', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              )
                            else
                              ...items,
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAuditList(AcademicProvider academic, AuthProvider auth) {
    final List<Map<String, dynamic>> items = [];
    final homeworks = academic.homeworks;
    final submissions = academic.submissions;
    final schedules = academic.schedules;
    final holidays = academic.holidays;
    final todayStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    const sessionStart = "2026-04-16";

    // 1. Check Holiday/Week-off
    final isHoliday = holidays.any((h) => h['date'] == todayStr);
    final isMonday = _selectedDate.weekday == DateTime.monday;

    if (isHoliday) {
      final hol = holidays.firstWhere((h) => h['date'] == todayStr);
      return [
        _InfoItem(label: 'Holiday', title: hol['title'] ?? 'School Holiday', color: Colors.red),
      ];
    }
    if (isMonday) {
      return [
        const _InfoItem(label: 'Week Off', title: 'Institutional Holiday', color: Colors.blueGrey),
      ];
    }

    // 2. Cross-reference Schedule with Homework via IDs
    bool isMatch(String? n1, String? n2) {
      if (n1 == null || n2 == null) return false;
      String clean(String s) => s.toLowerCase().replaceAll('class', '').replaceAll('th', '').replaceAll('st', '').replaceAll('nd', '').replaceAll('rd', '').replaceAll(' ', '').replaceFirst(RegExp('^0+'), '');
      return clean(n1) == clean(n2);
    }

    bool isTeacherMatch(String? n1, String? n2) {
      if (n1 == null || n2 == null) return false;
      String clean(String s) => s.toLowerCase().replaceAll(' ', '').replaceAll('sir', '').replaceAll('kumar', '').replaceAll('miss', '').replaceAll('mrs', '').replaceAll('mr', '');
      final c1 = clean(n1);
      final c2 = clean(n2);
      if (c1 == "" || c2 == "") return false;
      return c1 == c2 || c1.contains(c2) || c2.contains(c1);
    }

    debugPrint("[Audit_Debug] schedules length: ${schedules.length}");
    if (schedules.isNotEmpty) {
      debugPrint("[Audit_Debug] First item keys: ${schedules.first.keys}");
      debugPrint("[Audit_Debug] First item dateKey: ${schedules.first['dateKey']}");
      debugPrint("[Audit_Debug] First item date: ${schedules.first['date']}");
    }

    final mySchedules = schedules.where((s) {
      // High-Resilience Date Parsing
      final String rawDate = (s['dateKey']?.toString() ?? s['date']?.toString() ?? "");
      final sDate = rawDate.contains('T') ? rawDate.split('T')[0] : rawDate;
      
      final match = sDate == todayStr;
      if (sDate.isNotEmpty && sDate.contains(todayStr.substring(0, 7))) {
         debugPrint("[Audit_Debug] Checking $sDate against $todayStr -> Match: $match");
      }
      return match;
    }).toList();

    debugPrint("[Audit_Debug] Total Schedules found for $todayStr: ${mySchedules.length}");

    for (var sched in mySchedules) {
      final slots = sched['slots'] as List? ?? [];
      for (var slot in slots) {
        final subject = slot['subject']?.toString();
        final teacherId = slot['teacherUserId']?.toString();
        final subjectId = slot['subjectId']?.toString();
        final slotId = slot['id']?.toString();
        final slotTeacherName = slot['teacherName']?.toString();

        // Multi-Tiered Verification (ID-Priority Flow)
        final hw = homeworks.firstWhere((h) {
          if (h.date != todayStr) return false;

          // 1. Precise Slot ID Match (Direct Link)
          if (slotId != null && h.slotId == slotId) return true;

          // 2. High-Fidelity ID Match (Teacher ID + Subject ID)
          final teacherIdMatch = h.teacherUserId != "" && teacherId != null && 
                                h.teacherUserId == teacherId;
          
          final subjectIdMatch = h.subjectId != "" && subjectId != null && 
                                h.subjectId == subjectId;

          if (teacherIdMatch && subjectIdMatch) return true;

          // 3. Fallback: Identity Match + Subject Name Match
          final subjectNameMatch = h.subject.toLowerCase() == subject?.toLowerCase();
          if (teacherIdMatch && subjectNameMatch) return true;

          // 4. Fallback: Name Match (Fuzzy) + Subject Name Match
          final nameMatch = isTeacherMatch(h.teacherName, slotTeacherName);
          return subjectNameMatch && nameMatch;
        }, orElse: () => Homework(id: '', classId: '', slotId: '', title: '', subject: '', subjectId: '', content: '', teacherUserId: '', teacherName: '', date: ''));

        if (hw.id != null && hw.id != '') {
          final sub = submissions.firstWhere(
            (s) => s.homeworkId == hw.id,
            orElse: () => HomeworkSubmission(id: '', homeworkId: hw.id!, studentId: '', status: 'pending'),
          );
          items.add({
            'sortKey': slot['startTime'] ?? '00:00',
            'widget': _HomeworkHistoryItem(
              homework: hw, 
              submission: sub, 
              startTime: slot['startTime'],
              onRefresh: () => academic.fetchData(
                auth.currentStudent!.id,
                auth.user!['uid'],
                auth.currentStudent!.className,
                auth.currentStudent!.classId,
                auth.currentStudent!.coachingClass,
                auth.currentStudent!.coachingClassId,
                auth.currentStudent!.wing,
                auth.token!,
                forceRefresh: true,
              ),
            ),
          });
        } else {
          items.add({
            'sortKey': slot['startTime'] ?? '00:00',
            'widget': _SkippedHomeworkItem(date: todayStr, subject: subject ?? 'Unknown', time: slot['startTime'] ?? 'N/A'),
          });
        }
      }
    }

    items.sort((a, b) => b['sortKey'].toString().compareTo(a['sortKey'].toString()));
    return items.map((e) => e['widget'] as Widget).toList();
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
            'Curriculum Audit',
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
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String title;
  final Color color;
  const _InfoItem({required this.label, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.1), width: 2),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.calendar, color: color.withOpacity(0.4), size: 40),
          const SizedBox(height: 16),
          Text(label.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: color.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _HomeworkHistoryItem extends StatelessWidget {
  final Homework homework;
  final HomeworkSubmission submission;
  final String? startTime;
  final VoidCallback onRefresh;

  const _HomeworkHistoryItem({
    required this.homework,
    required this.submission,
    this.startTime,
    required this.onRefresh,
  });

  Future<void> _openAttachment(String? url, BuildContext context) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the attachment link.')),
      );
    }
  }

  void _showSubmitSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HomeworkSubmitSheet(
        homework: homework,
        onSubmitSuccess: () {
          Navigator.pop(context);
          onRefresh();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDone = submission.status == 'submitted';
    final primaryColor = AppTheme.getWingColor(context.read<AuthProvider>().activeWingMode);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border.withOpacity(0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isDone ? AppTheme.success : AppTheme.warning).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDone ? LucideIcons.checkCircle2 : LucideIcons.clock,
                        color: isDone ? AppTheme.success : AppTheme.warning,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          homework.subject.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: primaryColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (startTime != null)
                          Text(
                            startTime!,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isDone ? AppTheme.success : AppTheme.warning).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isDone ? 'DONE' : 'PENDING',
                    style: TextStyle(
                      color: isDone ? AppTheme.success : AppTheme.warning,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Homework Title
            Text(
              homework.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.textBase,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),

            // Homework Content
            if (homework.content.isNotEmpty) ...[
              Text(
                homework.content,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppTheme.textMuted.withOpacity(0.85),
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Teacher Name Footer
            Row(
              children: [
                Icon(LucideIcons.user, size: 12, color: AppTheme.textMuted),
                const SizedBox(width: 6),
                Text(
                  'Assigned by: ${homework.teacherName}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: AppTheme.border, height: 1),
            const SizedBox(height: 16),

            // Actions Block
            if (!isDone)
              ElevatedButton.icon(
                onPressed: () => _showSubmitSheet(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(LucideIcons.uploadCloud, size: 16),
                label: const Text(
                  'Submit Homework',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                ),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(LucideIcons.check, color: AppTheme.success, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Submitted successfully',
                        style: TextStyle(
                          color: AppTheme.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (submission.attachmentUrl != null && submission.attachmentUrl!.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _openAttachment(submission.attachmentUrl, context),
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      icon: const Icon(LucideIcons.eye, size: 14),
                      label: const Text(
                        'View File',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkippedHomeworkItem extends StatelessWidget {
  final String date;
  final String subject;
  final String time;

  const _SkippedHomeworkItem({required this.date, required this.subject, required this.time});

  @override
  Widget build(BuildContext context) {
    String displayDate = date;
    try {
      displayDate = DateFormat('dd MMM yyyy').format(DateTime.parse(date));
    } catch (_) {}

    final cleanSub = subject.toLowerCase().trim();
    
    // FANG-Level Smart Logic to classify non-academic/fun slots
    bool isFood = cleanSub.contains('breakfast') || 
                  cleanSub.contains('lunch') || 
                  cleanSub.contains('dinner') || 
                  cleanSub.contains('snack') || 
                  cleanSub.contains('tea') || 
                  cleanSub.contains('meal') || 
                  cleanSub.contains('recess') || 
                  cleanSub.contains('break') || 
                  cleanSub.contains('tiffin');
                  
    bool isSports = cleanSub.contains('sport') || 
                    cleanSub.contains('game') || 
                    cleanSub.contains('pt') || 
                    cleanSub.contains('gym') || 
                    cleanSub.contains('yoga') || 
                    cleanSub.contains('play') || 
                    cleanSub.contains('physical') || 
                    cleanSub.contains('activity');
                    
    bool isRecreation = cleanSub.contains('assembly') || 
                        cleanSub.contains('prayer') || 
                        cleanSub.contains('meditat') || 
                        cleanSub.contains('rest') || 
                        cleanSub.contains('sleep') || 
                        cleanSub.contains('self study') || 
                        cleanSub.contains('library') || 
                        cleanSub.contains('reading');

    if (isFood) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.isDarkMode ? Colors.green.withOpacity(0.15) : const Color(0xFFF0FDF4), // soft green
          borderRadius: BorderRadius.zero,
          border: const Border(left: BorderSide(color: Colors.green, width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const BoxDecoration(color: Colors.green, borderRadius: BorderRadius.zero),
                    child: Text(subject.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Fuel Your Brain! 🍳',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.green),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Time to enjoy a delicious meal and charge up! No homework for this break session.',
                    style: TextStyle(color: AppTheme.isDarkMode ? Colors.green.shade200 : const Color(0xFF166534), fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: const BoxDecoration(color: Colors.green, borderRadius: BorderRadius.zero),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.coffee, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text('MEAL TIME', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (isSports) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.isDarkMode ? Colors.blue.withOpacity(0.15) : const Color(0xFFEFF6FF), // soft light blue
          borderRadius: BorderRadius.zero,
          border: const Border(left: BorderSide(color: Colors.blue, width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.zero),
                    child: Text(subject.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Play Hard, Study Hard! ⚽',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.blue),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Get active, stretch out, and stay fit! No homework for physical activity slots.',
                    style: TextStyle(color: AppTheme.isDarkMode ? Colors.blue.shade200 : const Color(0xFF1E40AF), fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: const BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.zero),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.activity, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text('PLAY TIME', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (isRecreation) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.isDarkMode ? Colors.purple.withOpacity(0.15) : const Color(0xFFFAF5FF), // soft light purple
          borderRadius: BorderRadius.zero,
          border: const Border(left: BorderSide(color: Colors.purple, width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.zero),
                    child: Text(subject.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Peace & Recharge! 🧘‍♂️',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.purple),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Calm your mind, rest, or read a book. No homework during rest & meditation.',
                    style: TextStyle(color: AppTheme.isDarkMode ? Colors.purple.shade200 : const Color(0xFF6B21A8), fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: const BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.zero),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.smile, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text('CALM SLOT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.isDarkMode ? Colors.red.withOpacity(0.15) : const Color(0xFFFEF2F2), // soft light red background
        borderRadius: BorderRadius.zero, // strict zero-fillet
        border: Border(left: BorderSide(color: AppTheme.danger, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.danger, borderRadius: BorderRadius.zero),
                  child: Text(subject.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ),
                const SizedBox(height: 12),
                Text(
                  'Homework Missed',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textBase),
                ),
                const SizedBox(height: 6),
                Text(
                  'Teacher missed uploading homework for this session ($time).',
                  style: TextStyle(color: AppTheme.isDarkMode ? Colors.red.shade200 : Colors.red.shade900, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppTheme.danger, borderRadius: BorderRadius.zero),
                child: Row(
                  children: [
                    const Icon(LucideIcons.calendarClock, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      displayDate,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.isDarkMode ? Colors.transparent : const Color(0xFFFEF2F2),
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.zero,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.lock, size: 10, color: AppTheme.danger),
                    const SizedBox(width: 4),
                    Text('LOCKED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.danger, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
