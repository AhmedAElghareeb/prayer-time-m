import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:prayer_times/src/features/parayer_screen/controller/model.dart';
import 'package:prayer_times/src/features/parayer_screen/controller/prayer_controller.dart';
import 'package:prayer_times/src/features/parayer_screen/widgets/circle_progress_timer.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen>
    with SingleTickerProviderStateMixin {
  final controller = PrayerController();

  PrayerData? data;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    controller.loadAndSchedule().then((value) {
      setState(() => data = value);
      _animationController.forward();
    });
  }

  Map<String, dynamic> getNextAndPrevPrayer(Map<String, DateTime> times) {
    final now = DateTime.now();
    final entries = times.entries.toList();

    entries.sort((a, b) => a.value.compareTo(b.value));

    for (int i = 0; i < entries.length; i++) {
      if (entries[i].value.isAfter(now)) {
        return {
          'nextName': entries[i].key,
          'nextTime': entries[i].value,
          'prevTime': i > 0
              ? entries[i - 1].value
              : entries[i].value.subtract(const Duration(hours: 6)),
        };
      }
    }

    return {
      'nextName': entries.first.key,
      'nextTime': entries.first.value.add(const Duration(days: 1)),
      'prevTime': entries.last.value,
    };
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? currentPrayerInfo;
    if (data != null) {
      currentPrayerInfo = getNextAndPrevPrayer(data!.times);
    }

    return Scaffold(
      appBar: AppBar(title: Text('times'.tr())),
      body: (data == null)
          ? const Center(
              child: CircularProgressIndicator(
              color: Colors.lightBlue,
            ))
          : Column(
              children: [
                const SizedBox(height: 20),
                // TextButton(
                //     onPressed: () async => await LocalNotificationService
                //         .instance
                //         .testAthanInTenSeconds(),
                //     child: const Text('Test Athan in 10 seconds')),
                CircleProgressTimer(
                  prayerName: currentPrayerInfo!['nextName'],
                  nextPrayerTime: currentPrayerInfo['nextTime'],
                  previousPrayerTime: currentPrayerInfo['prevTime'],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: data?.times.length,
                    itemBuilder: (context, index) {
                      final prayerEntries = data?.times.entries.toList();
                      final entry = prayerEntries?[index];
                      final animation = Tween<Offset>(
                        begin: const Offset(0, 0.4),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            index / (prayerEntries?.length ?? 0),
                            1.0,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                      );

                      final fadeAnimation = Tween<double>(
                        begin: 0,
                        end: 1,
                      ).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            index / (prayerEntries?.length ?? 0),
                            1.0,
                            curve: Curves.easeOut,
                          ),
                        ),
                      );

                      return FadeTransition(
                        opacity: fadeAnimation,
                        child: SlideTransition(
                          position: animation,
                          child: Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              title: Text(
                                entry?.key ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              trailing: Text(
                                DateFormat('hh:mm a').format(
                                  entry?.value as DateTime,
                                ),
                                textDirection: ui.TextDirection.ltr,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
