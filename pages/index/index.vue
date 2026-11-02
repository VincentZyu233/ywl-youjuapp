<template>
	<view
		:style="{ height: '100vh', backgroundColor: '#f8fafc', position: 'relative', display: 'flex', flexDirection: 'column' }">
		<!-- 顶部区域 -->
		<view
			:style="{ position: 'relative', background: 'linear-gradient(to bottom right, #2563eb, #4f46e5)', padding: '24rpx', paddingTop: '140rpx', paddingBottom: '64rpx', borderRadius: '0 0 80rpx 80rpx', overflow: 'hidden', zIndex: 10, flexShrink: 0 }">
			<view
				:style="{ position: 'absolute', top: 0, right: 0, width: '384rpx', height: '384rpx', backgroundColor: 'rgba(255,255,255,0.1)', borderRadius: '50%', filter: 'blur(64rpx)', marginRight: '-256rpx', marginTop: '-256rpx' }">
			</view>
			<view
				:style="{ position: 'absolute', bottom: 0, left: 0, width: '384rpx', height: '384rpx', backgroundColor: 'rgba(96,165,250,0.2)', borderRadius: '50%', filter: 'blur(64rpx)', marginLeft: '-256rpx', marginBottom: '-256rpx' }">
			</view>
			<view :style="{ position: 'relative', display: 'flex', flexDirection: 'column', rowGap: '48rpx' }">
				<view :style="{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }">
					<view :style="{ display: 'flex', alignItems: 'center', columnGap: '24rpx' }">
						<view
							:style="{ backgroundColor: 'rgba(255,255,255,0.2)', padding: '20rpx', borderRadius: '40rpx', backdropFilter: 'blur(8px)' }">
							<image src="/static/svg/bl.svg" mode="aspectFit"
								:style="{ width: '48rpx', height: '48rpx', filter: 'brightness(0) invert(1)' }"></image>
						</view>
						<view>
							<text
								:style="{ fontSize: '48rpx', fontWeight: 'bold', letterSpacing: '-0.5px', color: '#fff' }">蓝牙连接</text>
							<view
								:style="{ display: 'flex', alignItems: 'center', columnGap: '12rpx', marginTop: '8rpx' }">
								<view
									:style="{ width: '16rpx', height: '16rpx', borderRadius: '50%', backgroundColor: isBluetoothOn ? '#4ade80' : '#94a3b8', animation: isBluetoothOn ? 'pulse 2s infinite' : 'none' }">
								</view>
								<text
									:style="{ fontSize: '28rpx', color: '#dbeafe' }">{{ isBluetoothOn ? '系统已开启并就绪' : '系统已关闭' }}</text>
							</view>
						</view>
					</view>
					<view class="toggle-btn" :class="isBluetoothOn ? 'toggle-on' : 'toggle-off'"
						@click="toggleBluetooth">
						<view class="toggle-knob" :class="isBluetoothOn ? 'knob-on' : 'knob-off'"></view>
					</view>
				</view>
			</view>
		</view>

		<!-- 设备列表 -->
		<scroll-view scroll-y
			:style="{ flex: 1, padding: '0 32rpx', paddingTop: '48rpx', paddingBottom: '448rpx', position: 'relative', zIndex: 0, boxSizing: 'border-box' }">
			<view
				:style="{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '16rpx', padding: '0 8rpx' }">
				<text
					:style="{ fontSize: '28rpx', fontWeight: 'bold', color: '#64748b', textTransform: 'uppercase', letterSpacing: '2rpx' }">附近设备
					({{ deviceList.length }})</text>
				<text v-if="isScanning" :style="{ color: '#3B82F6', animation: 'spin 1s linear infinite' }">⟳</text>
			</view>

			<view v-if="deviceList.length === 0 && !isScanning"
				:style="{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', paddingTop: '192rpx', color: '#94a3b8' }">
				<image src="/static/svg/bl.svg" mode="aspectFit"
					:style="{ width: '96rpx', height: '96rpx', opacity: 0.5 }"></image>
				<text :style="{ marginTop: '32rpx', fontSize: '28rpx', color: '#64748b' }">暂未发现设备</text>
				<text :style="{ marginTop: '8rpx', fontSize: '24rpx' }">点击下方按钮扫描</text>
			</view>

			<view v-for="device in deviceList" :key="device.deviceId" :style="{ marginBottom: '32rpx' }">
				<device-card :device-name="device.name || '未知设备'" :mac-address="device.deviceId"
					:signal-level="device.RSSI" :is-connected="connectedDeviceId === device.deviceId"
					@click="goToDevice(device)"></device-card>
			</view>
		</scroll-view>

		<!-- 底部按钮 -->
		<view
			:style="{ position: 'absolute', bottom: 0, left: 0, right: 0, padding: '48rpx', background: 'linear-gradient(to top, #f8fafc, #f8fafc 60%, transparent)', zIndex: 20, pointerEvents: 'none' }">
			<button
				:style="{ width: '100%', backgroundColor: '#0f172a', color: '#fff', borderRadius: '40rpx', padding: '32rpx', display: 'flex', alignItems: 'center', justifyContent: 'center', columnGap: '16rpx', fontSize: '32rpx', fontWeight: '500', boxShadow: '0 20px 40px rgba(15,23,42,0.2)', pointerEvents: 'auto' }"
				@click="scanDevices">
				<text
					:style="{ fontSize: '36rpx', animation: isScanning ? 'spin 1s linear infinite' : '' }">{{ isScanning ? '⟳' : '⌕' }}</text>
				<text>{{ isScanning ? '扫描中...' : '扫描附近设备' }}</text>
			</button>
		</view>
	</view>
