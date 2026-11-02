# youjuAPP UniApp Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将蓝牙设备管理 HTML 页面重构为 UniApp + Vue 3 项目，生成 Android APK

**Architecture:** 使用 UniApp 的 Vue 3 模式，页面路由管理，封装蓝牙通信工具模块，纯本地存储

**Tech Stack:** UniApp + Vue 3, HBuilderX, uni-ble API

---

## File Structure

```
youjuAPP/
├── pages/
│   ├── index/
│   │   └── index.vue           # 设备列表页
│   └── device/
│       └── index.vue           # 设备详情页
├── components/
│   ├── device-card.vue         # 设备卡片组件
│   ├── setting-card.vue        # 设置卡片组件
│   ├── control-button.vue      # 群控按钮组件
│   └── bottom-nav.vue          # 底部导航组件
├── utils/
│   ├── ble.js                  # 蓝牙通信封装
│   └── storage.js              # 本地存储封装
├── static/
│   └── (empty, 使用 CDN)
├── App.vue
├── main.js
├── manifest.json
└── pages.json
```

---

## Task 1: 创建 UniApp 项目骨架

**Files:**
- Create: `youjuAPP/App.vue`
- Create: `youjuAPP/main.js`
- Create: `youjuAPP/manifest.json`
- Create: `youjuAPP/pages.json`

- [ ] **Step 1: 创建项目目录结构**

```bash
mkdir -p pages/index pages/device components utils static
```

- [ ] **Step 2: 创建 main.js**

```javascript
import App from './App'

App.mpType = 'app'

const app = Vue.createApp(App)
app.mount()
```

- [ ] **Step 3: 创建 App.vue**

```vue
<script>
export default {
  onLaunch() {
    console.log('App Launch')
  },
  onShow() {
    console.log('App Show')
  },
  onHide() {
    console.log('App Hide')
  }
}
</script>
<style>
page {
  background-color: #f8fafc;
}
</style>
```

- [ ] **Step 4: 创建 manifest.json（应用配置）**

```json
{
  "name": "youjuAPP",
  "appid": "__UNI__YOUJUAPP",
  "description": "蓝牙设备管理",
  "versionName": "1.0.0",
  "versionCode": "100",
  "transformPx": false,
  "app-plus": {
    "usingComponents": true,
    "nvueStyleCompiler": "uni-app",
    "compilerVersion": 3,
    "splashscreen": {
      "alwaysShowBeforeRender": true,
      "waiting": true,
      "autoclose": true,
      "delay": 0
    },
    "modules": {},
    "distribute": {
      "android": {
        "permissions": [
          "<uses-permission android:name=\"android.permission.BLUETOOTH\"/>",
          "<uses-permission android:name=\"android.permission.BLUETOOTH_ADMIN\"/>",
          "<uses-permission android:name=\"android.permission.ACCESS_FINE_LOCATION\"/>",
          "<uses-permission android:name=\"android.permission.ACCESS_COARSE_LOCATION\"/>"
        ]
      }
    }
  },
  "uniStatistics": {
    "enable": false
  }
}
```

- [ ] **Step 5: 创建 pages.json**

```json
{
  "pages": [
    {
      "path": "pages/index/index",
      "style": {
        "navigationBarTitleText": "蓝牙连接",
        "navigationStyle": "custom",
        "disableScroll": true
      }
    },
    {
      "path": "pages/device/index",
      "style": {
        "navigationBarTitleText": "设备详情",
        "navigationStyle": "custom"
      }
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

## Task 2: 创建工具模块

**Files:**
- Create: `utils/ble.js`
- Create: `utils/storage.js`

- [ ] **Step 1: 创建 storage.js**

```javascript
const STORAGE_KEYS = {
  LAST_CONNECTED_DEVICE: 'lastConnectedDevice',
  DEVICE_LIST: 'deviceList'
}

export function setLastConnectedDevice(mac) {
  uni.setStorageSync(STORAGE_KEYS.LAST_CONNECTED_DEVICE, mac)
}

export function getLastConnectedDevice() {
  return uni.getStorageSync(STORAGE_KEYS.LAST_CONNECTED_DEVICE) || ''
}

export function setDeviceList(list) {
  uni.setStorageSync(STORAGE_KEYS.DEVICE_LIST, list)
}

export function getDeviceList() {
  return uni.getStorageSync(STORAGE_KEYS.DEVICE_LIST) || []
}

export function clearStorage() {
  uni.removeStorageSync(STORAGE_KEYS.LAST_CONNECTED_DEVICE)
  uni.removeStorageSync(STORAGE_KEYS.DEVICE_LIST)
}
```

- [ ] **Step 2: 创建 ble.js（蓝牙通信封装）**

```javascript
// BLE 服务与特征值 UUID（需根据实际设备调整）
const BLE_SERVICE_UUID = '0000FFE0-0000-1000-8000-00805F9B34FB'
const BLE_CHAR_WRITE_UUID = '0000FFE1-0000-1000-8000-00805F9B34FB'
const BLE_CHAR_NOTIFY_UUID = '0000FFE2-0000-1000-8000-00805F9B34FB'

