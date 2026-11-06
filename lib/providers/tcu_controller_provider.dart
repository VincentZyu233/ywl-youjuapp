import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/unified_bluetooth_service.dart';
import '../models/ncu_protocol.dart';

class AstronomicalParams {
  String longitude;
  String latitude;
  String timezone;

  AstronomicalParams({
    this.longitude = '112.83',
    this.latitude = '23.11',
    this.timezone = '8',
  });
}

class ComponentParams {
  String width;
  String spacing;

  ComponentParams({
    this.width = '2.3',
    this.spacing = '5.5',
  });
}

class ProtectionParams {
  String overcurrent;
  String nightReturnAngle;
  String cleanAngle;
  String windAngle;
  String tcuVersion;

  ProtectionParams({
    this.overcurrent = '6500',
    this.nightReturnAngle = '0',
    this.cleanAngle = '30',
    this.windAngle = '0',
    this.tcuVersion = '7.1.08',
  });
}

class LimitAngles {
  String east;
  String west;

  LimitAngles({
    this.east = '-45',
    this.west = '45',
  });
}

class TcuControllerProvider extends ChangeNotifier {
  final UnifiedBluetoothService _service = UnifiedBluetoothService();

  String _currentTime = '';
  Timer? _timer;

  String tcuVersionNumber = '12';
  String netStatus = '2';

  final List<String> availableTcuVersions = ['7.1.08', '7.1.09', '8.0.01'];

  AstronomicalParams astronomical = AstronomicalParams();
  ComponentParams component = ComponentParams();
  ProtectionParams protection = ProtectionParams();
  LimitAngles limitAngles = LimitAngles();

  // 遥测与通信状态
  NcuTelemetry? _latestTelemetry;
  NcuCommandAck? _lastAck;
  StreamSubscription? _telemetrySub;
  StreamSubscription? _ackSub;

  NcuTelemetry? get latestTelemetry => _latestTelemetry;
  NcuCommandAck? get lastAck => _lastAck;
  String get currentTime => _currentTime;

  TcuControllerProvider() {
    _startClock();
    _loadFromPrefs();
    _initProtocolListeners();
  }

  void _startClock() {
    _updateClock();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
  }

  void _updateClock() {
    final now = DateTime.now();
    _currentTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    notifyListeners();
  }

  void _initProtocolListeners() {
    _telemetrySub = _service.telemetryStream.listen((telemetry) {
      _latestTelemetry = telemetry;
      notifyListeners();
    });

    _ackSub = _service.ackStream.listen((ack) {
      _lastAck = ack;
      Fluttertoast.showToast(
        msg: "指令 [${ack.cmdType}] 回执: ${ack.status} (${ack.message.isNotEmpty ? ack.message : 'OK'})",
      );
      notifyListeners();
    });
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    astronomical.longitude = prefs.getString('astro_long') ?? '112.83';
    astronomical.latitude = prefs.getString('astro_lat') ?? '23.11';
    astronomical.timezone = prefs.getString('astro_tz') ?? '8';

    component.width = prefs.getString('comp_width') ?? '2.3';
    component.spacing = prefs.getString('comp_spacing') ?? '5.5';

    protection.overcurrent = prefs.getString('prot_overcurrent') ?? '6500';
    protection.nightReturnAngle = prefs.getString('prot_night_angle') ?? '0';
    protection.cleanAngle = prefs.getString('prot_clean_angle') ?? '30';
    protection.windAngle = prefs.getString('prot_wind_angle') ?? '0';
    protection.tcuVersion = prefs.getString('prot_tcu_version') ?? '7.1.08';

    limitAngles.east = prefs.getString('limit_east') ?? '-45';
    limitAngles.west = prefs.getString('limit_west') ?? '45';

    notifyListeners();
  }

  /// 发送交接文档规范中的 10 项标准指令
  Future<bool> sendNcuCommand({
    required String cmdType,
    String tcuId = 'ALL',
    String controlMode = 'manual',
    double? targetAngle,
  }) async {
    final cmd = NcuCommand(
      requestId: _service.getNextRequestId(),
      cmdType: cmdType,
      tcuId: tcuId,
      controlMode: controlMode,
      targetAngle: targetAngle,
    );

    final ok = await _service.sendCommand(cmd);
    if (ok) {
      Fluttertoast.showToast(msg: "指令已下发: $cmdType (目标: $tcuId)");
    } else {
      Fluttertoast.showToast(msg: "指令下发失败 (请检查蓝牙连接)");
    }
    return ok;
  }

  // 10 大便捷指令封装
  Future<void> cmdSetAngle({required double angle, String tcuId = 'ALL'}) async {
    await sendNcuCommand(cmdType: NcuCommand.CMD_SET_ANGLE, tcuId: tcuId, targetAngle: angle);
  }

  Future<void> cmdStop({String tcuId = 'ALL'}) async {
    await sendNcuCommand(cmdType: NcuCommand.CMD_STOP, tcuId: tcuId);
  }

