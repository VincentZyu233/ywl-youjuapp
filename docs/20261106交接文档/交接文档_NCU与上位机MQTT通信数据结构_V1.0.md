# NCU 与上位机 MQTT 通信数据结构交接文档 V1.0

> 文档状态：实验室阶段正式交接基线
> 更新日期：2026-08-18
> 适用对象：上位机前端、后端、MQTT 接入及联调人员
> 下位机范围：1 台 NCU（`001`）+ 5 台 TCU（`001`～`005`）

## 1. 文档目的

本文档定义上位机与 NCU 之间当前已经实现并完成双向联调的 MQTT 数据接口，包括：

- MQTT Topic 和消息方向；
- NCU 周期遥测 JSON；
- NCU 故障事件 JSON；
- 上位机控制命令 JSON；
- 10 种命令的行为、参数和示例；
- 在线状态、时间、坐标、角度和告警的解释；
- 上位机解析、状态展示和异常处理要求。

本文档取代旧文档中与当前代码不一致的字段描述。特别需要注意：目标角 `expect_angle` 现在属于每个 `tcuData` 项，不再是 NCU 顶层字段；遥测还增加了 TCU 在线状态和堵转告警。

## 2. 系统链路和职责边界

```text
上位机 ⇄ MQTT Broker ⇄ ZQWL-GE105S ⇄ USART3 ⇄ NCU ⇄ nRF24L01 ⇄ TCU 001～005
```

- 上位机负责 MQTT 连接、订阅、发布、页面展示、NCU 超时离线判断和历史数据存储。
- GE105S 负责 MQTT 与透明串口数据之间的转换。
- NCU 负责读取环境传感器、聚合 5 个 TCU 状态、解析命令并逐个无线下发。
- TCU 负责 RTC、姿态测量、天文算法、电机控制和堵转检测。
- MQTT Broker 地址、账号、密码、QoS 和会话参数属于部署配置，不写入本数据结构协议。

## 3. MQTT Topic

| 方向 | Topic | 发布方 | 订阅方 | 载荷 |
|---|---|---|---|---|
| NCU → 上位机 | `youju/device/up/data` | GE105S/NCU | 上位机 | 遥测或故障 JSON |
| 上位机 → NCU | `youju/device/down/cmd` | 上位机 | GE105S/NCU | 命令 JSON |

约定：

- JSON 使用 UTF-8 编码，当前字段名和枚举值均位于 ASCII 子集。
- NCU 在 USART3 上行 JSON 后追加 `\r\n`。GE105S 透明转发后，MQTT 载荷可能保留尾部空白；上位机解析前应允许并忽略首尾空白。
- NCU 下行按完整 JSON 根对象分帧，不依赖 `\r\n`，支持拆包、粘包和格式化多行 JSON。
- 单条下行 JSON 最长 511 字节。
- 控制 Topic 必须使用非保留消息，即 MQTT `Retain=false`，避免 GE105S 或上位机重连后重新执行历史电机命令。
- 当前 NCU 没有 MQTT 应用层成功 ACK，不能把 MQTT 客户端的 publish 成功等同于 TCU 已执行。

## 4. 设备编号

| 对象 | 当前取值 | 类型 | 说明 |
|---|---|---|---|
| NCU | `"001"` | string | 当前实验室阶段固定一台 |
| TCU | `"001"`～`"005"` | string | 固定 5 台，必须保留三位格式 |
| 全部 TCU | `"ALL"` | string | NCU 按 1～5 顺序逐个无线单播 |
| 全部 NCU | `"ALL"` | string | 当前只有一台 NCU，作为兼容广播值保留 |

上位机应按字符串保存 ID，不应转换后丢失前导零。

## 5. NCU 上行消息分类

同一个上行 Topic 包含两种结构，上位机应先判断根对象是否存在 `fault_code`：

1. 存在 `fault_code`：按故障事件解析；
2. 不存在 `fault_code` 且存在 `ncu_id`、`tcuData`：按周期遥测解析；
3. 其他结构：记录为未知消息，不应让整个 MQTT 消费线程退出。

## 6. 周期遥测结构

### 6.1 发送周期

NCU 每 5 秒上传一条完整遥测。上位机建议保存自己的 MQTT 接收时间 `received_at`，不要只依赖设备上报的 `timestamp`。

### 6.2 完整示例

