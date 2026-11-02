<template>
  <view :style="{ backgroundColor: '#fff', borderRadius: '48rpx', marginBottom: '40rpx', boxShadow: '0 1px 3px rgba(0,0,0,0.1)', border: '1px solid #f1f5f9', overflow: 'hidden' }">
    <view :style="{ display: 'flex', alignItems: 'center', columnGap: '16rpx', padding: '40rpx', paddingLeft: '40rpx', paddingRight: '40rpx', backgroundColor: '#f8fafc', borderBottom: '1px solid #f1f5f9' }">
      <view :style="{ padding: '12rpx', backgroundColor: '#dbeafe', color: '#2563eb', borderRadius: '16rpx' }">
        <image v-if="icon === 'location'" src="/static/svg/bl.svg" mode="aspectFit" :style="{ width: '32rpx', height: '32rpx', filter: 'sepia(100%) saturate(1000%) hue-rotate(200deg)' }"></image>
        <image v-else-if="icon === 'shield'" src="/static/svg/bl.svg" mode="aspectFit" :style="{ width: '32rpx', height: '32rpx', filter: 'sepia(100%) saturate(1000%) hue-rotate(200deg)' }"></image>
        <image v-else src="/static/svg/bl.svg" mode="aspectFit" :style="{ width: '32rpx', height: '32rpx', filter: 'sepia(100%) saturate(1000%) hue-rotate(200deg)' }"></image>
      </view>
      <h3 :style="{ color: '#1e293b', fontWeight: 'bold', fontSize: '28rpx' }">{{ title }}</h3>
    </view>
    <view :style="{ padding: '32rpx' }">
      <slot></slot>
      <view :style="{ marginTop: '40rpx', display: 'flex', justifyContent: 'flex-end' }">
        <button :style="{ backgroundColor: '#0f172a', color: '#fff', padding: '20rpx 40rpx', borderRadius: '24rpx', fontSize: '28rpx', fontWeight: '500', display: 'flex', alignItems: 'center', columnGap: '16rpx', boxShadow: '0 2px 4px rgba(0,0,0,0.1)' }" @click="handleWrite">
          <text :style="{ fontSize: '28rpx', color: '#fff' }">➤</text>
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
