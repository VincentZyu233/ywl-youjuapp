// BLE 服务与特征值 UUID（需根据实际设备调整）
const BLE_SERVICE_UUID = '0000FFE0-0000-1000-8000-00805F9B34FB'
const BLE_CHAR_WRITE_UUID = '0000FFE1-0000-1000-8000-00805F9B34FB'
const BLE_CHAR_NOTIFY_UUID = '0000FFE2-0000-1000-8000-00805F9B34FB'

// 蓝牙状态
let isBluetoothAvailable = false
let isDiscovering = false
let connectedDeviceId = null

// ============ 原生蓝牙（App内弹系统对话框）============

let _BluetoothAdapter = null
let _mainActivity = null

function getMainActivity() {
  if (!_mainActivity) {
    _mainActivity = plus.android.runtimeMainActivity()
  }
  return _mainActivity
}

function getBluetoothAdapter() {
  if (!_BluetoothAdapter) {
    _BluetoothAdapter = plus.android.importClass('android.bluetooth.BluetoothAdapter')
  }
  return _BluetoothAdapter
}

// 获取原生蓝牙状态: 0=关闭, 1=开启, -1=不支持
export function getNativeBluetoothState() {
  try {
    const adapter = getBluetoothAdapter()
    if (!adapter) return -1
    return adapter.getDefaultAdapter().isEnabled() ? 1 : 0
  } catch (e) {
    return -1
  }
}

// 打开蓝牙（App内弹系统对话框）
// 使用 startActivityForResult 让对话框在 App 内弹出
export function openNativeBluetooth() {
  try {
    const adapter = getBluetoothAdapter().getDefaultAdapter()
    if (!adapter) {
      console.error('设备不支持蓝牙')
      return
    }
    if (adapter.isEnabled()) {
      console.log('蓝牙已开启')
      return
    }
    const Intent = plus.android.importClass('android.content.Intent')
    const enableBtIntent = new Intent(adapter.ACTION_REQUEST_ENABLE)
    const activity = getMainActivity()
    // startActivityForResult 在 Activity 上调用
    activity.startActivityForResult(enableBtIntent, 10001)
  } catch (e) {
    console.error('openNativeBluetooth error:', e)
  }
}

// 关闭蓝牙
export function closeNativeBluetooth() {
  try {
    const adapter = getBluetoothAdapter().getDefaultAdapter()
    if (!adapter) return
    if (!adapter.isEnabled()) return
    adapter.disable()
  } catch (e) {
    console.error('closeNativeBluetooth error:', e)
  }
}

// ============ UniApp 蓝牙适配器 ============

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

// 关闭蓝牙适配器
export function closeBluetoothAdapter() {
  return new Promise((resolve, reject) => {
    uni.closeBluetoothAdapter({
      success: (res) => {
        isBluetoothAvailable = false
        isDiscovering = false
        resolve(res)
      },
      fail: reject
    })
  })
}

export {
  isBluetoothAvailable,
  isDiscovering,
  connectedDeviceId,
  BLE_SERVICE_UUID,
  BLE_CHAR_WRITE_UUID,
  BLE_CHAR_NOTIFY_UUID
}
