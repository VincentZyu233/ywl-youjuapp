import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/tcu_controller_provider.dart';
import '../../../models/ncu_protocol.dart';

class GroupControlTab extends StatefulWidget {
  const GroupControlTab({super.key});

  @override
  State<GroupControlTab> createState() => _GroupControlTabState();
}

class _GroupControlTabState extends State<GroupControlTab> {
  String _selectedTcuTarget = 'ALL';
  double _targetAngle = 0.0;
  String _lastTriggeredCmd = '';

  final List<String> _targetOptions = ['ALL', '001', '002', '003', '004', '005'];

  Widget _buildActionButton({
    required String label,
    required String cmdType,
    required IconData icon,
    required Color color,
    required Future<void> Function() onAction,
  }) {
    final isTriggered = _lastTriggeredCmd == cmdType;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          setState(() => _lastTriggeredCmd = cmdType);
          await onAction();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isTriggered ? color : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isTriggered ? color : const Color(0xFFE2E8F0),
              width: isTriggered ? 1.8 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isTriggered ? color.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: isTriggered ? Colors.white : color,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isTriggered ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tcu = context.watch<TcuControllerProvider>();
    final lastAck = tcu.lastAck;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      physics: const BouncingScrollPhysics(),
      children: [
        // 目标机组与自定义角度控制卡片
        Container(
          padding: const EdgeInsets.all(20),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune, color: Color(0xFF2563EB), size: 20),
                      SizedBox(width: 8),
                      Text(
                        "角度精准调节 (SET_ANGLE)",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  // 下拉选择下发目标
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedTcuTarget,
                        isDense: true,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        items: _targetOptions.map((opt) {
                          return DropdownMenuItem(
                            value: opt,
                            child: Text(opt == 'ALL' ? "全部 TCU (群控)" : "TCU $opt"),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedTcuTarget = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 角度显示与滑块
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("目标角度", style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  Text(
                    "${_targetAngle.toStringAsFixed(1)}°",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF2563EB),
                  thumbColor: const Color(0xFF2563EB),
                  trackHeight: 6,
                ),
                child: Slider(
                  value: _targetAngle,
                  min: -45.0,
                  max: 45.0,
                  divisions: 90,
                  label: "${_targetAngle.toStringAsFixed(1)}°",
                  onChanged: (val) {
                    setState(() => _targetAngle = val);
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("东限位 -45°", style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  Text("水平 0°", style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  Text("西限位 +45°", style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                ],
              ),

              const SizedBox(height: 16),

              // 下发按钮
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 1,
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    "执行角度设置 (${_selectedTcuTarget == 'ALL' ? '全场群控' : 'TCU $_selectedTcuTarget'})",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () {
                    tcu.cmdSetAngle(angle: _targetAngle, tcuId: _selectedTcuTarget);
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 10 大标准交接控制指令网格
        Container(
          padding: const EdgeInsets.all(20),
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
                  Icon(Icons.dashboard_customize_outlined, color: Color(0xFF2563EB), size: 20),
                  SizedBox(width: 8),
                  Text(
                    "群控标准指令 (下位机协议 V1.0)",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
                children: [
                  _buildActionButton(
                    label: "自动模式",
                    cmdType: NcuCommand.CMD_AUTO_ALL,
                    icon: Icons.auto_mode,
                    color: const Color(0xFF2563EB),
                    onAction: () => tcu.cmdAutoAll(),
                  ),
                  _buildActionButton(
                    label: "一键放平",
                    cmdType: NcuCommand.CMD_FLAT_ALL,
                    icon: Icons.horizontal_rule,
                    color: const Color(0xFF0284C7),
                    onAction: () => tcu.cmdFlatAll(),
                  ),
                  _buildActionButton(
                    label: "紧急停止",
                    cmdType: NcuCommand.CMD_STOP,
                    icon: Icons.stop_circle,
                    color: const Color(0xFFDC2626),
                    onAction: () => tcu.cmdStop(),
                  ),
                  _buildActionButton(
                    label: "一键向西",
                    cmdType: NcuCommand.CMD_TURN_WEST,
                    icon: Icons.arrow_back,
                    color: const Color(0xFF4F46E5),
                    onAction: () => tcu.cmdTurnWest(),
                  ),
                  _buildActionButton(
                    label: "清洗模式",
                    cmdType: NcuCommand.CMD_CLEAN_ALL,
                    icon: Icons.cleaning_services,
                    color: const Color(0xFF0D9488),
                    onAction: () => tcu.cmdCleanAll(),
                  ),
                  _buildActionButton(
                    label: "一键向东",
                    cmdType: NcuCommand.CMD_TURN_EAST,
                    icon: Icons.arrow_forward,
                    color: const Color(0xFF4F46E5),
                    onAction: () => tcu.cmdTurnEast(),
                  ),
                  _buildActionButton(
                    label: "大风模式",
                    cmdType: NcuCommand.CMD_WIND_MODE,
                    icon: Icons.air,
                    color: const Color(0xFFEA580C),
                    onAction: () => tcu.cmdWindMode(),
                  ),
                  _buildActionButton(
                    label: "阴天模式",
                    cmdType: NcuCommand.CMD_CLOUDY_MODE,
                    icon: Icons.cloud,
                    color: const Color(0xFF64748B),
                    onAction: () => tcu.cmdCloudyMode(),
                  ),
                  _buildActionButton(
                    label: "清除堵转",
                    cmdType: NcuCommand.CMD_RESET,
                    icon: Icons.restart_alt,
                    color: const Color(0xFF16A34A),
                    onAction: () => tcu.cmdResetFault(),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 最近一次 ACK 回执卡片
        if (lastAck != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: lastAck.status == 'accepted' || lastAck.status == 'forwarded'
                  ? const Color(0xFFF0FDF4)
                  : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: lastAck.status == 'accepted' || lastAck.status == 'forwarded'
                    ? const Color(0xFF86EFAC)
                    : const Color(0xFFFCA5A5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  lastAck.status == 'accepted' || lastAck.status == 'forwarded'
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  color: lastAck.status == 'accepted' || lastAck.status == 'forwarded'
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "指令 [${lastAck.cmdType}] 执行响应: ${lastAck.status.toUpperCase()} (${lastAck.message.isNotEmpty ? lastAck.message : '成功'})",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: lastAck.status == 'accepted' || lastAck.status == 'forwarded'
                          ? const Color(0xFF15803D)
                          : const Color(0xFFB91C1C),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
