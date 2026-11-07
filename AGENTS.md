# AGENTS.md

本文件为 AI 编码助手（Gemini、Claude Code、Codex 等）及协作者在本地运行、维护、测试与二次开发 `youjuAPP` 的操作指引。

---

## 1. 项目概述

`youjuAPP` 是一款面向光伏电站现场运维的**太阳能智能跟踪支架控制器（TCU - Tracker Control Unit）移动端蓝牙管理应用**。

- **核心技术栈**：Flutter (Dart 3.x) + Android 原生 Kotlin (经典蓝牙 SPP 插件) + Material 3 现代工业工控设计规范。
- **通信架构**：
  - **经典蓝牙 SPP (主)**：基于 RFCOMM Socket（UUID: `00001101-0000-1000-8000-00805F9B34FB`），完美兼容下位机主流透传模块（JDY-31、HC-05）。
  - **BLE GATT (辅)**：保留低功耗蓝牙扫描与通信底座，构成双模一体化服务。
  - **协议闭环**：完全对齐官方《交接文档》，采用 `\r\n` (CRLF) 分帧解析下位机 JSON 遥测报文，支持 5 台 TCU 实时轮询监控与 10 项标准群控指令。
- **调试设施**：内置滑出式「报文监控终端抽屉」，支持双向 Hex/ASCII 实时日志与清屏调试。

---

## 2. 本地专属配置与发现规范 (Local Config)

为了防止个人局域网 IP、本地私有开发路径与特定设备信息被误提交至公开 Git 仓库，本项目遵循以下本地配置发现规范：

```
youjuAPP-flutter/
├── AGENT.local.example.md    # [Git跟踪] 配置规范模板与格式说明
├── AGENT.local.md            # [Git忽略] 本机实际生效的私有配置（由开发者/Agent维护）
└── .gitignore                # 已配置忽略 AGENT.local.md
```

### Agent 加载优先级策略
1. **优先读取**：AI Agent 每次准备执行真机联调、截图、ADB 自动化或仿真时，首先检查根目录是否存在 [`AGENT.local.md`](AGENT.local.md)。
2. **提取参数**：从 `AGENT.local.md` 中读取本地 ADB 路径、无线调试端点（IP:Port）、设备型号及物理分辨率。
3. **回退兜底**：若 `AGENT.local.md` 不存在，读取 [`AGENT.local.example.md`](AGENT.local.example.md) 中的模板格式，并提示用户提供当前手机的局域网无线调试端点后在本地生成。

---

## 3. 无线 ADB 真机调试指引 (Wireless ADB Debugging)

通过 Android 11+ 原生无线调试功能，无需物理 USB 连接线即可实现代码热重载、APK 静默安装、屏幕自动操控及实时日志抓取。

### 3.1 连接与 Session 隔离避坑

> [!WARNING]
> 在多进程或沙箱式 Shell（如独立 PowerShell 会话）中，后台 ADB daemon 可能会在子进程结束后释放。
> **铁律**：每次执行 ADB 子命令前，必须在同一行命令中先行执行 `connect` 确保处于活跃连接态：
> ```powershell
> $adb = "D:\SSoftwareFiles\scrcpy\scrcpy-win64-v3.3.3\adb.exe"
> $device = "192.168.31.3:43001"
> & $adb connect $device ; & $adb -s $device <子命令>
> ```

### 3.2 屏幕截图与画面采集规范

> [!CAUTION]
> 严禁在 PowerShell 下使用 `adb exec-out screencap -p > screen.png` 重定向！PowerShell 会将输出流转码为带有 BOM 的 UTF-16LE 文本，彻底损坏 PNG 图像二进制标头。
> **正确做法**：在 Android 手机本地生成图片后再回拉：
> ```powershell
> & $adb -s $device shell screencap -p /sdcard/screen.png
> & $adb -s $device pull /sdcard/screen.png "D:\temp\gemini\ywl-youjuapp\screen.png"
> ```

### 3.3 触控自动化与分辨率适配

- **物理分辨率确认**：不同真机屏幕比例差异较大（如 vivo iQOO V2307A 物理分辨率为 **`1260 x 2800`**，而非传统 1080p）。
- **获取物理分辨率**：
  ```powershell
  & $adb -s $device shell wm size
  ```
