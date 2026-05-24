import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/test.dart';
import '../theme/app_theme.dart';

class PastTestResultsSheet extends StatefulWidget {
  final Test test;

  const PastTestResultsSheet({super.key, required this.test});

  @override
  State<PastTestResultsSheet> createState() => _PastTestResultsSheetState();
}

class _PastTestResultsSheetState extends State<PastTestResultsSheet> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _results = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    try {
      final auth = context.read<AuthProvider>();
      if (auth.token == null) return;
      final results = await _api.getTestResults(widget.test.id, auth.token!);
      
      // Sort by rank or score
      results.sort((a, b) {
        final rankA = a['rank'] ?? 999;
        final rankB = b['rank'] ?? 999;
        return rankA.compareTo(rankB);
      });
      
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final currentStudentId = auth.currentStudent?.id ?? '';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Handle bar
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.test.title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textBase,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Full Class Leaderboard',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted.withOpacity(0.8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.trophy, color: AppTheme.primary, size: 24),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Motivational CTA based on performance
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildMotivationalCTA(currentStudentId),
          ),
          
          const SizedBox(height: 16),
          Divider(height: 1, color: AppTheme.border),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _results.isEmpty
                        ? const Center(child: Text('No results published yet.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final res = _results[index];
                              final bool isMe = res['studentId'] == currentStudentId;
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isMe ? AppTheme.primary.withOpacity(0.05) : AppTheme.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isMe ? AppTheme.primary : AppTheme.border.withOpacity(0.5),
                                    width: isMe ? 2.0 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isMe ? AppTheme.primary : AppTheme.background,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '#${res['rank'] ?? '-'}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                          color: isMe ? Colors.white : AppTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            res['studentName'] ?? 'Unknown',
                                            style: TextStyle(
                                              fontWeight: isMe ? FontWeight.w900 : FontWeight.bold,
                                              fontSize: 15,
                                              color: isMe ? AppTheme.primary : AppTheme.textBase,
                                            ),
                                          ),
                                          if (isMe) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              'This is you',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primary.withOpacity(0.8),
                                              ),
                                            ),
                                          ]
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${res['score']}/${widget.test.maxMarks}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                            color: isMe ? AppTheme.primary : AppTheme.textBase,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'MARKS',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textMuted,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Close',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMotivationalCTA(String studentId) {
    if (_isLoading || _results.isEmpty) return const SizedBox.shrink();
    
    // Find my rank
    int myRank = 999;
    double myPercent = 0.0;
    
    for (var r in _results) {
      if (r['studentId'] == studentId) {
        myRank = r['rank'] ?? 999;
        double maxMarks = widget.test.maxMarks > 0 ? widget.test.maxMarks.toDouble() : 1.0;
        double score = double.tryParse(r['score'].toString()) ?? 0.0;
        myPercent = score / maxMarks;
        break;
      }
    }
    
    String ctaMsg = "";
    Color ctaColor = AppTheme.primary;
    IconData ctaIcon = LucideIcons.trendingUp;
    
    if (myRank <= 3 || myPercent >= 0.8) {
      ctaMsg = "Outstanding performance! Keep up the excellent work and aim for consistency in upcoming tests.";
      ctaColor = Colors.green;
      ctaIcon = LucideIcons.star;
    } else if (myPercent >= 0.5) {
      ctaMsg = "Good effort, but there is room for improvement. Review your mistakes and join doubt sessions!";
      ctaColor = Colors.orange;
      ctaIcon = LucideIcons.alertCircle;
    } else {
      ctaMsg = "Don't lose heart! Put in more effort, analyze your weak areas, and attend extra doubt clearing sessions. You can do this!";
      ctaColor = AppTheme.danger;
      ctaIcon = LucideIcons.trendingDown;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ctaColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ctaColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ctaIcon, color: ctaColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ctaMsg,
              style: TextStyle(
                color: ctaColor.withOpacity(0.9),
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
