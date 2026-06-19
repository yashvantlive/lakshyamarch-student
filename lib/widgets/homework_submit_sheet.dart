import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/homework.dart';
import '../theme/app_theme.dart';

class HomeworkSubmitSheet extends StatefulWidget {
  final Homework homework;
  final VoidCallback onSubmitSuccess;

  const HomeworkSubmitSheet({
    super.key,
    required this.homework,
    required this.onSubmitSuccess,
  });

  @override
  State<HomeworkSubmitSheet> createState() => _HomeworkSubmitSheetState();
}

class _HomeworkSubmitSheetState extends State<HomeworkSubmitSheet> {
  final ApiService _apiService = ApiService();
  final TextEditingController _linkController = TextEditingController();

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  bool _isSubmitting = false;

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    
    try {
      final auth = context.read<AuthProvider>();

      // Submit Homework details with optional link
      await _apiService.submitHomework(
        homeworkId: widget.homework.id,
        studentId: auth.currentStudent!.id,
        studentName: auth.currentStudent!.name,
        driveLink: _linkController.text.trim(),
        token: auth.token!,
      );

      HapticFeedback.mediumImpact();
      widget.onSubmitSuccess();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Text(
            'Submit Homework',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: AppTheme.textBase,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.homework.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _linkController,
            decoration: InputDecoration(
              hintText: 'Paste Drive / PDF Link (Optional)',
              prefixIcon: Icon(LucideIcons.link, color: wingColor),
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: wingColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Submit Button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: wingColor,
              disabledBackgroundColor: wingColor.withOpacity(0.5),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Submit Answer',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
