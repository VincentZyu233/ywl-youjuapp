#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
NCU 经典蓝牙 SPP 串口本地仿真器 (Mock Server)
用途：配合 USB-TTL + HC-05/JDY-31 模块，或者虚拟串口，在电脑上无硬件仿真 NCU 与 5 台 TCU。
依赖：pip install pyserial
"""

import sys
import time
import json
import threading

try:
    import serial
except ImportError:
    print("[错误] 未安装 pyserial 库，请先运行: pip install pyserial")
    sys.exit(1)

# 请根据 Windows 设备管理器中的实际端口修改，例如 'COM3'
SERIAL_PORT = 'COM3'
BAUD_RATE = 9600

def main():
    print("=" * 60)
    print("       NCU 经典蓝牙 SPP 本地模拟仿真器 v1.0")
    print("=" * 60)
    
    try:
        ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=0.1)
        print(f"[OK] 成功打开串口 {SERIAL_PORT} (波特率 {BAUD_RATE})，等待 App 连接...\n")
    except Exception as e:
        print(f"[ERR] 无法打开串口 {SERIAL_PORT}: {e}")
        print("提示：请确认 USB-TTL 模块已插入电脑，且端口号与 SERIAL_PORT 变量一致。\n")
        return

    # 全局模拟状态
    state = {
        "angle": 15.0,
        "mode": "auto",
        "has_fault": False,
    }

    # 后台线程：每隔 2 秒自动向 App 广播一次 telemetry 遥测数据
    def telemetry_loop():
        while True:
            time.sleep(2.0)
            cur_angle = state["angle"]
            is_fault = state["has_fault"]

            telemetry_data = {
                "protocol_version": 1,
                "message_type": "telemetry",
                "ncu_id": "001",
                "windSpeed": 2.8,
                "windDirrect": 115.0,
                "solarIrradiance": 780.0,
                "timestamp": int(time.time()),
                "tcuData": [
                    {"tcu_id": "001", "actual_angle": cur_angle, "expect_angle": cur_angle, "current": 1.25, "onlineStatus": True, "stall_fault": False},
                    {"tcu_id": "002", "actual_angle": cur_angle, "expect_angle": cur_angle, "current": 6.80 if is_fault else 1.20, "onlineStatus": True, "stall_fault": is_fault},
                    {"tcu_id": "003", "actual_angle": cur_angle, "expect_angle": cur_angle, "current": 1.30, "onlineStatus": True, "stall_fault": False},
                    {"tcu_id": "004", "actual_angle": cur_angle, "expect_angle": cur_angle, "current": 1.22, "onlineStatus": True, "stall_fault": False},
                    {"tcu_id": "005", "actual_angle": cur_angle, "expect_angle": cur_angle, "current": 1.18, "onlineStatus": True, "stall_fault": False}
                ]
            }
            payload = json.dumps(telemetry_data) + "\r\n"
            try:
                ser.write(payload.encode('utf-8'))
            except Exception:
                pass

    t = threading.Thread(target=telemetry_loop, daemon=True)
    t.start()

    print("[提示] 遥测定时广播中 (每2秒)...")
    print("[提示] 可以在控制台输入 'fault' 模拟 TCU 002 发生堵转，输入 'ok' 恢复正常\n")

    # 控制台输入监听线程
    def console_input_loop():
        while True:
            try:
                cmd_line = input().strip()
                if cmd_line.lower() == 'fault':
                    state["has_fault"] = True
                    print("[模拟] 已触发 TCU 002 堵转故障！")
                elif cmd_line.lower() == 'ok':
                    state["has_fault"] = False
                    print("[模拟] 已恢复 TCU 002 正常状态！")
            except Exception:
                break

    ci_thread = threading.Thread(target=console_input_loop, daemon=True)
    ci_thread.start()

    # 主循环：读取并解析 App 下发的指令，并回送 command_ack
    buffer = ""
    while True:
        try:
            raw = ser.read(1024).decode('utf-8', errors='ignore')
            if raw:
                buffer += raw
                while "\n" in buffer:
                    line, buffer = buffer.split("\n", 1)
                    line = line.strip()
                    if not line:
                        continue
                    print(f"\n[RX 收到指令] {line}")
                    try:
                        cmd = json.loads(line)
                        cmd_type = cmd.get("cmdType", "")
                        req_id = cmd.get("request_id", 0)

                        # 执行模拟动作
                        if cmd_type == "SET_ANGLE":
                            target = cmd.get("target_angle", 0.0)
                            state["angle"] = float(target)
                            print(f"[执行] 调整目标角度至: {target}°")
                        elif cmd_type == "FLAT_ALL":
                            state["angle"] = 0.0
                            print("[执行] 一键放平: 0.0°")
                        elif cmd_type == "RESET":
                            state["has_fault"] = False
                            print("[执行] 故障复位成功！")

                        # 回复 command_ack
                        ack = {
                            "protocol_version": 1,
                            "message_type": "command_ack",
                            "request_id": req_id,
                            "cmdType": cmd_type,
                            "ncu_id": cmd.get("ncu_id", "001"),
                            "tcu_id": cmd.get("tcu_id", "ALL"),
                            "status": "accepted",
                            "error_code": 0,
                            "message": f"{cmd_type} executed successfully",
                            "timestamp": int(time.time())
                        }
                        ser.write((json.dumps(ack) + "\r\n").encode('utf-8'))
                        print(f"[TX 回应 ACK] 已应答 request_id={req_id}")

                    except Exception as e:
                        print(f"[WARN] JSON 格式解析异常: {e}")

        except KeyboardInterrupt:
            print("\n仿真器已安全停止。")
            break

if __name__ == '__main__':
    main()
