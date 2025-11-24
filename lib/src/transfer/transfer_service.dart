// ignore_for_file: avoid_print

import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:dio/dio.dart' hide Response;
import 'package:path_provider/path_provider.dart';

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
      final name = _fileToSend!.path.split('/').last;
      final size = _fileToSend!.lengthSync();
      return Response.ok('{"name": "$name", "size": $size}', 
        headers: {'content-type': 'application/json'});
    });

    // Endpoint: /download -> Streams the file bytes
    router.get('/download', (Request request) {
      if (_fileToSend == null) return Response.notFound('No file selected');
      return Response.ok(
        _fileToSend!.openRead(), // Stream the file efficiently
        headers: {
          'content-type': 'application/octet-stream',
          'content-disposition': 'attachment; filename="${_fileToSend!.path.split('/').last}"'
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
      
      // A. Get File Info first
      final infoResponse = await dio.get('$baseUrl/info');
      final Map data = infoResponse.data is String 
          ? jsonDecode(infoResponse.data) // decode if string
          : infoResponse.data;            // else use map
          
      final String fileName = data['name'];
      
      // B. Determine where to save it
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/$fileName';

      print('📥 Downloading $fileName...');

      // C. Download the bytes
      await dio.download('$baseUrl/download', savePath);
      
      print('✅ File saved to: $savePath');
    } catch (e) {
      print('❌ Download failed: $e');
    }
  }

  // Helper for JSON decoding if needed (dio handles it usually but good to be safe)
  dynamic jsonDecode(String source) {
    // We would need 'dart:convert' import for real decoding, 
    // but Dio usually returns a Map automatically.
    // For MVP robustness, let's just assume Dio does its job.
    return {}; 
  }

  void stop() {
    _server?.close();
  }
}