  Future<void> cmdResetFault({String tcuId = 'ALL'}) async {
    await sendNcuCommand(cmdType: NcuCommand.CMD_RESET, tcuId: tcuId);
  }

  Future<void> cmdAutoAll() async {
    await sendNcuCommand(cmdType: NcuCommand.CMD_AUTO_ALL, tcuId: 'ALL', controlMode: 'auto');
  }

  Future<void> cmdTurnEast() async {
    await sendNcuCommand(cmdType: NcuCommand.CMD_TURN_EAST, tcuId: 'ALL', targetAngle: 45.0);
  }

  Future<void> cmdTurnWest() async {
    await sendNcuCommand(cmdType: NcuCommand.CMD_TURN_WEST, tcuId: 'ALL', targetAngle: -45.0);
  }

  Future<void> cmdFlatAll() async {
    await sendNcuCommand(cmdType: NcuCommand.CMD_FLAT_ALL, tcuId: 'ALL', targetAngle: 0.0);
  }

  Future<void> cmdCleanAll() async {
    await sendNcuCommand(cmdType: NcuCommand.CMD_CLEAN_ALL, tcuId: 'ALL', targetAngle: 45.0);
  }

  Future<void> cmdWindMode() async {
    await sendNcuCommand(cmdType: NcuCommand.CMD_WIND_MODE, tcuId: 'ALL', targetAngle: 0.0);
  }

  Future<void> cmdCloudyMode() async {
    await sendNcuCommand(cmdType: NcuCommand.CMD_CLOUDY_MODE, tcuId: 'ALL', targetAngle: 0.0);
  }

  // 参数保存与下发
  Future<void> saveAstronomicalParams() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('astro_long', astronomical.longitude);
    await prefs.setString('astro_lat', astronomical.latitude);
    await prefs.setString('astro_tz', astronomical.timezone);

    final paramMap = {
      'protocol_version': 1,
      'message_type': 'config',
      'config_type': 'astronomical',
      'longitude': double.tryParse(astronomical.longitude) ?? 112.83,
      'latitude': double.tryParse(astronomical.latitude) ?? 23.11,
      'timezone': int.tryParse(astronomical.timezone) ?? 8,
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
    await _service.sendRawText(jsonEncode(paramMap));

    Fluttertoast.showToast(msg: "天文参数已保存并广播");
    notifyListeners();
  }

  Future<void> saveComponentParams() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('comp_width', component.width);
    await prefs.setString('comp_spacing', component.spacing);

    final paramMap = {
      'protocol_version': 1,
      'message_type': 'config',
      'config_type': 'component',
      'width': double.tryParse(component.width) ?? 2.3,
      'spacing': double.tryParse(component.spacing) ?? 5.5,
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
    await _service.sendRawText(jsonEncode(paramMap));

    Fluttertoast.showToast(msg: "组件参数已保存并广播");
    notifyListeners();
  }

  Future<void> saveProtectionParams() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('prot_overcurrent', protection.overcurrent);
    await prefs.setString('prot_night_angle', protection.nightReturnAngle);
    await prefs.setString('prot_clean_angle', protection.cleanAngle);
    await prefs.setString('prot_wind_angle', protection.windAngle);
    await prefs.setString('prot_tcu_version', protection.tcuVersion);

    final paramMap = {
      'protocol_version': 1,
      'message_type': 'config',
      'config_type': 'protection',
      'overcurrent': int.tryParse(protection.overcurrent) ?? 6500,
      'night_angle': double.tryParse(protection.nightReturnAngle) ?? 0.0,
      'clean_angle': double.tryParse(protection.cleanAngle) ?? 30.0,
      'wind_angle': double.tryParse(protection.windAngle) ?? 0.0,
      'tcu_version': protection.tcuVersion,
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
    await _service.sendRawText(jsonEncode(paramMap));

    Fluttertoast.showToast(msg: "保护参数已保存并广播");
    notifyListeners();
  }

  Future<void> saveLimitAngles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('limit_east', limitAngles.east);
    await prefs.setString('limit_west', limitAngles.west);

    final paramMap = {
      'protocol_version': 1,
      'message_type': 'config',
      'config_type': 'limit_angles',
      'east_limit': double.tryParse(limitAngles.east) ?? -45.0,
      'west_limit': double.tryParse(limitAngles.west) ?? 45.0,
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
    await _service.sendRawText(jsonEncode(paramMap));

    Fluttertoast.showToast(msg: "东西限位角已保存并广播");
    notifyListeners();
  }

  void setTcuVersion(String version) {
    protection.tcuVersion = version;
    notifyListeners();
  }

  Future<void> calibrateTime() async {
    _updateClock();
    final timeMap = {
      'protocol_version': 1,
      'message_type': 'time_sync',
      'time_str': _currentTime,
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
    await _service.sendRawText(jsonEncode(timeMap));
    Fluttertoast.showToast(msg: "已校准并同步本机时间至 NCU");
  }

  @override
  void dispose() {
    _timer?.cancel();
    _telemetrySub?.cancel();
    _ackSub?.cancel();
    super.dispose();
  }
}
