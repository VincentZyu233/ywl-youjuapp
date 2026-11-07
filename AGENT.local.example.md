# AGENT.local.example.md - 本地无线调试与设备配置模板

> **使用说明**：
> 1. 本文件为模板与格式规范，由 Git 跟踪维护（**请勿修改本文件中的具体个人 IP/私有路径**）。
> 2. 开发者或 AI Agent 在本地进行真机调试前，复制本文件并在根目录重命名为 `AGENT.local.md`。
> 3. `AGENT.local.md` 已被 `.gitignore` 忽略，用于安全持久化个人局域网 IP、无线调试端口及工具链路径。

---

## 1. ADB 与无线调试配置

```yaml
adb:
  # 本地 adb.exe 绝对路径（例如 scrcpy 内置 adb 或 Android SDK platform-tools）
  path: "D:\\SSoftwareFiles\\scrcpy\\scrcpy-win64-v3.3.3\\adb.exe"

device:
  # 手机与电脑在同一局域网下的无线调试地址（格式: IP:Port）
  # 提示: Android 11+ 无线调试每次开关或重启后端口可能会变化，如遇断开请在手机「开发者选项 -> 无线调试」中查看当前端口
  wireless_endpoint: "192.168.31.3:43001"
  
  # 设备型号与物理屏幕分辨率（用于自动化触控坐标换算）
  model: "vivo V2307A"
  screen_width: 1260
  screen_height: 2800
  
  # 应用包名与主入口
  package_name: "com.youju.tcuapp"
  main_activity: "com.youju.tcuapp.MainActivity"
```

---

## 2. 下位机仿真与本地联调环境

```yaml
simulation:
  # Python 运行器（支持 uv run python 或标准 python）
  python_runner: "uv run python"
  
  # 仿真服务脚本路径
  mock_server_script: "docs/20261107调试文档/mock_ncu_server.py"
  
  # 硬件模式下的串口号（若使用 USB-TTL 模块直连 PC，例如 COM3 / COM4）
  serial_port: "COM3"
  baud_rate: 9600
```

---

## 3. 常用 ADB 操作速查命令

在 PowerShell 下使用示例：

```powershell
# 1. 定义变量并建立连接
$adb = "D:\SSoftwareFiles\scrcpy\scrcpy-win64-v3.3.3\adb.exe"
$device = "192.168.31.3:43001"
& $adb connect $device

# 2. 推送并静默覆盖安装最新 APK
& $adb -s $device install -r "download/v2.1.1/youjuAPP_v2.1.1.apk"

# 3. 启动应用
& $adb -s $device shell am start -n "com.youju.tcuapp/com.youju.tcuapp.MainActivity"

# 4. 抓取高保真真机截图（严禁在 PowerShell 使用 > 重定向，避免文件编码损坏）
& $adb -s $device shell screencap -p /sdcard/screen.png
& $adb -s $device pull /sdcard/screen.png "D:\temp\screen.png"

# 5. 模拟点击与滑动（按 1260x2800 分辨率）
& $adb -s $device shell input tap 630 1400
& $adb -s $device shell input swipe 630 2000 630 800 300

# 6. 查看 Flutter 与蓝牙 SPP 插件实时运行日志
& $adb -s $device logcat -c
& $adb -s $device logcat -s Flutter:V BluetoothSppPlugin:V
```
