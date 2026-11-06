# NCU 与 Android App 蓝牙通信数据结构交接文档 V1.0

> 文档状态：实验室阶段正式交接基线
> 更新日期：2026-08-18
> 适用对象：Android App 开发、UI、测试及联调人员
> 下位机范围：HC-05 + NCU `001` + TCU `001`～`005`

## 1. 文档目的

本文档定义 Android App 与 NCU 之间当前已经实现并通过基础命令实测的经典蓝牙接口，包括：

- Bluetooth Classic RFCOMM/SPP 连接方式；
- 字节流分帧规则；
- 周期遥测 `telemetry`；
- 控制命令 `command`；
- 命令确认 `command_ack`；
- 链路错误 `error`；
- App 侧连接、超时、状态展示和安全处理要求。

App 通过 HC-05 与 NCU 通信，不能按 BLE/GATT 设备开发。

## 2. 链路和当前状态

```text
Android App ⇄ Bluetooth Classic RFCOMM/SPP ⇄ HC-05 ⇄ USART1 ⇄ NCU ⇄ nRF24L01 ⇄ TCU 001～005
```

当前 NCU 配置：

```c
#define BLUETOOTH_ENABLE                    1U
#define BLUETOOTH_LINK_TEST_MODE            1U
#define BLUETOOTH_FORWARD_COMMANDS          1U
#define BLUETOOTH_BAUD_RATE                 9600U
#define BLUETOOTH_TELEMETRY_PERIOD_SECONDS  2U
```

含义：蓝牙功能和 OLED 诊断页已开启，合法手机命令会正式转发给目标 TCU。App 联调时必须遵守机构安全边界。

## 3. Android 连接参数

| 项目 | 约定 |
|---|---|
| 蓝牙类型 | Bluetooth Classic |
| 传输协议 | RFCOMM / Serial Port Profile（SPP） |
| SPP UUID | `00001101-0000-1000-8000-00805F9B34FB` |
| NCU 串口 | USART1，9600 baud、8N1、无流控 |
| 文本编码 | UTF-8，协议字段使用 ASCII 子集 |
| NCU 上行帧结束 | `\r\n` |
| App 下行帧结束 | 建议 `\r\n`；NCU 不依赖换行 |
| NCU 单条输入上限 | 511 字节 |

Android 官方 `BluetoothDevice` 文档将上述 UUID 列为连接蓝牙串口板时可尝试的标准 SPP UUID：<https://developer.android.com/reference/android/bluetooth/BluetoothDevice#createRfcommSocketToServiceRecord(java.util.UUID)>。

权限要求以 Android 官方说明为准：<https://developer.android.com/develop/connectivity/bluetooth/bt-permissions>。若 App 目标版本为 Android 12/API 31 或更高：

- 连接已经配对的 HC-05：声明并动态申请 `BLUETOOTH_CONNECT`；
- App 内扫描附近设备：还需要 `BLUETOOTH_SCAN`；
- 本项目不需要 `BLUETOOTH_ADVERTISE`。

建议首次配对由用户在 Android 系统蓝牙设置中完成，App 从已配对设备列表选择并保存其 MAC 地址。不要只按设备显示名识别，因为 HC-05 名称可以被修改且可能重复。

HC-05 的名称、PIN 和实际数据模式波特率属于模块配置，不属于 JSON 协议。当前实测使用 9600 baud。

## 4. 字节流和分帧

RFCOMM 是连续字节流，以下假设都是错误的：

- 一次 App `write()` 必然对应 NCU 一次接收；
- 一次 App `read()` 必然得到一条完整 JSON；
- 一个蓝牙数据包必然等于一个 JSON 对象。

### 4.1 App → NCU

- 每次发送一个完整 JSON 根对象；
- 推荐在对象后追加 `\r\n`；
- NCU 按 JSON 大括号深度识别完整对象，不依赖换行；
- NCU 支持拆包、粘包、格式化 JSON、字符串内部大括号和转义引号；
- App 不应在 JSON 外发送调试文本；
- 单条 JSON 必须小于等于 511 字节。

