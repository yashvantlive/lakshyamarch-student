import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/academic_provider.dart';
import '../theme/app_theme.dart';

class GlobalErrorWrapper extends StatelessWidget {
  final Widget child;

  const GlobalErrorWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final academic = context.watch<AcademicProvider>();
    
    final error = auth.error ?? academic.error;

    return Stack(
      children: [
        child,
        if (error != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, double value, child) {
                return Transform.translate(
                  offset: Offset(0, -100 * (1 - value)),
                  child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.danger,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppTheme.danger.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertTriangle, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getFriendlyError(error),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, color: Colors.white70, size: 16),
                      onPressed: () {
                        // Clear error logic could be here
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _getFriendlyError(String error) {
    if (error.contains('SocketException') || error.contains('Failed host lookup')) {
      return 'No internet connection. Using offline data.';
    }
    if (error.contains('401')) {
      return 'Session expired. Please login again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
