<template>
  <button
    :style="{
      aspectRatio: '4/3',
      borderRadius: '32rpx',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontSize: '30rpx',
      fontWeight: '600',
      transition: 'all 0.2s',
      ...(isActive ? activeStyle : { backgroundColor: '#f8fafc', color: '#475569', border: '1px solid #e2e8f0' })
    }"
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
    activeStyle: {
      type: Object,
      default: () => ({ backgroundColor: '#10b981', color: '#fff', border: 'none' })
    }
  },
  methods: {
    handleClick() {
      this.$emit('click', this.text)
    }
  }
}
</script>