### 4.2 NCU → App

- NCU 每个 JSON 对象后固定追加 `\r\n`；
- App 应长期累积 InputStream 字节，按 CRLF 提取一帧，再对该帧做 JSON 解析；
- 一次 read 可能得到半帧，也可能得到多帧；
- 空行应忽略，解析失败的原始帧应记录但不能导致接收协程/线程永久退出。

### 4.3 推荐接收流程

```text
读取字节 → 追加到缓存 → 查找 CRLF → 取出一帧 → UTF-8 解码
        → JSON 解析 → 按 message_type 分发 → 继续处理缓存中的下一帧
```

## 5. 消息类型总览

| `message_type` | 方向 | 周期/触发 | 说明 |
|---|---|---|---|
| `telemetry` | NCU → App | 每 2 秒 | NCU、环境传感器和 5 个 TCU 的状态 |
| `command` | App → NCU | 用户操作 | 控制单台或全部 TCU |
| `command_ack` | NCU → App | 每个完整命令 JSON | 校验和无线转发结果 |
| `error` | NCU → App | 缓冲溢出/超长帧 | 无法与有效命令关联的链路错误 |

所有正式 App 报文必须携带数字型 `protocol_version:1`。当前固件为兼容已有 MQTT 解析器，暂时没有强制校验 `protocol_version` 和 `message_type`，但 App 不能省略；未来固件可能启用严格校验。

## 6. 通用数据约定

| 项目 | 约定 |
|---|---|
| NCU ID | 字符串 `"001"` |
| TCU ID | 字符串 `"001"`～`"005"` |
| 全部 TCU | 字符串 `"ALL"` |
| 角度 | number，单位 °，软件范围 `-45.0`～`+45.0` |
| 状态布尔值 | integer，`0`/`1` |
| 时间 | `YYYY-MM-DDTHH:mm:ss`，UTC+8 本地时间，不带时区后缀 |
| 坐标 | WGS84 十进制度；北纬/东经为正 |
| 未知字段 | 接收方应忽略，以便兼容扩展 |

## 7. 遥测消息 `telemetry`

### 7.1 完整示例

```json
{
  "protocol_version": 1,
  "message_type": "telemetry",
  "sequence": 25,
  "ncu_id": "001",
  "onlineStatus": 1,
  "windSpeed": 4.2,
  "windDirrect": 2,
  "solarIrradiance": 820.5,
  "timestamp": "2026-08-17T14:30:25",
  "tcuData": [
    {
      "tcu_id": "001",
      "actual_angle": 18.4,
      "expect_angle": 20.0,
      "current": 3.0,
      "onlineStatus": 1,
      "stall_fault": 0
    },
    {
      "tcu_id": "002",
      "actual_angle": 19.8,
      "expect_angle": 20.0,
      "current": 0.0,
      "onlineStatus": 1,
      "stall_fault": 0
    },
    {
      "tcu_id": "003",
      "actual_angle": 0.0,
      "expect_angle": 0.0,
      "current": 0.0,
      "onlineStatus": 0,
      "stall_fault": 0
    },
    {
      "tcu_id": "004",
      "actual_angle": -10.2,
      "expect_angle": -10.0,
      "current": 0.0,
      "onlineStatus": 1,
      "stall_fault": 0
    },
    {
      "tcu_id": "005",
      "actual_angle": 5.0,
      "expect_angle": 10.0,
      "current": 0.0,
      "onlineStatus": 1,
      "stall_fault": 1
    }
  ]
}
```

### 7.2 顶层字段

