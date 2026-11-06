import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'classic_spp_service.dart';
import 'ble_service.dart';
import '../models/ncu_protocol.dart';

enum DeviceTransportType {
  classicSpp,
  ble,
}

class UnifiedDevice {
  final String id;
  final String name;
  final DeviceTransportType transportType;
  final bool isBonded;
  final int rssi;
  final BluetoothDevice? bleDevice;

  UnifiedDevice({
    required this.id,
    required this.name,
    required this.transportType,
    this.isBonded = false,
    this.rssi = 0,
    this.bleDevice,
  });

  String get displayName {
    if (name.isNotEmpty && name != '未知设备') {
      return name;
    }
    return '设备 ($id)';
  }
}

class UnifiedBluetoothService {
  static final UnifiedBluetoothService _instance = UnifiedBluetoothService._internal();
  factory UnifiedBluetoothService() => _instance;
  UnifiedBluetoothService._internal() {
    _init();
  }

  final ClassicSppService _sppService = ClassicSppService();
  final BleService _bleService = BleService();

  final Map<String, UnifiedDevice> _discoveredDevices = {};
  final StreamController<List<UnifiedDevice>> _devicesController = StreamController<List<UnifiedDevice>>.broadcast();
  final StreamController<String> _connectionStateController = StreamController<String>.broadcast();
  final StreamController<String> _rawLogController = StreamController<String>.broadcast();

  // 遥测数据与 ACK 流
  final StreamController<NcuTelemetry> _telemetryController = StreamController<NcuTelemetry>.broadcast();
  final StreamController<NcuCommandAck> _ackController = StreamController<NcuCommandAck>.broadcast();

  StreamSubscription? _sppDataSub;
  StreamSubscription? _sppStateSub;
  StreamSubscription? _sppDeviceSub;

  StreamSubscription? _bleScanSub;
  StreamSubscription? _bleNotifySub;

  UnifiedDevice? _connectedDevice;
  String _currentState = 'disconnected'; // disconnected, connecting, connected
  int _requestIdCounter = 1;

  UnifiedDevice? get connectedDevice => _connectedDevice;
  String get connectionState => _currentState;
  bool get isConnected => _currentState == 'connected';

  Stream<List<UnifiedDevice>> get devicesStream => _devicesController.stream;
  Stream<String> get connectionStateStream => _connectionStateController.stream;
  Stream<String> get rawLogStream => _rawLogController.stream;
  Stream<NcuTelemetry> get telemetryStream => _telemetryController.stream;
  Stream<NcuCommandAck> get ackStream => _ackController.stream;

  void _init() {
    // 监听经典蓝牙设备扫描结果
    _sppDeviceSub = _sppService.deviceStream.listen((sppList) {
      for (final dev in sppList) {
        _discoveredDevices[dev.address] = UnifiedDevice(
          id: dev.address,
          name: dev.name,
          transportType: DeviceTransportType.classicSpp,
          isBonded: dev.bonded,
          rssi: dev.rssi,
        );
      }
      _emitDevices();
    });

    // 监听经典蓝牙状态
    _sppStateSub = _sppService.stateStream.listen((state) {
      if (_connectedDevice?.transportType == DeviceTransportType.classicSpp) {
        _currentState = state;
        _connectionStateController.add(state);
        _log('[SPP 状态] $state');
      }
    });

    // 监听经典蓝牙接收数据 (以 \r\n 分割的 JSON)
    _sppDataSub = _sppService.dataStream.listen((data) {
      _log('[RX-SPP] $data');
      _processIncomingJson(data);
    });

    // 监听 BLE 扫描
    _bleScanSub = _bleService.scanResultsStream.listen((results) {
      for (final r in results) {
        final name = r.advertisementData.advName.isNotEmpty
            ? r.advertisementData.advName
            : r.device.platformName;
        final id = r.device.remoteId.str;
        // 如果经典蓝牙已经扫到该 MAC，且带名字，以经典蓝牙或带名字的为准
        if (!_discoveredDevices.containsKey(id) || _discoveredDevices[id]?.name == '未知设备') {
          _discoveredDevices[id] = UnifiedDevice(
            id: id,
            name: name.isEmpty ? 'BLE 设备' : name,
            transportType: DeviceTransportType.ble,
            rssi: r.rssi,
            bleDevice: r.device,
          );
        }
      }
      _emitDevices();
    });

    // 监听 BLE 接收
    _bleNotifySub = _bleService.dataNotificationStream.listen((bytes) {
      try {
        final text = utf8.decode(bytes);
        _log('[RX-BLE] $text');
        _processIncomingJson(text);
      } catch (_) {}
    });
  }

  void _log(String msg) {
    if (kDebugMode) {
      print(msg);
    }
    _rawLogController.add(msg);
  }

