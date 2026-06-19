import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/notifications_screen.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static String? initialPayloadUrl;
  static String? initialPayloadUserId;
  static bool hasInitialNotification = false;

  static Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    if (kIsWeb) return;
    
    try {
      // 0. Request Permissions
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // 1. Initialize Local Notifications
      const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
      const InitializationSettings initSettings = InitializationSettings(android: androidInit);
      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null) {
            try {
              final payloadData = jsonDecode(response.payload!);
              processNotificationRoute(navigatorKey, url: payloadData['url'], targetUserId: payloadData['userId']);
            } catch (_) {
              processNotificationRoute(navigatorKey, url: response.payload);
            }
          }
        },
      );

      // 2. Create High Importance Channel for Android 8.0+
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        description: 'This channel is used for important notifications.', // description
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Handle notification taps when app is in background but alive
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        processNotificationRoute(navigatorKey, url: message.data['url']?.toString(), targetUserId: message.data['userId']?.toString());
      });

      // Handle notification taps when app was completely closed/killed
      // Await it to prevent race conditions with main.dart's auth check
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        hasInitialNotification = true;
        initialPayloadUrl = initialMessage.data['url']?.toString();
        initialPayloadUserId = initialMessage.data['userId']?.toString();
      }

      // 3. Foreground Notification Listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          _localNotifications.show(
            id: notification.hashCode,
            title: notification.title,
            body: notification.body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: '@mipmap/launcher_icon',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
            payload: jsonEncode({
              'url': message.data['url']?.toString(),
              'userId': message.data['userId']?.toString()
            }),
          );
        }
      });
      
      debugPrint('🔔 FCM & Local Notifications initialized.');
    } catch (e) {
      debugPrint('🔔 FCM Init error: $e');
    }
  }

  static Future<void> processNotificationRoute(GlobalKey<NavigatorState> navigatorKey, {String? url, String? targetUserId}) async {
    final context = navigatorKey.currentContext;
    if (context == null) {
      // If context is null, try again after a short delay
      Future.delayed(const Duration(milliseconds: 100), () => processNotificationRoute(navigatorKey, url: url, targetUserId: targetUserId));
      return;
    }

    if (targetUserId != null) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.user != null && auth.user!['uid'] != targetUserId) {
        debugPrint("FCM Auto-Switching to target user: $targetUserId");
        await auth.switchAccount(targetUserId);
        // Wait for UI to completely rebuild after account switch
        await Future.delayed(const Duration(milliseconds: 400));
      }
    }

    // Always pop back to the root navigator (Home) first to avoid stacking on top of random deep screens
    navigatorKey.currentState?.popUntil((route) => route.isFirst);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigatorKey.currentState == null) return;
      
      navigatorKey.currentState!.push(
        MaterialPageRoute(builder: (_) => NotificationsScreen(highlightUrl: url)),
      );
    });
  }

  static Future<void> setExternalUserId(String userId) async {
    if (kIsWeb) return;
    // Handled by backend API subscription
  }

  static Future<void> removeExternalUserId() async {
    if (kIsWeb) return;
    FirebaseMessaging.instance.deleteToken();
  }

  static Future<void> setTags(Map<String, dynamic> tags) async {
    if (kIsWeb) return;
    // Tags are handled at backend now
  }

  static Future<String?> getFcmToken() async {
    if (kIsWeb) return null;
    return await FirebaseMessaging.instance.getToken();
  }
}