| 字段 | JSON 类型 | 范围/格式 | 单位 | 说明 |
|---|---|---|---|---|
| `protocol_version` | integer | `1` | - | 协议主版本 |
| `message_type` | string | `"telemetry"` | - | 消息分发类型 |
| `sequence` | integer | uint32 | - | 本次 NCU 上电后的蓝牙遥测序号；重启后重新开始 |
| `ncu_id` | string | `"001"` | - | NCU ID |
| `onlineStatus` | integer | `1` | - | 兼容字段；App 必须根据连接和收帧超时判断 NCU 在线 |
| `windSpeed` | number | 通常 `0.0`～`30.0` | m/s | 风速，1 位小数 |
| `windDirrect` | integer | `0`～`7`，`8`=无效 | 方位码 | 保留现有拼写 |
| `solarIrradiance` | number | 通常 `0.0`～`1800.0` | W/m² | 太阳总辐照度，1 位小数 |
| `timestamp` | string | `YYYY-MM-DDTHH:mm:ss` | - | 最近收到的有效 TCU RTC 时间 |
| `tcuData` | array | 固定 5 项 | - | TCU `001`～`005` 状态 |

风向编码：0=北、1=东北、2=东、3=东南、4=南、5=西南、6=西、7=西北、8=无效。

NCU 刚上电且尚未收到任何有效 TCU 状态时，`timestamp` 初始值为 `2000-01-01T00:00:00`，TCU 数据也可能是初始化的 0 值和离线状态。App 应结合 `onlineStatus` 判断，而不是把初始化值当成实时测量。

### 7.3 `tcuData` 项字段

| 字段 | JSON 类型 | 范围/格式 | 单位 | 说明 |
|---|---|---|---|---|
| `tcu_id` | string | `"001"`～`"005"` | - | TCU ID |
| `actual_angle` | number | 通常 `-45.0`～`+45.0` | ° | 实际角度 |
| `expect_angle` | number | `-45.0`～`+45.0` | ° | 当前目标角；自动模式由 TCU 自行计算 |
| `current` | number | 当前估算 `0.0`～`3.0` | A | PWM 占空比换算值，不是硬件实测电流 |
| `onlineStatus` | integer | `0`/`1` | - | NCU 连续 60 秒未收到该 TCU 状态时置 0 |
| `stall_fault` | integer | `0`/`1` | - | 堵转锁存；1 时 PWM 已清零，直到 `RESET` 才清除 |

TCU 离线后旧角度和电流仍保留，App 必须把 `onlineStatus=0` 作为这些数据已经过期的标志。

### 7.4 App 在线判断

- RFCOMM Socket 断开：立即显示 NCU 蓝牙离线；
- Socket 仍连接但连续 6 秒无有效 `telemetry`：显示“数据超时”；
- 收到下一条有效遥测：恢复数据在线；
- `sequence` 倒退或重新从小值开始，通常表示 NCU 重启，App 应清除未完成命令状态。

## 8. 控制命令 `command`

### 8.1 标准模板

```json
{
  "protocol_version": 1,
  "message_type": "command",
  "request_id": 1001,
  "cmdType": "SET_ANGLE",
  "ncu_id": "001",
  "tcu_id": "003",
  "controlMode": "manual",
  "target_angle": 20.0,
  "timestamp": "2026-08-17T14:32:00"
}
```

### 8.2 字段定义

