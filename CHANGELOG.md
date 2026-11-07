# 更新日志 (CHANGELOG)

本项目遵循 [Semantic Versioning 2.0.0](https://semver.org/lang/zh-CN/) 语义化版本规范。

---

## [[v2.1.1](download/v2.1.1/youjuAPP_v2.1.1.apk)] - 2026-11-07 (当前最新稳定版)

### 修复与优化 (Fixes & Improvements)
- **蓝牙未开启拦截与系统原生授权弹窗**：在手机物理蓝牙未开启时，点击“开始搜索”前置拦截虚假扫描状态，调用 Android 系统原生 `ACTION_REQUEST_ENABLE` 弹窗引导用户开启蓝牙。
- **消除 Tab 切换遮罩残影**：设备控制页底部 4 个导航 Tab（设备信息、参数设置、广播控制、群控联动）切换时彻底移除 `InkWell` 系统默认的水波纹与灰色圆角矩形遮罩，改用平滑的 `AnimatedContainer` Material 3 胶囊动效，杜绝视觉残留。
- **真机联调闭环验证**：通过无线 ADB 在真实 Android 手机上完整验证了蓝牙权限弹窗、报文监控抽屉唤出、Tab 平滑切换等交互闭环。

### 工程清理与文档 (Maintenance & Docs)
- **彻底清理旧工程遗留代码**：彻底移除仓库中残留的历史 uni-app 源码（`App.vue`, `pages/`, `components/`, `scripts/` 等），使工程纯度提升至 90%+ 纯粹 Flutter (Dart/Kotlin)。
- **配套联调与仿真套件交付**：
  - 新增 [`docs/20261107调试文档/经典蓝牙SPP与下位机NCU本地联调测试指南.md`](docs/20261107调试文档/经典蓝牙SPP与下位机NCU本地联调测试指南.md)。
  - 新增配套 Python 仿真服务 [`mock_ncu_server.py`](docs/20261107调试文档/mock_ncu_server.py)，支持 0 元副手机与 20 元 USB-TTL 硬件方案进行闭环仿真测试。

---

## [[v2.1.0](download/v2.1.0/youjuAPP_v2.1.0.apk)] - 2026-11-07

### 重大特性 (Features)
- **双模蓝牙通信底座**：
  - 原生 Kotlin 实现 Android 经典蓝牙 SPP 插件 (`BluetoothSppPlugin.kt`)，支持标准 RFCOMM UUID (`00001101-0000-1000-8000-00805F9B34FB`)。
  - 彻底解决工业现场下位机常用经典蓝牙串口模块（JDY-31 / HC-05）在原生层无法搜索与配对连接的痛点。
- **官方《交接文档》协议对齐**：
  - 实现以 `\r\n` (CRLF) 分帧的 UTF-8 JSON 遥测报文解析。
  - 支持 10 项标准群控指令（网络参数配置、工作模式切换、白名单写入、心跳等）。
- **TCU 遥测监控大盘**：
  - 实时解析并展示 5 台 TCU 设备状态卡片（倾角、工作电压、工作电流、电机状态、系统告警等）。
- **实时报文监控抽屉**：
  - 控制页面右上角新增滑出式控制台终端，支持实时 Hex/ASCII 报文收发日志、自动滚屏与一键清屏。

---

## [[v2.0.0](download/v2.0.0/youjuAPP_v2.0.0.apk)] - 2026-11-06

### 重大重构 (Architecture)
- **全面重构为原生 Flutter 架构**：彻底告别 uni-app (Vue 2) 与 WebView 混合开发体系，消除跨平台掉帧与蓝牙连接不稳定现象。
- **Material 3 现代工控视觉**：工业深蓝科技配色、波纹状态指示、高响应度交互卡片。
- **设备控制中心框架**：建立「设备信息」、「参数设置」、「广播控制」、「群控联动」四大管理 Tab。
- **CI/CD 流水线**：搭建基于 GitHub Actions 的 Flutter 自动化构建与 Release APK 产物归档流程。

---

## [v1.x 历史版本 (uni-app 早期版本)]

- **v1.0.14**：重构设备列表滚动与底部吸底按钮布局，实现详情页真实 BLE GATT 蓝牙连接。
- **v1.0.3**：接入自动化版本管理脚本 `bump.js` 与本地离线私有证书签名流水线。
- **v1.0.0**：项目立项，基于 uni-app + Vue 2 开发的 TCU 蓝牙调试原型工具。
