import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';
import 'study_hub/class_selection_screen.dart';
import 'study_hub/subject_selection_screen.dart';
import 'doubt_room_screen.dart';

class StudyMaterialScreen extends StatefulWidget {
  const StudyMaterialScreen({super.key});

  @override
  State<StudyMaterialScreen> createState() => _StudyMaterialScreenState();
}

class _StudyMaterialScreenState extends State<StudyMaterialScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final screenHeight = MediaQuery.of(context).size.height;
    const appBarHeight = 120.0;
    final gridHeight = screenHeight - appBarHeight - MediaQuery.of(context).padding.top - 40;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildCenteredAppBar(auth.activeWingMode),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: (MediaQuery.of(context).size.width / 2) / (gridHeight / 4.2),
                  children: [
                    _buildHubTile(
                      context,
                      title: 'NCERT Books',
                      icon: LucideIcons.bookOpen,
                      color: AppTheme.primary,
                      type: 'NCERT',
                    ),
                    _buildHubTile(
                      context,
                      title: 'Daily Practice',
                      icon: LucideIcons.edit,
                      color: AppTheme.success,
                      type: 'DPP',
                    ),
                    _buildHubTile(
                      context,
                      title: 'Expert Notes',
                      icon: LucideIcons.fileText,
                      color: AppTheme.warning,
                      type: 'Notes',
                    ),
                    _buildHubTile(
                      context,
                      title: 'Formula Bank',
                      icon: LucideIcons.calculator,
                      color: Colors.purple,
                      type: 'Notes',
                    ),
                    _buildHubTile(
                      context,
                      title: 'Prev. Year',
                      icon: LucideIcons.history,
                      color: Colors.deepOrange,
                      type: 'NCERT',
                    ),
                    _buildHubTile(
                      context,
                      title: 'Video Library',
                      icon: LucideIcons.playCircle,
                      color: Colors.red,
                      type: 'NCERT',
                    ),
                    _buildHubTile(
                      context,
                      title: 'Doubt Room',
                      icon: LucideIcons.helpCircle,
                      color: Colors.indigo,
                      type: 'NCERT',
                    ),
                    _buildHubTile(
                      context,
                      title: 'Syllabus',
                      icon: LucideIcons.clipboardList,
                      color: Colors.teal,
                      type: 'NCERT',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
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
            'Integrated Study Hub',
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

  Widget _buildHubTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String type,
  }) {
    return Container(
      decoration: BoxDecoration(
color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            final auth = context.read<AuthProvider>();
            final student = auth.currentStudent;
            
            if (student == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student profile not found')));
              return;
            }

            if (title == 'Doubt Room') {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const DoubtRoomScreen()));
               return;
            }

            final isCoaching = auth.activeWingMode == 'coaching';
            final cId = isCoaching ? student.coachingClassId : student.classId;
            final cName = isCoaching ? student.coachingClass : student.className;
            
            if (cId == null || cId.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No class assigned to you for this wing.')),
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => SubjectSelectionScreen(
                classId: cId,
                className: cName ?? 'Your Class',
                materialType: type,
              )),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textBase,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