| 字段 | JSON 类型 | 允许值/格式 | App 要求 | 说明 |
|---|---|---|---|---|
| `protocol_version` | integer | `1` | 必填 | 协议主版本 |
| `message_type` | string | `"command"` | 必填 | 消息类型 |
| `request_id` | integer | `0`～`4294967295` | 必填，建议从 1 递增 | ACK 关联 ID；同一次连接内不得重复使用尚未完成的 ID |
| `cmdType` | string | 见第 9 节 | 必填 | 区分大小写 |
| `ncu_id` | string | `"001"`、`"ALL"` | 必填 | 当前建议发送明确的 `"001"` |
| `tcu_id` | string | `"001"`～`"005"`、`"ALL"` | 必填 | 实际控制目标 |
| `controlMode` | string | `"manual"`、`"auto"` | 标准报文必填 | `SET_ANGLE` 时固件强制校验 |
| `target_angle` | number | 建议 `-45.0`～`+45.0` | 手动 `SET_ANGLE` 必填 | 超范围会被限幅，App 仍应先校验 |
| `timestamp` | string | `YYYY-MM-DDTHH:mm:ss` | 标准报文必填 | 有效时同步目标 TCU RTC |
| `latitude` | number | `-90.0`～`+90.0` | 可选，与经度成对 | WGS84 纬度；无线层精度 0.01° |
| `longitude` | number | `-180.0`～`+180.0` | 可选，与纬度成对 | WGS84 经度；无线层精度 0.01° |

坐标未提供时 TCU 使用当前保存值；实验室默认纬度 `24.48`、经度 `118.09`。

## 9. 命令及行为

| `cmdType` | 命令码 | 实际行为 | 保持规则 |
|---|---:|---|---|
| `SET_ANGLE` | 1 | manual：执行 `target_angle`；auto：兼容旧接口的自动模式别名 | 到下一命令 |
| `STOP` | 2 | PWM 立即清零，保持当前位置，退出自动模式 | 可接受下一命令 |
| `RESET` | 3 | 清除堵转锁存，PWM 清零并保持当前位置 | 可接受下一命令 |
| `AUTO_ALL` | 4 | 进入自动模式，TCU 天文算法持续计算目标角 | 到下一命令 |
| `TURN_EAST` | 5 | 手动目标 `+45°` | 到下一命令 |
| `TURN_WEST` | 6 | 手动目标 `-45°` | 到下一命令 |
| `FLAT_ALL` | 7 | 手动目标 `0°` | 到下一命令 |
| `CLEAN_ALL` | 8 | 手动目标 `+45°` | 到下一命令 |
| `WIND_MODE` | 9 | 手动目标 `0°` | 到下一命令 |
| `CLOUDY_MODE` | 10 | 手动目标 `0°` | 到下一命令 |

`tcu_id:"ALL"` 时，NCU 依次向 1～5 号 TCU 分别发送。命令名称包含 `ALL` 不代表必须控制全部节点，实际目标只由 `tcu_id` 决定。

## 10. 命令示例

### 10.1 单台手动角度

```json
{
  "protocol_version": 1,
  "message_type": "command",
  "request_id": 1001,
  "cmdType": "SET_ANGLE",
  "ncu_id": "001",
  "tcu_id": "003",
  "controlMode": "manual",
  "target_angle": 20.0,
  "timestamp": "2026-08-17T14:32:00"
}
```

### 10.2 全部进入自动模式

```json
{
  "protocol_version": 1,
  "message_type": "command",
  "request_id": 1002,
  "cmdType": "AUTO_ALL",
  "ncu_id": "001",
  "tcu_id": "ALL",
  "controlMode": "auto",
  "latitude": 24.48,
  "longitude": 118.09,
  "timestamp": "2026-08-17T14:32:00"
}
```

### 10.3 单台停止

```json
{
  "protocol_version": 1,
  "message_type": "command",
  "request_id": 1003,
  "cmdType": "STOP",
  "ncu_id": "001",
  "tcu_id": "001",
  "controlMode": "manual",
  "timestamp": "2026-08-17T14:32:00"
}
```

### 10.4 清除堵转

```json
{
  "protocol_version": 1,
  "message_type": "command",
  "request_id": 1004,
  "cmdType": "RESET",
  "ncu_id": "001",
  "tcu_id": "005",
  "controlMode": "manual",
  "timestamp": "2026-08-17T14:32:00"
}
```

### 10.5 预定义模式

以下结构中的 `cmdType` 可替换为 `TURN_EAST`、`TURN_WEST`、`FLAT_ALL`、`CLEAN_ALL`、`WIND_MODE` 或 `CLOUDY_MODE`：

