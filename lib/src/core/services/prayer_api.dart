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
  }) async {
    final method = CountryMethod.methodFromCountry(countryCode);

    final uri = Uri.parse(
      'https://api.aladhan.com/v1/timings'
      '?latitude=$latitude'
      '&longitude=$longitude'
      '&method=$method',
    );

    // Log request details
    debugPrint('🌐 [API REQUEST]');
    debugPrint('URL: ${uri.toString()}');
    debugPrint('Method: GET');
    debugPrint('Headers: ${const {'Content-Type': 'application/json'}}');
    debugPrint('Parameters:');
    debugPrint('  - latitude: $latitude');
    debugPrint('  - longitude: $longitude');
    debugPrint('  - method: $method');
    debugPrint('  - countryCode: $countryCode');

    final stopwatch = Stopwatch()..start();
    final response = await http.get(uri);
    stopwatch.stop();
    // Log response details
    debugPrint('📡 [API RESPONSE]');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Response Time: ${stopwatch.elapsedMilliseconds}ms');
    debugPrint('Content-Type: ${response.headers['content-type']}');
    debugPrint('Content-Length: ${response.body.length} bytes');

    if (kDebugMode) {
      try {
        final formattedJson = const JsonEncoder.withIndent('  ')
            .convert(jsonDecode(response.body));
        debugPrint('Response Body:');
        debugPrint(formattedJson);
      } catch (e) {
        debugPrint('Response Body (raw): ${response.body}');
      }
    }

    if (response.statusCode != 200) {
      debugPrint('❌ API Error: Status ${response.statusCode}');
      throw Exception(
          'Failed to fetch prayer times (Status: ${response.statusCode})');
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

    final Map<String, tz.TZDateTime> prayerTimes = {
      'fajr'.tr(): parseTime(timings['Fajr']),
      'dhuhr'.tr(): parseTime(timings['Dhuhr']),
      'asr'.tr(): parseTime(timings['Asr']),
      'maghrib'.tr(): parseTime(timings['Maghrib']),
      'isha'.tr(): parseTime(timings['Isha']),
    };

    // // Store timezone for notification service
    // prayerTimes['_timezone'] = timezone;

    // Log parsed prayer times
    debugPrint('✅ [API SUCCESS]');
    debugPrint('Timezone: $timezone');
    debugPrint('Prayer Times:');
    prayerTimes.forEach((key, value) {
      debugPrint('  - $key: $value');
    });

    return PrayerData(timezone: timezone, times: prayerTimes);
  }
}
