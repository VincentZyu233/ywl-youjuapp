import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_service.dart';

enum DeviceConnectionState {
  disconnected,
  connecting,
  connected,
}

class BleProvider extends ChangeNotifier {
  final BleService _bleService = BleService();

  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  bool _isScanning = false;
  final Map<String, DiscoveredDevice> _devicesMap = {};
  DeviceConnectionState _connectionState = DeviceConnectionState.disconnected;
  String? _connectedDeviceId;

  StreamSubscription? _adapterSub;
  StreamSubscription? _scanSub;
  StreamSubscription? _scanningStateSub;

  BluetoothAdapterState get adapterState => _adapterState;
  bool get isBluetoothOn => _adapterState == BluetoothAdapterState.on;
  bool get isScanning => _isScanning;
  List<DiscoveredDevice> get devices => _devicesMap.values.toList();
  DeviceConnectionState get connectionState => _connectionState;
  String? get connectedDeviceId => _connectedDeviceId;

  BleProvider() {
    _init();
  }

  void _init() {
    _adapterSub = _bleService.adapterStateStream.listen((state) {
      _adapterState = state;
      if (state != BluetoothAdapterState.on) {
        _devicesMap.clear();
        _isScanning = false;
      }
      notifyListeners();
    });

    _scanningStateSub = _bleService.isScanningStream.listen((scanning) {
      _isScanning = scanning;
      notifyListeners();
    });

    _scanSub = _bleService.scanResultsStream.listen((results) {
      for (final r in results) {
        final name = r.advertisementData.advName.isNotEmpty 
            ? r.advertisementData.advName 
            : r.device.platformName;

        // 过滤空名称与未知设备
        if (name.isNotEmpty && name.toLowerCase() != 'unknown') {
          final id = r.device.remoteId.str;
          _devicesMap[id] = DiscoveredDevice(
            device: r.device,
            name: name,
            id: id,
            rssi: r.rssi,
          );
        }
      }
      notifyListeners();
    });
  }

  Future<void> toggleBluetooth() async {
    if (isBluetoothOn) {
      await stopScan();
      // Android 系统出于隐私和安全规范，应用无法直接关闭系统全局蓝牙，但可提示或断开
    } else {
      await _bleService.turnOnBluetooth();
    }
  }

  Future<void> startScan() async {
    if (_isScanning) return;
    _devicesMap.clear();
    notifyListeners();
    await _bleService.startScan();
  }

  Future<void> stopScan() async {
    await _bleService.stopScan();
  }

  Future<bool> connect(DiscoveredDevice discovered) async {
    _connectionState = DeviceConnectionState.connecting;
    _connectedDeviceId = discovered.id;
    notifyListeners();

    final success = await _bleService.connectDevice(discovered.device);
    if (success) {
      _connectionState = DeviceConnectionState.connected;
    } else {
      _connectionState = DeviceConnectionState.disconnected;
      _connectedDeviceId = null;
    }
    notifyListeners();
    return success;
  }

  Future<void> disconnect() async {
    await _bleService.disconnectDevice();
    _connectionState = DeviceConnectionState.disconnected;
    _connectedDeviceId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _adapterSub?.cancel();
    _scanSub?.cancel();
    _scanningStateSub?.cancel();
    super.dispose();
  }
}
