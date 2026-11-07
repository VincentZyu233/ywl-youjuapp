# 经典蓝牙 SPP 与下位机 NCU 本地联调测试指南

> **创建日期**：2026-11-07  
> **适用项目**：`youjuAPP-flutter` (v2.1.0 / v2.1.1 及更高版本)  
> **适用模块**：经典蓝牙 2.0/3.0 SPP 串口透传（JDY-31-SPP / HC-05）、NCU 与 TCU 全链路通信协议

---

## 零、 核心原理：为什么本地调试根本不需要买单片机？

甲方或硬件工程师常说：“本地调试要买单片机、杜邦线、还要搭建烧录环境”。这是硬件工程的惯性思维。

从 **App 软件通信与协议测试** 的角度来看：
- 现场的下位机硬件拓扑为：`手机 App ⇄ 经典蓝牙 SPP 模块 (HC-05/JDY-31) ⇄ 串口(USART1) ⇄ NCU 单片机 ⇄ 5台TCU`；
- 蓝牙透传模块（JDY-31 / HC-05）本质就是一条 **“无线的物理串口线”**，它只负责透明传输字符流，根本不关心串口另一端接的是 STM32 单片机还是电脑 USB 串口；
- 因此，只要用 **电脑 USB 串口** 或 **另一台手机** 代替单片机收发以 `\r\n` 分帧的 UTF-8 JSON 文本，就能 100% 仿真现场全部功能，甚至可以随意模拟现场罕见的极端工况（如大风保护、电机瞬间堵转报警等）。

---

## 方案 0：零成本、立刻测（无需购买任何硬件，10分钟开跑）

如果您手头有 **另一台闲置安卓手机、安卓平板或朋友的手机**，现在就可以直接开测：

### 1. 准备工具
在副机上打开手机应用市场（或酷安/应用宝），下载任意一款支持经典蓝牙服务端的调试工具：
- 推荐软件：**“蓝牙串口助手”**、**“SPP蓝牙调试器”** 或 **“Serial Bluetooth Terminal”**。

### 2. 操作步骤
1. **修改设备名**：在副机系统蓝牙设置或软件设置中，将蓝牙名称改为：`JDY-31-SPP`；
2. **开启监听模式**：在调试软件中选择 **“服务端模式 (Server Mode / Listen)”**，此时副机开始作为从机对外广播；
3. **连接**：在主力机上打开我们的 **`youjuAPP`**，在首页设备列表中找到 `JDY-31-SPP`，点击直连；
4. **双向收发验证**：
   - **上行遥测**：副机中粘贴文末的 `telemetry` JSON 报文发送，主力机 App 上的风速、辐照度和 5 台 TCU 状态大盘立即动态更新；
   - **下行控制**：在主力机 App 上点击“一键放平”或滑动滑块控制角度，副机屏幕上会立刻打印出 App 发出的 `command` JSON。

---

## 方案 1：20元淘宝硬件极速联调（电脑充当 NCU 终极仿真器）

如果您希望有一套长期可用的真实硬件环境，只需在淘宝购买以下两样小配件（总计约 20 元）：

### 1. 淘宝购买清单

| 序号 | 物品名称 | 淘宝搜索关键词 | 选型注意事项 | 参考价格 |
| :---: | :--- | :--- | :--- | :---: |
| 1 | **经典蓝牙透传模块** | `JDY-31 蓝牙模块 带底板`<br>或 `HC-05 蓝牙模块 带底板` | **必须选“带底板/6脚插针”**（支持 3.6V~6V 宽电压供电，带排针方便接线，切勿买贴片裸板） | 约 10~15 元 |
| 2 | **USB 转 TTL 串口板** | `CH340G USB转TTL模块`<br>(选带母对母杜邦线套餐) | 必须包含 **4 根母对母杜邦线**，插电脑 USB 自动识别为 COM 口 | 约 5~8 元 |