// 蓝牙状态
let isBluetoothAvailable = false
let isDiscovering = false
let connectedDeviceId = null

// 初始化蓝牙适配器
export function initBluetooth() {
  return new Promise((resolve, reject) => {
    uni.openBluetoothAdapter({
      success: (res) => {
        isBluetoothAvailable = true
        resolve(res)
      },
      fail: (err) => {
        isBluetoothAvailable = false
        reject(err)
      }
    })
  })
}

// 获取蓝牙适配器状态
export function getBluetoothAdapterState() {
  return new Promise((resolve, reject) => {
    uni.getBluetoothAdapterState({
      success: resolve,
      fail: reject
    })
  })
}

// 开始扫描设备
export function startBluetoothDevicesDiscovery() {
  return new Promise((resolve, reject) => {
    if (isDiscovering) {
      resolve()
      return
    }
    uni.startBluetoothDevicesDiscovery({
      allowDuplicatesKey: false,
      success: (res) => {
        isDiscovering = true
        resolve(res)
      },
      fail: reject
    })
  })
}

// 停止扫描
export function stopBluetoothDevicesDiscovery() {
  return new Promise((resolve, reject) => {
    uni.stopBluetoothDevicesDiscovery({
      success: (res) => {
        isDiscovering = false
        resolve(res)
      },
      fail: reject
    })
  })
}

// 获取已发现的设备列表
export function getBluetoothDevices() {
  return new Promise((resolve, reject) => {
    uni.getBluetoothDevices({
      success: resolve,
      fail: reject
    })
  })
}

// 获取连接中的设备
export function getConnectedBluetoothDevices() {
  return new Promise((resolve, reject) => {
    uni.getConnectedBluetoothDevices({
      success: resolve,
      fail: reject
    })
  })
}

// 连接设备
export function createBLEConnection(deviceId) {
  return new Promise((resolve, reject) => {
    uni.createBLEConnection({
      deviceId,
      success: (res) => {
        connectedDeviceId = deviceId
        resolve(res)
      },
      fail: reject
    })
  })
}

// 断开连接
export function closeBLEConnection(deviceId) {
  return new Promise((resolve, reject) => {
    uni.closeBLEConnection({
      deviceId: deviceId || connectedDeviceId,
      success: (res) => {
        connectedDeviceId = null
        resolve(res)
      },
      fail: reject
    })
  })
}

// 获取设备服务
export function getBLEDeviceServices(deviceId) {
  return new Promise((resolve, reject) => {
    uni.getBLEDeviceServices({
      deviceId,
      success: resolve,
      fail: reject
    })
  })
}

// 获取特征值
export function getBLEDeviceCharacteristics(deviceId, serviceId) {
  return new Promise((resolve, reject) => {
    uni.getBLEDeviceCharacteristics({
      deviceId,
      serviceId,
      success: resolve,
      fail: reject
    })
  })
}

// 启用通知
export function notifyBLECharacteristicValueChange(deviceId, serviceId, characteristicId) {
  return new Promise((resolve, reject) => {
    uni.notifyBLECharacteristicValueChange({
      deviceId,
      serviceId,
      characteristicId,
      state: true,
      success: resolve,
      fail: reject
    })
  })
}

// 写入数据
export function writeBLECharacteristicValue(deviceId, serviceId, characteristicId, data) {
  return new Promise((resolve, reject) => {
    const buffer = new ArrayBuffer(data.length)
    const view = new Uint8Array(buffer)
    for (let i = 0; i < data.length; i++) {
      view[i] = data[i]
    }
    uni.writeBLECharacteristicValue({
      deviceId,
      serviceId,
      characteristicId,
      value: buffer,
      success: resolve,
      fail: reject
    })
  })
}

// 监听设备发现
export function onBluetoothDeviceFound(callback) {
  uni.onBluetoothDeviceFound(callback)
}

// 监听适配器状态变化
export function onBluetoothAdapterStateChange(callback) {
  uni.onBluetoothAdapterStateChange(callback)
}

// 监听连接状态变化
export function onBLEConnectionStateChange(callback) {
  uni.onBLEConnectionStateChange(callback)
}

// 监听特征值变化
export function onBLECharacteristicValueChange(callback) {
  uni.onBLECharacteristicValueChange(callback)
}

