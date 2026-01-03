import 'package:flutter/services.dart';

class ArCoreService {
  static const MethodChannel _channel =
      MethodChannel('arcore_channel');

  static Future<void> startAR() async {
    await _channel.invokeMethod('startAR');
  }

  static Future<void> stopAR() async {
    await _channel.invokeMethod('stopAR');
  }
}