  void _processIncomingJson(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        final type = decoded['message_type']?.toString();
        if (type == 'telemetry') {
          final telemetry = NcuTelemetry.fromJson(decoded);
          _telemetryController.add(telemetry);
        } else if (type == 'command_ack') {
          final ack = NcuCommandAck.fromJson(decoded);
          _ackController.add(ack);
        }
      }
    } catch (e) {
      // 容错：可能收到的不是 JSON 格式或者是片段
    }
  }

  void _emitDevices() {
    final list = _discoveredDevices.values.toList();
    // 排序：已配对设备排在最前，其次按信号或名称
    list.sort((a, b) {
      if (a.isBonded && !b.isBonded) return -1;
      if (!a.isBonded && b.isBonded) return 1;
      // 优先将含 JDY 或 HC 或 TCU 的排前面
      final aKey = a.name.toUpperCase().contains('JDY') || a.name.toUpperCase().contains('HC');
      final bKey = b.name.toUpperCase().contains('JDY') || b.name.toUpperCase().contains('HC');
      if (aKey && !bKey) return -1;
      if (!aKey && bKey) return 1;
      return b.rssi.compareTo(a.rssi);
    });
    _devicesController.add(list);
  }

  /// 扫描前先读取系统已配对的经典蓝牙设备（如 JDY-31-SPP, HC-05 等）
  Future<void> loadBondedDevices() async {
    final bonded = await _sppService.getBondedDevices();
    for (final dev in bonded) {
      _discoveredDevices[dev.address] = UnifiedDevice(
        id: dev.address,
        name: dev.name,
        transportType: DeviceTransportType.classicSpp,
        isBonded: true,
        rssi: 0,
      );
    }
    _emitDevices();
  }

  /// 启动全网双模扫描：经典蓝牙 + BLE
  Future<void> startScan() async {
    _discoveredDevices.clear();
    await loadBondedDevices();

    // 启动原生经典蓝牙扫描
    await _sppService.startDiscovery();

    // 启动 BLE 扫描
    try {
      await _bleService.startScan();
    } catch (_) {}
  }

  Future<void> stopScan() async {
    await _sppService.stopDiscovery();
    try {
      await _bleService.stopScan();
    } catch (_) {}
  }

  /// 连接指定设备
  Future<bool> connect(UnifiedDevice device) async {
    await stopScan();
    _currentState = 'connecting';
    _connectedDevice = device;
    _connectionStateController.add('connecting');
    _log('[连接开始] ${device.displayName} (${device.transportType.name})');

    try {
      if (device.transportType == DeviceTransportType.classicSpp) {
        final ok = await _sppService.connect(device.id);
        if (ok) {
          _currentState = 'connected';
          _connectionStateController.add('connected');
          _log('[连接成功] 经典蓝牙 SPP 连接建立');
          return true;
        }
      } else {
        if (device.bleDevice != null) {
          final ok = await _bleService.connectDevice(device.bleDevice!);
          if (ok) {
            _currentState = 'connected';
            _connectionStateController.add('connected');
            _log('[连接成功] BLE 连接建立');
            return true;
          }
        }
      }
    } catch (e) {
      _log('[连接失败] $e');
    }

    _currentState = 'disconnected';
    _connectedDevice = null;
    _connectionStateController.add('disconnected');
    return false;
  }

  Future<void> disconnect() async {
    if (_connectedDevice?.transportType == DeviceTransportType.classicSpp) {
      await _sppService.disconnect();
    } else {
      await _bleService.disconnectDevice();
    }
    _currentState = 'disconnected';
    _connectedDevice = null;
    _connectionStateController.add('disconnected');
    _log('[断开连接]');
  }

  /// 发送下位机协议 JSON 指令
  Future<bool> sendCommand(NcuCommand cmd) async {
    final jsonStr = cmd.toJsonString();
    _log('[TX-CMD] $jsonStr');
    return sendRawText(jsonStr);
  }

  /// 发送文本 (自动添加 CRLF)
  Future<bool> sendRawText(String text) async {
    if (!isConnected || _connectedDevice == null) {
      _log('[TX 失败] 设备未连接');
      return false;
    }
    if (_connectedDevice!.transportType == DeviceTransportType.classicSpp) {
      return await _sppService.send(text);
    } else {
      // BLE 发送
      final payload = text.endsWith('\r\n') ? text : '$text\r\n';
      return await _bleService.writeData(utf8.encode(payload));
    }
  }

  int getNextRequestId() {
    return _requestIdCounter++;
  }

  void dispose() {
    _sppDataSub?.cancel();
    _sppStateSub?.cancel();
    _sppDeviceSub?.cancel();
    _bleScanSub?.cancel();
    _bleNotifySub?.cancel();
    _devicesController.close();
    _connectionStateController.close();
    _rawLogController.close();
    _telemetryController.close();
    _ackController.close();
    _sppService.dispose();
  }
}
