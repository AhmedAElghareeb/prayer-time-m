import 'package:flutter/foundation.dart';
import 'package:prayer_times/src/core/services/local_notification.dart';
import 'package:prayer_times/src/core/services/location_services.dart';
import 'package:prayer_times/src/core/services/prayer_api.dart';
import 'package:prayer_times/src/features/parayer_screen/controller/model.dart';
import 'package:timezone/timezone.dart' as tz;

class PrayerController {
  final _location = LocationService();
  final _api = PrayerApiService();

  Future<PrayerData?> loadAndSchedule() async {
    try {
      debugPrint("🛰️ Requesting location...");
      final position = await _location.getCurrentLocation();
      debugPrint("🌍 Location acquired: ${position.latitude}");
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

      final location = tz.getLocation(todayData.timezone);
      tz.setLocalLocation(location); // Sync local to API timezone

      await LocalNotificationService.instance
          .init(timezone: todayData.timezone);
      await LocalNotificationService.instance.cancelAll();

      // await LocalNotificationService.instance.testAdhanNow();

      int id = 0;
      // Now tzNow is in the CORRECT timezone
      final tzNow = tz.TZDateTime.now(location);

      List<PrayerData> combinedDays = [todayData, tomorrowData];

      for (var day in combinedDays) {
        for (var entry in day.times.entries) {
          // Ensure entry.value is a TZDateTime in the correct location
          if (entry.value.isAfter(tzNow)) {
            await LocalNotificationService.instance.schedulePrayer(
              id: id++,
              prayerName: entry.key,
              time: entry.value,
              timezone: day.timezone,
            );
          }
        }
      }

      final count =
          await LocalNotificationService.instance.getPendingNotificationCount();
      debugPrint('🎯 Total Pending Notifications: $count');
      debugPrint('🎯 Scheduled $id notifications for today and tomorrow.');
      return todayData; // Return today's data for the UI
    } catch (e) {
      debugPrint('❌ Error: $e');
      return null;
    }
  }
}
