import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Yerel bildirim servisi (yoklama alındığında veliye bildirim).
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    try {
      await _plugin.initialize(settings);
      _initialized = true;
    } catch (e) {
      if (kDebugMode) print('Notification init error: $e');
    }
  }

  static Future<void> show({
    required String title,
    required String body,
  }) async {
    if (!_initialized) await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'attendance_channel',
        'Yoklama Bildirimleri',
        channelDescription: 'Çocuğunuzun servis durumu hakkında bildirimler',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    try {
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        details,
      );
    } catch (e) {
      if (kDebugMode) print('Notification show error: $e');
    }
  }
}
