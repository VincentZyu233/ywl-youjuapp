import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/ble_provider.dart';

class BleStatusCard extends StatelessWidget {
  final VoidCallback? onOpenLogs;

  const BleStatusCard({super.key, this.onOpenLogs});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleProvider>();
    final isConnected = ble.isConnected;
    final connectedName = ble.connectedDevice?.displayName ?? '未连接';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "光伏跟踪支架控制器",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isConnected ? const Color(0xFF4ADE80) : const Color(0xFFFACC15),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isConnected ? "已连接: $connectedName" : "支持 JDY-31 / HC-05 串口 & BLE",
                                style: const TextStyle(
                                  color: Color(0xFFDBEAFE),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (onOpenLogs != null)
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.terminal, color: Colors.white, size: 20),
                      ),
                      tooltip: "通信日志",
                      onPressed: onOpenLogs,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
