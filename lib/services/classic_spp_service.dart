import 'dart:async';
import 'package:flutter/services.dart';

class DiscoveredDevice {
  final String name;
  final String address;
  final String type; // "classic" | "ble"
  final bool bonded;
  final int rssi;

  DiscoveredDevice({
    required this.name,
    required this.address,
    required this.type,
    required this.bonded,
    required this.rssi,
  });

  factory DiscoveredDevice.fromMap(Map<dynamic, dynamic> map) {
    return DiscoveredDevice(
      name: map['name']?.toString() ?? '未知设备',
      address: map['address']?.toString() ?? '',
      type: map['type']?.toString() ?? 'classic',
      bonded: map['bonded'] == true,
      rssi: (map['rssi'] as num?)?.toInt() ?? 0,
    );
  }
}

class ClassicSppService {
  static const MethodChannel _methodChannel = MethodChannel('com.youju.tcuapp/spp');
  static const EventChannel _dataChannel = EventChannel('com.youju.tcuapp/spp_data');
  static const EventChannel _stateChannel = EventChannel('com.youju.tcuapp/spp_state');
  static const EventChannel _deviceChannel = EventChannel('com.youju.tcuapp/spp_devices');

  final StreamController<String> _dataStreamController = StreamController<String>.broadcast();
  final StreamController<String> _stateStreamController = StreamController<String>.broadcast();
  final StreamController<List<DiscoveredDevice>> _deviceStreamController = StreamController<List<DiscoveredDevice>>.broadcast();

  StreamSubscription? _dataSubscription;
  StreamSubscription? _stateSubscription;
  StreamSubscription? _deviceSubscription;

  String _connectionState = 'disconnected'; // "disconnected", "connecting", "connected"
  String get connectionState => _connectionState;
  bool get isConnected => _connectionState == 'connected';

  ClassicSppService() {
    _initChannels();
  }

  void _initChannels() {
    _dataSubscription = _dataChannel.receiveBroadcastStream().listen((dynamic event) {
      if (event is String) {
        _dataStreamController.add(event);
      }
    }, onError: (err) {
      // Stream error
    });

    _stateSubscription = _stateChannel.receiveBroadcastStream().listen((dynamic event) {
      if (event is String) {
        _connectionState = event;
        _stateStreamController.add(event);
      }
    }, onError: (err) {
      _connectionState = 'disconnected';
      _stateStreamController.add('disconnected');
    });

    _deviceSubscription = _deviceChannel.receiveBroadcastStream().listen((dynamic event) {
      if (event is List) {
        final list = event.map((item) => DiscoveredDevice.fromMap(item as Map)).toList();
        _deviceStreamController.add(list);
      }
    }, onError: (err) {
      // Device stream error
    });
  }

  Stream<String> get dataStream => _dataStreamController.stream;
  Stream<String> get stateStream => _stateStreamController.stream;
  Stream<List<DiscoveredDevice>> get deviceStream => _deviceStreamController.stream;

  Future<bool> isBluetoothEnabled() async {
    try {
      final bool? enabled = await _methodChannel.invokeMethod<bool>('isEnabled');
      return enabled ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestEnable() async {
    try {
      final bool? success = await _methodChannel.invokeMethod<bool>('requestEnable');
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<List<DiscoveredDevice>> getBondedDevices() async {
    try {
      final List<dynamic>? res = await _methodChannel.invokeMethod<List<dynamic>>('getBondedDevices');
      if (res != null) {
        return res.map((item) => DiscoveredDevice.fromMap(item as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> startDiscovery() async {
    try {
      final bool? success = await _methodChannel.invokeMethod<bool>('startDiscovery');
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> stopDiscovery() async {
    try {
      final bool? success = await _methodChannel.invokeMethod<bool>('stopDiscovery');
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> connect(String address) async {
    try {
      final bool? res = await _methodChannel.invokeMethod<bool>('connect', {'address': address});
      return res ?? false;
    } catch (e) {
      _connectionState = 'disconnected';
      _stateStreamController.add('disconnected');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    try {
      await _methodChannel.invokeMethod('disconnect');
    } catch (_) {}
  }

  Future<bool> send(String data) async {
    try {
      final bool? res = await _methodChannel.invokeMethod<bool>('send', {'data': data});
      return res ?? false;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _dataSubscription?.cancel();
    _stateSubscription?.cancel();
    _deviceSubscription?.cancel();
    _dataStreamController.close();
    _stateStreamController.close();
    _deviceStreamController.close();
  }
}
