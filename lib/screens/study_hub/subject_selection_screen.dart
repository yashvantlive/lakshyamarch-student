import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/academic_provider.dart';
import '../../providers/auth_provider.dart';
import 'resource_list_screen.dart';
import 'book_selection_screen.dart';
import '../../widgets/premium_widgets.dart';

class SubjectSelectionScreen extends StatefulWidget {
  final String classId;
  final String className;
  final String materialType;

  const SubjectSelectionScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.materialType,
  });

  @override
  State<SubjectSelectionScreen> createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelectionScreen> {
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = true;
  String? _selectedWingFilter;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);
    
    final academic = context.read<AcademicProvider>();
    final auth = context.read<AuthProvider>();
    final student = auth.currentStudent;
    
    if (_selectedWingFilter == null) {
      _selectedWingFilter = student?.wing == 'both' ? 'school' : (student?.wing ?? 'school');
    }
    
    final isCoaching = _selectedWingFilter == 'coaching';
    final targetClassId = isCoaching 
        ? (student?.coachingClassId?.isNotEmpty == true ? student?.coachingClassId : student?.classId)
        : student?.classId;
        
    final targetClassName = isCoaching 
        ? (student?.coachingClass?.isNotEmpty == true ? student?.coachingClass : student?.className)
        : student?.className;
        
    if (widget.materialType.toUpperCase() == 'NCERT') {
      final wing = _selectedWingFilter ?? 'school';
      final localData = await academic.fetchLocalNcertBooks(wing);
      final cId = targetClassId ?? widget.classId;
      final classData = localData.firstWhere(
        (c) => c['classId'] == cId || c['_id'] == cId,
        orElse: () => null
      );
      
      if (classData != null && classData['books'] != null) {
        final Map<String, Map<String, dynamic>> subjectMap = {};
        final books = classData['books'] as List;
        for (var book in books) {
          final subjectName = book['subjectName'] ?? 'Unknown';
          if (!subjectMap.containsKey(subjectName)) {
            subjectMap[subjectName] = {
              'id': subjectName,
              'name': subjectName,
              'icon': _getIconForSubject(subjectName),
              'color': _getColorForSubject(subjectName),
              'localBooks': [],
            };
          }
          subjectMap[subjectName]!['localBooks'].add(book);
        }
        setState(() {
          _subjects = subjectMap.values.toList();
          _isLoading = false;
        });
        return;
      } else {
        setState(() {
          _subjects = [];
          _isLoading = false;
        });
        return;
      }
    }

    final materials = await academic.fetchStudyMaterials(
      targetClassId ?? widget.classId, 
      widget.materialType, 
      auth.token ?? ''
    );

    final Map<String, Map<String, dynamic>> subjectMap = {};
    for (var m in materials) {
      final subjectObj = m['subjectId'];
      final subjectName = subjectObj['name'];
      final subjectId = subjectObj['_id'];
      
      if (!subjectMap.containsKey(subjectId)) {
        subjectMap[subjectId] = {
          'id': subjectId,
          'name': subjectName,
          'icon': _getIconForSubject(subjectName),
          'color': _getColorForSubject(subjectName),
        };
      }
    }

    setState(() {
      _subjects = subjectMap.values.toList();
      _isLoading = false;
    });
  }

  IconData _getIconForSubject(String name) {
    name = name.toLowerCase();
    if (name.contains('math')) return LucideIcons.calculator;
    if (name.contains('physics')) return LucideIcons.atom;
    if (name.contains('chemistry')) return LucideIcons.beaker;
    if (name.contains('biology')) return LucideIcons.dna;
    if (name.contains('science')) return LucideIcons.flaskConical;
    if (name.contains('history')) return LucideIcons.scroll;
    if (name.contains('geography')) return LucideIcons.globe;
    if (name.contains('political') || name.contains('civics')) return LucideIcons.landmark;
    if (name.contains('economics')) return LucideIcons.barChart;
    if (name.contains('account')) return LucideIcons.fileText;
    if (name.contains('business')) return LucideIcons.briefcase;
    if (name.contains('computer')) return LucideIcons.monitor;
    if (name.contains('sociology')) return LucideIcons.users;
    if (name.contains('english')) return LucideIcons.bookOpen;
    if (name.contains('hindi')) return LucideIcons.type;
    return LucideIcons.book;
  }

  Color _getColorForSubject(String name) {
    name = name.toLowerCase();
    if (name.contains('math')) return Colors.red;
    if (name.contains('physics')) return Colors.blue;
    if (name.contains('chemistry')) return Colors.orange;
    if (name.contains('biology')) return Colors.green;
    if (name.contains('science')) return Colors.teal;
    if (name.contains('history')) return Colors.amber;
    if (name.contains('geography')) return Colors.blueAccent;
    if (name.contains('political') || name.contains('civics')) return Colors.purple;
    if (name.contains('economics')) return Colors.indigo;
    if (name.contains('account')) return Colors.blueGrey;
    if (name.contains('business')) return Colors.brown;
    if (name.contains('computer')) return Colors.cyan;
    if (name.contains('sociology')) return Colors.deepOrange;
    if (name.contains('english')) return Colors.pink;
    if (name.contains('hindi')) return Colors.orangeAccent;
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final student = auth.currentStudent;
    final hasBoth = student?.wing == 'both' || (student?.classId?.isNotEmpty == true && student?.coachingClassId?.isNotEmpty == true);
    
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = hasBoth ? 160.0 : 120.0;
    final gridHeight = screenHeight - appBarHeight - MediaQuery.of(context).padding.top - 40;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildCenteredAppBar(auth.activeWingMode, student, hasBoth),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _subjects.isEmpty 
                    ? _buildEmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: (MediaQuery.of(context).size.width / 2) / (gridHeight / 4.2),
                        ),
                        itemCount: _subjects.length,
                        itemBuilder: (context, index) {
                          final s = _subjects[index];
                          return _buildSubjectTile(context, s);
                        },
                      ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.folderOpen, size: 64, color: AppTheme.textMuted.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'No subjects found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildCenteredAppBar(String? defaultWingMode, dynamic student, bool hasBoth) {
    final isCoaching = _selectedWingFilter == 'coaching';
    final targetClassName = isCoaching 
        ? (student?.coachingClass?.isNotEmpty == true ? student?.coachingClass : student?.className)
        : student?.className;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      width: double.infinity,
      child: Column(
        children: [
          AnimatedBrandHeader(wingMode: _selectedWingFilter ?? defaultWingMode),
          const SizedBox(height: 8),
          Text(
            '${targetClassName ?? widget.className} - ${widget.materialType}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textBase.withOpacity(0.8)),
          ),
          if (hasBoth) ...[
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
          });
          _loadSubjects();
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

  Widget _buildSubjectTile(BuildContext context, Map<String, dynamic> subject) {
    return _FAANGSubjectTile(
      title: subject['name'],
      icon: subject['icon'],
      color: subject['color'],
      onTap: () {
        final auth = context.read<AuthProvider>();
        final student = auth.currentStudent;
        final isCoaching = _selectedWingFilter == 'coaching';
        final targetClassId = isCoaching 
            ? (student?.coachingClassId?.isNotEmpty == true ? student?.coachingClassId : student?.classId)
            : student?.classId;

        if (widget.materialType.toUpperCase() == 'NCERT') {
          _navigateTo(
            context,
            BookSelectionScreen(
              subjectName: subject['name'],
              materialType: widget.materialType,
              books: subject['localBooks'] ?? [],
            ),
          );
        } else {
          _navigateTo(
            context,
            ResourceListScreen(
              classId: targetClassId ?? widget.classId,
              subjectId: subject['id'],
              subjectName: subject['name'],
              materialType: widget.materialType,
            ),
          );
        }
      },
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: animation.drive(Tween(begin: const Offset(0, 0.05), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutQuart))),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}

class _FAANGSubjectTile extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FAANGSubjectTile({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  State<_FAANGSubjectTile> createState() => _FAANGSubjectTileState();
}

class _FAANGSubjectTileState extends State<_FAANGSubjectTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
color: AppTheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.border.withOpacity(0.4), width: 1.2),
          boxShadow: [
            BoxShadow(color: widget.color.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTapDown: (_) => _controller.forward(),
            onTapUp: (_) => _controller.reverse(),
            onTapCancel: () => _controller.reverse(),
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onTap();
            },
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: widget.color.withOpacity(0.12), shape: BoxShape.circle),
                    child: Icon(widget.icon, color: widget.color, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.textBase, letterSpacing: -0.3, height: 1.1),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
