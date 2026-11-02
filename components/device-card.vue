<template>
  <view :style="{ backgroundColor: '#fff', borderRadius: '32rpx', padding: '32rpx', boxShadow: '0 1px 3px rgba(0,0,0,0.1)', border: '1px solid #f1f5f9' }" @click="handleClick">
    <view :style="{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }">
      <view :style="{ display: 'flex', alignItems: 'flex-start', flex: 1, overflow: 'hidden', columnGap: '24rpx' }">
        <view :style="{ padding: '16rpx', borderRadius: '24rpx', marginTop: '4rpx', backgroundColor: isConnected ? '#f0fdf4' : '#f8fafc' }">
          <image src="/static/svg/bl.svg" mode="aspectFit" :style="{ width: '40rpx', height: '40rpx', filter: isConnected ? 'sepia(100%) saturate(1000%) hue-rotate(90deg)' : 'grayscale(100%)' }"></image>
        </view>
        <view :style="{ flex: 1, minWidth: 0 }">
          <view :style="{ display: 'flex', alignItems: 'center', columnGap: '16rpx' }">
            <text :style="{ fontSize: '32rpx', fontWeight: 'bold', color: '#1e293b', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }">{{ deviceName }}</text>
            <view v-if="isConnected" :style="{ padding: '4rpx 16rpx', backgroundColor: '#dcfce7', color: '#16a34a', fontSize: '20rpx', fontWeight: 'bold', borderRadius: '20rpx', textTransform: 'uppercase', letterSpacing: '1rpx' }">已连接</view>
          </view>
          <text :style="{ fontSize: '26rpx', fontFamily: 'monospace', color: '#64748b', marginTop: '8rpx', display: 'flex', alignItems: 'center', columnGap: '12rpx' }">{{ macAddress }}</text>
        </view>
      </view>
      <view :style="{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', justifyContent: 'space-between', height: '100%', paddingLeft: '24rpx', rowGap: '24rpx' }">
        <view :style="{ display: 'flex', alignItems: 'center', columnGap: '8rpx', color: '#94a3b8' }">
          <text :style="{ fontSize: '24rpx', fontWeight: 'bold', color: signalLevel >= 3 ? '#3B82F6' : '#94a3b8' }">{{ signalLevel }}</text>
          <text :style="{ color: signalLevel >= 3 ? '#3B82F6' : '#94a3b8', fontSize: '28rpx' }">⋮</text>
        </view>
        <text :style="{ color: '#CBD5E1', fontSize: '36rpx' }">›</text>
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
