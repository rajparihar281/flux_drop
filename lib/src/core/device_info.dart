import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';

class MyDeviceInfo {
  final String id;
  final String name;
  final int type; // 1 = Mobile, 2 = Desktop

  MyDeviceInfo({
    required this.id,
    required this.name,
    required this.type,
  });

  // Factory to load current device info
  static Future<MyDeviceInfo> getInfo() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String name = 'Unknown Device';
    int type = 1;

    // 1. Get Device Name based on Platform
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        // Prefer "model" (e.g. Pixel 6) because "device" can be cryptic code names
        name = androidInfo.model; 
        type = 1;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        name = iosInfo.name;
        type = 1;
      } else if (Platform.isMacOS) {
        MacOsDeviceInfo macInfo = await deviceInfo.macOsInfo;
        name = macInfo.computerName;
        type = 2;
      } else if (Platform.isWindows) {
        WindowsDeviceInfo winInfo = await deviceInfo.windowsInfo;
        name = winInfo.computerName;
        type = 2;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error getting device info: $e');
    }

    // 2. Generate a Unique ID (In a real app, save this to SharedPreferences)
    // For MVP, generating a new one each session is fine.
    final String id = const Uuid().v4();

    return MyDeviceInfo(id: id, name: name, type: type);
  }

  // Convert to JSON to send over the network
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
  };

  factory MyDeviceInfo.fromJson(Map<String, dynamic> json) {
    return MyDeviceInfo(
      id: json['id'],
      name: json['name'],
      type: json['type'],
    );
  }
}