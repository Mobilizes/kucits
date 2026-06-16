import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised by the time this is called
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Set this in main.dart to enable in-app notification banners
  static GlobalKey<ScaffoldMessengerState>? messengerKey;

  static Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Save token whenever auth state changes (covers login and token refresh)
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null && !user.isAnonymous) {
        await _saveOrUpdateToken();
      }
    });

    _messaging.onTokenRefresh.listen((_) => _saveOrUpdateToken());

    FirebaseMessaging.onMessage.listen(_showInAppBanner);

    // Handle tap when app was terminated
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleNotificationTap(initial);

    // Handle tap when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  static Future<void> _saveOrUpdateToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': token});
    } catch (_) {
      // User doc may not exist yet — silently ignore
    }
  }

  static void _showInAppBanner(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    messengerKey?.currentState?.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title ?? 'KucITS',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (notification.body != null) Text(notification.body!),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // Placeholder for future deep-link navigation on notification tap
  static void _handleNotificationTap(RemoteMessage message) {}
}
