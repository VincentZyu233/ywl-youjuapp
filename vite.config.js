import { defineConfig } from 'vite';

export default defineConfig({
  resolve: {
    extensions: ['.mjs', '.js', '.ts', '.jsx', '.tsx', '.json', '.vue']
  },
  server: {
    port: 61102,
    host: '0.0.0.0',
    strictPort: true
  }
});
