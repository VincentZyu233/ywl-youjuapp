import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/unified_bluetooth_service.dart';

enum DeviceConnectionState {
  disconnected,
  connecting,
  connected,
}

class BleProvider extends ChangeNotifier {
  final UnifiedBluetoothService _service = UnifiedBluetoothService();

  bool _isScanning = false;
  List<UnifiedDevice> _devices = [];
  DeviceConnectionState _connectionState = DeviceConnectionState.disconnected;
  UnifiedDevice? _connectedDevice;
  final List<String> _communicationLogs = [];

  StreamSubscription? _deviceSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _logSub;

  bool get isScanning => _isScanning;
  List<UnifiedDevice> get devices => _devices;
  DeviceConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == DeviceConnectionState.connected;
  UnifiedDevice? get connectedDevice => _connectedDevice;
  String? get connectedDeviceId => _connectedDevice?.id;
  List<String> get logs => List.unmodifiable(_communicationLogs);

  BleProvider() {
    _init();
  }

  void _init() {
    _deviceSub = _service.devicesStream.listen((devList) {
      _devices = devList;
      notifyListeners();
    });

    _stateSub = _service.connectionStateStream.listen((stateStr) {
      if (stateStr == 'connected') {
        _connectionState = DeviceConnectionState.connected;
        _connectedDevice = _service.connectedDevice;
      } else if (stateStr == 'connecting') {
        _connectionState = DeviceConnectionState.connecting;
      } else {
        _connectionState = DeviceConnectionState.disconnected;
        _connectedDevice = null;
      }
      notifyListeners();
    });

    _logSub = _service.rawLogStream.listen((log) {
      _communicationLogs.add('${DateTime.now().toString().substring(11, 19)} $log');
      if (_communicationLogs.length > 200) {
        _communicationLogs.removeAt(0);
      }
      notifyListeners();
    });

    // 默认启动时加载已配对设备
    _service.loadBondedDevices();
  }

  Future<bool> checkAndRequestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    bool allGranted = true;
    statuses.forEach((key, status) {
      if (status.isPermanentlyDenied) {
        allGranted = false;
      }
    });
    return allGranted;
  }

  Future<bool> checkBluetoothEnabled() async {
    return await _service.isBluetoothEnabled();
  }

  Future<void> requestTurnOnBluetooth() async {
    await _service.requestEnableBluetooth();
  }

  Future<void> startScan() async {
    if (_isScanning) return;

    final hasPerm = await checkAndRequestPermissions();
    if (!hasPerm) {
      Fluttertoast.showToast(msg: "请在系统设置中授予蓝牙与位置权限");
      return;
    }

    final isEnabled = await _service.isBluetoothEnabled();
    if (!isEnabled) {
      Fluttertoast.showToast(msg: "蓝牙未开启，正在请求打开系统蓝牙...");
      await _service.requestEnableBluetooth();
      return;
    }

    _isScanning = true;
    notifyListeners();

    try {
      await _service.startScan();
    } catch (e) {
      _isScanning = false;
      notifyListeners();
      Fluttertoast.showToast(msg: "启动扫描失败: $e");
    }

    // 经典蓝牙扫描一般 12 秒左右，设置 15 秒后自动停止扫描状态
    Future.delayed(const Duration(seconds: 15), () {
      if (_isScanning) {
        stopScan();
      }
    });
  }

  Future<void> stopScan() async {
    _isScanning = false;
    notifyListeners();
    await _service.stopScan();
  }

  Future<bool> connect(UnifiedDevice device) async {
    _connectionState = DeviceConnectionState.connecting;
    _connectedDevice = device;
    notifyListeners();

    final success = await _service.connect(device);
    if (!success) {
      _connectionState = DeviceConnectionState.disconnected;
      _connectedDevice = null;
      Fluttertoast.showToast(msg: "连接失败，请确认设备已通电并处于范围内");
    } else {
      Fluttertoast.showToast(msg: "已连接到 ${device.displayName}");
    }
    notifyListeners();
    return success;
  }

  Future<void> disconnect() async {
    await _service.disconnect();
    _connectionState = DeviceConnectionState.disconnected;
    _connectedDevice = null;
    notifyListeners();
  }

  void clearLogs() {
    _communicationLogs.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _deviceSub?.cancel();
    _stateSub?.cancel();
    _logSub?.cancel();
    super.dispose();
  }
}
