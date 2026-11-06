import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/tcu_controller_provider.dart';

class BroadcastTab extends StatelessWidget {
  const BroadcastTab({super.key});

  @override
  Widget build(BuildContext context) {
    final tcu = context.watch<TcuControllerProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      physics: const BouncingScrollPhysics(),
      children: [
        // 模式提示卡片
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
          ),
          child: Row(
            children: const [
              Icon(Icons.cell_tower, color: Color(0xFF2563EB), size: 28),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "当前为 广播时间 / 群发模式",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "下发指令将经由 NCU 无线射频广播至现场全部 5 台 TCU 驱动器",
                      style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 快捷群发动作
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
              const Text(
                "全场广播快捷指令",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.alarm_on, color: Color(0xFF2563EB)),
                ),
                title: const Text("广播时钟对齐", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text("当前本机时钟: ${tcu.currentTime}", style: const TextStyle(fontSize: 12)),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => tcu.calibrateTime(),
                  child: const Text("群发对时"),
                ),
              ),
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.emergency, color: Color(0xFFDC2626)),
                ),
                title: const Text("全场紧急停机", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text("立即阻断所有正在执行的电机旋转动作", style: TextStyle(fontSize: 12)),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => tcu.cmdStop(tcuId: 'ALL'),
                  child: const Text("全场停机"),
                ),
              ),
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.sync_alt, color: Color(0xFF15803D)),
                ),
                title: const Text("全场复位故障", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text("清除所有 TCU 的堵转报警标志", style: TextStyle(fontSize: 12)),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => tcu.cmdResetFault(tcuId: 'ALL'),
                  child: const Text("群发复位"),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
