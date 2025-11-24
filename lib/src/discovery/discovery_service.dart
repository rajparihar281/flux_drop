import 'dart:async';
import 'dart:io';
import 'package:bonsoir/bonsoir.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/device_info.dart';

class DiscoveryService {
  static const String _serviceType = '_fluxdrop._tcp';

  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;

  final StreamController<List<BonsoirService>> _devicesController =
      StreamController.broadcast();
  Stream<List<BonsoirService>> get devicesStream => _devicesController.stream;

  final List<BonsoirService> _foundDevices = [];

  /// 1. Start Advertising "I am Here"
  Future<void> startBroadcast(MyDeviceInfo info) async {
    if (Platform.isAndroid) {
      await [Permission.location, Permission.nearbyWifiDevices].request();
    }

    String safeId = info.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

    BonsoirService service = BonsoirService(
      name: 'flux_$safeId',
      type: _serviceType,
      port: 4000,
      attributes: {'real_name': info.name, 'type': info.type.toString()},
    );

    _broadcast = BonsoirBroadcast(service: service);

    // FIX: 'ready' call removed completely.
    await _broadcast!.start();

    // ignore: avoid_print
    print('📡 Broadcasting started as: ${info.name}');
  }

  /// 2. Start Listening for others
  Future<void> startDiscovery() async {
    _discovery = BonsoirDiscovery(type: _serviceType);

    // FIX: 'ready' call removed completely.

    _discovery!.eventStream!.listen((event) {
      if (event is BonsoirDiscoveryServiceFoundEvent) {
        // ignore: avoid_print
        print('🔎 Found device: ${event.service.name}');
        event.service.resolve(_discovery!.serviceResolver);
      } else if (event is BonsoirDiscoveryServiceResolvedEvent) {
        _addDevice(event.service);
      } else if (event is BonsoirDiscoveryServiceLostEvent) {
        // FIX: service is non-nullable now, so no need for checks
        _removeDevice(event.service);
      }
    });

    await _discovery!.start();
    // ignore: avoid_print
    print('👀 Discovery started...');
  }

  void _addDevice(BonsoirService service) {
    final index = _foundDevices.indexWhere((s) => s.name == service.name);
    if (index != -1) return;

    _foundDevices.add(service);
    _devicesController.add(List.from(_foundDevices));
  }

  void _removeDevice(BonsoirService service) {
    _foundDevices.removeWhere((s) => s.name == service.name);
    _devicesController.add(List.from(_foundDevices));
  }

  void stop() {
    _broadcast?.stop();
    _discovery?.stop();
    _devicesController.close();
  }
}
