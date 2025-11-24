import 'package:flutter/material.dart';
import 'src/core/device_info.dart';
import 'src/ui/radar_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final info = await MyDeviceInfo.getInfo();

  runApp(
    MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: RadarScreen(myInfo: info),
    ),
  );
}
