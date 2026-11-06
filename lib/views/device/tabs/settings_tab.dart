import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/tcu_controller_provider.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  Widget _buildParamInput({
    required String label,
    required String initialValue,
    required ValueChanged<String> onChanged,
    String? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
          SizedBox(
            width: 170,
            height: 44,
            child: TextFormField(
              initialValue: initialValue,
              onChanged: onChanged,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                suffixText: suffix,
                suffixStyle: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onWrite,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF2563EB), size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
          const SizedBox(height: 16),
          // 像素级对齐原版的“写入并广播”大按钮
          Center(
            child: SizedBox(
              width: 160,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: onWrite,
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text(
                  "写入并广播",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tcu = context.watch<TcuControllerProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      physics: const BouncingScrollPhysics(),
      children: [
        // 模式提示横幅
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 18),
              SizedBox(width: 8),
              Text(
                "当前为 广播时间 模式",
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // 1. 天文参数设置
        _buildSectionCard(
          context: context,
          title: "天文参数设置",
          icon: Icons.public,
          onWrite: () => tcu.saveAstronomicalParams(),
          children: [
            _buildParamInput(
              label: "经度",
              initialValue: tcu.astronomical.longitude,
              onChanged: (v) => tcu.astronomical.longitude = v,
            ),
            _buildParamInput(
              label: "纬度",
              initialValue: tcu.astronomical.latitude,
              onChanged: (v) => tcu.astronomical.latitude = v,
            ),
            _buildParamInput(
              label: "时区",
              initialValue: tcu.astronomical.timezone,
              onChanged: (v) => tcu.astronomical.timezone = v,
            ),
          ],
        ),

        // 2. 组件参数设置
        _buildSectionCard(
          context: context,
          title: "组件参数设置",
          icon: Icons.tune,
          onWrite: () => tcu.saveComponentParams(),
          children: [
            _buildParamInput(
              label: "组件宽度",
              initialValue: tcu.component.width,
              suffix: "m",
              onChanged: (v) => tcu.component.width = v,
            ),
            _buildParamInput(
              label: "组件间距",
              initialValue: tcu.component.spacing,
              suffix: "m",
              onChanged: (v) => tcu.component.spacing = v,
            ),
          ],
        ),

        // 3. 保护参数设置
        _buildSectionCard(
          context: context,
          title: "保护参数设置",
          icon: Icons.shield_outlined,
          onWrite: () => tcu.saveProtectionParams(),
          children: [
            _buildParamInput(
              label: "过流保护",
              initialValue: tcu.protection.overcurrent,
              suffix: "mA",
              onChanged: (v) => tcu.protection.overcurrent = v,
            ),
            _buildParamInput(
              label: "夜返保护角",
              initialValue: tcu.protection.nightReturnAngle,
              suffix: "°",
              onChanged: (v) => tcu.protection.nightReturnAngle = v,
            ),
            _buildParamInput(
              label: "清洗保护角",
              initialValue: tcu.protection.cleanAngle,
              suffix: "°",
              onChanged: (v) => tcu.protection.cleanAngle = v,
            ),
            _buildParamInput(
              label: "迎风保护角",
              initialValue: tcu.protection.windAngle,
              suffix: "°",
              onChanged: (v) => tcu.protection.windAngle = v,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "TCU版本选择",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  width: 170,
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: tcu.protection.tcuVersion,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                      items: tcu.availableTcuVersions.map((v) {
                        return DropdownMenuItem(
                          value: v,
                          child: Text(
                            v,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) tcu.setTcuVersion(val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // 4. 东西限位角设置
        _buildSectionCard(
          context: context,
          title: "东西限位角设置",
          icon: Icons.compass_calibration_outlined,
          onWrite: () => tcu.saveLimitAngles(),
          children: [
            _buildParamInput(
              label: "东限位角",
              initialValue: tcu.limitAngles.east,
              suffix: "°",
              onChanged: (v) => tcu.limitAngles.east = v,
            ),
            _buildParamInput(
              label: "西限位角",
              initialValue: tcu.limitAngles.west,
              suffix: "°",
              onChanged: (v) => tcu.limitAngles.west = v,
            ),
          ],
        ),
      ],
    );
  }
}