export {
  isBluetoothAvailable,
  isDiscovering,
  connectedDeviceId,
  BLE_SERVICE_UUID,
  BLE_CHAR_WRITE_UUID,
  BLE_CHAR_NOTIFY_UUID
}
```

---

## Task 3: 创建通用组件

**Files:**
- Create: `components/device-card.vue`
- Create: `components/setting-card.vue`
- Create: `components/control-button.vue`
- Create: `components/bottom-nav.vue`

- [ ] **Step 1: 创建 device-card.vue**

```vue
<template>
  <view class="bg-white rounded-2xl p-4 shadow-sm border border-slate-100 cursor-pointer hover:shadow-md active:scale-[0.98] transition-all duration-200" @click="handleClick">
    <view class="flex items-start justify-between">
      <view class="flex items-start space-x-3 flex-1 overflow-hidden">
        <view :class="['p-2 rounded-xl mt-0.5 shadow-sm', isConnected ? 'bg-green-50 text-green-600 ring-1 ring-green-500/20' : 'bg-slate-50 text-slate-400 ring-1 ring-slate-200']">
          <uni-icons type="bluetooth" size="20"></uni-icons>
        </view>
        <view class="flex-1 min-w-0">
          <view class="flex items-center space-x-2">
            <text class="text-[16px] font-bold text-slate-800 truncate">{{ deviceName }}</text>
            <view v-if="isConnected" class="px-2 py-0.5 bg-green-100 text-green-700 text-[10px] font-bold rounded-full uppercase tracking-wider">已连接</view>
          </view>
          <text class="text-[13px] font-mono text-slate-500 mt-1 flex items-center space-x-1.5">
            <text>{{ macAddress }}</text>
          </text>
        </view>
      </view>
      <view class="flex flex-col items-end justify-between h-full pl-3 space-y-3">
        <view class="flex items-center space-x-1 text-slate-400">
          <text class="text-xs font-bold" :class="signalLevel >= 3 ? 'text-blue-500' : 'text-slate-400'">{{ signalLevel }}</text>
          <uni-icons type="signal" size="14" :color="signalLevel >= 3 ? '#3B82F6' : '#94A3B8'"></uni-icons>
        </view>
        <uni-icons type="right" size="18" color="#CBD5E1" class="group-hover:text-blue-500 transition-colors"></uni-icons>
      </view>
    </view>
  </view>
</template>

<script>
export default {
  name: 'DeviceCard',
  props: {
    deviceName: {
      type: String,
      default: '未知设备'
    },
    macAddress: {
      type: String,
      default: '00:00:00:00:00:00'
    },
    signalLevel: {
      type: Number,
      default: 0
    },
    isConnected: {
      type: Boolean,
      default: false
    }
  },
  methods: {
    handleClick() {
      this.$emit('click', {
        name: this.deviceName,
        mac: this.macAddress
      })
    }
  }
}
</script>
```

- [ ] **Step 2: 创建 setting-card.vue**

```vue
<template>
  <view class="bg-white rounded-3xl mb-5 shadow-sm border border-slate-100 overflow-hidden">
    <view class="flex items-center space-x-2 px-5 py-4 bg-slate-50/50 border-b border-slate-100">
      <view class="p-1.5 bg-blue-100 text-blue-600 rounded-lg">
        <uni-icons :type="icon" size="16"></uni-icons>
      </view>
      <h3 class="text-slate-800 font-bold text-sm">{{ title }}</h3>
    </view>
    <view class="p-4">
      <slot></slot>
      <view class="mt-5 flex justify-end">
        <button class="bg-slate-900 text-white px-5 py-2.5 rounded-xl text-sm font-medium shadow-md flex items-center space-x-2 hover:bg-slate-800 active:scale-95 transition-all" @click="handleWrite">
          <uni-icons type="paperplane" size="16" color="#fff"></uni-icons>
          <text>写入并广播</text>
        </button>
      </view>
    </view>
  </view>
</template>

<script>
export default {
  name: 'SettingCard',
  props: {
    title: {
      type: String,
      required: true
    },
    icon: {
      type: String,
      default: 'settings'
    }
  },
  methods: {
    handleWrite() {
      this.$emit('write')
    }
  }
}
</script>
```

- [ ] **Step 3: 创建 control-button.vue**

```vue
<template>
  <button
    :class="[
      'aspect-[4/3] rounded-2xl flex items-center justify-center text-[15px] transition-all duration-200 shadow-sm font-semibold border',
      isActive ? activeClass : 'bg-slate-50 text-slate-600 border-slate-200 hover:bg-slate-100 active:bg-slate-200',
      isHighlighted ? 'active:scale-95' : ''
    ]"
    @click="handleClick"
  >
    {{ text }}
  </button>
</template>

