import 'dart:convert';
import 'dart:io' show Platform;

import 'package:beerco/core/utils/hive_init.dart';
import 'package:beerco/features/table/data/repositories/table_repository.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

const _timerCategoryId = 'member_timer_actions';
const _timerActionExtend10 = 'extend_10';
const _liveActivityChannel = MethodChannel('beerco/live_activity');

@pragma('vm:entry-point')
Future<void> notificationTapBackground(
  NotificationResponse notificationResponse,
) async {
  await NotificationService.instance.handleNotificationResponse(
    notificationResponse,
  );
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _permissionsRequested = false;
  bool _timezoneInitialized = false;
  int _nextNotificationId = 1;

  Future<void> initialize() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('app_icon');
    final ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          _timerCategoryId,
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(_timerActionExtend10, '+10 min'),
          ],
        ),
      ],
    );

    final settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    await _configureLocalTimeZone();
    _initialized = true;
  }

  Future<void> _configureLocalTimeZone() async {
    if (_timezoneInitialized) return;
    tz.initializeTimeZones();
    _timezoneInitialized = true;
  }

  Future<void> requestPermissions() async {
    await initialize();
    if (_permissionsRequested) return;

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
    _permissionsRequested = true;
  }

  Future<void> showMemberPaidNotification({
    required String memberName,
    String? tableName,
  }) async {
    await requestPermissions();

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

  Future<void> scheduleMemberTimerNotifications({
    required String memberId,
    required String memberName,
    required DateTime endsAt,
    String? tableName,
  }) async {
    await requestPermissions();
    await _cancelMemberTimerNotificationSlots(memberId);
    await _startOrUpdateMemberTimerLiveActivity(
      memberId: memberId,
      memberName: memberName,
      endsAt: endsAt,
      tableName: tableName,
    );

    final remaining = endsAt.difference(DateTime.now());
    final items =
        <({int id, DateTime at, String title, String body, bool isFinal})>[
          if (remaining > const Duration(minutes: 3))
            (
              id: _timerNotificationId(memberId, 1),
              at: endsAt.subtract(const Duration(minutes: 3)),
              title: '$memberName leaves in 10 min',
              body: tableName == null || tableName.isEmpty
                  ? 'Tap +10 min if they are staying longer.'
                  : '$tableName - tap +10 min if they are staying longer.',
              isFinal: false,
            ),
          if (remaining > const Duration(minutes: 3))
            (
              id: _timerNotificationId(memberId, 2),
              at: endsAt.subtract(const Duration(minutes: 2)),
              title: '$memberName leaves in 5 min',
              body: tableName == null || tableName.isEmpty
                  ? 'Tap +10 min if they are staying longer.'
                  : '$tableName - tap +10 min if they are staying longer.',
              isFinal: false,
            ),
          (
            id: _timerNotificationId(memberId, 3),
            at: endsAt,
            title: 'Alarm: $memberName timer ended',
            body: tableName == null || tableName.isEmpty
                ? 'Tap +10 min to extend the stay.'
                : '$tableName - tap +10 min to extend the stay.',
            isFinal: true,
          ),
        ];

    for (final item in items) {
      if (!item.at.isAfter(DateTime.now())) continue;

      final android = AndroidNotificationDetails(
        'member_timer_channel',
        'Member timer',
        channelDescription: 'Member stay timer reminders',
        importance: Importance.max,
        priority: Priority.high,
        category: item.isFinal
            ? AndroidNotificationCategory.alarm
            : AndroidNotificationCategory.reminder,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(_timerActionExtend10, '+10 min'),
        ],
      );
      final ios = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
        presentBanner: true,
        presentList: true,
        categoryIdentifier: _timerCategoryId,
        interruptionLevel: item.isFinal
            ? InterruptionLevel.timeSensitive
            : InterruptionLevel.active,
      );
      final details = NotificationDetails(android: android, iOS: ios);

      await _plugin.zonedSchedule(
        id: item.id,
        title: item.title,
        body: item.body,
        scheduledDate: tz.TZDateTime.from(item.at, tz.local),
        notificationDetails: details,
        payload: jsonEncode({'memberId': memberId}),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelMemberTimerNotifications(String memberId) async {
    await initialize();
    await _cancelMemberTimerNotificationSlots(memberId);
    await _endMemberTimerLiveActivity(memberId);
  }

  Future<void> _cancelMemberTimerNotificationSlots(String memberId) async {
    for (final slot in [1, 2, 3]) {
      await _plugin.cancel(id: _timerNotificationId(memberId, slot));
    }
  }

  Future<void> handleNotificationResponse(
    NotificationResponse notificationResponse,
  ) async {
    if (notificationResponse.actionId != _timerActionExtend10 ||
        notificationResponse.payload == null) {
      return;
    }

    final payload =
        jsonDecode(notificationResponse.payload!) as Map<String, dynamic>;
    final memberId = payload['memberId'] as String?;
    if (memberId == null) return;

    await initHive();
    final repository = TableRepository();
    final member = await repository.extendMemberTimer(memberId, 10);
    if (member == null) return;
    await syncMemberTimerNotification(memberId, repository);
  }

  Future<void> syncMemberTimerNotification(
    String memberId,
    TableRepository repository,
  ) async {
    final member = repository.getMember(memberId);
    final endsAt = member?.timerEndsAt;
    if (member == null || endsAt == null || !endsAt.isAfter(DateTime.now())) {
      await cancelMemberTimerNotifications(memberId);
      return;
    }

    await scheduleMemberTimerNotifications(
      memberId: member.id,
      memberName: member.name,
      endsAt: endsAt,
      tableName: repository.getTable(member.tableId)?.name,
    );
  }

  Future<void> syncTableTimerNotifications(
    String tableId,
    TableRepository repository,
  ) async {
    for (final member in repository.getMembersForTable(tableId)) {
      await syncMemberTimerNotification(member.id, repository);
    }
  }

  int _timerNotificationId(String memberId, int slot) {
    var hash = 17;
    for (final codeUnit in memberId.codeUnits) {
      hash = 0x1fffffff & (hash * 37 + codeUnit);
    }
    final base = hash % 214748364;
    return base * 10 + slot;
  }

  Future<void> _startOrUpdateMemberTimerLiveActivity({
    required String memberId,
    required String memberName,
    required DateTime endsAt,
    String? tableName,
  }) async {
    if (!Platform.isIOS || !endsAt.isAfter(DateTime.now())) return;

    try {
      await _liveActivityChannel.invokeMethod<bool>('startOrUpdateTimer', {
        'memberId': memberId,
        'memberName': memberName,
        'tableName': tableName,
        'endsAtMs': endsAt.millisecondsSinceEpoch,
      });
    } on MissingPluginException {
      // Live Activities are iOS-native and unavailable in some Flutter engines.
    } on PlatformException {
      // Notification scheduling should still work if ActivityKit is disabled.
    }
  }

  Future<void> _endMemberTimerLiveActivity(String memberId) async {
    if (!Platform.isIOS) return;

    try {
      await _liveActivityChannel.invokeMethod<bool>('endTimer', {
        'memberId': memberId,
      });
    } on MissingPluginException {
      // Live Activities are iOS-native and unavailable in some Flutter engines.
    } on PlatformException {
      // Nothing else to clean up on the Flutter side.
    }
  }
}
