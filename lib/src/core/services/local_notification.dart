import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:prayer_times/src/core/services/adhan_service.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  LocalNotificationService._();

  static final instance = LocalNotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  Future<int> getPendingNotificationCount() async {
    final List<PendingNotificationRequest> pendingRequests =
        await _plugin.pendingNotificationRequests();
    return pendingRequests.length;
  }

  Future<void> init({String? timezone}) async {
    // In your init or before scheduling
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }

    // In your init or before scheduling
    if (await Permission.scheduleExactAlarm.isPermanentlyDenied) {
      await openAppSettings();
    }

    tzdata.initializeTimeZones();

    if (timezone != null) {
      tz.setLocalLocation(tz.getLocation(timezone));
    } else {
      tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: (_) async {
        await AdhanAudioService.instance.playAdhan();
      },
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'prayer_channel_v2',
            'Prayer Times',
            importance: Importance.max,
            sound: RawResourceAndroidNotificationSound('adhan'),
          ),
        );

    final status = await Permission.notification.request();
    final alarmStatus = await Permission.scheduleExactAlarm.request();

    debugPrint("Notification Status: $status");
    debugPrint("Alarm Status: $alarmStatus");
  }

  Future<void> schedulePrayer({
    required int id,
    required String prayerName,
    required DateTime time,
    required String timezone,
  }) async {
    final location = tz.getLocation(timezone);
    final scheduled = tz.TZDateTime.from(time, location);
    final now = tz.TZDateTime.now(location);

    if (scheduled.isBefore(now)) return;

    debugPrint('🔔 [NOTIFICATION]');
    debugPrint('Now        : $now');
    debugPrint('Scheduled  : $scheduled');
    debugPrint('Timezone   : ${tz.local.name}');
    debugPrint('Difference : ${scheduled.difference(now).inSeconds}s');

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: '${'time'.tr()} $prayerName',
        body: '${'prayer_time'.tr()} $prayerName',
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'prayer_channel_v2',
            'Prayer Times',
            importance: Importance.max,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound('adhan'),
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentSound: true,
            presentAlert: true,
            presentBadge: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'prayer',
      );
      debugPrint('✅ Scheduled $prayerName at $scheduled');
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        debugPrint(
            '❌ Exact alarm permission missing in Manifest or not granted by user.');
      } else {
        rethrow;
      }
    }
  }

  Future<void> cancelAll() async => await _plugin.cancelAll();

  static Future<bool> requestNotificationPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final granted = await androidPlugin?.requestNotificationsPermission();
    return granted ?? false;
  }

  Future<void> testAdhanNow() async {
    final now = tz.TZDateTime.now(tz.local);
    final testTime = now.add(const Duration(seconds: 5));

    await _plugin.zonedSchedule(
      id: 999,
      title: "اختبار الأذان",
      body: "صوت الأذان سيعمل الآن",
      scheduledDate: testTime,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_channel_v2',
          'Prayer Times',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('adhan'),
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    debugPrint("🚀 Test scheduled for 5 seconds from now...");
  }

  Future<void> testImmediateDefault() async {
    await _plugin.show(
      id: 998,
      title: "Testing System",
      body: "If you see this, the notification system is working.",
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel', // New channel ID
          'Test Channel',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true, // Use default sound
        ),
      ),
    );
  }

  Future<void> testAthanInTenSeconds() async {
    final now = tz.TZDateTime.now(tz.local);

    await _plugin.zonedSchedule(
      id: 12345,
      title: "Test Athan",
      body: "This should play the adhan sound in 10 seconds",
      scheduledDate: now.add(const Duration(seconds: 10)),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_channel_v2', // Use the SAME ID from your init
          'Prayer Times',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('adhan'),
          // Must be in res/raw/adhan.mp3
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    debugPrint("⏰ Scheduled for 10 seconds from now...");
  }
}
