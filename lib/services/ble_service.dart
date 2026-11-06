import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class DiscoveredDevice {
  final BluetoothDevice device;
  final String name;
  final String id;
  final int rssi;

  DiscoveredDevice({
    required this.device,
    required this.name,
    required this.id,
    required this.rssi,
  });
}

class BleService {
  // 单例模式
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  // 预定义 TCU 服务与特征值 UUID
  static const String serviceUuid = "0000FFE0-0000-1000-8000-00805F9B34FB";
  static const String charWriteUuid = "0000FFE1-0000-1000-8000-00805F9B34FB";
  static const String charNotifyUuid = "0000FFE2-0000-1000-8000-00805F9B34FB";

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;

  BluetoothDevice? get connectedDevice => _connectedDevice;

  // 状态流
  Stream<BluetoothAdapterState> get adapterStateStream => FlutterBluePlus.adapterState;
  Stream<List<ScanResult>> get scanResultsStream => FlutterBluePlus.scanResults;
  Stream<bool> get isScanningStream => FlutterBluePlus.isScanning;
  Stream<List<int>> get dataNotificationStream =>
      _notifyCharacteristic?.onValueReceived ?? const Stream.empty();

  // 请求 Android 12+ 动态蓝牙与定位权限
  Future<bool> requestPermissions() async {
    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();
    final location = await Permission.locationWhenInUse.request();

    return scan.isGranted && connect.isGranted && location.isGranted;
  }

  // 开启原生系统蓝牙
  Future<void> turnOnBluetooth() async {
    try {
      await FlutterBluePlus.turnOn();
    } catch (e) {
      // 部分 Android 厂商限制，捕获异常
    }
  }

  // 开始扫描
  Future<void> startScan({Duration timeout = const Duration(seconds: 5)}) async {
    await requestPermissions();
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }
    await FlutterBluePlus.startScan(timeout: timeout);
  }

  // 停止扫描
  Future<void> stopScan() async {
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }
  }

  // 连接设备
  Future<bool> connectDevice(BluetoothDevice device, {Duration timeout = const Duration(seconds: 15)}) async {
    try {
      if (_connectedDevice != null && _connectedDevice!.remoteId != device.remoteId) {
        await disconnectDevice();
      }

      await device.connect(timeout: timeout, autoConnect: false);
      _connectedDevice = device;

      // 探索服务
      await discoverServices(device);
      return true;
    } catch (e) {
      _connectedDevice = null;
      return false;
    }
  }

  // 发现服务并绑定特征值
  Future<List<BluetoothService>> discoverServices(BluetoothDevice device) async {
    final services = await device.discoverServices();
    _writeCharacteristic = null;
    _notifyCharacteristic = null;

    for (final s in services) {
      for (final c in s.characteristics) {
        if (c.properties.write || c.properties.writeWithoutResponse) {
          _writeCharacteristic ??= c;
        }
        if (c.properties.notify || c.properties.indicate) {
          _notifyCharacteristic ??= c;
          try {
            await c.setNotifyValue(true);
          } catch (_) {}
        }
      }
    }
    return services;
  }

  // 写入数据
  Future<bool> writeData(List<int> bytes) async {
    if (_writeCharacteristic == null) return false;
    try {
      await _writeCharacteristic!.write(bytes, withoutResponse: _writeCharacteristic!.properties.writeWithoutResponse);
      return true;
    } catch (e) {
      return false;
    }
  }

  // 断开连接
  Future<void> disconnectDevice() async {
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (_) {}
      _connectedDevice = null;
      _writeCharacteristic = null;
      _notifyCharacteristic = null;
    }
  }
}