<script>
export default {
  name: 'ControlButton',
  props: {
    text: {
      type: String,
      required: true
    },
    isActive: {
      type: Boolean,
      default: false
    },
    activeClass: {
      type: String,
      default: 'bg-gradient-to-br from-emerald-400 to-emerald-500 text-white shadow-emerald-500/30 shadow-lg ring-2 ring-emerald-500/20'
    },
    isHighlighted: {
      type: Boolean,
      default: true
    }
  },
  methods: {
    handleClick() {
      this.$emit('click', this.text)
    }
  }
}
</script>
```

- [ ] **Step 4: 创建 bottom-nav.vue**

```vue
<template>
  <view class="absolute bottom-6 left-4 right-4 z-20">
    <view class="bg-white/80 backdrop-blur-xl rounded-full shadow-[0_8px_30px_rgb(0,0,0,0.08)] border border-white/50 px-2 py-2 flex justify-between items-center relative overflow-hidden">
      <view
        v-for="item in navItems"
        :key="item.key"
        :class="[
          'flex flex-col items-center justify-center w-16 py-1 rounded-2xl transition-all duration-300 relative z-10',
          activeKey === item.key ? 'text-blue-600 scale-105' : 'text-slate-400 hover:text-slate-600'
        ]"
        @click="handleNav(item.key)"
      >
        <view v-if="activeKey === item.key" class="nav-bg absolute inset-0 bg-blue-50 rounded-2xl -z-10 shadow-inner"></view>
        <uni-icons :type="item.icon" :size="20" :stroke-width="activeKey === item.key ? 2.5 : 2"></uni-icons>
        <text :class="['text-[10px] font-bold mt-1', activeKey === item.key ? 'text-blue-700' : '']">{{ item.label }}</text>
      </view>
    </view>
  </view>
</template>

<script>
export default {
  name: 'BottomNav',
  props: {
    activeKey: {
      type: String,
      default: 'settings'
    }
  },
  data() {
    return {
      navItems: [
        { key: 'info', label: '信息', icon: 'chat' },
        { key: 'settings', label: '设置', icon: 'hammer' },
        { key: 'broadcast', label: '广播', icon: 'radio' },
        { key: 'group', label: '群控', icon: 'cloud' }
      ]
    }
  },
  methods: {
    handleNav(key) {
      if (key !== this.activeKey) {
        this.$emit('change', key)
      }
    }
  }
}
</script>
```

---

## Task 4: 创建设备列表页

**Files:**
- Create: `pages/index/index.vue`

- [ ] **Step 1: 创建 index.vue**

```vue
<template>
  <view class="relative bg-slate-50" style="height: 100dvh;">
    <!-- 顶部区域 -->
    <view class="relative bg-gradient-to-br from-blue-600 to-indigo-700 text-white p-6 pt-14 pb-8 rounded-b-[2rem] shadow-lg overflow-hidden shrink-0 z-10">
      <view class="absolute top-0 right-0 -mr-16 -mt-16 w-48 h-48 bg-white/10 rounded-full blur-2xl"></view>
      <view class="absolute bottom-0 left-0 -ml-16 -mb-16 w-48 h-48 bg-blue-400/20 rounded-full blur-2xl"></view>
      <view class="relative flex flex-col space-y-6">
        <view class="flex items-center justify-between">
          <view class="flex items-center space-x-3">
            <view class="bg-white/20 p-2.5 rounded-2xl backdrop-blur-sm shadow-inner ring-1 ring-white/30">
              <uni-icons type="bluetooth" size="24" color="#fff"></uni-icons>
            </view>
            <view>
              <text class="text-2xl font-bold tracking-tight">蓝牙连接</text>
              <view class="flex items-center space-x-1.5 mt-0.5">
                <view :class="['w-2 h-2 rounded-full', isBluetoothOn ? 'bg-green-400 animate-pulse' : 'bg-slate-400']"></view>
                <text class="text-sm font-medium text-blue-100">{{ isBluetoothOn ? '系统已开启并就绪' : '系统已关闭' }}</text>
              </view>
            </view>
          </view>
          <view
            :class="['relative flex items-center w-16 h-8 rounded-full transition-all duration-300 shadow-inner', isBluetoothOn ? 'bg-blue-400/40 ring-1 ring-white/50' : 'bg-slate-800/40 ring-1 ring-white/10']"
            @click="toggleBluetooth"
          >
            <view :class="['absolute w-6 h-6 rounded-full bg-white shadow-md transition-all duration-300', isBluetoothOn ? 'translate-x-9' : 'translate-x-1']"></view>
          </view>
        </view>
      </view>
    </view>

    <!-- 设备列表 -->
    <scroll-view scroll-y class="flex-1 overflow-y-auto px-4 pt-6 pb-28 space-y-4 relative z-0">
      <view class="flex items-center justify-between px-1 mb-2">
        <text class="text-sm font-bold text-slate-500 uppercase tracking-wider">附近设备 ({{ deviceList.length }})</text>
        <uni-icons v-if="isScanning" type="reload" size="16" color="#3B82F6" class="animate-spin"></uni-icons>
      </view>

      <view v-if="deviceList.length === 0 && !isScanning" class="flex flex-col items-center justify-center py-12 text-slate-400">
        <uni-icons type="bluetooth" size="48" color="#CBD5E1"></uni-icons>
        <text class="mt-4 text-sm">暂未发现设备</text>
        <text class="text-xs mt-1">点击下方按钮扫描</text>
      </view>

      <device-card
        v-for="device in deviceList"
        :key="device.deviceId"
        :device-name="device.name || '未知设备'"
        :mac-address="device.deviceId"
        :signal-level="device.RSSI"
        :is-connected="connectedDeviceId === device.deviceId"
        @click="goToDevice(device)"
      ></device-card>
    </scroll-view>

    <!-- 底部按钮 -->
    <view class="absolute bottom-0 left-0 right-0 p-6 bg-gradient-to-t from-slate-50 via-slate-50 to-transparent pointer-events-none z-20">
      <button
        class="w-full bg-slate-900 text-white rounded-2xl py-4 flex items-center justify-center space-x-2 font-medium shadow-xl shadow-slate-900/20 active:scale-95 transition-all duration-200 pointer-events-auto hover:bg-slate-800"
        @click="scanDevices"
      >
        <uni-icons :type="isScanning ? 'reload' : 'search'" size="18" color="#fff" :class="isScanning ? 'animate-spin' : ''"></uni-icons>
        <text>{{ isScanning ? '扫描中...' : '扫描附近设备' }}</text>
      </button>
    </view>
  </view>
