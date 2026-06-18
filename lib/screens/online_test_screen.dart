import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/online_paper.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';
import '../services/app_cache.dart';

class OnlineTestScreen extends StatefulWidget {
  const OnlineTestScreen({super.key});

  @override
  State<OnlineTestScreen> createState() => _OnlineTestScreenState();
}

class _OnlineTestScreenState extends State<OnlineTestScreen> {
  // Navigation View State
  String _view = 'dashboard'; // 'dashboard', 'subcategories', 'subjects', 'papers', 'instructions', 'exam', 'detailed_result'

  // Manifest and Selection States
  List<OnlinePaper> _allPapers = [];
  bool _loadingPapers = false;
  String? _papersError;

  String? _selectedCategory; // 'BOARD', 'NCERT', 'PYQ', 'AITS'
  String? _selectedGrade; // '11', '12' for BOARD
  String? _selectedSubcategory; // 'jee_main', 'jee_advance', 'neet' for PYQ/AITS
  String? _selectedSubject; // 'physics', 'chemistry', 'maths', 'biology' for BOARD/NCERT
  OnlinePaper? _selectedPaper;

  // Exam Player Session State
  OnlinePaperDetail? _activePaperDetail;
  bool _loadingPaperDetail = false;
  String? _paperDetailError;

  int _currentQuestionIndex = 0;
  Map<String, String> _selectedAnswers = {};
  Map<String, String> _questionStatuses = {}; // 'unvisited', 'visited', 'saved', 'review', 'saved-review'
  int _timeRemaining = 0; // in seconds
  Timer? _timer;
  String _language = 'english'; // 'english', 'hindi'
  bool _examSubmitted = false;

  // History & Statistics States
  List<dynamic> _examHistory = [];
  int _totalAttempts = 0;
  double _avgScore = 0.0;
  int _highestScore = 0;

  // Selected Result for Review State
  Map<String, dynamic>? _selectedHistoryItem;
  String _resultLanguage = 'english';

  // Base URL for fetching papers manifest & questions
  static const String _remoteBaseUrl = 'https://raw.githubusercontent.com/yashvantlive/lakshyamarch-test/main/public';

  @override
  void initState() {
    super.initState();
    _loadPapersManifest();
    _loadExamHistory();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // =========================================================================
  // DATA LOADING & CACHING METHODS
  // =========================================================================

  Future<void> _loadPapersManifest() async {
    setState(() {
      _loadingPapers = true;
      _papersError = null;
    });

    final cacheKey = 'online_papers_manifest';
    
    // 1. Try reading from AppCache (Hive)
    final cached = AppCache.instance.get(cacheKey);
    if (cached is List) {
      try {
        _allPapers = cached.map((item) => OnlinePaper.fromJson(Map<String, dynamic>.from(item as Map))).toList();
        setState(() {
          _loadingPapers = false;
        });
      } catch (e) {
        debugPrint('Failed to parse cached manifest: $e');
      }
    }

    // 2. Fetch fresh manifest silently/actively
    try {
      final response = await http.get(Uri.parse('$_remoteBaseUrl/papers_manifest.json')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List decoded = jsonDecode(response.body);
        _allPapers = decoded.map((item) => OnlinePaper.fromJson(Map<String, dynamic>.from(item as Map))).toList();
        // Save to cache
        await AppCache.instance.set(cacheKey, decoded, ttl: const Duration(hours: 24));
        if (mounted) {
          setState(() {
            _loadingPapers = false;
          });
        }
      } else {
        throw Exception('Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to fetch online papers manifest: $e');
      if (mounted) {
        setState(() {
          _loadingPapers = false;
          if (_allPapers.isEmpty) {
            _papersError = 'Failed to load online mock papers. Please check your internet connection and retry.';
          }
        });
      }
    }
  }

  Future<void> _loadExamHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyStr = prefs.getString('online_exam_history');
    if (historyStr != null && historyStr.isNotEmpty) {
      try {
        final List historyList = jsonDecode(historyStr);
        setState(() {
          _examHistory = historyList;
          _totalAttempts = historyList.length;
          
          if (_totalAttempts > 0) {
            int totalScore = 0;
            int maxScore = -9999;
            for (var item in historyList) {
              final score = (item['score'] ?? 0) as int;
              totalScore += score;
              if (score > maxScore) {
                maxScore = score;
              }
            }
            _avgScore = totalScore / _totalAttempts;
            _highestScore = maxScore;
          } else {
            _avgScore = 0.0;
            _highestScore = 0;
          }
        });
      } catch (e) {
        debugPrint('Error loading exam history: $e');
      }
    }
  }

  Future<void> _saveExamToHistory(Map<String, dynamic> historyItem) async {
    final prefs = await SharedPreferences.getInstance();
    final historyList = List<dynamic>.from(_examHistory)..add(historyItem);
    await prefs.setString('online_exam_history', jsonEncode(historyList));
    _loadExamHistory();
  }

  Future<void> _loadPaperDetail(OnlinePaper paper) async {
    setState(() {
      _loadingPaperDetail = true;
      _paperDetailError = null;
      _activePaperDetail = null;
    });

    final cleanJsonPath = paper.jsonPath.startsWith('/') ? paper.jsonPath.substring(1) : paper.jsonPath;
    final url = '$_remoteBaseUrl/$cleanJsonPath';

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final paperDetail = OnlinePaperDetail.fromJson(Map<String, dynamic>.from(decoded as Map));
        
        if (mounted) {
          setState(() {
            _activePaperDetail = paperDetail;
            _loadingPaperDetail = false;
            
            // Check for in-progress autosave
            _checkAndLoadAutosave(paperDetail);
          });
        }
      } else {
        throw Exception('Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to load paper questions: $e');
      if (mounted) {
        setState(() {
          _loadingPaperDetail = false;
          _paperDetailError = 'Failed to load paper questions. Please check your internet connection.';
        });
      }
    }
  }