```json
{
  "protocol_version": 1,
  "message_type": "command",
  "request_id": 1005,
  "cmdType": "WIND_MODE",
  "ncu_id": "001",
  "tcu_id": "ALL",
  "controlMode": "manual",
  "timestamp": "2026-08-17T14:32:00"
}
```

## 11. 命令确认 `command_ack`

### 11.1 成功转发示例

```json
{
  "protocol_version": 1,
  "message_type": "command_ack",
  "request_id": 1003,
  "status": "forwarded",
  "code": 0,
  "cmdType": "STOP",
  "ncu_id": "001",
  "tcu_id": "001"
}
```

### 11.2 字段定义

| 字段 | JSON 类型 | 说明 |
|---|---|---|
| `protocol_version` | integer | 固定 1 |
| `message_type` | string | 固定 `"command_ack"` |
| `request_id` | integer | 原样返回命令的关联 ID；缺失或无法解析时为 0 |
| `status` | string | `accepted`、`forwarded`、`failed`、`rejected` |
| `code` | integer | 第 12 节错误码 |
| `cmdType` | string | 已识别命令；无法识别时为 `"INVALID"` |
| `ncu_id` | string | 固定 `"001"` |
| `tcu_id` | string | `"001"`～`"005"`、`"ALL"` 或 `"UNKNOWN"` |

### 11.3 `status` 解释

| `status` | 含义 | App 展示建议 |
|---|---|---|
| `accepted` | 命令校验通过，但 NCU 配置为禁止蓝牙命令转发 | 已验收，未执行 |
| `forwarded` | NCU 已完成对全部目标 TCU 的 nRF24L01 发送 | 已转发，等待设备状态 |
| `failed` | 至少一个目标 TCU 的无线发送失败 | 下发失败/部分失败 |
| `rejected` | JSON 或命令字段无效，未执行 | 命令被拒绝 |

当前 `BLUETOOTH_FORWARD_COMMANDS=1`，正常命令预期返回 `forwarded`。

`forwarded` 只说明 NCU 无线发送函数成功，不代表电机已经到达目标。App 应继续观察后续遥测中的 `expect_angle`、`actual_angle`、`onlineStatus` 和 `stall_fault`。

### 11.4 App 请求状态机

```text
创建 request_id → 写入 command → 等待同 request_id 的 ACK
  ├─ forwarded → 显示“已转发”，继续等待遥测验证
  ├─ accepted  → 显示“已验收但未执行”
  ├─ failed    → 显示失败和 code
  ├─ rejected  → 显示参数错误和 code
  └─ 3 秒无 ACK → 显示“命令确认超时”，不自动无限重发
```

同一连接内建议使用单调递增 `request_id`。重连后可以重新生成随机起点或继续持久化序号，但不能同时复用尚未结束的 ID。当前 NCU 没有幂等缓存，App 自动重发可能导致动作重复。

## 12. 错误码和错误消息

| `code` | 含义 | 典型消息 |
|---:|---|---|
| 0 | 无错误 | `command_ack` |
| 1 | USART1 接收环形缓冲区溢出，残帧已丢弃 | `error` |
| 2 | 单条输入 JSON 超过 511 字节 | `error` |
| 3 | JSON 语法错误 | 拒绝 `command_ack` |
| 4 | NCU/TCU ID、命令或必要参数无效 | 拒绝 `command_ack` |
| 5 | 至少一个目标 TCU 无线发送失败 | `command_ack`，status=`failed` |
| 6 | NCU 蓝牙发送队列空间不足 | 可能只有 OLED 记录或表现为 ACK/遥测缺失 |

### 12.1 独立链路错误示例

缓冲区溢出或超长帧无法可靠关联原命令，NCU 发送：

