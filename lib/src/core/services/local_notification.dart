import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:prayer_times/src/core/services/adhan_service.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  LocalNotificationService._();

  static final instance = LocalNotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tzdata.initializeTimeZones();

    tz.setLocalLocation(tz.getLocation('Africa/Cairo'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: (_) {
        AdhanAudioService.instance.playAdhan();
      },
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'prayer_channel',
            'Prayer Times',
            importance: Importance.max,
            sound: RawResourceAndroidNotificationSound('adhan'),
          ),
        );
  }

  Future<void> schedulePrayer({
    required int id,
    required String prayerName,
    required DateTime time,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = tz.TZDateTime.from(time, tz.local);

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
            'prayer_channel',
            'Prayer Times',
            priority: Priority.high,
            importance: Importance.max,
            sound: RawResourceAndroidNotificationSound('adhan'),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        debugPrint('Exact alarm not permitted yet');
        return;
      }
      rethrow;
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static Future<bool> requestNotificationPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final granted = await androidPlugin?.requestNotificationsPermission();
    return granted ?? false;
  }

  static Future<void> testAdhanAfterOneMinute() async {
    final now = tz.TZDateTime.now(tz.local);
    final testTime =
        tz.TZDateTime.now(tz.local).add(const Duration(minutes: 3));

    debugPrint('🔔 [TEST NOTIFICATION]');
    debugPrint('Now        : $now');
    debugPrint('Scheduled  : $testTime');
    debugPrint('Timezone   : ${tz.local.name}');
    debugPrint('Difference : ${testTime.difference(now).inSeconds}s');

    try {
      await _plugin.zonedSchedule(
        id: 9999,
        title: 'أذان تجريبي',
        body: 'سيتم تشغيل صوت الأذان بعد 20 ثانية',
        scheduledDate: testTime,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'prayer_channel',
            'Prayer Times',
            priority: Priority.high,
            importance: Importance.max,
            sound: RawResourceAndroidNotificationSound('adhan'),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
      );

      debugPrint('✅ Notification scheduled successfully');
    } on PlatformException catch (e) {
      debugPrint('❌ Schedule failed');
      debugPrint('Code : ${e.code}');
      debugPrint('Msg  : ${e.message}');
    }
  }

  static Future<void> debugImmediateNotification() async {
    await _plugin.show(
      id: 7777,
      title: 'Debug Immediate',
      body: 'This notification should appear immediately',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_channel',
          'Prayer Times',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}
