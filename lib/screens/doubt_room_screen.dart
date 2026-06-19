import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_widgets.dart';

/* ============================================================================
   FUTURE IMPLEMENTATION PLAN: DOUBT ROOM (V1.1)
   ============================================================================
   Current Status: Marked as "Coming Soon" because the backend API and 
   proper cloud storage are not yet implemented.

   Future Architecture & Flow:
   
   1. Cloud Storage:
      - Since Vercel/Serverless does not persist local files, we MUST integrate 
        AWS S3, Cloudinary, or Firebase Storage for image uploads.
      - The Flutter app will call a backend route (e.g., /api/upload) which will 
        upload the image to Cloudinary/S3 and return the secure URL.
        
   2. Backend Routes (Next.js / Node):
      - Need to create routes under `src/app/api/doubts`:
        * POST `/api/doubts` -> Create a new doubt with subject, text, image URL.
        * GET `/api/doubts` -> Fetch student's doubts.
        * POST `/api/doubts/:id/reply` -> Add a reply (from teacher or student).
        
   3. Teacher Routing & Notifications:
      - When a student posts a doubt, the backend MUST determine the assigned 
        subject teacher for that student's class.
      - Trigger an FCM Push Notification to the specific teacher.
      - Build a "Doubt Desk" screen in the Teacher App to view and reply to 
        these doubts.
        
   4. Real-time updates:
      - Consider using WebSockets (Socket.io) or polling to update the chat UI 
        when the teacher replies in real-time.
============================================================================ */

class DoubtRoomScreen extends StatelessWidget {
  const DoubtRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar similar to ScheduleScreen
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [

                  Column(
                    children: [
                      AnimatedBrandHeader(wingMode: auth.activeWingMode),
                      const SizedBox(height: 4),
                      Text(
                        'Doubt Room',
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
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.messageSquare,
                          size: 64,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Coming Soon!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textBase,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'We are building a robust Doubt Room where you can directly interact with your teachers, share images of your questions, and get instant solutions.\n\nStay tuned for the next update!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textMuted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 48),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
