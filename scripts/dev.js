const path = require('path');
const fs = require('fs');
const { spawn } = require('child_process');

const projectRoot = path.resolve(__dirname, '..');

// 候选的 HBuilderX 根目录
const candidateHxRoots = [
  process.env.HX_APP_ROOT,
  'D:\\SSoftwareFiles\\HBuiderX\\HBuilderX.4.66.2025051912\\HBuilderX',
  'C:\\Program Files\\HBuilderX',
  'C:\\Program Files (x86)\\HBuilderX',
  'D:\\HBuilderX'
].filter(Boolean);

let hxRoot = candidateHxRoots.find(p => fs.existsSync(p));

if (!hxRoot) {
  console.error('[Error] 未找到本地 HBuilderX 安装目录，请设置环境变量 HX_APP_ROOT 指向 HBuilderX 安装路径。');
  process.exit(1);
}

const uniBin = path.join(hxRoot, 'plugins', 'uniapp-cli-vite', 'node_modules', '.bin', process.platform === 'win32' ? 'uni.cmd' : 'uni');

if (!fs.existsSync(uniBin)) {
  console.error(`[Error] 未在 ${hxRoot} 中找到 uniapp-cli-vite 插件，请确认已在 HBuilderX 中安装 uni-app 编译插件。`);
  process.exit(1);
}

// 端口持久化：默认 61102（可通过 PORT 环境变量或命令行参数 --port 覆盖）
const port = process.env.PORT || '61102';

const env = {
  ...process.env,
  HX_APP_ROOT: hxRoot,
  UNI_INPUT_DIR: projectRoot,
  VITE_ROOT_DIR: projectRoot
};

const args = [...process.argv.slice(2)];
if (!args.includes('--port')) {
  args.push('--port', port);
}

console.log(`[youjuAPP] 使用 HBuilderX 内核启动开发服务器: ${hxRoot}`);
console.log(`[youjuAPP] 服务端口: ${port}`);

const child = spawn(uniBin, args, {
  cwd: projectRoot,
  env,
  stdio: 'inherit',
  shell: true
});

child.on('close', code => {
  process.exit(code || 0);
});
