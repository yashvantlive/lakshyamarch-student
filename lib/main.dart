import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/academic_provider.dart';
import 'providers/schedule_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigator.dart';
import 'theme/app_theme.dart';

import 'providers/notice_provider.dart';

import 'widgets/global_error_wrapper.dart';

import 'services/notification_service.dart';
import 'services/app_cache.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Firebase using explicit config to bypass google-services.json requirement
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyD3jZC-FQG780bLGfLgaX5s79w1hEf1xhQ",
      authDomain: "lmlakshyamarch.firebaseapp.com",
      projectId: "lmlakshyamarch",
      storageBucket: "lmlakshyamarch.firebasestorage.app",
      messagingSenderId: "947048243933",
      appId: "1:947048243933:web:2f659c41ac575cee5af134",
      measurementId: "G-PKEP26TZLQ"
    ),
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await AppCache.instance.init();
  await NotificationService.initialize(navigatorKey);
  runApp(const LakshyaMarchStudentApp());
}

class LakshyaMarchStudentApp extends StatelessWidget {
  const LakshyaMarchStudentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AcademicProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProvider(create: (_) => NoticeProvider()),
      ],
      child: Builder(
        builder: (context) {
          final auth = context.watch<AuthProvider>();
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'LM Champs',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: auth.themeMode,
            builder: (context, child) => GlobalErrorWrapper(child: child!),
            home: const AuthGate(),
          );
        }
      ),
    );
  }
}

/// Checks persisted login on startup and routes accordingly.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final auth = context.read<AuthProvider>();
    await auth.tryAutoLogin();

    if (mounted) {
      setState(() => _isChecking = false);
      FlutterNativeSplash.remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Colors.white,
      );
    }

    final isAuthenticated = context.watch<AuthProvider>().isAuthenticated;
    return isAuthenticated ? const MainNavigator() : const LoginScreen();
  }
}
