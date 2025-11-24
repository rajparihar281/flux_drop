import 'package:flutter/material.dart';
import 'src/core/device_info.dart';
import 'src/ui/radar_screen.dart';
void main() async {
  // 1. Ensure Flutter binding is ready (needed for async calls before runApp)
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Load the device info (this calls the file you just created)
  final info = await MyDeviceInfo.getInfo();

  // 3. Run the app with the data passed in
 runApp(
    MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: RadarScreen(myInfo: info), // <--- Load the Radar
    ),
  );
}
