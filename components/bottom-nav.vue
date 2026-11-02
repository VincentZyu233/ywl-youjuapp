<template>
  <view :style="{ position: 'absolute', bottom: '48rpx', left: '32rpx', right: '32rpx', zIndex: 20 }">
    <view :style="{ backgroundColor: 'rgba(255,255,255,0.8)', backdropFilter: 'blur(20px)', borderRadius: '64rpx', padding: '16rpx', display: 'flex', justifyContent: 'space-between', alignItems: 'center', boxShadow: '0 8px 30px rgba(0,0,0,0.08)', border: '1px solid rgba(255,255,255,0.5)' }">
      <view
        v-for="item in navItems"
        :key="item.key"
        :style="{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          width: '128rpx',
          padding: '16rpx',
          borderRadius: '32rpx',
          transition: 'all 0.3s',
          position: 'relative',
          zIndex: 10,
          ...(activeKey === item.key ? { color: '#2563eb', transform: 'scale(1.05)' } : { color: '#94a3b8' })
        }"
        @click="handleNav(item.key)"
      >
        <view v-if="activeKey === item.key" :style="{ position: 'absolute', inset: 0, backgroundColor: '#eff6ff', borderRadius: '32rpx', zIndex: -1 }"></view>
        <text :style="{ fontSize: '40rpx' }">{{ item.icon }}</text>
        <text :style="{ fontSize: '20rpx', fontWeight: 'bold', marginTop: '8rpx', ...(activeKey === item.key ? { color: '#1d4ed8' } : {}) }">{{ item.label }}</text>
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
        { key: 'info', label: '信息', icon: 'ⓘ' },
        { key: 'settings', label: '设置', icon: '⚙' },
        { key: 'broadcast', label: '广播', icon: '📢' },
        { key: 'group', label: '群控', icon: '☰' }
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
