import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/material.dart';
import '../core/device_info.dart';
import '../discovery/discovery_service.dart';

class RadarScreen extends StatefulWidget {
  final MyDeviceInfo myInfo;
  const RadarScreen({super.key, required this.myInfo});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  final DiscoveryService _discoveryService = DiscoveryService();

  @override
  void initState() {
    super.initState();
    _startRadar();
  }

  Future<void> _startRadar() async {
    // Start both Broadcasting and Scanning
    await _discoveryService.startBroadcast(widget.myInfo);
    await _discoveryService.startDiscovery();
  }

  @override
  void dispose() {
    _discoveryService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FluxDrop Radar 📡')),
      body: Column(
        children: [
          // Header: Who am I?
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            width: double.infinity,
            child: Column(
              children: [
                const Text('Visible as:', style: TextStyle(color: Colors.grey)),
                Text(
                  widget.myInfo.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // The List of Found Devices
          Expanded(
            child: StreamBuilder<List<BonsoirService>>(
              stream: _discoveryService.devicesStream,
              builder: (context, snapshot) {
                final devices = snapshot.data ?? [];

                if (devices.isEmpty) {
                  return const Center(
                    child: Text('Scanning for nearby devices...'),
                  );
                }

                return ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    // We extract the REAL name from the attributes map we sent earlier
                    final realName =
                        device.attributes['real_name'] ?? 'Unknown';
                    final type = device.attributes['type'] == '2'
                        ? Icons.laptop
                        : Icons.phone_android;

                    return ListTile(
                      leading: Icon(type, size: 32, color: Colors.blue),
                      title: Text(
                        realName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${device.host} : ${device.port}'),
                      trailing: ElevatedButton(
                        onPressed: () {
                          // ignore: avoid_print
                          print("Connect clicked for ${device.name}");
                        },
                        child: const Text('Send'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
