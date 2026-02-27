import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class TimerPainter extends CustomPainter {
  final double progress;
  final Color color;

  TimerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    Paint circlePaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    Paint progressPaint = Paint()
      ..color = color
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = min(size.width / 2, size.height / 2);

    // رسم الدائرة الخلفية الباهتة
    canvas.drawCircle(center, radius, circlePaint);

    // رسم التقدم (نبدأ من الأعلى -pi/2)
    double angle = 2 * pi * progress;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2,
        angle, false, progressPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class CircleProgressTimer extends StatefulWidget {
  final DateTime nextPrayerTime;
  final DateTime previousPrayerTime;
  final String prayerName;

  const CircleProgressTimer({
    super.key,
    required this.nextPrayerTime,
    required this.previousPrayerTime,
    required this.prayerName,
  });

  @override
  State<CircleProgressTimer> createState() => _CircleProgressTimerState();
}

class _CircleProgressTimerState extends State<CircleProgressTimer> {
  late Timer _timer;
  late Duration _remainingTime;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    // تحديث كل ثانية
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateRemainingTime();
    });
  }

  void _calculateRemainingTime() {
    setState(() {
      _remainingTime = widget.nextPrayerTime.difference(DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // حساب النسبة (المدة المتبقية / المدة الكلية بين الصلاتين)
    double totalDuration = widget.nextPrayerTime
        .difference(widget.previousPrayerTime)
        .inSeconds
        .toDouble();
    double remainingSeconds = _remainingTime.inSeconds.toDouble();
    double progress = (remainingSeconds / totalDuration).clamp(0.0, 1.0);

    // تنسيق الوقت المتبقي (HH:mm:ss)
    String hours = _remainingTime.inHours.toString().padLeft(2, '0');
    String minutes = (_remainingTime.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (_remainingTime.inSeconds % 60).toString().padLeft(2, '0');

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // SizedBox(
            //   width: 250,
            //   height: 250,
            //   child: CustomPaint(
            //     painter: TimerPainter(
            //       progress: progress,
            //       color: Colors.lightBlue,
            //     ),
            //   ),
            // ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${'remaining'.tr()} ${widget.prayerName}",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                Text(
                  "$hours:$minutes:$seconds",
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