> **店铺推荐**：在淘宝搜索 `Telesky旗舰店`、`泽杰旗舰店`、`优信电子` 或 `优信电子`，在同一家店合并下单，支持次日达。

---

### 2. 四根杜邦线接线说明

将 USB-TTL 模块与蓝牙模块的 4 根引脚严格按下表连接：

```
USB 转 TTL 模块                   蓝牙模块 (HC-05 / JDY-31)
┌──────────────┐                 ┌──────────────┐
│     5V / VCC ├────────────────▶│ VCC          │
│          GND ├────────────────▶│ GND          │
│     TXD (发) ├────────────────▶│ RXD (收)     │ (注意交叉接)
│     RXD (收) ├────────────────▶│ TXD (发)     │ (注意交叉接)
└──────────────┘                 └──────────────┘
```
*(注：蓝牙模块上的 STATE 和 EN/KEY 引脚悬空不接)*

---

### 3. 电脑串口调试助手配置
1. 将 USB-TTL 模块插入电脑 USB 口，在 Windows “设备管理器 -> 端口 (COM 和 LPT)” 查看分配的端口号（如 `COM3`）；
2. 打开电脑端串口助手（推荐免费开源的 **VOFA+**、**XCOM** 或 **SSCOM**）：
   - **波特率**：`9600`
   - **数据位**：`8`
   - **停止位**：`1`
   - **校验位**：`None`
   - **发送选项**：**务必勾选“加回车换行”** 或 **“发送新行 CRLF (\r\n)”**（协议硬性要求以 `\r\n` 分帧）；
3. 用手机 App 连接此蓝牙模块，在电脑串口助手里点发送 JSON，手机 App 即可实时响应！

---

## 方案 2：Python 自动化仿真 NCU 脚本（Mock Server）

配合上面的硬件或电脑串口，直接运行以下 Python 脚本，即可实现每 2 秒自动向手机发送真实遥测，并自动应答控制回执：

```python
# mock_ncu_server.py
# 运行前请先执行: pip install pyserial
import serial
import time
import json
import threading

SERIAL_PORT = 'COM3'  # 修改为您电脑设备管理器中实际的 COM 口号
BAUD_RATE = 9600

def main():
    try:
        ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=0.1)
        print(f"[OK] 已打开串口 {SERIAL_PORT}，等待 App 连接通信...")
    except Exception as e:
        print(f"[ERR] 无法打开串口: {e}")
        return

    # 后台线程：每 2 秒定时广播一次遥测报文 (telemetry)
    def telemetry_loop():
        angle = 0.0
        while True:
            time.sleep(2.0)
            telemetry_data = {
                "protocol_version": 1,
                "message_type": "telemetry",
                "ncu_id": "001",
                "windSpeed": 2.6,
                "windDirrect": 125.0,
                "solarIrradiance": 720.5,
                "timestamp": int(time.time()),
                "tcuData": [
                    {"tcu_id": "001", "actual_angle": angle, "expect_angle": angle + 1.5, "current": 1.25, "onlineStatus": True, "stall_fault": False},
                    {"tcu_id": "002", "actual_angle": angle - 0.5, "expect_angle": angle, "current": 1.18, "onlineStatus": True, "stall_fault": False},
                    {"tcu_id": "003", "actual_angle": angle, "expect_angle": angle, "current": 1.30, "onlineStatus": True, "stall_fault": False},
                    {"tcu_id": "004", "actual_angle": angle + 0.8, "expect_angle": angle + 1.0, "current": 1.22, "onlineStatus": True, "stall_fault": False},
                    {"tcu_id": "005", "actual_angle": angle, "expect_angle": angle, "current": 1.15, "onlineStatus": True, "stall_fault": False}
                ]
            }
            msg = json.dumps(telemetry_data) + "\r\n"
            try:
                ser.write(msg.encode('utf-8'))
                # print("[TX 遥测] 上报成功")
            except Exception:
                pass

    t = threading.Thread(target=telemetry_loop, daemon=True)
    t.start()

    # 主循环：监听并解析 App 发来的控制指令 (command) 并回复 ACK
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
                    print(f"\n[RX 收到 App 指令] {line}")
                    try:
                        cmd = json.loads(line)
                        if cmd.get("message_type") == "command":
                            # 构造并回复 ACK 回执
                            ack = {
                                "protocol_version": 1,
                                "message_type": "command_ack",
                                "request_id": cmd.get("request_id", 0),
                                "cmdType": cmd.get("cmdType", "UNKNOWN"),
                                "ncu_id": cmd.get("ncu_id", "001"),
                                "tcu_id": cmd.get("tcu_id", "ALL"),
                                "status": "accepted",
                                "error_code": 0,
                                "message": "指令已执行",
                                "timestamp": int(time.time())
                            }
                            ser.write((json.dumps(ack) + "\r\n").encode('utf-8'))
                            print(f"[TX 回复 ACK] 已确认: {cmd.get('cmdType')}")
                    except Exception as parse_err:
                        print(f"[WARN] 报文解析错误: {parse_err}")
        except KeyboardInterrupt:
            print("\n退出仿真程序")
            break

if __name__ == '__main__':
    main()
```

