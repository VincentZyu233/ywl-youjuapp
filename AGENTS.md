# AGENTS.md

本文件为 AI 编码助手（Gemini、Claude Code、Codex 等）及协作者在本地运行、维护与二次开发 `youjuAPP` 的操作指引。

---

## 1. 项目概述

`youjuAPP` 是一款面向光伏电站现场运维的**太阳能智能跟踪支架控制器（TCU - Tracker Control Unit）移动端蓝牙管理应用**。
* **技术架构**：uni-app + Vue 3 模式开发，支持编译为 Android 原生应用（APK）以及 H5 Web 预览。
* **核心业务**：
  * BLE 蓝牙扫描与设备连接（`utils/ble.js`）。
  * TCU 参数下发与广播（天文参数、组件排距/宽度、过流保护与夜返/清洗/避风保护角、东西限位角）。
  * 12 键群控操作面板（自动、平置、急停、东/西点动、恶劣天气避险模式等）。
  * 设备 RTC 实时时钟校准与固件版本读取。

---

## 2. 常用命令 (CLI)

本地开发环境推荐使用 Node.js（v18+ / v20+ / v22+），无需依赖图形界面即可在命令行启动 H5 本地预览：

```bash
# 启动本地 H5 开发预览服务器（默认端口 61102）
npm run dev
# 或
npm run dev:h5

# 临时指定其他端口运行
npm run dev -- --port 8080
```

> **环境依赖说明**：
> 本地 CLI 运行基于 HBuilderX 内置的 uni-app Vite 编译内核（`uniapp-cli-vite`）。
> `scripts/dev.js` 会自动检测常见路径（如 `D:\SSoftwareFiles\HBuiderX\...` 或 `C:\Program Files\HBuilderX`）。
> 若 HBuilderX 安装在非默认目录，只需在环境中设置：
> ```bash
> $env:HX_APP_ROOT = "你的HBuilderX安装目录"
> ```

---

## 3. 端口持久化方案说明

本项目将开发服务器默认端口从 Vite 默认的 `5173` 改为 **`61102`**，持久化机制如下：

1. **`manifest.json`（DCloud 官方标准规范）**：
   在 `manifest.json` 中配置了：
   ```json
   "h5": {
     "title": "蓝牙设备管理",
     "devServer": {
       "port": 61102,
       "disableHostCheck": true
     }
   }
   ```
   无论是 HBuilderX 界面点击运行还是底层 Vite CLI 构建，编译器都会首选加载并持久化此端口。
2. **`scripts/dev.js`（CLI 跨平台启动器）**：
   默认兜底指定 `--port 61102`，同时也支持通过命令行参数（如 `--port 8080`）或环境变量临时覆盖。

---

## 4. 目录结构与规范

```
youjuAPP/
├── pages/
│   ├── index/index.vue       # 蓝牙设备扫描与列表页
│   └── device/index.vue      # 设备详情页（信息/参数设置/广播/群控）
├── components/
│   ├── device-card.vue       # 设备卡片组件
│   ├── setting-card.vue      # 参数设置卡片组件
│   ├── control-button.vue    # 群控按钮组件
│   └── bottom-nav.vue        # 底部导航组件
├── utils/
│   ├── ble.js                # BLE 蓝牙适配与数据通信封装
│   └── storage.js            # 本地缓存封装
├── scripts/
│   └── dev.js                # 跨平台一键 CLI 启动器
├── unpackage/res/icons/      # App 原生图标资源
├── manifest.json             # 应用配置（权限/版本/模块/H5端口）
├── pages.json                # 页面路由与窗口外观
├── vite.config.js            # Vite 配置（含持久化端口 61102）
└── index.html                # H5 运行入口模板
```

---

## 5. 打包与发布

* **Android APK 原生包**：
  使用 HBuilderX 打开本项目根目录，点击菜单 `发行` -> `原生 App-云打包` 或 `运行到手机或模拟器` 制作 Android APK。
* **H5 生产构建**：
  ```bash
  npx uni build -p h5
  ```
