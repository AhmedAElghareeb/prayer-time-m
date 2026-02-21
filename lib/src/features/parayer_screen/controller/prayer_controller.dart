import 'package:prayer_times/src/core/services/local_notification.dart';
import 'package:prayer_times/src/core/services/location_services.dart';
import 'package:prayer_times/src/core/services/permission_helper.dart';
import 'package:prayer_times/src/core/services/prayer_api.dart';

class PrayerController {
  final _location = LocationService();
  final _api = PrayerApiService();

  Future<Map<String, DateTime>> loadAndSchedule() async {
    final position = await _location.getCurrentLocation();

    final times = await _api.getPrayerTimes(
      latitude: position.latitude,
      longitude: position.longitude,
      countryCode: position.countryCode,
    );

    final granted = await ExactAlarmPermission.isGranted();

    if (!granted) {
      await ExactAlarmPermission.openSettings();
    }

    await LocalNotificationService.instance.cancelAll();
    //
    // int id = 0;
    // for (final e in times.entries) {
    //   if (e.value.isAfter(DateTime.now())) {
    //     await LocalNotificationService.instance.schedulePrayer(
    //       id: id++,
    //       prayerName: e.key,
    //       time: e.value,
    //     );
    //   }
    // }
    // return times;

    await LocalNotificationService.requestNotificationPermission();
    await LocalNotificationService.testAdhanAfterOneMinute();
    // await LocalNotificationService.debugImmediateNotification();
    return {};
  }
}
