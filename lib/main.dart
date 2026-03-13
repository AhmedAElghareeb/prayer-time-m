import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prayer_times/src/core/services/local_notification.dart';
import 'package:prayer_times/src/features/parayer_screen/controller/prayer_controller.dart';
import 'package:prayer_times/src/features/parayer_screen/screens/prayer_screen.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point') // Mandatory for Release mode
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      // 1. Initialize services inside the background isolate
      final controller = PrayerController();

      // 2. Call your existing logic
      await controller.loadAndSchedule();

      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  tz.initializeTimeZones();

  await LocalNotificationService.instance.init();

  // Initialize Workmanager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false, // Set to false for release
  );

  // Register the 24-hour task
  await Workmanager().registerPeriodicTask(
    "1",
    "refreshPrayerTimes",
    frequency: const Duration(hours: 24),
    // Android minimum is 15 mins
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    // Don't overwrite if exists
    constraints: Constraints(
      networkType: NetworkType.connected, // Only run if there is internet
    ),
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      saveLocale: true,
      startLocale: const Locale('ar'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: const PrayerScreen(),
    );
  }
}
