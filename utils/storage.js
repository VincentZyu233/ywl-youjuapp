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
