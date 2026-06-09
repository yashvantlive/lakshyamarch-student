import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/academic_provider.dart';
import '../../providers/auth_provider.dart';
import 'pdf_viewer_screen.dart';

class ResourceListScreen extends StatefulWidget {
  final String classId;
  final String subjectId;
  final String subjectName;
  final String materialType;

  const ResourceListScreen({
    super.key,
    required this.classId,
    required this.subjectId,
    required this.subjectName,
    required this.materialType,
  });

  @override
  State<ResourceListScreen> createState() => _ResourceListScreenState();
}

class _ResourceListScreenState extends State<ResourceListScreen> {
  List<dynamic> _chapters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    setState(() => _isLoading = true);
    
    final academic = context.read<AcademicProvider>();
    final auth = context.read<AuthProvider>();
    
    final materials = await academic.fetchStudyMaterials(
      widget.classId, 
      widget.materialType, 
      auth.token ?? ''
    );

    // Find the material for this subject ID
    final material = materials.firstWhere(
      (m) => m['subjectId']['_id'] == widget.subjectId,
      orElse: () => null
    );

    if (material != null) {
      setState(() {
        _chapters = material['chapters'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.subjectName),
        elevation: 0,
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textBase,
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _chapters.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              itemCount: _chapters.length,
              itemBuilder: (context, index) {
                final chapter = _chapters[index];
                return _buildChapterCard(chapter);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text('No chapters found', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildChapterCard(dynamic chapter) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withOpacity(0.04), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), shape: BoxShape.circle),
          child: Text(
            '${chapter['chapterNo']}',
            style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 12),
          ),
        ),
        title: Text(
          chapter['chapterName'],
          style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textBase, fontSize: 14),
        ),
        subtitle: Text('Tap to view ${widget.materialType} PDF', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        trailing: Icon(LucideIcons.fileText, color: AppTheme.primary, size: 20),
        onTap: () {
          HapticFeedback.lightImpact();
          if (chapter['pdfLink'] != null && chapter['pdfLink'].isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) => PDFViewerScreen(
                  url: chapter['pdfLink'],
                  title: chapter['chapterName'],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
