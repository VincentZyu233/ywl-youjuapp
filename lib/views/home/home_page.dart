import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ble_provider.dart';
import '../../services/unified_bluetooth_service.dart';
import '../device/device_page.dart';
import 'widgets/ble_status_card.dart';
import 'widgets/device_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _onDeviceTap(BuildContext context, UnifiedDevice device) async {
    final ble = context.read<BleProvider>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DevicePage(device: device),
      ),
    );
    ble.connect(device);
  }

  void _showLogsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer<BleProvider>(
          builder: (context, ble, child) {
            final logs = ble.logs;
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "蓝牙通信实时日志",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () => ble.clearLogs(),
                            tooltip: "清空日志",
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "白盒/黑盒排查专用：实时展示下位机 SPP/BLE 报文",
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const Divider(height: 20),
                  Expanded(
                    child: logs.isEmpty
                        ? const Center(
                            child: Text(
                              "暂无通信日志",
                              style: TextStyle(color: Color(0xFF94A3B8)),
                            ),
                          )
                        : ListView.builder(
                            itemCount: logs.length,
                            reverse: true,
                            itemBuilder: (context, index) {
                              final item = logs[logs.length - 1 - index];
                              final isRx = item.contains('[RX');
                              final isTx = item.contains('[TX');
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 3),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isRx
                                      ? const Color(0xFFEFF6FF)
                                      : isTx
                                          ? const Color(0xFFECFDF5)
                                          : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    color: isRx
                                        ? const Color(0xFF1D4ED8)
                                        : isTx
                                            ? const Color(0xFF047857)
                                            : const Color(0xFF334155),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleProvider>();
    final devices = ble.devices;
    final isScanning = ble.isScanning;

    // 区分已配对设备与新发现设备
    final bondedList = devices.where((d) => d.isBonded).toList();
    final otherList = devices.where((d) => !d.isBonded).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 顶部状态栏大卡片
          BleStatusCard(
            onOpenLogs: () => _showLogsBottomSheet(context),
          ),

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
                        "设备列表 (${devices.length})",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (isScanning)
                        const Row(
                          children: [
                            Text(
                              "正在全频段扫描...",
                              style: TextStyle(fontSize: 11, color: Color(0xFF2563EB)),
                            ),
                            SizedBox(width: 8),
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Color(0xFF2563EB)),
                              ),
                            ),
                          ],
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
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF1F5F9),
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
                                  "支持 JDY-31 / HC-05 经典蓝牙与 BLE 设备\n请确保设备已上电，点击下方按钮开始搜索",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.only(bottom: 90),
                            children: [
                              if (bondedList.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.only(left: 4, bottom: 8),
                                  child: Text(
                                    "已配对设备 (优先直连)",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                                ...bondedList.map((d) => DeviceCard(
                                      device: d,
                                      isConnected: ble.connectedDeviceId == d.id && ble.isConnected,
                                      onTap: () => _onDeviceTap(context, d),
                                    )),
                                const SizedBox(height: 12),
                              ],
                              if (otherList.isNotEmpty) ...[
                                if (bondedList.isNotEmpty)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4, bottom: 8),
                                    child: Text(
                                      "扫描到的其他设备",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ...otherList.map((d) => DeviceCard(
                                      device: d,
                                      isConnected: ble.connectedDeviceId == d.id && ble.isConnected,
                                      onTap: () => _onDeviceTap(context, d),
                                    )),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isScanning ? () => ble.stopScan() : () => ble.startScan(),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 3,
        icon: Icon(isScanning ? Icons.stop : Icons.search),
        label: Text(
          isScanning ? "停止搜索" : "搜索蓝牙设备",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
