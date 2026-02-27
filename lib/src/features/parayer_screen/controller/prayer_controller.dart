import 'package:flutter/foundation.dart';
import 'package:prayer_times/src/core/services/local_notification.dart';
import 'package:prayer_times/src/core/services/location_services.dart';
import 'package:prayer_times/src/core/services/permission_helper.dart';
import 'package:prayer_times/src/core/services/prayer_api.dart';
import 'package:prayer_times/src/features/parayer_screen/controller/model.dart';
import 'package:timezone/timezone.dart' as tz;

class PrayerController {
  final _location = LocationService();
  final _api = PrayerApiService();

  // Future<PrayerData?> loadAndSchedule() async {
  //   try {
  //     final position = await _location.getCurrentLocation();
  //
  //     final prayerData = await _api.getPrayerTimes(
  //       latitude: position.latitude,
  //       longitude: position.longitude,
  //       countryCode: position.countryCode,
  //     );
  //
  //     await LocalNotificationService.instance.init(
  //       timezone: prayerData.timezone,
  //     );
  //
  //     final notificationGranted =
  //         await LocalNotificationService.requestNotificationPermission();
  //     if (!notificationGranted) {
  //       debugPrint('❌ Notification permission denied');
  //       return prayerData;
  //     }
  //
  //     final exactAlarmGranted = await ExactAlarmPermission.isGranted();
  //     if (!exactAlarmGranted) {
  //       debugPrint(
  //           '⚠️ Exact alarm permission not granted, opening settings...');
  //       await ExactAlarmPermission.openSettings();
  //       return prayerData;
  //     }
  //
  //     await LocalNotificationService.instance.cancelAll();
  //
  //     int id = 0;
  //     for (final entry in prayerData.times.entries) {
  //       if (entry.value.isAfter(tz.TZDateTime.now(tz.local))) {
  //         await LocalNotificationService.instance.schedulePrayer(
  //           id: id++,
  //           prayerName: entry.key,
  //           time: entry.value,
  //         );
  //       }
  //     }
  //     debugPrint('🎯 Scheduled $id prayer notifications');
  //     return prayerData;
  //   } catch (e) {
  //     debugPrint('❌ Error in loadAndSchedule: $e');
  //     return null;
  //   }
  // }

  Future<PrayerData?> loadAndSchedule() async {
    try {
      final position = await _location.getCurrentLocation();
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      // 1. Fetch Today
      final todayData = await _api.getPrayerTimes(
        latitude: position.latitude,
        longitude: position.longitude,
        countryCode: position.countryCode,
        date: now,
      );

      // 2. Fetch Tomorrow
      final tomorrowData = await _api.getPrayerTimes(
        latitude: position.latitude,
        longitude: position.longitude,
        countryCode: position.countryCode,
        date: tomorrow,
      );

      await LocalNotificationService.instance.init(timezone: todayData.timezone);
      await LocalNotificationService.instance.cancelAll();

      int id = 0;
      final tzNow = tz.TZDateTime.now(tz.local);

      // 3. Schedule from both sets of data
      List<PrayerData> combinedDays = [todayData, tomorrowData];

      for (var day in combinedDays) {
        for (var entry in day.times.entries) {
          if (entry.value.isAfter(tzNow)) {
            await LocalNotificationService.instance.schedulePrayer(
              id: id++,
              prayerName: entry.key,
              time: entry.value,
              timezone: todayData.timezone,
            );
          }
        }
      }

      debugPrint('🎯 Scheduled $id notifications for today and tomorrow.');
      return todayData; // Return today's data for the UI
    } catch (e) {
      debugPrint('❌ Error: $e');
      return null;
    }
  }
}
