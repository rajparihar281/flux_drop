// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:dio/dio.dart' hide Response;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class TransferService {
  HttpServer? _server;
  
  // The file we want to share (for now, we just hold one file in memory)
  File? _fileToSend;

  /// 1. Start the File Server
  Future<void> startServer() async {
    final router = Router();

    // Endpoint: /info -> Tells the receiver what the file is
    router.get('/info', (Request request) {
      if (_fileToSend == null) return Response.notFound('No file selected');
      final name = path.basename(_fileToSend!.path);
      final size = _fileToSend!.lengthSync();
      return Response.ok(jsonEncode({'name': name, 'size': size}), 
        headers: {'content-type': 'application/json'});
    });

    // Endpoint: /download -> Streams the file bytes
    router.get('/download', (Request request) {
      if (_fileToSend == null) return Response.notFound('No file selected');
      return Response.ok(
        _fileToSend!.openRead(), // Stream the file efficiently
        headers: {
          'content-type': 'application/octet-stream',
          'content-disposition': 'attachment; filename="${path.basename(_fileToSend!.path)}"'
        },
      );
    });

    // Bind to ANY interface (Wi-Fi, Hotspot, etc.) on Port 4000
    _server = await shelf_io.serve(router.call, InternetAddress.anyIPv4, 4000);
    print('🚀 Transfer Server running on port ${_server!.port}');
  }

  /// 2. Set the file we want to share
  void setFile(File file) {
    _fileToSend = file;
    print('📂 File staged: ${file.path}');
  }

  /// 3. Download a file from another device
 Future<void> downloadFile(String host, int port) async {
    final dio = Dio();
    final baseUrl = 'http://$host:$port';

    try {
      print('⏳ Connecting to $baseUrl...');

      // A. Get File Info
      final infoResponse = await dio.get('$baseUrl/info');
      final Map data = infoResponse.data is String
          ? jsonDecode(infoResponse.data)
          : infoResponse.data;
      final String fileName = data['name'];

      // B. Determine Save Path (Visible Folder)
      String savePath;
      if (Platform.isAndroid) {
        // Create a 'FluxDrop' folder inside the standard Download directory
        final dir = Directory('/storage/emulated/0/Download/FluxDrop');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        savePath = path.join(dir.path, fileName);
      } else if (Platform.isIOS) {
        // iOS requires saving to Documents, then user moves it via Files app
        final dir = await getApplicationDocumentsDirectory();
        savePath = path.join(dir.path, fileName);
      } else {
        // Desktop (Windows/Mac) -> Downloads folder
        final dir = await getDownloadsDirectory();
        final fluxDropDir = Directory(path.join(dir?.path ?? '.', 'FluxDrop'));
        if (!await fluxDropDir.exists()) {
          await fluxDropDir.create(recursive: true);
        }
        savePath = path.join(fluxDropDir.path, fileName);
      }

      print('📥 Downloading to $savePath...');

      // C. Download
      await dio.download('$baseUrl/download', savePath);

      print('✅ File saved successfully!');
    } catch (e) {
      print('❌ Download failed: $e');
    }
  }



  void stop() {
    _server?.close();
  }
}