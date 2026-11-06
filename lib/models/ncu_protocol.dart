// ignore_for_file: constant_identifier_names
import 'dart:convert';

/// 单台 TCU 遥测状态数据
class TcuTelemetryItem {
  final String tcuId;
  final double actualAngle;
  final double expectAngle;
  final double current;
  final bool onlineStatus;
  final bool stallFault;

  TcuTelemetryItem({
    required this.tcuId,
    required this.actualAngle,
    required this.expectAngle,
    required this.current,
    required this.onlineStatus,
    required this.stallFault,
  });

  factory TcuTelemetryItem.fromJson(Map<String, dynamic> json) {
    return TcuTelemetryItem(
      tcuId: json['tcu_id']?.toString() ?? '',
      actualAngle: (json['actual_angle'] as num?)?.toDouble() ?? 0.0,
      expectAngle: (json['expect_angle'] as num?)?.toDouble() ?? 0.0,
      current: (json['current'] as num?)?.toDouble() ?? 0.0,
      onlineStatus: json['onlineStatus'] == true,
      stallFault: json['stall_fault'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'tcu_id': tcuId,
    'actual_angle': actualAngle,
    'expect_angle': expectAngle,
    'current': current,
    'onlineStatus': onlineStatus,
    'stall_fault': stallFault,
  };
}

/// NCU 整机遥测上报数据 (默认每 2 秒上报一次)
class NcuTelemetry {
  final int protocolVersion;
  final String messageType;
  final String ncuId;
  final double windSpeed;
  final double windDirrect;
  final double solarIrradiance;
  final int timestamp;
  final List<TcuTelemetryItem> tcuData;

  NcuTelemetry({
    required this.protocolVersion,
    required this.messageType,
    required this.ncuId,
    required this.windSpeed,
    required this.windDirrect,
    required this.solarIrradiance,
    required this.timestamp,
    required this.tcuData,
  });

  factory NcuTelemetry.fromJson(Map<String, dynamic> json) {
    var rawList = json['tcuData'];
    List<TcuTelemetryItem> list = [];
    if (rawList is List) {
      list = rawList.map((item) => TcuTelemetryItem.fromJson(item as Map<String, dynamic>)).toList();
    }
    return NcuTelemetry(
      protocolVersion: json['protocol_version'] as int? ?? 1,
      messageType: json['message_type']?.toString() ?? 'telemetry',
      ncuId: json['ncu_id']?.toString() ?? '001',
      windSpeed: (json['windSpeed'] as num?)?.toDouble() ?? 0.0,
      windDirrect: (json['windDirrect'] as num?)?.toDouble() ?? 0.0,
      solarIrradiance: (json['solarIrradiance'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      tcuData: list,
    );
  }
}

/// App 控制下发指令 (通过经典蓝牙 SPP 发送至 NCU)
class NcuCommand {
  static const String CMD_SET_ANGLE = 'SET_ANGLE';
  static const String CMD_STOP = 'STOP';
  static const String CMD_RESET = 'RESET';
  static const String CMD_AUTO_ALL = 'AUTO_ALL';
  static const String CMD_TURN_EAST = 'TURN_EAST';
  static const String CMD_TURN_WEST = 'TURN_WEST';
  static const String CMD_FLAT_ALL = 'FLAT_ALL';
  static const String CMD_CLEAN_ALL = 'CLEAN_ALL';
  static const String CMD_WIND_MODE = 'WIND_MODE';
  static const String CMD_CLOUDY_MODE = 'CLOUDY_MODE';

  final int protocolVersion;
  final String messageType;
  final int requestId;
  final String cmdType;
  final String ncuId;
  final String tcuId;
  final String controlMode;
  final double? targetAngle;
  final int timestamp;

  NcuCommand({
    this.protocolVersion = 1,
    this.messageType = 'command',
    required this.requestId,
    required this.cmdType,
    this.ncuId = '001',
    this.tcuId = 'ALL',
    this.controlMode = 'manual',
    this.targetAngle,
    int? timestamp,
  }) : timestamp = timestamp ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'protocol_version': protocolVersion,
      'message_type': messageType,
      'request_id': requestId,
      'cmdType': cmdType,
      'ncu_id': ncuId,
      'tcu_id': tcuId,
      'controlMode': controlMode,
      'timestamp': timestamp,
    };
    if (targetAngle != null) {
      map['target_angle'] = targetAngle;
    }
    return map;
  }

  String toJsonString() => jsonEncode(toMap());
}

/// NCU 针对 App 控制指令返回的 ACK
class NcuCommandAck {
  final int protocolVersion;
  final String messageType;
  final int requestId;
  final String cmdType;
  final String ncuId;
  final String tcuId;
  final String status; // forwarded, accepted, failed, rejected
  final int errorCode;
  final String message;
  final int timestamp;

  NcuCommandAck({
    required this.protocolVersion,
    required this.messageType,
    required this.requestId,
    required this.cmdType,
    required this.ncuId,
    required this.tcuId,
    required this.status,
    required this.errorCode,
    required this.message,
    required this.timestamp,
  });

  factory NcuCommandAck.fromJson(Map<String, dynamic> json) {
    return NcuCommandAck(
      protocolVersion: json['protocol_version'] as int? ?? 1,
      messageType: json['message_type']?.toString() ?? 'command_ack',
      requestId: json['request_id'] as int? ?? 0,
      cmdType: json['cmdType']?.toString() ?? '',
      ncuId: json['ncu_id']?.toString() ?? '001',
      tcuId: json['tcu_id']?.toString() ?? 'ALL',
      status: json['status']?.toString() ?? 'unknown',
      errorCode: json['error_code'] as int? ?? 0,
      message: json['message']?.toString() ?? '',
      timestamp: json['timestamp'] as int? ?? 0,
    );
  }
}