---

## 附录：可直接复制的测试报文模板（UTF-8 JSON）

> **注意**：串口助手发送时必须以 `\r\n` (换行) 结尾。

### 1. 正常遥测数据上报 (`telemetry`)
```json
{"protocol_version":1,"message_type":"telemetry","ncu_id":"001","windSpeed":3.2,"windDirrect":90.0,"solarIrradiance":850.0,"timestamp":1731000000,"tcuData":[{"tcu_id":"001","actual_angle":15.0,"expect_angle":15.0,"current":1.20,"onlineStatus":true,"stall_fault":false},{"tcu_id":"002","actual_angle":14.8,"expect_angle":15.0,"current":1.22,"onlineStatus":true,"stall_fault":false},{"tcu_id":"003","actual_angle":15.1,"expect_angle":15.0,"current":1.25,"onlineStatus":true,"stall_fault":false},{"tcu_id":"004","actual_angle":15.0,"expect_angle":15.0,"current":1.19,"onlineStatus":true,"stall_fault":false},{"tcu_id":"005","actual_angle":15.0,"expect_angle":15.0,"current":1.21,"onlineStatus":true,"stall_fault":false}]}
```

### 2. 模拟 TCU 002 发生“电机堵转故障”报警
*(发送此报文后，App 上 TCU 002 会立即呈现红色加粗警告框与“堵转告警 (点此复位)”按钮)*
```json
{"protocol_version":1,"message_type":"telemetry","ncu_id":"001","windSpeed":5.8,"windDirrect":180.0,"solarIrradiance":620.0,"timestamp":1731000010,"tcuData":[{"tcu_id":"001","actual_angle":10.0,"expect_angle":10.0,"current":1.10,"onlineStatus":true,"stall_fault":false},{"tcu_id":"002","actual_angle":10.0,"expect_angle":20.0,"current":6.80,"onlineStatus":true,"stall_fault":true},{"tcu_id":"003","actual_angle":10.0,"expect_angle":10.0,"current":1.15,"onlineStatus":true,"stall_fault":false},{"tcu_id":"004","actual_angle":10.0,"expect_angle":10.0,"current":1.12,"onlineStatus":true,"stall_fault":false},{"tcu_id":"005","actual_angle":10.0,"expect_angle":10.0,"current":1.18,"onlineStatus":true,"stall_fault":false}]}
```

### 3. 指令执行成功回执 (`command_ack`)
```json
{"protocol_version":1,"message_type":"command_ack","request_id":1,"cmdType":"SET_ANGLE","ncu_id":"001","tcu_id":"ALL","status":"accepted","error_code":0,"message":"success","timestamp":1731000000}
```
