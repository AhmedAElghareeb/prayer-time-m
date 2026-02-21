import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'package:prayer_times/src/core/services/country_method.dart';
import 'package:timezone/timezone.dart' as tz;

class PrayerApiService {
  Future<Map<String, DateTime>> getPrayerTimes({
    required double latitude,
    required double longitude,
    required String countryCode,
  }) async {
    final method = CountryMethod.methodFromCountry(countryCode);

    final uri = Uri.parse(
      'https://api.aladhan.com/v1/timings'
      '?latitude=$latitude'
      '&longitude=$longitude'
      '&method=$method',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch prayer times');
    }

    final decoded = jsonDecode(response.body);
    final data = decoded['data'];

    final timings = data['timings'];
    final date = data['date']['gregorian']['date'];
    final timezone = data['meta']['timezone'];

    final dateParts = date.split('-');
    final day = int.parse(dateParts[0]);
    final month = int.parse(dateParts[1]);
    final year = int.parse(dateParts[2]);

    final location = tz.getLocation(timezone);

    tz.TZDateTime parseTime(String time) {
      final parts = time.split(':');
      return tz.TZDateTime(
        location,
        year,
        month,
        day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    }

    return {
      'fajr'.tr(): parseTime(timings['Fajr']),
      'dhuhr'.tr(): parseTime(timings['Dhuhr']),
      'asr'.tr(): parseTime(timings['Asr']),
      'maghrib'.tr(): parseTime(timings['Maghrib']),
      'isha'.tr(): parseTime(timings['Isha']),
    };
  }
}
