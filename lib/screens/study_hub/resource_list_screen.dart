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
  final List<dynamic>? localChapters;
  final String? localBookName;

  const ResourceListScreen({
    super.key,
    required this.classId,
    required this.subjectId,
    required this.subjectName,
    required this.materialType,
    this.localChapters,
    this.localBookName,
  });

  @override
  State<ResourceListScreen> createState() => _ResourceListScreenState();
}

class _ResourceListScreenState extends State<ResourceListScreen> {

  List<dynamic> _books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    if (widget.localChapters != null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    
    final academic = context.read<AcademicProvider>();
    final auth = context.read<AuthProvider>();
    
    final materials = await academic.fetchStudyMaterials(
      widget.classId, 
      widget.materialType, 
      auth.token ?? ''
    );

    // Find ALL materials for this subject ID
    final subjectBooks = materials.where(
      (m) => m['subjectId']['_id'] == widget.subjectId
    ).toList();

    setState(() {
      _books = subjectBooks;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.localBookName != null 
            ? '${widget.localBookName} - ${widget.materialType}' 
            : '${widget.subjectName} Books'),
        elevation: 0,
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textBase,
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : widget.localChapters != null
          ? _buildFlatChaptersList()
          : _books.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                itemCount: _books.length,
                itemBuilder: (context, index) {
                  final book = _books[index];
                  return _buildBookCard(book);
                },
              ),
    );
  }

  Widget _buildFlatChaptersList() {
    if (widget.localChapters!.isEmpty) {
      return Center(
        child: Text('No chapters uploaded yet.', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: widget.localChapters!.length,
      itemBuilder: (context, index) {
        final chapter = widget.localChapters![index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(color: AppTheme.primary.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: _buildChapterTile(chapter),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text('No books found for ${widget.subjectName}', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBookCard(dynamic book) {
    final chapters = book['chapters'] as List<dynamic>? ?? [];
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withOpacity(0.04), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(LucideIcons.bookOpen, color: AppTheme.primary, size: 20),
          ),
          title: Text(
            book['bookName'] ?? 'Unknown Book',
            style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textBase, fontSize: 15),
          ),
          subtitle: Text('${chapters.length} Chapters', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          children: chapters.isEmpty 
            ? [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("No chapters uploaded yet.", style: TextStyle(color: AppTheme.textMuted, fontStyle: FontStyle.italic)),
                )
              ]
            : chapters.map((chapter) => _buildChapterTile(chapter)).toList(),
        ),
      ),
    );
  }

  Widget _buildChapterTile(dynamic chapter) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 30, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Text(
          '${chapter['chapterNo']}',
          style: TextStyle(color: AppTheme.textBase, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
      title: Text(
        chapter['chapterName'],
        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textBase, fontSize: 13),
      ),
      trailing: chapter['pdfLink'] != null && chapter['pdfLink'].isNotEmpty
          ? Icon(LucideIcons.externalLink, color: AppTheme.primary, size: 16)
          : Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text("Coming Soon", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
      onTap: () {
        if (chapter['pdfLink'] != null && chapter['pdfLink'].isNotEmpty) {
          HapticFeedback.lightImpact();
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
    );
  }
}