</template>

<script>
import deviceCard from '../../components/device-card.vue'
import * as ble from '../../utils/ble.js'

export default {
  components: { deviceCard },
  data() {
    return {
      isBluetoothOn: false,
      isScanning: false,
      deviceList: [],
      connectedDeviceId: null
    }
  },
  onLoad() {
    this.initBluetooth()
    this.setupBluetoothListeners()
  },
  onUnload() {
    ble.stopBluetoothDevicesDiscovery()
  },
  methods: {
    async initBluetooth() {
      try {
        await ble.initBluetooth()
        this.isBluetoothOn = true
        await this.scanDevices()
      } catch (err) {
        console.error('初始化蓝牙失败:', err)
        this.isBluetoothOn = false
        uni.showToast({ title: '请开启蓝牙', icon: 'none' })
      }
    },
    setupBluetoothListeners() {
      ble.onBluetoothAdapterStateChange((res) => {
        this.isBluetoothOn = res.available
        if (!res.available) {
          this.isScanning = false
          this.deviceList = []
        }
      })
      ble.onBluetoothDeviceFound((res) => {
        const devices = res.devices || []
        devices.forEach(device => {
          if (device.name && device.name !== 'unknown') {
            const index = this.deviceList.findIndex(d => d.deviceId === device.deviceId)
            if (index === -1) {
              this.deviceList.push(device)
            }
          }
        })
      })
    },
    async toggleBluetooth() {
      if (this.isBluetoothOn) {
        await ble.stopBluetoothDevicesDiscovery()
        this.isBluetoothOn = false
        this.deviceList = []
      } else {
        await this.initBluetooth()
      }
    },
    async scanDevices() {
      if (this.isScanning) return
      this.isScanning = true
      this.deviceList = []
      try {
        await ble.startBluetoothDevicesDiscovery()
        setTimeout(() => {
          this.isScanning = false
        }, 5000)
      } catch (err) {
        console.error('扫描失败:', err)
        this.isScanning = false
        uni.showToast({ title: '扫描失败', icon: 'none' })
      }
    },
    goToDevice(device) {
      uni.navigateTo({
        url: `/pages/device/index?deviceId=${device.deviceId}&deviceName=${device.name || '未知设备'}`
      })
    }
  }
}
</script>

