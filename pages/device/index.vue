<template>
	<view
		:style="{ height: '100vh', backgroundColor: '#f8fafc', position: 'relative', display: 'flex', flexDirection: 'column' }">
		<!-- 顶部区域 -->
		<view
			:style="{ background: 'linear-gradient(to bottom, #0f172a, #1e293b)', paddingTop: '120rpx', paddingBottom: '48rpx', paddingLeft: '32rpx', paddingRight: '32rpx', flexShrink: 0, shadow: '0 4px 6px rgba(0,0,0,0.1)', zIndex: 10, borderRadius: '0 0 48rpx 48rpx', position: 'relative', overflow: 'hidden' }">
			<view
				:style="{ position: 'absolute', inset: 0, opacity: 0.03, backgroundImage: 'radial-gradient(circle at 2px 2px, #fff 1px, transparent 0)', backgroundSize: '32rpx 32rpx' }">
			</view>
			<view
				:style="{ position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '40rpx' }">
				<view :style="{ padding: '16rpx', marginLeft: '-16rpx', borderRadius: '50%' }" @click="goBack">
					<text :style="{ color: '#fff', fontSize: '48rpx' }">←</text>
				</view>
				<view :style="{ display: 'flex', flexDirection: 'column', alignItems: 'center' }">
					<text
						:style="{ fontSize: '24rpx', fontWeight: 'bold', color: '#94a3b8', textTransform: 'uppercase', letterSpacing: '4rpx', marginBottom: '4rpx' }">当前设备</text>
					<text :style="{ fontWeight: 'bold', fontSize: '36rpx', color: '#fff' }">{{ deviceName }}</text>
				</view>
				<view :style="{ width: '80rpx' }"></view>
			</view>
			<view :style="{ display: 'flex', alignItems: 'center', columnGap: '24rpx' }">
				<view
					:style="{ flex: 1, backgroundColor: 'rgba(255,255,255,0.1)', backdropFilter: 'blur(12px)', borderRadius: '32rpx', padding: '24rpx', border: '1px solid rgba(255,255,255,0.1)' }">
					<view
						:style="{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '16rpx' }">
						<view :style="{ display: 'flex', alignItems: 'center', columnGap: '12rpx', color: '#93C5FD' }">
							<text :style="{ fontSize: '28rpx' }">⏰</text>
							<text :style="{ fontSize: '24rpx', color: '#93C5FD' }">设备时间</text>
						</view>
						<view
							:style="{ fontSize: '20rpx', fontWeight: 'bold', backgroundColor: 'rgba(59,130,246,0.2)', color: '#bfdbfe', padding: '4rpx 16rpx', borderRadius: '16rpx', border: '1px solid rgba(59,130,246,0.3)' }">
							校正</view>
					</view>
					<text
						:style="{ fontFamily: 'monospace', fontSize: '28rpx', color: '#fff' }">{{ currentTime }}</text>
				</view>
				<view :style="{ display: 'flex', flexDirection: 'column', rowGap: '16rpx' }">
					<view
						:style="{ backgroundColor: 'rgba(255,255,255,0.05)', borderRadius: '20rpx', padding: '12rpx 24rpx', border: '1px solid rgba(255,255,255,0.05)', display: 'flex', alignItems: 'center', columnGap: '16rpx' }">
						<text :style="{ fontSize: '24rpx' }">▪</text>
						<text :style="{ fontSize: '22rpx', color: '#cbd5e1' }">TCU: <strong
								:style="{ color: '#fff' }">{{ tcuVersion }}</strong></text>
					</view>
					<view
						:style="{ backgroundColor: 'rgba(255,255,255,0.05)', borderRadius: '20rpx', padding: '12rpx 24rpx', border: '1px solid rgba(255,255,255,0.05)', display: 'flex', alignItems: 'center', columnGap: '16rpx' }">
						<text :style="{ fontSize: '24rpx' }">◈</text>
						<text :style="{ fontSize: '22rpx', color: '#cbd5e1' }">NET: <strong
								:style="{ color: '#fff' }">{{ netStatus }}</strong></text>
					</view>
				</view>
			</view>
		</view>

		<!-- 内容区 -->
		<scroll-view scroll-y
			:style="{ flex: 1, paddingLeft: '32rpx', paddingRight: '32rpx', paddingTop: '48rpx', paddingBottom: '448rpx', position: 'relative', zIndex: 0, backgroundColor: '#f8fafc',boxSizing: 'border-box' }">
			<!-- Info Tab -->
			<view v-show="activeTab === 'info'"
				:style="{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '800rpx', color: '#94a3b8', opacity: 0.6 }">
				<view :style="{ padding: '32rpx', backgroundColor: '#f1f5f9', borderRadius: '50%' }">
					<text :style="{ fontSize: '64rpx', color: '#CBD5E1' }">ⓘ</text>
				</view>
				<text
					:style="{ fontSize: '36rpx', fontWeight: 'bold', color: '#475569', marginTop: '32rpx' }">信息内容区</text>
				<text :style="{ fontSize: '28rpx', color: '#64748b', marginTop: '16rpx' }">尚未提供相关设计图</text>
			</view>

			<!-- Settings Tab -->
			<view v-show="activeTab === 'settings'" :style="{ paddingBottom: '48rpx' }">
				<view
					:style="{ backgroundColor: '#dbeafe', color: '#2563eb', borderRadius: '32rpx', padding: '32rpx', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '28rpx', marginBottom: '48rpx', border: '1px solid #bfdbfe' }">
					当前为 广播时间 模式</view>

				<!-- 天文参数设置 -->
				<setting-card title="天文参数设置" icon="location" @write="writeAstronomicalParams">
					<view :style="{ display: 'flex', flexDirection: 'column', rowGap: '24rpx' }">
						<view :style="{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }">
							<text :style="{ fontSize: '26rpx', color: '#64748b' }">经度</text>
							<input type="text" v-model="astronomicalParams.longitude"
								:style="{ width: '384rpx', backgroundColor: '#f8fafc', border: '1px solid #e2e8f0', borderRadius: '24rpx', padding: '20rpx', fontSize: '28rpx', fontWeight: '600', color: '#1e293b' }" />
						</view>
						<view :style="{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }">
							<text :style="{ fontSize: '26rpx', color: '#64748b' }">纬度</text>
							<input type="text" v-model="astronomicalParams.latitude"
								:style="{ width: '384rpx', backgroundColor: '#f8fafc', border: '1px solid #e2e8f0', borderRadius: '24rpx', padding: '20rpx', fontSize: '28rpx', fontWeight: '600', color: '#1e293b' }" />
						</view>
						<view :style="{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }">
							<text :style="{ fontSize: '26rpx', color: '#64748b' }">时区</text>
							<input type="text" v-model="astronomicalParams.timezone"
								:style="{ width: '384rpx', backgroundColor: '#f8fafc', border: '1px solid #e2e8f0', borderRadius: '24rpx', padding: '20rpx', fontSize: '28rpx', fontWeight: '600', color: '#1e293b' }" />
						</view>
					</view>
				</setting-card>

				<!-- 组件参数设置 -->
				<setting-card title="组件参数设置" icon="settings" @write="writeComponentParams">
					<view :style="{ display: 'flex', flexDirection: 'column', rowGap: '24rpx' }">
						<view :style="{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }">
							<text :style="{ fontSize: '26rpx', color: '#64748b' }">组件宽度</text>
							<view :style="{ position: 'relative', width: '384rpx' }">
								<input type="text" v-model="componentParams.width"
									:style="{ width: '100%', backgroundColor: '#f8fafc', border: '1px solid #e2e8f0', borderRadius: '24rpx', padding: '20rpx', paddingRight: '64rpx', fontSize: '28rpx', fontWeight: '600', color: '#1e293b' }" />
								<text
									:style="{ position: 'absolute', right: '32rpx', top: '50%', transform: 'translateY(-50%)', fontSize: '24rpx', color: '#94a3b8' }">m</text>
							</view>
						</view>
						<view :style="{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }">
							<text :style="{ fontSize: '26rpx', color: '#64748b' }">组件间距</text>
							<view :style="{ position: 'relative', width: '384rpx' }">
								<input type="text" v-model="componentParams.spacing"
									:style="{ width: '100%', backgroundColor: '#f8fafc', border: '1px solid #e2e8f0', borderRadius: '24rpx', padding: '20rpx', paddingRight: '64rpx', fontSize: '28rpx', fontWeight: '600', color: '#1e293b' }" />
								<text
									:style="{ position: 'absolute', right: '32rpx', top: '50%', transform: 'translateY(-50%)', fontSize: '24rpx', color: '#94a3b8' }">m</text>
							</view>
						</view>
					</view>
				</setting-card>

				<!-- 保护参数设置 -->
				<setting-card title="保护参数设置" icon="shield" @write="writeProtectionParams">
					<view :style="{ display: 'flex', flexDirection: 'column', rowGap: '24rpx' }">
						<view :style="{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }">
							<text :style="{ fontSize: '26rpx', color: '#64748b' }">过流保护</text>
							<view :style="{ position: 'relative', width: '384rpx' }">
								<input type="text" v-model="protectionParams.overcurrent"
									:style="{ width: '100%', backgroundColor: '#f8fafc', border: '1px solid #e2e8f0', borderRadius: '24rpx', padding: '20rpx', paddingRight: '64rpx', fontSize: '28rpx', fontWeight: '600', color: '#1e293b' }" />
								<text
									:style="{ position: 'absolute', right: '32rpx', top: '50%', transform: 'translateY(-50%)', fontSize: '24rpx', color: '#94a3b8' }">mA</text>
							</view>
						</view>
						<view :style="{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }">
							<text :style="{ fontSize: '26rpx', color: '#64748b' }">夜返保护角</text>
							<view :style="{ position: 'relative', width: '384rpx' }">
								<input type="text" v-model="protectionParams.nightReturnAngle"
									:style="{ width: '100%', backgroundColor: '#f8fafc', border: '1px solid #e2e8f0', borderRadius: '24rpx', padding: '20rpx', paddingRight: '64rpx', fontSize: '28rpx', fontWeight: '600', color: '#1e293b' }" />
								<text
									:style="{ position: 'absolute', right: '32rpx', top: '50%', transform: 'translateY(-50%)', fontSize: '24rpx', color: '#94a3b8' }">°</text>
							</view>
						</view>
						<view :style="{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }">
							<text :style="{ fontSize: '26rpx', color: '#64748b' }">清洗保护角</text>
							<view :style="{ position: 'relative', width: '384rpx' }">
								<input type="text" v-model="protectionParams.cleanAngle"
									:style="{ width: '100%', backgroundColor: '#f8fafc', border: '1px solid #e2e8f0', borderRadius: '24rpx', padding: '20rpx', paddingRight: '64rpx', fontSize: '28rpx', fontWeight: '600', color: '#1e293b' }" />
								<text
									:style="{ position: 'absolute', right: '32rpx', top: '50%', transform: 'translateY(-50%)', fontSize: '24rpx', color: '#94a3b8' }">°</text>
							</view>
						</view>
						<view :style="{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }">
							<text :style="{ fontSize: '26rpx', color: '#64748b' }">迎风保护角</text>
							<view :style="{ position: 'relative', width: '384rpx' }">
								<input type="text" v-model="protectionParams.windAngle"
									:style="{ width: '100%', backgroundColor: '#f8fafc', border: '1px solid #e2e8f0', borderRadius: '24rpx', padding: '20rpx', paddingRight: '64rpx', fontSize: '28rpx', fontWeight: '600', color: '#1e293b' }" />
								<text
									:style="{ position: 'absolute', right: '32rpx', top: '50%', transform: 'translateY(-50%)', fontSize: '24rpx', color: '#94a3b8' }">°</text>
							</view>
						</view>
						<view
							:style="{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', paddingTop: '32rpx', borderTop: '1px solid #f1f5f9' }">
							<text :style="{ fontSize: '26rpx', color: '#64748b' }">TCU版本选择</text>
							<picker mode="selector" :range="tcuVersions" @change="onTcuVersionChange">
								<view
									:style="{ width: '384rpx', backgroundColor: '#f8fafc', border: '1px solid #e2e8f0', borderRadius: '24rpx', padding: '20rpx', fontSize: '28rpx', fontWeight: '600', color: '#1e293b' }">
									{{ protectionParams.tcuVersion }}
								</view>
							</picker>
						</view>
					</view>
				</setting-card>

				<!-- 东西限位角设置 -->
				<setting-card title="东西限位角设置" icon="location" @write="writeLimitAngles">
					<view :style="{ display: 'flex', flexDirection: 'column', rowGap: '24rpx' }">
						<view :style="{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }">
							<text :style="{ fontSize: '26rpx', color: '#64748b' }">东限位角</text>
							<view :style="{ position: 'relative', width: '384rpx' }">
								<input type="text" v-model="limitAngles.east"
									:style="{ width: '100%', backgroundColor: '#f8fafc', border: '1px solid #e2e8f0', borderRadius: '24rpx', padding: '20rpx', paddingRight: '64rpx', fontSize: '28rpx', fontWeight: '600', color: '#1e293b' }" />
								<text
									:style="{ position: 'absolute', right: '32rpx', top: '50%', transform: 'translateY(-50%)', fontSize: '24rpx', color: '#94a3b8' }">°</text>
							</view>
						</view>
						<view :style="{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }">
							<text :style="{ fontSize: '26rpx', color: '#64748b' }">西限位角</text>
							<view :style="{ position: 'relative', width: '384rpx' }">
								<input type="text" v-model="limitAngles.west"
									:style="{ width: '100%', backgroundColor: '#f8fafc', border: '1px solid #e2e8f0', borderRadius: '24rpx', padding: '20rpx', paddingRight: '64rpx', fontSize: '28rpx', fontWeight: '600', color: '#1e293b' }" />
								<text
									:style="{ position: 'absolute', right: '32rpx', top: '50%', transform: 'translateY(-50%)', fontSize: '24rpx', color: '#94a3b8' }">°</text>
							</view>
						</view>
					</view>
				</setting-card>
			</view>

			<!-- Broadcast Tab -->
			<view v-show="activeTab === 'broadcast'"
				:style="{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '800rpx', color: '#94a3b8', opacity: 0.6 }">
				<view :style="{ padding: '32rpx', backgroundColor: '#f1f5f9', borderRadius: '50%' }">
					<text :style="{ fontSize: '64rpx', color: '#CBD5E1' }">📢</text>
				</view>
				<text
					:style="{ fontSize: '36rpx', fontWeight: 'bold', color: '#475569', marginTop: '32rpx' }">广播功能区</text>
				<text :style="{ fontSize: '28rpx', color: '#64748b', marginTop: '16rpx' }">尚未提供相关设计图</text>
			</view>

			<!-- Group Tab -->
			<view v-show="activeTab === 'group'" :style="{ paddingBottom: '48rpx' }">
				<view
					:style="{ backgroundColor: '#fff', borderRadius: '64rpx', padding: '48rpx', boxShadow: '0 1px 3px rgba(0,0,0,0.1)', border: '1px solid #f1f5f9' }">
					<view
						:style="{ display: 'flex', alignItems: 'center', justifyContent: 'center', columnGap: '16rpx', marginBottom: '48rpx' }">
						<text :style="{ fontSize: '40rpx', color: '#94a3b8' }">⚙</text>
						<text :style="{ fontSize: '34rpx', fontWeight: 'bold', color: '#1e293b' }">整体控制面板</text>
					</view>
					<view :style="{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '24rpx' }">
						<control-button text="自动" @click="handleControl('auto')"></control-button>
						<control-button text="放平" @click="handleControl('flat')"></control-button>
						<control-button text="停止" :is-active="true"
							:active-style="{ backgroundColor: '#10b981', color: '#fff', border: 'none' }"
							@click="handleControl('stop')"></control-button>
						<control-button text="向西" @click="handleControl('west')"></control-button>
						<control-button text="清洗" @click="handleControl('clean')"></control-button>
						<control-button text="向东" @click="handleControl('east')"></control-button>
						<control-button text="大雪" @click="handleControl('snow')"></control-button>
						<control-button text="大雨" @click="handleControl('rain')"></control-button>
						<control-button text="洪水" @click="handleControl('flood')"></control-button>
						<control-button text="大风" @click="handleControl('wind')"></control-button>
						<view :style="{ aspectRatio: '4/3' }"></view>
						<control-button text="低功耗" @click="handleControl('lowpower')"></control-button>
					</view>
				</view>
				<view :style="{ height: '48rpx' }"></view>
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
		components: {
			bottomNav,
			settingCard,
			controlButton
		},
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
				this.currentTime =
					`${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`
			},
			onTcuVersionChange(e) {
				this.protectionParams.tcuVersion = this.tcuVersions[e.detail.value]
			},
			writeAstronomicalParams() {
				uni.showToast({
					title: '天文参数已写入',
					icon: 'success'
				})
			},
			writeComponentParams() {
				uni.showToast({
					title: '组件参数已写入',
					icon: 'success'
				})
			},
			writeProtectionParams() {
				uni.showToast({
					title: '保护参数已写入',
					icon: 'success'
				})
			},
			writeLimitAngles() {
				uni.showToast({
					title: '限位角已写入',
					icon: 'success'
				})
			},
			handleControl(action) {
				uni.showToast({
					title: `执行: ${action}`,
					icon: 'none'
				})
			}
		}
	}
</script>