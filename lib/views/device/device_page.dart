import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ble_provider.dart';
import '../../providers/tcu_controller_provider.dart';
import '../../services/ble_service.dart';
import 'tabs/settings_tab.dart';
import 'tabs/group_control_tab.dart';
import 'tabs/info_tab.dart';
import 'tabs/broadcast_tab.dart';

class DevicePage extends StatefulWidget {
  final DiscoveredDevice device;

  const DevicePage({super.key, required this.device});

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  int _currentIndex = 1; // 默认选中 Settings

  @override
  void dispose() {
    // 退出页面时断开连接释放资源
    context.read<BleProvider>().disconnect();
    super.dispose();
  }

  Widget _buildTopHeader(BuildContext context) {
    final ble = context.watch<BleProvider>();
    final tcu = context.watch<TcuControllerProvider>();

    Color connColor;
    String connText;
    if (ble.connectionState == DeviceConnectionState.connected) {
      connColor = const Color(0xFF4ADE80);
      connText = "已连接";
    } else if (ble.connectionState == DeviceConnectionState.connecting) {
      connColor = const Color(0xFFFACC15);
      connText = "正在连接...";
    } else {
      connColor = const Color(0xFFF87171);
      connText = "连接断开 (点击重试)";
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            children: [
              // 导航与设备名称
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Column(
                    children: [
                      const Text(
                        "当前设备",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.device.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 连接状态 Badge
                      InkWell(
                        onTap: () {
                          if (ble.connectionState != DeviceConnectionState.connected) {
                            ble.connect(widget.device);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: connColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                connText,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: connColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 48), // 占位平衡
                ],
              ),
              const SizedBox(height: 20),

              // 设备时间与系统指标卡片
              Row(
                children: [
                  // 设备时间卡片
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.access_time, color: Color(0xFF93C5FD), size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    "设备时间",
                                    style: TextStyle(color: Color(0xFF93C5FD), fontSize: 12),
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: () => tcu.calibrateTime(),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
                                  ),
                                  child: const Text(
                                    "校正",
                                    style: TextStyle(color: Color(0xFFBFDBFE), fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tcu.currentTime,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // TCU 和 NET 徽章
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: Row(
                          children: [
                            const Text("▪", style: TextStyle(color: Colors.white70, fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              "TCU: ${tcu.tcuVersionNumber}",
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: Row(
                          children: [
                            const Text("◈", style: TextStyle(color: Colors.white70, fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              "NET: ${tcu.netStatus}",
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildTopHeader(context),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                InfoTab(device: widget.device),
                const SettingsTab(),
                const BroadcastTab(),
                const GroupControlTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2)),
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (idx) {
              setState(() {
                _currentIndex = idx;
              });
            },
            backgroundColor: Colors.white,
            elevation: 0,
            indicatorColor: const Color(0xFFEFF6FF),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.info_outline),
                selectedIcon: Icon(Icons.info, color: Color(0xFF2563EB)),
                label: '信息',
              ),
              NavigationDestination(
                icon: Icon(Icons.tune_outlined),
                selectedIcon: Icon(Icons.tune, color: Color(0xFF2563EB)),
                label: '设置',
              ),
              NavigationDestination(
                icon: Icon(Icons.cell_tower_outlined),
                selectedIcon: Icon(Icons.cell_tower, color: Color(0xFF2563EB)),
                label: '广播',
              ),
              NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view, color: Color(0xFF2563EB)),
                label: '群控',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
