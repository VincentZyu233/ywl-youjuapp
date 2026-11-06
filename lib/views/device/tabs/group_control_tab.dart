import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/tcu_controller_provider.dart';

class GroupControlTab extends StatefulWidget {
  const GroupControlTab({super.key});

  @override
  State<GroupControlTab> createState() => _GroupControlTabState();
}

class _GroupControlTabState extends State<GroupControlTab> {
  String _activeAction = 'stop';

  Widget _buildControlButton({
    required String text,
    required String actionKey,
    required int code,
    Color? activeColor,
  }) {
    final tcu = context.read<TcuControllerProvider>();
    final isActive = _activeAction == actionKey;
    final color = activeColor ?? const Color(0xFF2563EB);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() {
          _activeAction = actionKey;
        });
        tcu.executeControlAction(text, code);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? color : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : const Color(0xFFE2E8F0),
            width: isActive ? 2 : 1.2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.015),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // 标题
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.settings_suggest, color: Color(0xFF64748B), size: 24),
                  SizedBox(width: 8),
                  Text(
                    "整体控制面板",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 3列网格按钮
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.35,
                children: [
                  _buildControlButton(text: "自动", actionKey: "auto", code: 1),
                  _buildControlButton(text: "放平", actionKey: "flat", code: 2),
                  _buildControlButton(
                    text: "停止",
                    actionKey: "stop",
                    code: 0,
                    activeColor: const Color(0xFF10B981),
                  ),
                  _buildControlButton(text: "向西", actionKey: "west", code: 3),
                  _buildControlButton(text: "清洗", actionKey: "clean", code: 4),
                  _buildControlButton(text: "向东", actionKey: "east", code: 5),
                  _buildControlButton(text: "大雪", actionKey: "snow", code: 6),
                  _buildControlButton(text: "大雨", actionKey: "rain", code: 7),
                  _buildControlButton(text: "洪水", actionKey: "flood", code: 8),
                  _buildControlButton(text: "大风", actionKey: "wind", code: 9),
                  const SizedBox.shrink(), // 占位保持布局
                  _buildControlButton(text: "低功耗", actionKey: "lowpower", code: 10),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
