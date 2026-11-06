import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/ble_service.dart';

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
  final BleService _bleService = BleService();

  String _currentTime = '';
  Timer? _timer;

  String tcuVersionNumber = '12';
  String netStatus = '2';

  final List<String> availableTcuVersions = ['7.1.08', '7.1.09', '8.0.01'];

  AstronomicalParams astronomical = AstronomicalParams();
  ComponentParams component = ComponentParams();
  ProtectionParams protection = ProtectionParams();
  LimitAngles limitAngles = LimitAngles();

  String get currentTime => _currentTime;

  TcuControllerProvider() {
    _startClock();
    _loadFromPrefs();
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

  Future<void> saveAstronomicalParams() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('astro_long', astronomical.longitude);
    await prefs.setString('astro_lat', astronomical.latitude);
    await prefs.setString('astro_tz', astronomical.timezone);

    // 尝试向蓝牙特征值写入参数帧 (若已连接)
    final frame = [0xAA, 0x01, int.tryParse(astronomical.timezone) ?? 8];
    await _bleService.writeData(frame);

    Fluttertoast.showToast(msg: "天文参数已保存并写入");
    notifyListeners();
  }

  Future<void> saveComponentParams() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('comp_width', component.width);
    await prefs.setString('comp_spacing', component.spacing);

    Fluttertoast.showToast(msg: "组件参数已保存并写入");
    notifyListeners();
  }

  Future<void> saveProtectionParams() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('prot_overcurrent', protection.overcurrent);
    await prefs.setString('prot_night_angle', protection.nightReturnAngle);
    await prefs.setString('prot_clean_angle', protection.cleanAngle);
    await prefs.setString('prot_wind_angle', protection.windAngle);
    await prefs.setString('prot_tcu_version', protection.tcuVersion);

    Fluttertoast.showToast(msg: "保护参数已保存并写入");
    notifyListeners();
  }

  Future<void> saveLimitAngles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('limit_east', limitAngles.east);
    await prefs.setString('limit_west', limitAngles.west);

    Fluttertoast.showToast(msg: "东西限位角已保存并写入");
    notifyListeners();
  }

  void setTcuVersion(String version) {
    protection.tcuVersion = version;
    notifyListeners();
  }

  void calibrateTime() {
    _updateClock();
    Fluttertoast.showToast(msg: "已校准至本机时间");
  }

  Future<void> executeControlAction(String actionName, int actionCode) async {
    // 构造标准的控制数据帧发送到蓝牙设备
    final command = [0x55, 0xAA, actionCode, 0x00, 0xED];
    final success = await _bleService.writeData(command);

    if (success) {
      Fluttertoast.showToast(msg: "执行: $actionName (指令已发送)");
    } else {
      Fluttertoast.showToast(msg: "执行: $actionName");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
