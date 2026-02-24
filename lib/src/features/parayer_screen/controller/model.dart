import 'package:timezone/timezone.dart' as tz;

class PrayerData {
  final String timezone;
  final Map<String, tz.TZDateTime> times;

  PrayerData({required this.timezone, required this.times});
}
