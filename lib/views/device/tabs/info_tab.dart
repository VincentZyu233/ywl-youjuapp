import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/ble_provider.dart';
import '../../../services/ble_service.dart';

class InfoTab extends StatelessWidget {
  final DiscoveredDevice device;

  const InfoTab({super.key, required this.device});

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: valueColor ?? const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleProvider>();
    final isConnected = ble.connectionState == DeviceConnectionState.connected;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      physics: const BouncingScrollPhysics(),
      children: [
        // 核心信息卡片
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 20),
                  SizedBox(width: 8),
                  Text(
                    "设备通信详情",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow("设备名称", device.name),
              _buildInfoRow("物理 MAC", device.id),
              _buildInfoRow("信号强度", "${device.rssi} dBm"),
              _buildInfoRow(
                "链路状态",
                isConnected ? "正常通信中" : "已断开",
                valueColor: isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
              _buildInfoRow("服务 UUID", "0000FFE0-..."),
              _buildInfoRow("特征值 UUID", "0000FFE1-..."),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 占位展示
        Center(
          child: Column(
            children: const [
              SizedBox(height: 30),
              Icon(Icons.monitor_heart_outlined, size: 48, color: Color(0xFFCBD5E1)),
              SizedBox(height: 12),
              Text(
                "实时遥测数据监控区",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
              SizedBox(height: 4),
              Text(
                "等待 TCU 传感器上报特征值 Notify 数据流",
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