```json
{
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

实际 `tcuData` 固定包含 5 项，并分别对应 TCU `001`～`005`。

### 6.3 NCU 顶层字段

| 字段 | JSON 类型 | 当前范围/格式 | 单位 | 必填 | 说明 |
|---|---|---|---|---|---|
| `ncu_id` | string | `"001"` | - | 是 | NCU 编号 |
| `onlineStatus` | integer | `0`/`1` | - | 是 | 兼容字段，当前固件固定为 1；不能用于判定 NCU 真正离线 |
| `windSpeed` | number | 通常 `0.0`～`30.0` | m/s | 是 | NCU 风速传感器换算值，保留 1 位小数 |
| `windDirrect` | integer | `0`～`7`，`8`=无效 | 方位码 | 是 | 保留既有拼写，不得改成 `windDirection` |
| `solarIrradiance` | number | 通常 `0.0`～`1800.0` | W/m² | 是 | 太阳总辐照度，保留 1 位小数 |
| `timestamp` | string | `YYYY-MM-DDTHH:mm:ss` | UTC+8 本地时间 | 是 | 最近一次有效 TCU 状态包中的 RTC 时间，不是 MQTT Broker 接收时间 |
| `tcuData` | array | 固定 5 项 | - | 是 | 每个 TCU 独立状态 |

风向编码：

| 值 | 方位 | 值 | 方位 |
|---|---|---|---|
| 0 | 北 N | 4 | 南 S |
| 1 | 东北 NE | 5 | 西南 SW |
| 2 | 东 E | 6 | 西 W |
| 3 | 东南 SE | 7 | 西北 NW |
| 8 | 无效/异常 | - | - |

NCU 刚上电且尚未收到任何有效 TCU 状态时，`timestamp` 初始值为 `2000-01-01T00:00:00`，各 TCU 数据也可能是初始化的 0 值和离线状态。上位机应结合 `onlineStatus` 和自己的 `received_at` 判断数据有效性。

### 6.4 `tcuData` 项字段

| 字段 | JSON 类型 | 当前范围/格式 | 单位 | 必填 | 说明 |
|---|---|---|---|---|---|
| `tcu_id` | string | `"001"`～`"005"` | - | 是 | TCU 编号 |
| `actual_angle` | number | 通常 `-45.0`～`+45.0` | ° | 是 | MPU6050 解算得到的实际角度，保留 1 位小数 |
| `expect_angle` | number | `-45.0`～`+45.0` | ° | 是 | 该 TCU 当前目标角；自动模式下由 TCU 天文算法计算 |
| `current` | number | 当前估算 `0.0`～`3.0` | A | 是 | 根据 PWM 占空比换算的估算值，不是电流传感器实测值；字段名保持兼容 |
| `onlineStatus` | integer | `0`/`1` | - | 是 | NCU 最近 60 秒内是否收到该 TCU 的有效状态包 |
| `stall_fault` | integer | `0`/`1` | - | 是 | 堵转锁存告警；1 时 TCU 已清零 PWM，并持续上报直到收到 `RESET` |

TCU 离线后，NCU 只把该项 `onlineStatus` 改为 0，其他字段保留最后一次有效值。上位机必须先看在线状态，再解释角度和电流，不能把离线节点的旧值当成实时值。

### 6.5 NCU 在线判断

NCU 真正离线必须由上位机根据消息超时判断。当前约定：连续 60 秒没有收到 NCU `001` 的有效遥测，可判定 NCU 离线。收到下一条有效遥测后恢复在线。

## 7. 故障事件结构

### 7.1 TCU → NCU 无线接收异常

```json
{
  "fault_code": "0x01"
}
```

说明：NCU 的 nRF24L01 接收状态异常。当前结构没有可靠的 `tcu_id`，上位机只能显示为 NCU 无线接收链路告警，并结合各 TCU 的 `onlineStatus` 定位。

### 7.2 NCU → 指定 TCU 命令发送失败

```json
{
  "fault_code": "0x02",
  "tcu_id": "003"
}
```

说明：NCU 对目标 TCU 最多尝试 3 次无线发送后仍失败。若上位机下发 `tcu_id:"ALL"`，某几个节点失败，NCU 会分别发送对应的故障事件。

### 7.3 堵转告警

堵转不是独立 `fault_code` 消息，而是在周期遥测中通过对应 TCU 的 `stall_fault:1` 持续上报。上位机应把它作为需要持续展示和确认的设备告警。

## 8. 上位机下行命令通用结构

### 8.1 推荐模板

```json
{
  "cmdType": "SET_ANGLE",
  "tcu_id": "001",
  "ncu_id": "001",
  "controlMode": "manual",
  "target_angle": 20.0,
  "timestamp": "2026-08-17T14:32:00"
}
```

### 8.2 字段定义

| 字段 | JSON 类型 | 允许值/格式 | 接口要求 | 说明 |
|---|---|---|---|---|
| `cmdType` | string | 见第 9 节 | 必填 | 区分大小写 |
| `tcu_id` | string | `"001"`～`"005"`、`"ALL"` | 必填 | 实际控制目标；`ALL` 时依次单播 5 台 TCU |
| `ncu_id` | string | `"001"`、`"ALL"` | 必填 | 当前建议明确发送 `"001"` |
| `controlMode` | string | `"manual"`、`"auto"` | 标准报文必填 | `SET_ANGLE` 时固件强制校验；预定义模式会覆盖其实际行为 |
| `target_angle` | number | 建议 `-45.0`～`+45.0` | 手动 `SET_ANGLE` 必填 | 超范围值会被 NCU 限幅，不建议依赖限幅代替前端校验 |
| `timestamp` | string | `YYYY-MM-DDTHH:mm:ss` | 标准报文必填 | 有效时随命令同步目标 TCU RTC；使用 UTC+8 本地时间，不带时区后缀 |
| `latitude` | number | `-90.0`～`+90.0` | 可选，与经度成对 | WGS84 十进制度，北纬为正；无线层保留到 0.01° |
| `longitude` | number | `-180.0`～`+180.0` | 可选，与纬度成对 | WGS84 十进制度，东经为正；无线层保留到 0.01° |

坐标未下发时，TCU 使用当前保存值；当前实验室默认坐标为纬度 `24.48`、经度 `118.09`。时间或坐标字段无效时，TCU 不覆盖已有有效值。

## 9. 命令清单和业务行为

| `cmdType` | 命令码 | 控制模式 | 目标/动作 | 保持规则 |
|---|---:|---|---|---|
| `SET_ANGLE` | 1 | manual/auto | manual 使用 `target_angle`；auto 为兼容旧接口的自动模式别名 | 到下一命令 |
| `STOP` | 2 | manual | PWM 立即清零，保持当前位置并退出自动模式 | 可接受下一命令 |
| `RESET` | 3 | manual | 清除堵转锁存，PWM 清零并保持当前位置 | 可接受下一命令 |
| `AUTO_ALL` | 4 | auto | 进入自动模式，由各 TCU 天文算法计算目标角 | 到下一命令 |
| `TURN_EAST` | 5 | manual | 目标 `+45°` | 到下一命令 |
| `TURN_WEST` | 6 | manual | 目标 `-45°` | 到下一命令 |
| `FLAT_ALL` | 7 | manual | 目标 `0°` | 到下一命令 |
| `CLEAN_ALL` | 8 | manual | 目标 `+45°` | 到下一命令 |
| `WIND_MODE` | 9 | manual | 目标 `0°` | 到下一命令 |
| `CLOUDY_MODE` | 10 | manual | 目标 `0°` | 到下一命令 |

命令名中的 `ALL` 是既有业务名称，不限制只能发送给 `tcu_id:"ALL"`。例如可以让 TCU `003` 单独进入 `WIND_MODE`。真正的目标范围始终由 `tcu_id` 决定。

## 10. 可直接使用的命令示例

### 10.1 单台 TCU 手动设置角度

```json
{
  "cmdType": "SET_ANGLE",
  "tcu_id": "003",
  "ncu_id": "001",
  "controlMode": "manual",
  "target_angle": 20.0,
  "timestamp": "2026-08-17T14:32:00"
}
```

### 10.2 全部 TCU 进入自动模式并更新时间坐标

```json
{
  "cmdType": "AUTO_ALL",
  "tcu_id": "ALL",
  "ncu_id": "001",
  "controlMode": "auto",
  "latitude": 24.48,
  "longitude": 118.09,
  "timestamp": "2026-08-17T14:32:00"
}
```

### 10.3 停止指定 TCU

```json
{
  "cmdType": "STOP",
  "tcu_id": "001",
  "ncu_id": "001",
  "controlMode": "manual",
  "timestamp": "2026-08-17T14:32:00"
}
```

### 10.4 清除指定 TCU 堵转锁存

```json
{
  "cmdType": "RESET",
  "tcu_id": "005",
  "ncu_id": "001",
  "controlMode": "manual",
  "timestamp": "2026-08-17T14:32:00"
}
```

### 10.5 预定义模式

以下示例只需替换 `cmdType`。允许值为 `TURN_EAST`、`TURN_WEST`、`FLAT_ALL`、`CLEAN_ALL`、`WIND_MODE`、`CLOUDY_MODE`：

```json
{
  "cmdType": "WIND_MODE",
  "tcu_id": "ALL",
  "ncu_id": "001",
  "controlMode": "manual",
  "timestamp": "2026-08-17T14:32:00"
}
```

## 11. 命令结果和上位机状态机

### 11.1 当前没有成功 ACK

MQTT 接口当前不会在成功解析并发送命令后返回 `command_ack`。因此上位机应区分：

- `已发布`：MQTT 客户端已把消息交给 Broker；
- `下发失败`：收到 `fault_code:"0x02"`；
- `设备状态已变化`：后续遥测与目标行为一致；
- `执行完成`：仅当后续 `actual_angle` 接近 `expect_angle` 且无堵转时才能由上位机推断。

对于 `STOP`、`RESET` 和自动/模式切换，当前遥测没有单独的控制模式字段，因此不能仅凭一帧遥测无歧义确认模式切换。页面不应在 MQTT publish 成功后直接显示“执行完成”。

### 11.2 建议等待时间

- 发布命令后至少等待下一帧 5 秒遥测再刷新设备状态；
- 角度动作需要根据实际机构速度设置更长的到位超时；
- 若目标 TCU `onlineStatus=0`，上位机应在下发前提示风险；
- 不应自动无限重发动作命令。

## 12. 非法命令和兼容规则

以下情况 NCU 不执行命令：

- JSON 语法错误；
- 缺少 `cmdType`、`ncu_id` 或 `tcu_id`；
- `ncu_id` 不是 `001`/`ALL`；
- `tcu_id` 不在 `001`～`005` 且不是 `ALL`；
- 未知 `cmdType`；
- `SET_ANGLE` 缺少合法 `controlMode`；
- 手动 `SET_ANGLE` 缺少数值型 `target_angle`。

当前 MQTT 正式模式对上述解析错误不返回错误 JSON，只是不执行。上位机必须在发布前完成同样的前端/后端校验，并记录原始下发报文。

接收方应忽略未来新增的未知字段；现有字段名、类型和枚举值不得擅自修改。尤其必须保留 `windDirrect` 的现有拼写和 `current` 的现有字段名。

## 13. 上位机实现检查清单

- [ ] 订阅 `youju/device/up/data`，发布 `youju/device/down/cmd`。
- [ ] 控制消息使用 `Retain=false`。
- [ ] 按 `fault_code` 区分遥测和故障事件。
- [ ] `tcuData` 按 `tcu_id` 更新，不依赖数组顺序作为唯一标识。
- [ ] NCU 60 秒无遥测判离线；TCU 使用上报的 `onlineStatus`。
- [ ] 离线 TCU 的历史角度、电流不当作实时值。
- [ ] `stall_fault=1` 持续展示，直到后续遥测恢复为 0。
- [ ] 下发前校验 ID、命令、角度、时间和坐标。
- [ ] 页面区分“MQTT 已发布”和“设备执行完成”。
- [ ] 保存 Broker 接收时间和设备 `timestamp` 两个时间概念。
- [ ] JSON 解析允许尾部 CR/LF 和未来未知字段。

## 14. 当前接口限制

- MQTT 下行没有 `request_id`、成功 ACK 和命令幂等缓存。
- MQTT 遥测没有 TCU 当前控制模式字段。
- NCU 顶层 `onlineStatus` 不是实际链路检测结果。
- TCU `current` 是 PWM 估算值。
- `fault_code:"0x01"` 当前没有具体 TCU ID。
- MQTT 与手机蓝牙目前没有控制权仲裁，后到达 TCU 的有效命令覆盖之前的模式或目标。

如后续需要修改以上限制，应发布新的协议版本并与下位机同步实现，不能只改单侧字段。