  // =========================================================================
  // AUTOSAVE & RESTORE METHODS
  // =========================================================================

  Future<void> _checkAndLoadAutosave(OnlinePaperDetail paperDetail) async {
    final prefs = await SharedPreferences.getInstance();
    final autosaveKey = 'online_attempt_${paperDetail.paperId}';
    final savedStr = prefs.getString(autosaveKey);
    
    if (savedStr != null && savedStr.isNotEmpty) {
      try {
        final Map<String, dynamic> parsed = jsonDecode(savedStr);
        final Map<String, String> answers = Map<String, String>.from(parsed['answers'] ?? {});
        final Map<String, String> statuses = Map<String, String>.from(parsed['statuses'] ?? {});
        final int currentIndex = parsed['currentIndex'] ?? 0;
        final int timeRemaining = parsed['timeRemaining'] ?? (paperDetail.duration * 60);

        // Ask user to resume or start fresh
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogCtx) => AlertDialog(
              title: const Text('In-Progress Exam Found', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Text('You have an unfinished attempt for "${paperDetail.title}". Do you want to resume?'),
              actions: [
                TextButton(
                  onPressed: () async {
                    // Start fresh
                    await prefs.remove(autosaveKey);
                    Navigator.pop(dialogCtx);
                    _initializeFreshExam(paperDetail);
                  },
                  child: const Text('Start Fresh', style: TextStyle(color: AppTheme.danger)),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Resume
                    Navigator.pop(dialogCtx);
                    setState(() {
                      _selectedAnswers = answers;
                      _questionStatuses = statuses;
                      _currentQuestionIndex = currentIndex;
                      _timeRemaining = timeRemaining;
                      _examSubmitted = false;
                      _view = 'exam';
                      _startTimer();
                    });
                  },
                  child: const Text('Resume Attempt'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        debugPrint('Error parsing autosave: $e');
        _initializeFreshExam(paperDetail);
      }
    } else {
      _initializeFreshExam(paperDetail);
    }
  }

  void _initializeFreshExam(OnlinePaperDetail paperDetail) {
    setState(() {
      _selectedAnswers = {};
      _questionStatuses = {};
      for (var q in paperDetail.questions) {
        _questionStatuses[q.id] = 'unvisited';
      }
      _questionStatuses[paperDetail.questions.first.id] = 'visited';
      _currentQuestionIndex = 0;
      _timeRemaining = paperDetail.duration * 60;
      _examSubmitted = false;
      _view = 'exam';
      _startTimer();
      _saveAutosave();
    });
  }

  Future<void> _saveAutosave() async {
    if (_activePaperDetail == null || _examSubmitted) return;
    final prefs = await SharedPreferences.getInstance();
    final attemptData = {
      'answers': _selectedAnswers,
      'statuses': _questionStatuses,
      'currentIndex': _currentQuestionIndex,
      'timeRemaining': _timeRemaining
    };
    await prefs.setString('online_attempt_${_activePaperDetail!.paperId}', jsonEncode(attemptData));
  }

  Future<void> _clearAutosave(String paperId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('online_attempt_$paperId');
  }

  // =========================================================================
  // TIMER & EXAM FLOW
  // =========================================================================

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeRemaining <= 1) {
        _timer?.cancel();
        _submitExam(isTimeout: true);
      } else {
        setState(() {
          _timeRemaining--;
        });
        if (t.tick % 5 == 0) {
          _saveAutosave();
        }
      }
    });
  }

  void _submitExam({bool isTimeout = false}) {
    _timer?.cancel();
    setState(() {
      _examSubmitted = true;
    });

    final paper = _activePaperDetail!;
    int score = 0;
    int correctCount = 0;
    int wrongCount = 0;
    int unattemptedCount = 0;

    List<Map<String, dynamic>> questionsReview = [];

    for (int i = 0; i < paper.questions.length; i++) {
      final q = paper.questions[i];
      final selected = _selectedAnswers[q.id];
      final status = _questionStatuses[q.id];
      final isAttempted = status == 'saved' || status == 'saved-review';

      bool isCorrect = false;
      if (isAttempted && selected != null) {
        if (q.type == 'MCQ') {
          isCorrect = int.tryParse(selected) == q.correctAnswer;
        } else {
          isCorrect = double.tryParse(selected) == double.tryParse(q.correctAnswer.toString());
        }
      }

      String reviewStatus = 'Unattempted';
      if (isAttempted) {
        if (isCorrect) {
          score += 4;
          correctCount++;
          reviewStatus = 'Correct';
        } else {
          score -= 1;
          wrongCount++;
          reviewStatus = 'Wrong';
        }
      } else {
        unattemptedCount++;
      }

      questionsReview.add({
        'questionId': q.questionId,
        'id': q.id,
        'type': q.type,
        'imagePath': q.imagePath,
        'selectedAnswer': selected ?? '---',
        'correctAnswer': q.correctAnswer.toString(),
        'status': reviewStatus,
      });
    }

    final student = context.read<AuthProvider>().currentStudent;

    final historyItem = {
      'id': '${paper.paperId}_${DateTime.now().millisecondsSinceEpoch}',
      'paperId': paper.paperId,
      'title': paper.title,
      'category': paper.category,
      'grade': paper.grade,
      'subject': paper.subject,
      'duration': paper.duration,
      'date': DateTime.now().toIso8601String().split('T')[0],
      'score': score,
      'totalQuestions': paper.totalQuestions,
      'correct': correctCount,
      'wrong': wrongCount,
      'unattempted': unattemptedCount,
      'totalTimeUsed': (paper.duration * 60) - _timeRemaining,
      'selectedAnswers': _selectedAnswers,
      'questions': questionsReview,
      'candidateName': student?.name ?? 'Candidate',
      'candidateRoll': student?.admissionNo ?? '---'
    };

    // Save history
    _saveExamToHistory(historyItem);
    
    // Clear autosave
    _clearAutosave(paper.paperId);

    // Navigate to Detailed Results
    setState(() {
      _selectedHistoryItem = historyItem;
      _resultLanguage = 'english';
      _view = 'detailed_result';
    });
  }

  // =========================================================================
  // VIEW NAVIGATION & FILTER HELPER METHODS
  // =========================================================================

  void _navigateBack() {
    setState(() {
      if (_view == 'subcategories') {
        _view = 'dashboard';
        _selectedCategory = null;
      } else if (_view == 'subjects') {
        if (_selectedCategory == 'NCERT') {
          _view = 'dashboard';
          _selectedCategory = null;
        } else {
          _view = 'subcategories';
        }
        _selectedGrade = null;
        _selectedSubcategory = null;
      } else if (_view == 'papers') {
        _view = 'subjects';
        _selectedSubject = null;
      } else if (_view == 'instructions') {
        _view = 'papers';
      }
    });
  }

  void _handleCategorySelect(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'NCERT') {
        _view = 'subjects';
      } else {
        _view = 'subcategories';
      }
    });
  }

  List<OnlinePaper> _getFilteredPapers() {
    return _allPapers.where((paper) {
      if (paper.category != _selectedCategory) return false;
      
      if (_selectedCategory == 'BOARD') {
        if (paper.grade != _selectedGrade) return false;
        if (paper.subject != _selectedSubject) return false;
      } else if (_selectedCategory == 'NCERT') {
        if (paper.subject != _selectedSubject) return false;
      } else if (_selectedCategory == 'PYQ' || _selectedCategory == 'AITS') {
        if (paper.subject != _selectedSubcategory) return false; // manifest subject stores jee_main, jee_advance, neet
      }
      return true;
    }).toList();
  }

  String _getCategoryTitle() {
    if (_selectedCategory == 'BOARD') return 'BOARD Exams (Class $_selectedGrade)';
    if (_selectedCategory == 'NCERT') return 'NCERT Series';
    if (_selectedCategory == 'PYQ') return 'PYQ - ${_selectedSubcategory?.toUpperCase().replaceAll('_', ' ')}';
    if (_selectedCategory == 'AITS') return 'AITS - ${_selectedSubcategory?.toUpperCase().replaceAll('_', ' ')}';
    return '';
  }

  String _formatTimerText(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _getLanguageImagePath(String basePath, String activeLanguage) {
    // Resolve prefix folder name
    final subjectFolder = _activePaperDetail!.subject.replaceAll('_', ' ');
    final cat = _activePaperDetail!.category;
    final grade = _activePaperDetail!.grade;

    String dirPrefix = '';
    if (cat == 'BOARD') {
      dirPrefix = '/BOARD/$grade/quiz/$subjectFolder/Quiz/';
    } else if (cat == 'NCERT') {
      dirPrefix = '/NCERT/quiz/$subjectFolder/Quiz/';
    } else if (cat == 'PYQ') {
      dirPrefix = '/PYQ/quiz/$subjectFolder/Quiz/';
    } else if (cat == 'AITS') {
      dirPrefix = '/AITS/quiz/$subjectFolder/Quiz/';
    }

    String fullPath = '$dirPrefix$basePath'.replaceAll(RegExp(r'/+'), '/');
    if (!fullPath.startsWith('/')) {
      fullPath = '/$fullPath';
    }

    if (activeLanguage == 'hindi') {
      fullPath = fullPath.replaceAll('English', 'Hindi').replaceAll('english', 'hindi');
    }
    return '$_remoteBaseUrl$fullPath';
  }

  // =========================================================================
  // EXAM PALETTE & CONTROLLER ACTIONS
  // =========================================================================

  void _handleSelectQuestion(int index) {
    final currentQ = _activePaperDetail!.questions[_currentQuestionIndex];
    
    setState(() {
      if (_questionStatuses[currentQ.id] == 'unvisited') {
        _questionStatuses[currentQ.id] = 'visited';
      }
      
      _currentQuestionIndex = index;
      
      final targetQ = _activePaperDetail!.questions[index];
      if (_questionStatuses[targetQ.id] == 'unvisited') {
        _questionStatuses[targetQ.id] = 'visited';
      }
    });
    _saveAutosave();
  }

  void _handleSaveNext() {
    final currentQ = _activePaperDetail!.questions[_currentQuestionIndex];
    final ans = _selectedAnswers[currentQ.id];
    if (ans == null || ans.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentQ.type == 'MCQ' ? 'Please select an option.' : 'Please enter numerical answer.'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _questionStatuses[currentQ.id] = 'saved';
      if (_currentQuestionIndex < _activePaperDetail!.questions.length - 1) {
        _handleSelectQuestion(_currentQuestionIndex + 1);
      }
    });
    _saveAutosave();
  }

  void _handleMarkForReview() {
    final currentQ = _activePaperDetail!.questions[_currentQuestionIndex];
    final ans = _selectedAnswers[currentQ.id];
    final hasAns = ans != null && ans.trim().isNotEmpty;

    setState(() {
      _questionStatuses[currentQ.id] = hasAns ? 'saved-review' : 'review';
      if (_currentQuestionIndex < _activePaperDetail!.questions.length - 1) {
        _handleSelectQuestion(_currentQuestionIndex + 1);
      }
    });
    _saveAutosave();
  }

  void _handleClearResponse() {
    final currentQ = _activePaperDetail!.questions[_currentQuestionIndex];
    setState(() {
      _selectedAnswers.remove(currentQ.id);
      _questionStatuses[currentQ.id] = 'visited';
    });
    _saveAutosave();
  }

  // Custom Numerical Keyboard Input
  void _handleKeypadInput(String key) {
    final currentQ = _activePaperDetail!.questions[_currentQuestionIndex];
    final currentVal = _selectedAnswers[currentQ.id] ?? '';

    setState(() {
      if (key == 'clear') {
        _selectedAnswers[currentQ.id] = '';
      } else if (key == 'backspace') {
        if (currentVal.isNotEmpty) {
          _selectedAnswers[currentQ.id] = currentVal.substring(0, currentVal.length - 1);
        }
      } else if (key == '-') {
        if (currentVal.startsWith('-')) {
          _selectedAnswers[currentQ.id] = currentVal.substring(1);
        } else {
          _selectedAnswers[currentQ.id] = '-$currentVal';
        }
      } else {
        if (key == '.' && currentVal.contains('.')) return;
        _selectedAnswers[currentQ.id] = currentVal + key;
      }
    });
  }

  // =========================================================================
  // VIEW BUILDERS
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    // If active in exam player
    if (_view == 'exam' && _activePaperDetail != null) {
      return _buildExamPlayerScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final auth = context.read<AuthProvider>();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      color: AppTheme.surface,
      border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (_view != 'dashboard')
                IconButton(
                  onPressed: _navigateBack,
                  icon: Icon(LucideIcons.arrowLeft, color: AppTheme.textBase),
                ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedBrandHeader(wingMode: auth.activeWingMode),
                  Text(
                    'Practice Hub Portal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textBase,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_view == 'dashboard')
            ElevatedButton.icon(
              onPressed: _showPerformanceHistoryModal,
              icon: const Icon(LucideIcons.barChart2, size: 14),
              label: const Text('Performance'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_view) {
      case 'dashboard':
        return _buildDashboardView();
      case 'subcategories':
        return _buildSubcategorySelectionView();
      case 'subjects':
        return _buildSubjectSelectionView();
      case 'papers':
        return _buildPapersListView();
      case 'instructions':
        return _buildInstructionsView();
      case 'detailed_result':
        return _buildDetailedResultView();
      default:
        return const Center(child: Text('View not found.'));
    }
  }

  // --- VIEW 1: DASHBOARD ---
  Widget _buildDashboardView() {
    if (_loadingPapers) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PremiumActivityIndicator(),
            SizedBox(height: 12),
            Text('Syncing Mock Test Center...'),
          ],
        ),
      );
    }

    if (_papersError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertTriangle, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                _papersError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadPapersManifest,
                child: const Text('Retry Connection'),
              )
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadPapersManifest();
        await _loadExamHistory();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Panel
            _buildStatsCard(),
            const SizedBox(height: 24),

            // Category Picker Headers
            const Text(
              'Choose Assessment Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.extrabold, letterSpacing: -0.5),
            ),
            const SizedBox(height: 12),

            // BOARD, NCERT, PYQ responsive cards
            Row(
              children: [
                Expanded(child: _buildCategoryCard('BOARD', '🎓', 'BOARD EXAMS', 'Class 11 & 12 Syllabus')),
                const SizedBox(width: 8),
                Expanded(child: _buildCategoryCard('NCERT', '📚', 'NCERT SERIES', 'Chapter-wise MCQ Banks')),
                const SizedBox(width: 8),
                Expanded(child: _buildCategoryCard('PYQ', '⏳', 'PREVIOUS YEARS', 'Past 10 Yrs Papers')),
              ],
            ),
            const SizedBox(height: 24),

            // AITS Dedicated Row
            const Text(
              'All India Test Series (AITS)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.extrabold, letterSpacing: -0.5),
            ),
            const SizedBox(height: 12),
            _buildAitsBannerCard(),
            const SizedBox(height: 28),

            // Informative Alerts & Guides Section
            const Text(
              'Exam Alerts & Prep Guides',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.extrabold, letterSpacing: -0.5),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildGuideCard(
                    title: 'NEET UG Shifting to CBT',
                    badge: 'PATTERN ALERT 🚨',
                    description: 'Read the Supreme Court panels recommendations on converting OMR to computer-based testing.',
                    onTap: _showNeetCbtGuide,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGuideCard(
                    title: 'Exam Day Strategies',
                    badge: 'SCORE BOOSTER 💡',
                    description: 'Master time-allocation, the Three-Pass solving technique, and virtual calculator tips.',
                    onTap: _showCbtStrategyGuide,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [AppTheme.primary, Colors.black87],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('INTERACTIVE PRACTICE PORTAL', style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
                child: const Text('OFFLINE STATS', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatDetail('Attempts', _totalAttempts.toString()),
              _buildStatDetail('Avg. Score', _avgScore.toStringAsFixed(1)),
              _buildStatDetail('Highest', _highestScore.toString()),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildCategoryCard(String id, String icon, String title, String subtitle) {
    return InkWell(
      onTap: () => _handleCategorySelect(id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 135,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textBase),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 9, color: AppTheme.textMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAitsBannerCard() {
    return InkWell(
      onTap: () => _handleCategorySelect('AITS'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B1815), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE9B019), width: 1.5),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFE9B019), borderRadius: BorderRadius.circular(8)),
                    child: const Text('ELITE NATIONAL LEVEL', style: TextStyle(color: Colors.black87, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'All India Test Series',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.extrabold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Simulated online CBT matching exact NTA difficulty criteria with bilingual questions.',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
              child: const Icon(LucideIcons.trophy, size: 28, color: Color(0xFFE9B019)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGuideCard({
    required String title,
    required String badge,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(badge, style: TextStyle(fontSize: 8, fontWeight: FontWeight.extrabold, color: AppTheme.primary)),
                const SizedBox(height: 6),
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textBase), maxLines: 1),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(fontSize: 9.5, color: AppTheme.textMuted, height: 1.3), maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Read Guide →', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- VIEW 2: SUBCATEGORY SELECTION ---
  Widget _buildSubcategorySelectionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _selectedCategory == 'BOARD' ? 'Select Class / Grade' : 'Select Stream / Target Exam',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textBase),
          ),
          const SizedBox(height: 24),
          if (_selectedCategory == 'BOARD') ...[
            _buildSelectionRowItem('Class 11th', 'Board mock papers for XI science syllabus.', () {
              setState(() {
                _selectedGrade = '11';
                _view = 'subjects';
              });
            }),
            const SizedBox(height: 16),
            _buildSelectionRowItem('Class 12th', 'Board assessment papers for XII boards.', () {
              setState(() {
                _selectedGrade = '12';
                _view = 'subjects';
              });
            }),
          ] else ...[
            _buildSelectionRowItem('JEE Main', 'Joint Entrance Exam Mains simulated practice.', () {
              setState(() {
                _selectedSubcategory = 'jee_main';
                _view = 'papers';
              });
            }),
            const SizedBox(height: 16),
            _buildSelectionRowItem('JEE Advanced', 'Advanced level conceptual assessment test sheets.', () {
              setState(() {
                _selectedSubcategory = 'jee_advance';
                _view = 'papers';
              });
            }),
            const SizedBox(height: 16),
            _buildSelectionRowItem('NEET UG', 'Medical stream biology, chemistry, physics mocks.', () {
              setState(() {
                _selectedSubcategory = 'neet';
                _view = 'papers';
              });
            }),
          ]
        ],
      ),
    );
  }

  Widget _buildSelectionRowItem(String title, String desc, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border, width: 1.2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textBase)),
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  // --- VIEW 3: SUBJECT SELECTION ---
  Widget _buildSubjectSelectionView() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      padding: const EdgeInsets.all(24),
      children: [
        _buildSubjectGridCard('physics', '⚡', 'Physics', 'Mechanics, Optics'),
        _buildSubjectGridCard('chemistry', '🧪', 'Chemistry', 'Organic, Inorganic'),
        _buildSubjectGridCard('maths', '📐', 'Mathematics', 'Calculus, Algebra'),
        _buildSubjectGridCard('biology', '🧬', 'Biology', 'Zoology, Botany'),
      ],
    );
  }

  Widget _buildSubjectGridCard(String id, String emoji, String title, String sub) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedSubject = id;
          _view = 'papers';
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border, width: 1),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textBase)),
            const SizedBox(height: 4),
            Text(sub, style: TextStyle(fontSize: 10, color: AppTheme.textMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // --- VIEW 4: PAPERS LIST ---
  Widget _buildPapersListView() {
    final filtered = _getFilteredPapers();
    
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: AppTheme.surface,
          child: Text(
            '${_getCategoryTitle()} Mock Sheets (${filtered.length})',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textBase),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.fileQuestion, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text('No mock papers found for selected criteria.', style: TextStyle(color: AppTheme.textMuted)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final paper = filtered[idx];
                    return _buildPaperListItemCard(paper);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPaperListItemCard(OnlinePaper paper) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(paper.category.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 0.5)),
              Row(
                children: [
                  Icon(LucideIcons.clock, size: 10, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text('${paper.duration} Mins', style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(paper.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textBase)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${paper.totalQuestions} Questions', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedPaper = paper;
                    _view = 'instructions';
                  });
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(100, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Launch', style: TextStyle(fontSize: 12)),
              )
            ],
          )
        ],
      ),
    );
  }

  // --- VIEW 5: INSTRUCTIONS ---
  Widget _buildInstructionsView() {
    if (_loadingPaperDetail) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PremiumActivityIndicator(),
            SizedBox(height: 12),
            Text('Loading exam setup...'),
          ],
        ),
      );
    }

    if (_paperDetailError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertTriangle, size: 48, color: AppTheme.danger),
              const SizedBox(height: 12),
              Text(_paperDetailError!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _loadPaperDetail(_selectedPaper!),
                child: const Text('Retry'),
              )
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedPaper!.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInstructionMeta(LucideIcons.clock, 'DURATION', '${_selectedPaper!.duration} Mins'),
              const SizedBox(width: 24),
              _buildInstructionMeta(LucideIcons.fileText, 'QUESTIONS', '${_selectedPaper!.totalQuestions} Total'),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 24),
          const Text('GENERAL INSTRUCTIONS:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          _buildInstructionText('1. Total duration of this mock exam is ${_selectedPaper!.duration} minutes.'),
          _buildInstructionText('2. Every correct answer earns +4 Marks.'),
          _buildInstructionText('3. Incorrect answers trigger a negative marking of -1 Mark.'),
          _buildInstructionText('4. Unattempted questions fetch 0 marks.'),
          _buildInstructionText('5. Do not close or lock the application during the exam. The progress will auto-save but the timer continues in real-time.'),
          _buildInstructionText('6. Choose preferred rendering language for the questions in the selector below (can be toggled in the exam player too).'),
          const SizedBox(height: 28),
          
          // Language selection
          const Text('Select Exam Language:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('English', style: TextStyle(fontWeight: FontWeight.bold))),
                  selected: _language == 'english',
                  onSelected: (val) {
                    if (val) setState(() => _language = 'english');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('हिन्दी / Hindi', style: TextStyle(fontWeight: FontWeight.bold))),
                  selected: _language == 'hindi',
                  onSelected: (val) {
                    if (val) setState(() => _language = 'hindi');
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              _loadPaperDetail(_selectedPaper!);
            },
            child: const Text('Start Assessment'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionMeta(IconData icon, String label, String val) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 8, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
            Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textBase)),
          ],
        )
      ],
    );
  }

  Widget _buildInstructionText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted, height: 1.4),
      ),
    );
  }

  // --- VIEW 6: TIMED EXAM PLAYER ---
  Widget _buildExamPlayerScreen() {
    final paper = _activePaperDetail!;
    final currentQ = paper.questions[_currentQuestionIndex];
    final selectedAns = _selectedAnswers[currentQ.id];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black87,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(paper.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            Row(
              children: [
                const Icon(LucideIcons.clock, size: 12, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  _formatTimerText(_timeRemaining),
                  style: const TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                )
              ],
            )
          ],
        ),
        actions: [
          // Language Switcher
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                _buildLangButton('EN', 'english'),
                _buildLangButton('HN', 'hindi'),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              _showConfirmSubmitDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(80, 36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Submit', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Question Image Viewer
            Expanded(
              flex: 4,
              child: Container(
                color: Colors.white,
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                child: InteractiveViewer(
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      _getLanguageImagePath(currentQ.imagePath, _language),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: PremiumActivityIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.imageCrash, color: Colors.grey, size: 36),
                              const SizedBox(height: 8),
                              Text('Failed to load question image.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            
            // Selected Option / Keyboard Control
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: Border(top: BorderSide(color: AppTheme.border, width: 1.2)),
                ),
                child: Column(
                  children: [
                    // Heading / Question Type
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Question ${_currentQuestionIndex + 1} of ${paper.totalQuestions}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textBase),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              currentQ.type.toUpperCase(),
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primary),
                            ),
                          )
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    
                    // Option inputs
                    Expanded(
                      child: currentQ.type == 'MCQ' 
                          ? _buildMcqOptionSelector(selectedAns) 
                          : _buildNumericalKeypad(selectedAns),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Action Controls
            Container(
              padding: const EdgeInsets.all(12),
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.border)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: _handleClearResponse,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textBase,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(color: AppTheme.border),
                    ),
                    child: const Text('Clear', style: TextStyle(fontSize: 12)),
                  ),
                  OutlinedButton(
                    onPressed: _handleMarkForReview,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: const BorderSide(color: Colors.purple),
                    ),
                    child: const Text('Mark Review', style: TextStyle(fontSize: 12)),
                  ),
                  ElevatedButton(
                    onPressed: _handleSaveNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(110, 42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Save & Next', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            
            // Drawer-like Bottom Question Navigation Palette
            _buildHorizontalQuestionPalette(paper),
          ],
        ),
      ),
    );
  }

  Widget _buildLangButton(String text, String langCode) {
    final isSelected = _language == langCode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _language = langCode;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text, style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMcqOptionSelector(String? selectedAns) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            children: [
              Expanded(child: _buildOptionButton('1', 'Option A', selectedAns)),
              const SizedBox(width: 16),
              Expanded(child: _buildOptionButton('2', 'Option B', selectedAns)),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildOptionButton('3', 'Option C', selectedAns)),
              const SizedBox(width: 16),
              Expanded(child: _buildOptionButton('4', 'Option D', selectedAns)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(String value, String label, String? selectedAns) {
    final isSelected = selectedAns == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAnswers[_activePaperDetail!.questions[_currentQuestionIndex].id] = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 20,
              width: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.primary : Colors.transparent,
                border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.textMuted),
              ),
              alignment: Alignment.center,
              child: isSelected ? const Icon(LucideIcons.check, size: 12, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected ? AppTheme.primary : AppTheme.textBase,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNumericalKeypad(String? selectedAns) {
    return Column(
      children: [
        // Answer box
        Container(
          width: double.infinity,
          color: AppTheme.background,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('YOUR ANSWER: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              Text(
                (selectedAns == null || selectedAns.isEmpty) ? '___' : selectedAns,
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: (selectedAns == null || selectedAns.isEmpty) ? AppTheme.textMuted : AppTheme.primary,
                  fontFamily: 'monospace'
                ),
              ),
            ],
          ),
        ),
        
        // Keypad grid
        Expanded(
          child: Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 5,
              childAspectRatio: 1.5,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              children: [
                _buildKeypadKey('1'),
                _buildKeypadKey('2'),
                _buildKeypadKey('3'),
                _buildKeypadKey('-'),
                _buildKeypadIconKey(LucideIcons.backspace, 'backspace'),
                
                _buildKeypadKey('4'),
                _buildKeypadKey('5'),
                _buildKeypadKey('6'),
                _buildKeypadKey('.'),
                _buildKeypadIconKey(LucideIcons.trash2, 'clear'),
                
                _buildKeypadKey('7'),
                _buildKeypadKey('8'),
                _buildKeypadKey('9'),
                _buildKeypadKey('0'),
                const SizedBox.shrink(), // placeholder
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildKeypadKey(String val) {
    return InkWell(
      onTap: () => _handleKeypadInput(val),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        alignment: Alignment.center,
        child: Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textBase)),
      ),
    );
  }

  Widget _buildKeypadIconKey(IconData icon, String action) {
    return InkWell(
      onTap: () => _handleKeypadInput(action),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: action == 'clear' ? AppTheme.danger : AppTheme.textBase, size: 18),
      ),
    );
  }

  Widget _buildHorizontalQuestionPalette(OnlinePaperDetail paper) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black87,
        border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: paper.questions.length,
        itemBuilder: (context, idx) {
          final q = paper.questions[idx];
          final status = _questionStatuses[q.id] ?? 'unvisited';
          final isSelected = _currentQuestionIndex == idx;
          
          Color bgColor = Colors.white12;
          Color borderCol = isSelected ? Colors.amber : Colors.transparent;
          Widget? badge;

          if (status == 'saved') {
            bgColor = const Color(0xFF10B981);
          } else if (status == 'review') {
            bgColor = Colors.purple.shade600;
          } else if (status == 'saved-review') {
            bgColor = Colors.purple.shade600;
            badge = Positioned(
              right: 2, top: 2,
              child: Container(height: 6, width: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
            );
          } else if (status == 'visited') {
            bgColor = Colors.red.shade600;
          }

          return GestureDetector(
            onTap: () => _handleSelectQuestion(idx),
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected ? Border.all(color: Colors.amber, width: 2) : Border.all(color: Colors.transparent),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${idx + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                    ),
                  ),
                ),
                if (badge != null) badge,
              ],
            ),
          );
        },
      ),
    );
  }

  void _showConfirmSubmitDialog() {
    // Count stats
    int answered = 0;
    int review = 0;
    int answeredReview = 0;
    int visited = 0;
    int unvisited = 0;

    _activePaperDetail!.questions.forEach((q) {
      final status = _questionStatuses[q.id];
      if (status == 'saved') answered++;
      else if (status == 'review') review++;
      else if (status == 'saved-review') answeredReview++;
      else if (status == 'visited') visited++;
      else unvisited++;
    });

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Confirm Submission', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to submit your response?'),
            const SizedBox(height: 16),
            _buildSummaryRow('Answered / Saved', answered, Colors.green),
            _buildSummaryRow('Marked for Review', review, Colors.purple),
            _buildSummaryRow('Answered & Review', answeredReview, Colors.indigo),
            _buildSummaryRow('Visited but Unanswered', visited, Colors.red),
            _buildSummaryRow('Unvisited', unvisited, Colors.grey),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _submitExam();
            },
            child: const Text('Submit Exam'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, int val, Color col) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(height: 8, width: 8, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
          Text(val.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- VIEW 7: BILINGUAL CANDIDATE RESPONSE SHEET ---
  Widget _buildDetailedResultView() {
    final item = _selectedHistoryItem;
    if (item == null) return const Center(child: Text('Result data error.'));

    final questions = item['questions'] as List? ?? [];
    
    // Stats calculation
    final correct = item['correct'] ?? 0;
    final wrong = item['wrong'] ?? 0;
    final totalQ = item['totalQuestions'] ?? 1;
    final score = item['score'] ?? 0;
    final accuracy = totalQ > 0 ? ((correct / (correct + wrong == 0 ? 1 : correct + wrong)) * 100) : 0.0;
    final timeUsed = item['totalTimeUsed'] ?? 0;

    return Column(
      children: [
        // Sub-Header Performance summary
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border(bottom: BorderSide(color: AppTheme.border)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['title'] ?? 'Mock Test Result', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Candidate: ${item['candidateName']}', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Text('Language: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ChoiceChip(
                        label: const Text('EN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                        selected: _resultLanguage == 'english',
                        onSelected: (val) { if (val) setState(() => _resultLanguage = 'english'); },
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 4),
                      ChoiceChip(
                        label: const Text('HN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                        selected: _resultLanguage == 'hindi',
                        onSelected: (val) { if (val) setState(() => _resultLanguage = 'hindi'); },
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Horizontal metrics grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildResultMetric('Score', '$score', Colors.amber.shade700),
                  _buildResultMetric('Correct', '$correct', Colors.green),
                  _buildResultMetric('Wrong', '$wrong', Colors.red),
                  _buildResultMetric('Accuracy', '${accuracy.toStringAsFixed(0)}%', Colors.blue),
                  _buildResultMetric('Time Used', '${timeUsed ~/ 60}m', Colors.purple),
                ],
              )
            ],
          ),
        ),

        // Scrollable Questions list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: questions.length,
            itemBuilder: (context, idx) {
              final q = questions[idx];
              final reviewStatus = q['status'] ?? 'Unattempted';
              final selected = q['selectedAnswer'] ?? '---';
              final correctVal = q['correctAnswer'] ?? '---';

              Color cardBorderCol = AppTheme.border;
              Color badgeCol = Colors.grey;
              IconData badgeIcon = LucideIcons.ban;

              if (reviewStatus == 'Correct') {
                cardBorderCol = Colors.green.shade300;
                badgeCol = Colors.green;
                badgeIcon = LucideIcons.check;
              } else if (reviewStatus == 'Wrong') {
                cardBorderCol = Colors.red.shade300;
                badgeCol = Colors.red;
                badgeIcon = LucideIcons.x;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorderCol, width: 1.5),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Question ${idx + 1} (${q['type']})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: badgeCol.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Row(
                            children: [
                              Icon(badgeIcon, color: badgeCol, size: 10),
                              const SizedBox(width: 4),
                              Text(reviewStatus.toUpperCase(), style: TextStyle(color: badgeCol, fontSize: 8.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Question Image
                    Container(
                      color: Colors.white,
                      height: 120,
                      width: double.infinity,
                      child: Image.network(
                        _getLanguageImagePath(q['imagePath'], _resultLanguage),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(LucideIcons.image, color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Answers comparison
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              const Text('SELECTED RESPONSE', style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(selected, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: badgeCol)),
                            ],
                          ),
                          Container(height: 20, width: 1, color: AppTheme.border),
                          Column(
                            children: [
                              const Text('CORRECT ANSWER KEY', style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(correctVal, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
        
        // Return to Dashboard CTA
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.all(12),
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _view = 'dashboard';
                _selectedHistoryItem = null;
                _selectedPaper = null;
                _activePaperDetail = null;
              });
            },
            child: const Text('Back to Dashboard'),
          ),
        )
      ],
    );
  }

  Widget _buildResultMetric(String label, String value, Color col) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: col)),
      ],
    );
  }

  // =========================================================================
  // HELPER MODALS (INFO GUIDES & HISTORY LIST)
  // =========================================================================

  void _showNeetCbtGuide() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(height: 5, width: 48, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              Text('NEET UG Shifting to CBT Mode', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textBase)),
              const SizedBox(height: 12),
              Text(
                'Based on recommendations from the Supreme Court-appointed panel to prevent paper leaks, NTA is preparing a transition of NEET UG from pen-and-paper OMR sheets to Computer Based Testing (CBT).',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text('Why CBT is Safer:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              _buildBulletItem('Encrypted question distribution directly to center terminals minutes before start.'),
              _buildBulletItem('Dynamic section layout preventing adjacent copying.'),
              _buildBulletItem('Automated logs for timing and key entries.'),
              const SizedBox(height: 16),
              const Text('OMR vs CBT Mode Comparison:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Table(
                border: TableBorder.all(color: AppTheme.border, width: 1, borderRadius: BorderRadius.circular(8)),
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: AppTheme.background),
                    children: const [
                      TableCell(child: Padding(padding: EdgeInsets.all(8), child: Text('Feature', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
                      TableCell(child: Padding(padding: EdgeInsets.all(8), child: Text('OMR Sheet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
                      TableCell(child: Padding(padding: EdgeInsets.all(8), child: Text('CBT Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
                    ]
                  ),
                  const TableRow(
                    children: [
                      TableCell(child: Padding(padding: EdgeInsets.all(8), child: Text('Time Loss', style: TextStyle(fontSize: 10.5)))),
                      TableCell(child: Padding(padding: EdgeInsets.all(8), child: Text('Bubbling takes 10-15s per question', style: TextStyle(fontSize: 10.5)))),
                      TableCell(child: Padding(padding: EdgeInsets.all(8), child: Text('1 click selection (0.5s)', style: TextStyle(fontSize: 10.5)))),
                    ]
                  ),
                  const TableRow(
                    children: [
                      TableCell(child: Padding(padding: EdgeInsets.all(8), child: Text('Modification', style: TextStyle(fontSize: 10.5)))),
                      TableCell(child: Padding(padding: EdgeInsets.all(8), child: Text('Impossible to change bubbled answer', style: TextStyle(fontSize: 10.5)))),
                      TableCell(child: Padding(padding: EdgeInsets.all(8), child: Text('Clear response and change anytime', style: TextStyle(fontSize: 10.5)))),
                    ]
                  ),
                  const TableRow(
                    children: [
                      TableCell(child: Padding(padding: EdgeInsets.all(8), child: Text('Palette Status', style: TextStyle(fontSize: 10.5)))),
                      TableCell(child: Padding(padding: EdgeInsets.all(8), child: Text('Manual tracking required', style: TextStyle(fontSize: 10.5)))),
                      TableCell(child: Padding(padding: EdgeInsets.all(8), child: Text('Visual color-coded grid indicators', style: TextStyle(fontSize: 10.5)))),
                    ]
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Got it, Thanks!'),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showCbtStrategyGuide() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(height: 5, width: 48, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              Text('CBT Exam Day Strategies', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textBase)),
              const SizedBox(height: 12),
              Text(
                'Maximizing score in online examinations requires systematic time allocation and proper coordination with the portal UI.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text('The Three-Pass Solving Strategy:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              _buildBulletItem('Pass 1 (Easy / Fast): Go through questions 1 to N, solving only direct conceptual and simple formula-based questions. (Target: 35-45% paper).'),
              _buildBulletItem('Pass 2 (Moderate): Address questions that require calculations or multi-step logic. Use "Mark for Review" if you need to double-check.'),
              _buildBulletItem('Pass 3 (Difficult): Try complex numericals or time-consuming derivations in the remaining 15-20 minutes.'),
              const SizedBox(height: 16),
              const Text('Understanding NTA Color Coding Palette:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              _buildBulletItem('🔴 Red: Visited but unanswered. Needs review.'),
              _buildBulletItem('🟢 Green: Answered and saved. Calculated in final scoring.'),
              _buildBulletItem('🟣 Purple: Marked for Review (No response). Not calculated.'),
              _buildBulletItem('🟣+🟢 Dot: Answered & Marked for Review. Calculated in final scoring (if timer expires).'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close Strategy Guide'),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted, height: 1.35))),
        ],
      ),
    );
  }

  void _showPerformanceHistoryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(child: Container(height: 5, width: 48, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 16),
            Text('Practice Attempt History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textBase)),
            const SizedBox(height: 12),
            Expanded(
              child: _examHistory.isEmpty
                  ? Center(child: Text('No mock attempts recorded yet.', style: TextStyle(color: AppTheme.textMuted)))
                  : ListView.builder(
                      itemCount: _examHistory.length,
                      itemBuilder: (listCtx, idx) {
                        final item = _examHistory[idx];
                        final score = item['score'] ?? 0;
                        final date = item['date'] ?? '---';
                        final correct = item['correct'] ?? 0;
                        final wrong = item['wrong'] ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['title'] ?? 'Mock Paper', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Text('Date: $date  |  Correct: $correct, Wrong: $wrong', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '$score',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: score >= 0 ? Colors.green : Colors.red),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      setState(() {
                                        _selectedHistoryItem = item;
                                        _resultLanguage = 'english';
                                        _view = 'detailed_result';
                                      });
                                    },
                                    child: const Text('Details', style: TextStyle(fontSize: 12)),
                                  )
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
