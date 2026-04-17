import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

/// Top-level handler required by firebase_messaging for background messages.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are surfaced by the OS tray automatically when the
  // app is terminated. No local plugin action is required here.
}

/// Singleton service that wraps [FlutterLocalNotificationsPlugin] and
/// [FirebaseMessaging] for all notification needs in Beacon of New Beginnings.
class NotificationService {
  // ── Singleton ────────────────────────────────────────────────────────────
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // ── Private fields ───────────────────────────────────────────────────────
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static const String _fcmTokenKey = 'fcm_token';

  /// Android notification channel used for all Beacon safety alerts.
  static const AndroidNotificationChannel _safetyChannel =
      AndroidNotificationChannel(
    'beacon_safety',
    'Safety Alerts',
    description: 'Critical safety check-in and emergency notifications',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  // ── Initialization ───────────────────────────────────────────────────────

  /// Initializes both local notifications and Firebase Cloud Messaging.
  ///
  /// Call once from [main()] or your top-level widget's [initState].
  Future<void> initialize() async {
    await _initLocalNotifications();
    await _initFCM();
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS / macOS — request permissions at init time.
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create the Android notification channel so importance/sound settings
    // survive app restarts on Android 8+.
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_safetyChannel);
  }

  Future<void> _initFCM() async {
    // FCM requires Firebase to be configured (google-services.json / GoogleService-Info.plist).
    // If not configured, skip silently so local notifications still work.
    try {
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      final String? token = await _fcm.getToken();
      if (token != null) {
        await _saveFcmToken(token);
      }

      _fcm.onTokenRefresh.listen((newToken) async {
        await _saveFcmToken(newToken);
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final RemoteNotification? notification = message.notification;
        if (notification != null) {
          _showLocalNotification(
            id: message.hashCode,
            title: notification.title ?? 'Beacon',
            body: notification.body ?? '',
          );
        }
      });
    } catch (e) {
      // Firebase not configured — FCM push notifications unavailable.
      // Local notifications (check-in reminders) still work.
    }
  }

  Future<void> _saveFcmToken(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, token);
  }

  // ── Notification tapped callback ─────────────────────────────────────────

  void _onNotificationTapped(NotificationResponse response) {
    // Route to the relevant screen based on response.payload when navigation
    // is wired up.
  }

  // ── Public API ───────────────────────────────────────────────────────────

  /// Schedules a local check-in reminder notification at [scheduledTime].
  ///
  /// [id] should be unique per logical alarm so it can be cancelled individually.
  Future<void> scheduleCheckIn(
    int id,
    String title,
    DateTime scheduledTime,
  ) async {
    final tz.TZDateTime tzScheduled =
        tz.TZDateTime.from(scheduledTime, tz.local);

    await _localNotifications.zonedSchedule(
      id,
      title,
      "Time to check in and let your trusted contacts know you're safe.",
      tzScheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _safetyChannel.id,
          _safetyChannel.name,
          channelDescription: _safetyChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancels the scheduled notification with the given [id].
  Future<void> cancelCheckIn(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancels every pending local notification.
  Future<void> cancelAllCheckIns() async {
    await _localNotifications.cancelAll();
  }

  /// Displays an immediate (heads-up) local notification.
  Future<void> showImmediate(String title, String body) async {
    await _showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
    );
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _safetyChannel.id,
          _safetyChannel.name,
          channelDescription: _safetyChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }
}