```json
{
  "protocol_version": 1,
  "message_type": "error",
  "request_id": 0,
  "status": "rejected",
  "code": 2,
  "ncu_id": "001"
}
```

### 12.2 JSON 语法错误 ACK 示例

对于大括号完整但语法错误的 JSON，NCU 回复：

```json
{
  "protocol_version": 1,
  "message_type": "command_ack",
  "request_id": 0,
  "status": "rejected",
  "code": 3,
  "cmdType": "INVALID",
  "ncu_id": "001",
  "tcu_id": "UNKNOWN"
}
```

## 13. App 消息分发建议

App 收到一帧合法 JSON 后，必须按 `message_type` 分发：

```text
telemetry    → 更新 NCU、传感器、TCU 和告警页面
command_ack  → 按 request_id 完成或更新待确认命令
error        → 记录链路错误并提示用户
未知类型      → 记录日志并忽略，不中断连接
```

禁止仅通过“是否存在某个字段”猜测蓝牙消息类型，因为 V1 已提供明确的 `message_type`。

## 14. MQTT 与 App 同时控制

当前 NCU 没有控制权租约或来源优先级。MQTT 和 App 的有效命令都可以到达 TCU，后到的命令会覆盖先到的自动/手动状态或目标角。

实验室阶段要求：

- App 页面明确显示当前蓝牙连接和命令 ACK；
- App 操作电机时，测试人员应避免上位机同时下发控制命令；
- App 不得因为重连自动重放上次动作命令；
- 后续若需要多人控制，必须另行设计控制权申请、操作者身份和租约超时。

## 15. 安全和异常处理

- 当前协议没有应用层登录、签名或权限令牌，主要依赖 HC-05 配对，定位为实验室方案。
- App 不能把配对成功等同于 NCU 数据正常，必须等待有效 `telemetry`。
- App 不能把按钮点击等同于命令发送成功，必须等待 `command_ack`。
- App 不能把 `forwarded` 等同于运动到位，必须等待遥测。
- `stall_fault=1` 时应醒目显示，并提示只能在排除机械问题后发送 `RESET`。
- TCU 离线时应限制或二次确认控制操作。
- RFCOMM 断开时关闭输入输出流、清除待确认命令并允许用户主动重连。

## 16. Android 团队交付检查清单

- [ ] 使用 Bluetooth Classic RFCOMM/SPP，不使用 BLE/GATT。
- [ ] 使用标准 SPP UUID。
- [ ] 正确申请当前 Android 版本所需蓝牙权限。
- [ ] 支持从已配对设备选择并保存 MAC 地址。
- [ ] 独立后台线程/协程执行阻塞式连接和流读写。
- [ ] 接收端支持半帧、多帧和 CRLF 分帧。
- [ ] 按 `message_type` 分发三类 NCU 上行消息。
- [ ] 每条命令生成唯一 `request_id` 并维护 3 秒 ACK 超时。
- [ ] 6 秒无遥测显示数据超时。
- [ ] 展示 5 台 TCU 的在线、实际角、目标角、估算电流和堵转状态。
- [ ] 区分“已验收”“已转发”“转发失败”“被拒绝”和“运动到位”。
- [ ] 不自动重放或无限重试电机动作命令。
- [ ] 忽略未知扩展字段和未知消息类型，但保留诊断日志。

## 17. 当前接口限制

- 仅支持 Android 和经典蓝牙 HC-05，不支持 iOS/BLE。
- 没有应用层身份认证和控制权仲裁。
- 没有命令幂等缓存；相同 `request_id` 不会被 NCU 自动去重。
- ACK 只确认校验/无线发送，不确认电机到位。
- 遥测没有明确的当前控制模式字段。
- `current` 是 PWM 估算值。
- 四脚 HC-05 没有连接状态引脚，NCU 不能直接上报手机物理连接状态。

如需改变这些限制，应定义新协议版本并同步修改 NCU 与 App，不能只改单侧实现。
