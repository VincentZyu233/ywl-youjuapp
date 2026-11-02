# youjuAPP UniApp 重构设计文档

## 项目概述

将现有的蓝牙设备管理 HTML 页面完全重构为 UniApp + Vue 3 项目，生成 Android APK。

**目标平台**: Android

**核心功能**:
1. 蓝牙设备扫描与列表展示
2. 蓝牙设备连接管理
3. 读取设备数据
4. 写入参数并广播
5. 群控操作面板

**后端**: 纯本地操作，无需后端

---

## 界面设计

### 页面结构

| 页面 | 路由 | 功能 |
|------|------|------|
| 设备列表页 | `/pages/index/index` | 扫描附近蓝牙设备，显示列表 |
| 设备详情页 | `/pages/device/index` | 显示设备信息、设置参数、群控面板 |

### 设备列表页

- **顶部区域**: 蓝牙开关、状态指示（已开启/已关闭）
- **设备列表**: 显示设备名称、MAC 地址、信号强度、连接状态
- **底部按钮**: "扫描附近设备" 按钮
- **交互**: 点击设备卡片进入设备详情页

### 设备详情页

- **顶部区域**: 返回按钮、设备名称、设备时间（实时）、TCU 版本、NET 状态
- **底部 Tab 导航**: 信息 / 设置 / 广播 / 群控

#### Tab: 信息
- 占位区域，待后续实现

#### Tab: 设置（4 个卡片）
1. **天文参数设置**: 经度、纬度、时区
2. **组件参数设置**: 组件宽度、组件间距
3. **保护参数设置**: 过流保护、夜返保护角、清洗保护角、迎风保护角、TCU 版本选择
4. **东西限位角设置**: 东限位角、西限位角

每个卡片都有 "写入并广播" 按钮。

#### Tab: 广播
- 占位区域，待后续实现

#### Tab: 群控
- 12 按钮网格布局: 自动、放平、停止、向西、清洗、向东、大雪、大雨、洪水、大风、空、低功耗

### 视觉风格

- **配色**: 蓝白配色（主色 #3B82F6，背景 #F8FAFC）
- **圆角**: 大圆角卡片（rounded-2xl / rounded-3xl）
- **字体**: system-ui, -apple-system, sans-serif
- **阴影**: 轻量阴影（shadow-sm / shadow-md）
- **移动端优先**: 100dvh 高度，iPhone 模拟框架样式

---

## 组件结构

```
components/
├── device-card.vue        # 设备列表中的设备卡片
├── setting-card.vue       # 设置页面的参数卡片
├── control-button.vue     # 群控按钮
└── bottom-nav.vue         # 底部导航栏
```

---

## 工具模块

```
utils/
├── ble.js                 # 蓝牙通信封装
│   ├── initBluetooth()    # 初始化蓝牙适配器
│   ├── startDiscovery()   # 开始扫描设备
│   ├── stopDiscovery()     # 停止扫描
│   ├── connectDevice()    # 连接设备
│   ├── disconnectDevice() # 断开连接
│   ├── readDeviceInfo()   # 读取设备信息
│   └── writeParameter()   # 写入参数并广播
└── storage.js             # 本地存储封装
```

---

## 路由配置

```json
{
  "pages": [
    {
      "path": "pages/index/index",
      "style": { "navigationBarTitleText": "蓝牙连接" }
    },
    {
      "path": "pages/device/index",
      "style": { "navigationBarTitleText": "设备详情" }
    }
  ],
  "globalStyle": {
    "navigationBarTextStyle": "black",
    "navigationBarTitleText": "蓝牙设备管理",
    "navigationBarBackgroundColor": "#F8FAFC",
    "backgroundColor": "#F8FAFC"
  }
}
```

---

## 蓝牙协议设计

使用 UniApp 的 `uni-ble` API 与 TCU 设备通信。

### 服务与特征值

| 服务/特征值 | 说明 | 用途 |
|------------|------|------|
| `0000FFE0-0000-1000-8000-00805F9B34FB` | BLE 服务 UUID | 主服务 |
| `0000FFE1-0000-1000-8000-00805F9B34FB` | 写入特征值 | 下发命令/参数 |
| `0000FFE2-0000-1000-8000-00805F9B34FB` | 通知特征值 | 接收设备数据 |

### 数据格式

命令格式（待与硬件团队确认）:
- 写入: 设备地址 + 命令类型 + 参数数据
- 读取: 设备地址 + 命令类型

---

## 本地存储

使用 `uni.setStorageSync` / `uni.getStorageSync`:

| Key | 类型 | 说明 |
|-----|------|------|
| `lastConnectedDevice` | string | 上次连接的设备 MAC 地址 |
| `deviceList` | array | 扫描到的设备列表缓存 |

---

## 实施步骤

1. 创建 UniApp 项目（HBuilderX）
2. 配置 manifest.json（AppID、应用名称、平台配置）
3. 创建页面结构（index, device）
4. 封装蓝牙工具模块（ble.js）
5. 实现设备列表页（扫描、显示设备）
6. 实现设备详情页（Tab 导航、设置卡片）
7. 实现群控面板
8. 调试蓝牙功能
9. 打包 APK

---

## 待确认事项

- [ ] 蓝牙服务的具体 UUID（需与硬件团队确认）
- [ ] 命令协议的具体数据格式（需与硬件团队确认）
- [ ] 是否需要连接历史记录功能
- [ ] 是否需要设备别名/备注功能
