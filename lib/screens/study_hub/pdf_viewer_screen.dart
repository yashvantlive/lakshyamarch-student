import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

class PDFViewerScreen extends StatefulWidget {
  final String url;
  final String title;

  const PDFViewerScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  @override
  void initState() {
    super.initState();
    // Launch the native in-app browser immediately for the fastest experience
    Future.delayed(Duration.zero, () => _launchInAppBrowser());
  }

  Future<void> _launchInAppBrowser() async {
    final Uri uri = Uri.parse(widget.url);
    try {
      // mode: LaunchMode.inAppBrowserView is the most modern native way 
      // it opens a sheet (Android Custom Tab / iOS SafariView) inside the app
      final success = await launchUrl(
        uri, 
        mode: LaunchMode.inAppBrowserView,
      );
      
      if (!success) {
        // Fallback to external application if in-app view fails
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      
      // Once the browser is closed, we can pop back to the list
      if (mounted) Navigator.pop(context);
      
    } catch (e) {
      debugPrint('Error launching browser: $e');
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // This is a minimal transition screen that the user sees for a split second
    // before the native browser overlay slides up.
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 3),
            const SizedBox(height: 20),
            Text(
              'Opening ${widget.title}...',
              style: TextStyle(
                color: AppTheme.primary, 
                fontWeight: FontWeight.bold,
                fontSize: 14
              ),
            ),
          ],
        ),
      ),
    );
  }
}
