import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  int _nextNotificationId = 1;

  Future<void> initialize() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('app_icon');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<void> _ensurePermissions() async {
    await initialize();

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> showMemberPaidNotification({
    required String memberName,
    String? tableName,
  }) async {
    await _ensurePermissions();

    const android = AndroidNotificationDetails(
      'member_paid_channel',
      'Member paid',
      channelDescription: 'Alerts when a table member pays',
      importance: Importance.max,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
      presentBanner: true,
      presentList: true,
    );

    final details = const NotificationDetails(android: android, iOS: ios);
    final body = tableName == null || tableName.isEmpty
        ? '$memberName paid.'
        : '$memberName paid at $tableName.';

    await _plugin.show(
      id: _nextNotificationId++,
      title: 'BeerCo',
      body: body,
      notificationDetails: details,
    );
  }
}
