import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';

/// Requests push permission, keeps the parent's FCM token saved to their
/// profile, and surfaces incoming event/booking notifications while the
/// app is in the foreground. Actual sending (e.g. "reminder: workshop
/// starts in 1 hour") happens server-side via Cloud Functions, which is
/// out of scope for this client.
class NotificationService {
  NotificationService(this._authService)
      : _messaging = FirebaseMessaging.instance;

  final AuthService _authService;
  final FirebaseMessaging _messaging;

  final ValueNotifier<RemoteMessage?> latestForegroundMessage =
      ValueNotifier(null);

  Future<void> initialize() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await _messaging.getToken();
    if (token != null) {
      await _authService.saveFcmToken(token);
    }
    _messaging.onTokenRefresh.listen(_authService.saveFcmToken);

    FirebaseMessaging.onMessage.listen((message) {
      latestForegroundMessage.value = message;
    });
  }
}
