import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService
{
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async
  {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
    InitializationSettings(android: androidInit);

    await _notificationsPlugin.initialize(initSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'vaccine_channel',
      'Vaccine Reminders',
      description: 'Reminds parents ',
      importance: Importance.high,
    );
    final android = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(channel);
  }

  static Future<void> showNotification(
      {
    required String title,
    required String body,
  }) async
  {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'vaccine_channel',
      'Vaccine Reminders',
      channelDescription: 'Reminds parents ',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0,
        title,
        body,
        notificationDetails,
    );
  }
}