<style scoped>
page {
  background-color: #f8fafc;
}
</style>
```

---

## Task 5: 创建设备详情页

**Files:**
- Create: `pages/device/index.vue`

- [ ] **Step 1: 创建 device/index.vue**

```vue
<template>
  <view class="relative bg-slate-50" style="height: 100dvh;">
    <!-- 顶部区域 -->
    <view class="bg-gradient-to-b from-slate-900 to-slate-800 text-white pt-12 pb-6 px-4 flex-shrink-0 shadow-lg z-10 rounded-b-3xl relative overflow-hidden">
      <view class="absolute inset-0 opacity-[0.03]" style="background-image: radial-gradient(circle at 2px 2px, white 1px, transparent 0); background-size: 16px 16px;"></view>
      <view class="relative flex items-center justify-between mb-5">
        <view class="p-2 -ml-2 rounded-full hover:bg-white/10 active:bg-white/20 transition-colors" @click="goBack">
          <uni-icons type="left" size="24" color="#fff"></uni-icons>
        </view>
        <view class="flex flex-col items-center">
          <text class="text-xs font-bold text-slate-400 uppercase tracking-widest mb-0.5">当前设备</text>
          <text class="font-bold text-lg">{{ deviceName }}</text>
        </view>
        <view class="w-10"></view>
      </view>
      <view class="flex items-center gap-3 relative">
        <view class="flex-1 bg-white/10 backdrop-blur-md rounded-2xl p-3 border border-white/10 shadow-inner">
          <view class="flex items-center justify-between mb-2">
            <view class="flex items-center space-x-1.5 text-blue-300">
              <uni-icons type="clock" size="14" color="#93C5FD"></uni-icons>
              <text class="text-xs font-medium">设备时间</text>
            </view>
            <view class="text-[10px] font-bold bg-blue-500/20 text-blue-200 px-2 py-0.5 rounded-full border border-blue-500/30">校正</view>
          </view>
          <text class="font-mono text-sm tracking-tight text-white">{{ currentTime }}</text>
        </view>
        <view class="flex flex-col gap-2">
          <view class="bg-white/5 rounded-xl px-3 py-1.5 border border-white/5 flex items-center space-x-2">
            <uni-icons type="square" size="12" color="#34D399"></uni-icons>
            <text class="text-[11px] font-medium text-slate-300">TCU: <strong class="text-white">{{ tcuVersion }}</strong></text>
          </view>
          <view class="bg-white/5 rounded-xl px-3 py-1.5 border border-white/5 flex items-center space-x-2">
            <uni-icons type="wifi" size="12" color="#A78BFA"></uni-icons>
            <text class="text-[11px] font-medium text-slate-300">NET: <strong class="text-white">{{ netStatus }}</strong></text>
          </view>
        </view>
      </view>
    </view>

    <!-- 内容区 -->
    <scroll-view scroll-y class="flex-1 overflow-y-auto px-4 pt-6 pb-28 relative z-0 bg-slate-50">
      <!-- Info Tab -->
      <view v-show="activeTab === 'info'" class="flex flex-col items-center justify-center text-slate-400 opacity-60 space-y-4" style="height: 60vh;">
        <view class="p-4 bg-slate-100 rounded-full">
          <uni-icons type="info" size="32" color="#CBD5E1"></uni-icons>
        </view>
        <text class="text-lg font-bold text-slate-600">信息内容区</text>
        <text class="text-sm font-medium">尚未提供相关设计图</text>
      </view>

      <!-- Settings Tab -->
      <view v-show="activeTab === 'settings'" class="space-y-2 pb-6">
        <view class="bg-blue-50 text-blue-700 rounded-2xl p-4 flex items-center justify-center font-medium text-sm shadow-inner border border-blue-100 mb-6">当前为 广播时间 模式</view>

        <!-- 天文参数设置 -->
        <setting-card title="天文参数设置" icon="location" @write="writeAstronomicalParams">
          <view class="flex flex-col space-y-3">
            <view class="flex flex-col sm:flex-row sm:items-center justify-between group">
              <text class="text-[13px] font-medium text-slate-500 mb-1.5 sm:mb-0">经度</text>
              <view class="relative w-full sm:w-48">
                <input type="text" v-model="astronomicalParams.longitude" class="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-sm font-semibold text-slate-800 outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all shadow-inner" />
              </view>
            </view>
            <view class="flex flex-col sm:flex-row sm:items-center justify-between group">
              <text class="text-[13px] font-medium text-slate-500 mb-1.5 sm:mb-0">纬度</text>
              <view class="relative w-full sm:w-48">
                <input type="text" v-model="astronomicalParams.latitude" class="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-sm font-semibold text-slate-800 outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all shadow-inner" />
              </view>
            </view>
            <view class="flex flex-col sm:flex-row sm:items-center justify-between group">
              <text class="text-[13px] font-medium text-slate-500 mb-1.5 sm:mb-0">时区</text>
              <view class="relative w-full sm:w-48">
                <input type="text" v-model="astronomicalParams.timezone" class="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-sm font-semibold text-slate-800 outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all shadow-inner" />
              </view>
            </view>
          </view>
        </setting-card>

        <!-- 组件参数设置 -->
        <setting-card title="组件参数设置" icon="settings" @write="writeComponentParams">
          <view class="flex flex-col space-y-3">
            <view class="flex flex-col sm:flex-row sm:items-center justify-between group">
              <text class="text-[13px] font-medium text-slate-500 mb-1.5 sm:mb-0">组件宽度</text>
              <view class="relative w-full sm:w-48">
                <input type="text" v-model="componentParams.width" class="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-sm font-semibold text-slate-800 outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all shadow-inner pr-8" />
                <text class="absolute right-4 top-1/2 -translate-y-1/2 text-xs font-bold text-slate-400">m</text>
              </view>
            </view>
            <view class="flex flex-col sm:flex-row sm:items-center justify-between group">
              <text class="text-[13px] font-medium text-slate-500 mb-1.5 sm:mb-0">组件间距</text>
              <view class="relative w-full sm:w-48">
                <input type="text" v-model="componentParams.spacing" class="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-sm font-semibold text-slate-800 outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all shadow-inner pr-8" />
                <text class="absolute right-4 top-1/2 -translate-y-1/2 text-xs font-bold text-slate-400">m</text>
              </view>
            </view>
          </view>
        </setting-card>

        <!-- 保护参数设置 -->
        <setting-card title="保护参数设置" icon="shield" @write="writeProtectionParams">
          <view class="flex flex-col space-y-3">
            <view class="flex flex-col sm:flex-row sm:items-center justify-between group">
              <text class="text-[13px] font-medium text-slate-500 mb-1.5 sm:mb-0">过流保护</text>
              <view class="relative w-full sm:w-48">
                <input type="text" v-model="protectionParams.overcurrent" class="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-sm font-semibold text-slate-800 outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all shadow-inner pr-8" />
                <text class="absolute right-4 top-1/2 -translate-y-1/2 text-xs font-bold text-slate-400">mA</text>
              </view>
            </view>
            <view class="flex flex-col sm:flex-row sm:items-center justify-between group">
              <text class="text-[13px] font-medium text-slate-500 mb-1.5 sm:mb-0">夜返保护角</text>
              <view class="relative w-full sm:w-48">
                <input type="text" v-model="protectionParams.nightReturnAngle" class="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-sm font-semibold text-slate-800 outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all shadow-inner pr-6" />
                <text class="absolute right-4 top-1/2 -translate-y-1/2 text-xs font-bold text-slate-400">°</text>
              </view>
            </view>
            <view class="flex flex-col sm:flex-row sm:items-center justify-between group">
              <text class="text-[13px] font-medium text-slate-500 mb-1.5 sm:mb-0">清洗保护角</text>
              <view class="relative w-full sm:w-48">
                <input type="text" v-model="protectionParams.cleanAngle" class="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-sm font-semibold text-slate-800 outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all shadow-inner pr-6" />
                <text class="absolute right-4 top-1/2 -translate-y-1/2 text-xs font-bold text-slate-400">°</text>
              </view>
            </view>
            <view class="flex flex-col sm:flex-row sm:items-center justify-between group">
              <text class="text-[13px] font-medium text-slate-500 mb-1.5 sm:mb-0">迎风保护角</text>
              <view class="relative w-full sm:w-48">
                <input type="text" v-model="protectionParams.windAngle" class="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-sm font-semibold text-slate-800 outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all shadow-inner pr-6" />
                <text class="absolute right-4 top-1/2 -translate-y-1/2 text-xs font-bold text-slate-400">°</text>
              </view>
            </view>
            <view class="flex flex-col sm:flex-row sm:items-center justify-between group mt-2 pt-4 border-t border-slate-100">
              <text class="text-[13px] font-medium text-slate-500 mb-1.5 sm:mb-0">TCU版本选择</text>
              <view class="relative w-full sm:w-48">
                <picker mode="selector" :range="tcuVersions" @change="onTcuVersionChange">
                  <view class="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-sm font-semibold text-slate-800 outline-none transition-all shadow-inner">
                    {{ protectionParams.tcuVersion }}
                  </view>
                </picker>
              </view>
            </view>
          </view>
        </setting-card>

        <!-- 东西限位角设置 -->
        <setting-card title="东西限位角设置" icon="location" @write="writeLimitAngles">
          <view class="flex flex-col space-y-3">
            <view class="flex flex-col sm:flex-row sm:items-center justify-between group">
              <text class="text-[13px] font-medium text-slate-500 mb-1.5 sm:mb-0">东限位角</text>
              <view class="relative w-full sm:w-48">
                <input type="text" v-model="limitAngles.east" class="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-sm font-semibold text-slate-800 outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all shadow-inner pr-6" />
                <text class="absolute right-4 top-1/2 -translate-y-1/2 text-xs font-bold text-slate-400">°</text>
              </view>
            </view>
            <view class="flex flex-col sm:flex-row sm:items-center justify-between group">
              <text class="text-[13px] font-medium text-slate-500 mb-1.5 sm:mb-0">西限位角</text>
              <view class="relative w-full sm:w-48">
                <input type="text" v-model="limitAngles.west" class="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-sm font-semibold text-slate-800 outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all shadow-inner pr-6" />
                <text class="absolute right-4 top-1/2 -translate-y-1/2 text-xs font-bold text-slate-400">°</text>
              </view>
            </view>
          </view>
        </setting-card>
      </view>

      <!-- Broadcast Tab -->
      <view v-show="activeTab === 'broadcast'" class="flex flex-col items-center justify-center text-slate-400 opacity-60 space-y-4" style="height: 60vh;">
        <view class="p-4 bg-slate-100 rounded-full">
          <uni-icons type="radio" size="32" color="#CBD5E1"></uni-icons>
        </view>
        <text class="text-lg font-bold text-slate-600">广播功能区</text>
        <text class="text-sm font-medium">尚未提供相关设计图</text>
      </view>

      <!-- Group Tab -->
      <view v-show="activeTab === 'group'" class="pb-6">
        <view class="bg-white rounded-[2rem] p-6 shadow-sm border border-slate-100">
          <view class="flex items-center space-x-2 mb-6 justify-center">
            <uni-icons type="settings" size="20" color="#94A3B8"></uni-icons>
            <text class="text-center text-slate-800 text-[17px] font-bold tracking-wide">整体控制面板</text>
          </view>
          <view class="grid grid-cols-3 gap-3">
            <control-button text="自动" @click="handleControl('auto')"></control-button>
            <control-button text="放平" @click="handleControl('flat')"></control-button>
            <control-button text="停止" :is-active="true" active-class="bg-gradient-to-br from-emerald-400 to-emerald-500 text-white shadow-emerald-500/30 shadow-lg ring-2 ring-emerald-500/20" @click="handleControl('stop')"></control-button>
            <control-button text="向西" @click="handleControl('west')"></control-button>
            <control-button text="清洗" @click="handleControl('clean')"></control-button>
            <control-button text="向东" @click="handleControl('east')"></control-button>
            <control-button text="大雪" @click="handleControl('snow')"></control-button>
            <control-button text="大雨" @click="handleControl('rain')"></control-button>
            <control-button text="洪水" @click="handleControl('flood')"></control-button>
            <control-button text="大风" @click="handleControl('wind')"></control-button>
            <view class="aspect-[4/3]"></view>
            <control-button text="低功耗" @click="handleControl('lowpower')"></control-button>
          </view>
        </view>
        <view class="flex-1 min-h-[3rem]"></view>
      </view>
    </scroll-view>

    <!-- 底部导航 -->
    <bottom-nav :active-key="activeTab" @change="switchTab"></bottom-nav>
  </view>
