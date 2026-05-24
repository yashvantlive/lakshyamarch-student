import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../screens/notice_feed_screen.dart';
import '../screens/notifications_screen.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static String? initialPayloadUrl;
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
          _navigateToNotifications(navigatorKey, url: response.payload);
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
        _navigateToNotifications(navigatorKey, url: message.data['url']?.toString());
      });

      // Handle notification taps when app was completely closed/killed
      FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          hasInitialNotification = true;
          initialPayloadUrl = message.data['url']?.toString();
          _tryNavigate(navigatorKey, url: initialPayloadUrl);
        }
      });

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
            payload: message.data['url']?.toString(),
          );
        }
      });
      
      debugPrint('🔔 FCM & Local Notifications initialized.');
    } catch (e) {
      debugPrint('🔔 FCM Init error: $e');
    }
  }

  static void _navigateToNotifications(GlobalKey<NavigatorState> navigatorKey, {String? url}) {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.push(
        MaterialPageRoute(builder: (_) => NotificationsScreen(highlightUrl: url)),
      );
    }
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

  static void _tryNavigate(GlobalKey<NavigatorState> key, {String? url}) {
    if (key.currentState != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        key.currentState!.push(MaterialPageRoute(builder: (_) => NotificationsScreen(highlightUrl: url)));
      });
    } else {
      Future.delayed(const Duration(milliseconds: 50), () => _tryNavigate(key, url: url));
    }
  }
}
