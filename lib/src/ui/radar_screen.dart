import 'dart:io';
import 'package:bonsoir/bonsoir.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../core/device_info.dart';
import '../discovery/discovery_service.dart';
import '../transfer/transfer_service.dart'; // Import TransferService

class RadarScreen extends StatefulWidget {
  final MyDeviceInfo myInfo;
  const RadarScreen({super.key, required this.myInfo});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  final DiscoveryService _discoveryService = DiscoveryService();
  final TransferService _transferService = TransferService(); // 1. Create Transfer Instance
  
  File? _selectedFile; // Track what we are sharing

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    // Start Discovery (Radar)
    await _discoveryService.startBroadcast(widget.myInfo);
    await _discoveryService.startDiscovery();
    
    // Start File Server (Transfer)
    await _transferService.startServer();
  }

  @override
  void dispose() {
    _discoveryService.stop();
    _transferService.stop(); // Stop server on exit
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
      // Tell the server: "This is the file to serve"
      _transferService.setFile(_selectedFile!);
      
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Staged: ${path.basename(_selectedFile!.path)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FluxDrop Radar 📡')),
      
      // 2. Button to Pick File
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickFile,
        icon: const Icon(Icons.add),
        label: Text(_selectedFile == null ? 'Select File' : 'Change File'),
        backgroundColor: _selectedFile == null ? Colors.blue : Colors.green,
      ),
      
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            width: double.infinity,
            child: Column(
              children: [
                Text(widget.myInfo.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(_selectedFile == null ? "No file selected" : "Serving: ${path.basename(_selectedFile!.path)}",
                    style: TextStyle(color: _selectedFile == null ? Colors.grey : Colors.green)),
              ],
            ),
          ),
          
          // Device List
          Expanded(
            child: StreamBuilder<List<BonsoirService>>(
              stream: _discoveryService.devicesStream,
              builder: (context, snapshot) {
                final devices = snapshot.data ?? [];
                if (devices.isEmpty) return const Center(child: Text('Scanning...'));

                return ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    final realName = device.attributes['real_name'] ?? 'Unknown';

                    return ListTile(
                      leading: const Icon(Icons.laptop, size: 32, color: Colors.blue),
                      title: Text(realName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${device.host} : ${device.port}'),
                      trailing: ElevatedButton(
                        child: const Text('Download'),
                        onPressed: () {
                          // 3. Connect to this device to download
                          if (device.host != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Connecting to $realName...')),
                            );
                            _transferService.downloadFile(device.host!, device.port);
                          }
                        },
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