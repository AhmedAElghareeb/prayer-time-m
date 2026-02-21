import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:prayer_times/src/features/parayer_screen/controller/prayer_controller.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen>
    with SingleTickerProviderStateMixin {
  final controller = PrayerController();
  Map<String, DateTime>? data;

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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('times'.tr())),
      body: (data == null)
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: data!.length,
              itemBuilder: (context, index) {
                final entry = data!.entries.elementAt(index);
                final animation = Tween<Offset>(
                  begin: const Offset(0, 0.4),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      index / data!.length,
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
                      index / data!.length,
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
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        trailing: Text(
                          DateFormat('hh:mm a').format(entry.value),
                          textDirection: ui.TextDirection.ltr,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
