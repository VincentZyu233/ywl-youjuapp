import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/ble_provider.dart';
import '../../../providers/tcu_controller_provider.dart';
import '../../../services/unified_bluetooth_service.dart';
import '../../../models/ncu_protocol.dart';

class InfoTab extends StatelessWidget {
  final UnifiedDevice device;

  const InfoTab({super.key, required this.device});

  Widget _buildEnvMetricCard({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: color,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTcuUnitCard(BuildContext context, TcuTelemetryItem item, TcuControllerProvider tcuProvider) {
    final hasFault = item.stallFault;
    final isOnline = item.onlineStatus;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasFault ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
          width: hasFault ? 2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: hasFault ? const Color(0xFFEF4444).withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部状态行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "TCU ${item.tcuId}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOnline ? "在线" : "离线",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              if (hasFault)
                InkWell(
                  onTap: () => tcuProvider.cmdResetFault(tcuId: item.tcuId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEF4444), width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFDC2626)),
                        SizedBox(width: 4),
                        Text(
                          "堵转告警 (点此复位)",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Text(
                  "运转正常",
                  style: TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.w500),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // 4 项数据行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSubData("实际角度", "${item.actualAngle.toStringAsFixed(1)}°"),
              _buildSubData("期望角度", "${item.expectAngle.toStringAsFixed(1)}°"),
              _buildSubData("工作电流", "${item.current.toStringAsFixed(2)} A"),
              _buildSubData("状态", item.stallFault ? "堵转" : "运行中", isAlert: item.stallFault),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubData(String label, String value, {bool isAlert = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: isAlert ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleProvider>();
    final tcu = context.watch<TcuControllerProvider>();
    final telemetry = tcu.latestTelemetry;

    // 默认展示交接文档中规划的 5 台 TCU 列表
    final List<TcuTelemetryItem> displayTcuList = telemetry?.tcuData ?? [
      TcuTelemetryItem(tcuId: "001", actualAngle: 0.0, expectAngle: 0.0, current: 0.0, onlineStatus: ble.isConnected, stallFault: false),
      TcuTelemetryItem(tcuId: "002", actualAngle: 0.0, expectAngle: 0.0, current: 0.0, onlineStatus: ble.isConnected, stallFault: false),
      TcuTelemetryItem(tcuId: "003", actualAngle: 0.0, expectAngle: 0.0, current: 0.0, onlineStatus: ble.isConnected, stallFault: false),
      TcuTelemetryItem(tcuId: "004", actualAngle: 0.0, expectAngle: 0.0, current: 0.0, onlineStatus: ble.isConnected, stallFault: false),
      TcuTelemetryItem(tcuId: "005", actualAngle: 0.0, expectAngle: 0.0, current: 0.0, onlineStatus: ble.isConnected, stallFault: false),
    ];

    final windSpeed = telemetry != null ? telemetry.windSpeed.toStringAsFixed(1) : "0.0";
    final windDir = telemetry != null ? telemetry.windDirrect.toStringAsFixed(0) : "0";
    final irradiance = telemetry != null ? telemetry.solarIrradiance.toStringAsFixed(1) : "0.0";

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      physics: const BouncingScrollPhysics(),
      children: [
        // 顶部环境传感器指标
        Row(
          children: [
            _buildEnvMetricCard(
              label: "风速",
              value: windSpeed,
              unit: "m/s",
              icon: Icons.air,
              color: const Color(0xFF0284C7),
            ),
            const SizedBox(width: 10),
            _buildEnvMetricCard(
              label: "风向",
              value: windDir,
              unit: "°",
              icon: Icons.navigation,
              color: const Color(0xFF059669),
            ),
            const SizedBox(width: 10),
            _buildEnvMetricCard(
              label: "日照辐照",
              value: irradiance,
              unit: "W/m²",
              icon: Icons.wb_sunny,
              color: const Color(0xFFD97706),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // 状态说明栏
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.hub_outlined, size: 18, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Text(
                  "NCU 节点监测 (${telemetry != null ? 'NCU-${telemetry.ncuId}' : 'NCU-001'})",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: ble.isConnected ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ble.isConnected ? "遥测接收中 (2s)" : "等待SPP连接",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: ble.isConnected ? const Color(0xFF059669) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 5 台 TCU 实时状态卡片列表
        ...displayTcuList.map((item) => _buildTcuUnitCard(context, item, tcu)),

        const SizedBox(height: 12),

        // 链路协议诊断卡
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "下位机通信链路状态",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 8),
              Text(
                "• 物理传输：经典蓝牙 SPP (HC-05 / JDY-31 9600 8N1)\n• 分帧规则：CRLF (\\r\\n) 结束符 UTF-8 JSON\n• 下位机拓扑：App ⇄ SPP ⇄ NCU (USART1) ⇄ nRF24L01 ⇄ 5台TCU\n• 当前设备 MAC：${device.id}",
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.6),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
