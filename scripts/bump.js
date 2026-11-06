#!/usr/bin/env node
/**
 * 📦 统一更新 package.json 与 manifest.json 的版本信息。
 * 
 * 用法示例：
 *   1. 自动递增补丁版本 (如 1.0.2 -> 1.0.3, versionCode 102 -> 103):
 *      node scripts/bump.js patch
 *      或直接: npm run bump
 *   2. 自动递增次版本号 (如 1.0.2 -> 1.1.0):
 *      npm run bump minor
 *   3. 自动递增主版本号 (如 1.0.2 -> 2.0.0):
 *      npm run bump major
 *   4. 直接指定目标版本号与自定义 versionCode:
 *      npm run bump 1.0.3 -c 103
 *   5. 仅更新 versionCode 为当前上海日期 (如 20261106):
 *      npm run bump --date-code
 *   6. 预演检查（不实际写文件）:
 *      npm run bump patch --dry-run
 */

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const PACKAGE_JSON = path.join(ROOT, 'package.json');
const MANIFEST_JSON = path.join(ROOT, 'manifest.json');

const COLORS = {
  reset: '\x1b[0m',
  bold: '\x1b[1m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  cyan: '\x1b[36m',
  dim: '\x1b[2m'
};

function logOk(msg) {
  console.log(`  ${COLORS.green}✅${COLORS.reset} ${msg}`);
}
function logWarn(msg) {
  console.log(`  ${COLORS.yellow}⚠️ ${COLORS.reset} ${msg}`);
}
function logErr(msg) {
  console.log(`  ${COLORS.red}❌${COLORS.reset} ${msg}`);
}
function logInfo(msg) {
  console.log(`  ${COLORS.cyan}ℹ️ ${COLORS.reset} ${COLORS.dim}${msg}${COLORS.reset}`);
}

function parseSemver(v) {
  const match = v.match(/^(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?(?:\+([0-9A-Za-z.-]+))?$/);
  if (!match) return null;
  return {
    major: parseInt(match[1], 10),
    minor: parseInt(match[2], 10),
    patch: parseInt(match[3], 10),
    prerelease: match[4] || null,
    build: match[5] || null
  };
}

function formatSemver(parts) {
  let v = `${parts.major}.${parts.minor}.${parts.patch}`;
  if (parts.prerelease) v += `-${parts.prerelease}`;
  if (parts.build) v += `+${parts.build}`;
  return v;
}

function getShanghaiDateCode() {
  const now = new Date();
  const utc = now.getTime() + now.getTimezoneOffset() * 60000;
  const shanghai = new Date(utc + 8 * 3600000);
  const y = shanghai.getFullYear();
  const m = String(shanghai.getMonth() + 1).padStart(2, '0');
  const d = String(shanghai.getDate()).padStart(2, '0');
  return parseInt(`${y}${m}${d}`, 10);
}

function main() {
  const args = process.argv.slice(2);
  const isDryRun = args.includes('--dry-run') || args.includes('-d');
  const isDateCode = args.includes('--date-code');

  let customCode = null;
  const codeIdx = args.findIndex(a => a === '-c' || a === '--code' || a === '--versioncode');
  if (codeIdx !== -1 && args[codeIdx + 1]) {
    customCode = parseInt(args[codeIdx + 1], 10);
  }

  // 过滤掉标志位参数，获取版本动作或目标版本号
  const actionArgs = args.filter(a => !a.startsWith('-') && (codeIdx === -1 || a !== args[codeIdx + 1]));
  const targetAction = actionArgs[0] || 'patch';

  console.log(`\n  ${COLORS.bold}========================================${COLORS.reset}`);
  console.log(`  ${COLORS.bold}         youjuAPP 版本管理工具          ${COLORS.reset}`);
  console.log(`  ${COLORS.bold}         模式: ${isDryRun ? '👀 预演 (DRY RUN)' : '🚀 执行写入'}${COLORS.reset}`);
  console.log(`  ${COLORS.bold}========================================${COLORS.reset}\n`);

  if (!fs.existsSync(PACKAGE_JSON) || !fs.existsSync(MANIFEST_JSON)) {
    logErr('未找到 package.json 或 manifest.json 文件！');
    process.exit(1);
  }

  const pkgContent = fs.readFileSync(PACKAGE_JSON, 'utf8');
  const manifestContent = fs.readFileSync(MANIFEST_JSON, 'utf8');

  // 提取当前 manifest.json 中的版本
  const versionNameMatch = manifestContent.match(/"versionName"\s*:\s*"([^"]+)"/);
  const versionCodeMatch = manifestContent.match(/"versionCode"\s*:\s*(\d+)/);

  if (!versionNameMatch || !versionCodeMatch) {
    logErr('无法从 manifest.json 中读取 versionName 或 versionCode！');
    process.exit(1);
  }

  const currentVersionName = versionNameMatch[1];
  const currentVersionCode = parseInt(versionCodeMatch[1], 10);

  logInfo(`当前 versionName: ${COLORS.bold}${currentVersionName}${COLORS.reset}, versionCode: ${COLORS.bold}${currentVersionCode}${COLORS.reset}`);

  let nextVersionName = currentVersionName;
  let nextVersionCode = currentVersionCode;

  if (targetAction === 'patch' || targetAction === 'minor' || targetAction === 'major') {
    const sem = parseSemver(currentVersionName);
    if (!sem) {
      logErr(`当前版本 "${currentVersionName}" 不是标准语义化版本 (x.y.z)`);
      process.exit(1);
    }
    if (targetAction === 'major') {
      sem.major += 1;
      sem.minor = 0;
      sem.patch = 0;
    } else if (targetAction === 'minor') {
      sem.minor += 1;
      sem.patch = 0;
    } else if (targetAction === 'patch') {
      sem.patch += 1;
    }
    nextVersionName = formatSemver(sem);
    nextVersionCode = currentVersionCode + 1;
  } else if (/^\d+\.\d+\.\d+/.test(targetAction)) {
    nextVersionName = targetAction;
    nextVersionCode = currentVersionCode + 1;
  } else if (targetAction === '--date-code' || isDateCode) {
    // 仅更新代码
  } else {
    logWarn(`未知动作 "${targetAction}"，将保留当前版本名称`);
  }

  if (customCode !== null) {
    nextVersionCode = customCode;
  } else if (isDateCode) {
    nextVersionCode = getShanghaiDateCode();
  }

  console.log(`\n  👉 计划变更:`);
  console.log(`     versionName : ${COLORS.yellow}${currentVersionName}${COLORS.reset} -> ${COLORS.green}${nextVersionName}${COLORS.reset}`);
  console.log(`     versionCode : ${COLORS.yellow}${currentVersionCode}${COLORS.reset} -> ${COLORS.green}${nextVersionCode}${COLORS.reset}\n`);

  if (isDryRun) {
    logInfo('预演模式结束，未修改任何文件。');
    return;
  }

  // 1. 更新 manifest.json
  const newManifestContent = manifestContent
    .replace(/"versionName"\s*:\s*"[^"]+"/, `"versionName" : "${nextVersionName}"`)
    .replace(/"versionCode"\s*:\s*\d+/, `"versionCode" : ${nextVersionCode}`);
  fs.writeFileSync(MANIFEST_JSON, newManifestContent, 'utf8');
  logOk(`成功更新 manifest.json -> versionName: ${nextVersionName}, versionCode: ${nextVersionCode}`);

  // 2. 更新 package.json
  const newPkgContent = pkgContent.replace(/"version"\s*:\s*"[^"]+"/, `"version": "${nextVersionName}"`);
  fs.writeFileSync(PACKAGE_JSON, newPkgContent, 'utf8');
  logOk(`成功更新 package.json -> version: ${nextVersionName}`);

  console.log(`\n  ${COLORS.bold}${COLORS.green}✨ 版本更新完成！${COLORS.reset}\n`);
}

main();
