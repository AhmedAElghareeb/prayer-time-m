import 'dart:io';

import 'package:flutter/services.dart';

class ExactAlarmPermission {
  static const _channel = MethodChannel('exact_alarm_permission');

  static Future<bool> isGranted() async {
    if (!Platform.isAndroid) return true;
    return await _channel.invokeMethod<bool>('isGranted') ?? false;
  }

  static Future<void> openSettings() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('openSettings');
  }
}