- **核心操作命令**：
  ```powershell
  # 点击指定坐标
  & $adb -s $device shell input tap <X> <Y>
  
  # 滑动（从 X1,Y1 滑至 X2,Y2，耗时 ms）
  & $adb -s $device shell input swipe 630 2000 630 800 300
  
  # 输入纯英文字符串
  & $adb -s $device shell input text "JDY-31"
  
  # 常用按键事件：4=返回键, 66=回车键, 67=删除键, 123=移动光标到行尾
  & $adb -s $device shell input keyevent 4
  ```

### 3.4 APK 一键编译与真机推送安装

最新 Release APK 统一输出在 [`download/v2.1.1/youjuAPP_v2.1.1.apk`](download/v2.1.1/youjuAPP_v2.1.1.apk)。本地推送覆盖安装命令：

```powershell
# 1. 覆盖安装应用 (-r 保持数据)
& $adb -s $device install -r "D:\aaaStuffsaaa\from_git\gitee\ywl-youjuapp\youjuAPP-flutter\download\v2.1.1\youjuAPP_v2.1.1.apk"

# 2. 唤醒并冷启动应用主页面
& $adb -s $device shell am start -n "com.youju.tcuapp/com.youju.tcuapp.MainActivity"
```

### 3.5 实时日志捕获与经典蓝牙排查

排查蓝牙广播、SPP Socket 建立、JSON 遥测解析及 Flutter 渲染异常时：

```powershell
# 清空历史缓冲区
& $adb -s $device logcat -c

# 过滤 Flutter 框架日志与原生蓝牙插件日志
& $adb -s $device logcat -s Flutter:V BluetoothSppPlugin:V *:S
```

---

## 4. 下位机仿真测试指南

当现场缺少物理光伏支架和 TCU 单片机硬件时，可通过本地仿真套件完成 100% 协议与界面闭环测试：

- **联调文档**：[`docs/20261107调试文档/经典蓝牙SPP与下位机NCU本地联调测试指南.md`](docs/20261107调试文档/经典蓝牙SPP与下位机NCU本地联调测试指南.md)
- **仿真脚本**：[`docs/20261107调试文档/mock_ncu_server.py`](docs/20261107调试文档/mock_ncu_server.py)
  - **模式 A (硬件串口直连)**：电脑插入 CH340 USB 转 TTL + JDY-31 经典蓝牙模块，运行脚本后手机端直接扫描连接蓝牙从机。
  - **模式 B (0元副手机/平板)**：副手机安装 SPP 蓝牙串口调试助手运行仿真逻辑。

---

## 5. 项目工程结构

```
youjuAPP-flutter/
├── android/                  # Android 原生平台源码与签名配置
│   ├── app/src/main/kotlin/  # Kotlin 核心实现
│   │   └── com/youju/tcuapp/
│   │       ├── MainActivity.kt
│   │       └── BluetoothSppPlugin.kt  # 原生经典蓝牙 SPP 插件 (RFCOMM)
│   └── app/youjuapp.keystore # 永久私有发布签名证书
├── lib/                      # Flutter 跨平台源码
│   ├── models/               # 数据模型 (ncu_protocol.dart 官方协议对象)
│   ├── providers/            # 状态管理 (BleProvider, TcuControllerProvider)
│   ├── services/             # 通信服务 (UnifiedBluetoothService, ClassicSppService)
│   ├── theme/                # Material 3 工业设计主题 (app_theme.dart)
│   └── views/                # 页面组件
│       ├── home/             # 首页（蓝牙设备列表、连接状态卡片）
│       └── device/           # 控制中心（信息/参数/广播/群控 Tab + 报文终端抽屉）
├── docs/                     # 协议与联调文档
├── download/                 # 编译归档 Release APK (v2.0.0, v2.1.0, v2.1.1)
├── CHANGELOG.md              # 语义化版本演进日志
├── README.md                 # 项目主索引与文档导航
├── AGENT.local.example.md    # 本地调试配置模板
└── AGENT.local.md            # [本地私有] 开发者私有无线调试配置 (已忽略)
```