</template>

<script>
import bottomNav from '../../components/bottom-nav.vue'
import settingCard from '../../components/setting-card.vue'
import controlButton from '../../components/control-button.vue'

export default {
  components: { bottomNav, settingCard, controlButton },
  data() {
    return {
      deviceId: '',
      deviceName: '',
      activeTab: 'settings',
      currentTime: '',
      tcuVersion: '12',
      netStatus: '2',
      tcuVersions: ['7.1.08', '7.1.09', '8.0.01'],
      astronomicalParams: {
        longitude: '112.83',
        latitude: '23.11',
        timezone: '8'
      },
      componentParams: {
        width: '2.3',
        spacing: '5.5'
      },
      protectionParams: {
        overcurrent: '6500',
        nightReturnAngle: '0',
        cleanAngle: '30',
        windAngle: '0',
        tcuVersion: '7.1.08'
      },
      limitAngles: {
        east: '-45',
        west: '45'
      }
    }
  },
  onLoad(options) {
    this.deviceId = options.deviceId || ''
    this.deviceName = options.deviceName || '未知设备'
    this.updateTime()
    setInterval(this.updateTime, 1000)
  },
  methods: {
    goBack() {
      uni.navigateBack()
    },
    switchTab(tab) {
      this.activeTab = tab
    },
    updateTime() {
      const d = new Date()
      const pad = n => String(n).padStart(2, '0')
      this.currentTime = `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`
    },
    onTcuVersionChange(e) {
      this.protectionParams.tcuVersion = this.tcuVersions[e.detail.value]
    },
    writeAstronomicalParams() {
      uni.showToast({ title: '天文参数已写入', icon: 'success' })
    },
    writeComponentParams() {
      uni.showToast({ title: '组件参数已写入', icon: 'success' })
    },
    writeProtectionParams() {
      uni.showToast({ title: '保护参数已写入', icon: 'success' })
    },
    writeLimitAngles() {
      uni.showToast({ title: '限位角已写入', icon: 'success' })
    },
    handleControl(action) {
      uni.showToast({ title: `执行: ${action}`, icon: 'none' })
    }
  }
}
</script>

<style scoped>
page {
  background-color: #f8fafc;
}
</style>
```

---

## Task 6: 验证与打包

**Files:**
- Modify: `manifest.json`（确认 Android 配置正确）

- [ ] **Step 1: 在 HBuilderX 中打开项目并检查**

打开 HBuilderX → 文件 → 导入 → 选择 youjuAPP 文件夹

- [ ] **Step 2: 运行到 Android 模拟器测试**

- [ ] **Step 3: 打包 APK**

在 HBuilderX 中 → 选择 "运行" → "运行到手机或模拟器" → "制作 APK 包"

---

## Spec Coverage Checklist

- [x] 设备列表页（扫描、显示设备）
- [x] 设备详情页（Tab 导航）
- [x] 设置 Tab（4 个参数卡片）
- [x] 群控 Tab（12 按钮面板）
- [x] 信息 Tab（占位）
- [x] 广播 Tab（占位）
- [x] 蓝牙工具封装（ble.js）
- [x] 本地存储封装（storage.js）
- [x] 视觉风格保持一致（蓝白配色、圆角卡片）
