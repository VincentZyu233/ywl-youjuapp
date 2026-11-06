import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ble_provider.dart';
import '../../services/ble_service.dart';
import '../device/device_page.dart';
import 'widgets/ble_status_card.dart';
import 'widgets/device_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _onDeviceTap(BuildContext context, DiscoveredDevice device) async {
    final ble = context.read<BleProvider>();
    // 点击直接连接并跳转
    ble.connect(device);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DevicePage(device: device),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleProvider>();
    final devices = ble.devices;
    final isScanning = ble.isScanning;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 顶部状态栏大卡片
          const BleStatusCard(),

          // 设备列表区域
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 18),
                  // 标题栏与刷新指示
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "附近设备 (${devices.length})",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (isScanning)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Color(0xFF2563EB)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 列表视图或空状态
                  Expanded(
                    child: devices.isEmpty && !isScanning
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.bluetooth_searching,
                                    size: 48,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "暂未发现设备",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "请确保 TCU 蓝牙已上电，并点击下方按钮扫描",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 4, bottom: 20),
                            itemCount: devices.length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final d = devices[index];
                              final isConn = ble.connectedDeviceId == d.id;
                              return DeviceCard(
                                device: d,
                                isConnected: isConn,
                                onTap: () => _onDeviceTap(context, d),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          // 底部沉底扫描按钮
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              14 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(
                top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (isScanning) {
                    ble.stopScan();
                  } else {
                    ble.startScan();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFF0F172A).withValues(alpha: 0.25),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isScanning) ...[
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "正在扫描周边设备...",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ] else ...[
                      const Icon(Icons.search, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        "扫描附近设备",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
