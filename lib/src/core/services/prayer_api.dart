import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:prayer_times/src/core/services/country_method.dart';
import 'package:prayer_times/src/features/parayer_screen/controller/model.dart';
import 'package:timezone/timezone.dart' as tz;

class PrayerApiService {
  Future<PrayerData> getPrayerTimes({
    required double latitude,
    required double longitude,
    required String countryCode,
    required DateTime date,
  }) async {
    final method = CountryMethod.methodFromCountry(countryCode);
    final formattedDate = DateFormat('dd-MM-yyyy').format(date);

    final uri = Uri.parse(
      'https://api.aladhan.com/v1/timings/$formattedDate'
          '?latitude=$latitude'
          '&longitude=$longitude'
          '&method=$method',
    );

    // --- LOGGING: Request ---
    debugPrint('🌍 [API REQUEST] URL: $uri');

    final response = await http.get(uri);

    // --- LOGGING: Response ---
    debugPrint('📥 [API RESPONSE] Status Code: ${response.statusCode}');

    if (response.statusCode != 200) {
      debugPrint('❌ [API ERROR] Body: ${response.body}');
      throw Exception('Failed to load prayer times: ${response.statusCode}');
    }

    // Optional: Uncomment the next line to see the full raw JSON
    debugPrint('📄 [API RESPONSE] Body: ${response.body}');

    final decoded = jsonDecode(response.body);
    final data = decoded['data'];

    // Extract the specific date returned by the API to be safe
    final String dateFromApi = data['date']['gregorian']['date'];
    final dateParts = dateFromApi.split('-');

    final day = int.parse(dateParts[0]);
    final month = int.parse(dateParts[1]);
    final year = int.parse(dateParts[2]);

    final timezone = data['meta']['timezone'];
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

    final Map<String, tz.TZDateTime> prayerTimes = {
      'fajr'.tr(): parseTime(data['timings']['Fajr']),
      'dhuhr'.tr(): parseTime(data['timings']['Dhuhr']),
      'asr'.tr(): parseTime(data['timings']['Asr']),
      'maghrib'.tr(): parseTime(data['timings']['Maghrib']),
      'isha'.tr(): parseTime(data['timings']['Isha']),
    };

    // --- LOGGING: Parsed Data ---
    debugPrint('✅ [PARSED DATA] Timezone: $timezone');
    debugPrint('⏰ [PARSED DATA] Fajr: ${prayerTimes['fajr'.tr()]}');

    return PrayerData(timezone: timezone, times: prayerTimes);
  }
}