</template>

<script>
	import deviceCard from '../../components/device-card.vue'
	import * as ble from '../../utils/ble.js'

	export default {
		components: {
			deviceCard
		},
		data() {
			return {
				isBluetoothOn: false,
				isBluetoothAvailable: false,
				isScanning: false,
				deviceList: [],
				connectedDeviceId: null,
			}
		},
		onLoad() {
			this.initBluetooth()
			this.setupBluetoothListeners()
		},
		onShow() {
			// 从系统对话框返回后，重新检查蓝牙状态
			setTimeout(() => {
				this.checkBluetoothAfterReturn()
			}, 1000)
		},
		onUnload() {
			ble.stopBluetoothDevicesDiscovery()
		},
		methods: {
			async checkBluetoothAfterReturn() {
				// 从系统对话框返回后，等待蓝牙系统稳定后重新初始化
				const nativeState = ble.getNativeBluetoothState()
				console.log('onShow 蓝牙状态检查:', nativeState)
				if (nativeState === 1) {
					// 原生蓝牙已开启，尝试初始化 UniApp 适配器
					try {
						await ble.initBluetooth()
						const state = await ble.getBluetoothAdapterState()
						this.isBluetoothAvailable = state.available
						this.isBluetoothOn = state.available
						if (state.available && this.deviceList.length === 0) {
							await this.scanDevices()
						}
					} catch (e) {
						console.log('onShow 重新初始化失败:', e)
					}
				}
			},
			async initBluetooth() {
				try {
					// 关闭 UniApp 适配器，确保每次重新初始化
					try {
						await ble.closeBluetoothAdapter()
					} catch (e) {
						// 忽略关闭失败
					}
					// 每次都尝试打开原生蓝牙（系统对话框内部会判断是否需要弹）
					await ble.openNativeBluetooth()
					// 不在这里等待，改为 onShow 时检查
				} catch (err) {
					console.error('打开原生蓝牙失败:', err)
				}
			},
			setupBluetoothListeners() {
				ble.onBluetoothAdapterStateChange((res) => {
					this.isBluetoothAvailable = res.available
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
					try {
						await ble.stopBluetoothDevicesDiscovery()
						await ble.closeBluetoothAdapter()
					} catch (e) {
						console.log('关闭 UniApp 适配器失败:', e)
					}
					try {
						await ble.closeNativeBluetooth()
					} catch (e) {
						console.log('关闭原生蓝牙失败（可能无权限）:', e)
					}
					const nativeStateAfterClose = ble.getNativeBluetoothState()
					console.log('关闭后原生蓝牙状态:', nativeStateAfterClose, '(0=关,1=开,-1=不支持)')
					this.isBluetoothOn = false
					this.isBluetoothAvailable = false
					this.isScanning = false
					this.deviceList = []
				} else {
					const nativeStateBeforeOpen = ble.getNativeBluetoothState()
					console.log('打开前原生蓝牙状态:', nativeStateBeforeOpen, '(0=关,1=开,-1=不支持)')
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
					uni.showToast({
						title: '扫描失败',
						icon: 'none'
					})
				}
			},
			goToDevice(device) {
				uni.navigateTo({
					url: `/pages/device/index?deviceId=${device.deviceId}&deviceName=${device.name || '未知设备'}`
				})
			},
		}
	}
</script>

<style>
	@keyframes spin {
		from {
			transform: rotate(0deg);
		}

		to {
			transform: rotate(360deg);
		}
	}

	@keyframes pulse {

		0%,
		100% {
			opacity: 1;
		}

		50% {
			opacity: 0.5;
		}
	}

	.toggle-btn {
		position: relative;
		width: 128rpx;
		height: 64rpx;
		border-radius: 64rpx;
		transition: all 0.3s;
	}

	.toggle-off {
		background-color: rgba(30, 41, 59, 0.4);
		box-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.1);
	}

	.toggle-on {
		background-color: rgba(96, 165, 250, 0.4);
		box-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.1);
	}

	.toggle-knob {
		position: absolute;
		top: 8rpx;
		width: 48rpx;
		height: 48rpx;
		border-radius: 50%;
		background-color: #fff;
		box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
		transition: all 0.3s;
	}

	.knob-off {
		left: 8rpx;
	}

	.knob-on {
		left: 72rpx;
	}
</style>