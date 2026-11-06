package com.youju.tcuapp

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStream
import java.io.IOException
import java.util.UUID
import java.util.concurrent.Executors

class BluetoothSppPlugin(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    companion object {
        private const val METHOD_CHANNEL = "com.youju.tcuapp/spp"
        private const val EVENT_DATA_CHANNEL = "com.youju.tcuapp/spp_data"
        private const val EVENT_STATE_CHANNEL = "com.youju.tcuapp/spp_state"
        private const val EVENT_DEVICE_CHANNEL = "com.youju.tcuapp/spp_devices"

        // 标准经典蓝牙 SPP UUID (HC-05 / JDY-31 / SPP 串口透传)
        private val SPP_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    }

    private val methodChannel = MethodChannel(messenger, METHOD_CHANNEL)
    private val dataEventChannel = EventChannel(messenger, EVENT_DATA_CHANNEL)
    private val stateEventChannel = EventChannel(messenger, EVENT_STATE_CHANNEL)
    private val deviceEventChannel = EventChannel(messenger, EVENT_DEVICE_CHANNEL)

    private var dataSink: EventChannel.EventSink? = null
    private var stateSink: EventChannel.EventSink? = null
    private var deviceSink: EventChannel.EventSink? = null

    private val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
    private val executor = Executors.newCachedThreadPool()
    private val mainHandler = Handler(Looper.getMainLooper())

    private var currentSocket: BluetoothSocket? = null
    private var outputStream: OutputStream? = null
    private var isReading = false
    private var isReceiverRegistered = false

    private val discoveredDevices = mutableMapOf<String, Map<String, Any?>>()

    init {
        methodChannel.setMethodCallHandler(this)

        dataEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                dataSink = events
            }
            override fun onCancel(arguments: Any?) {
                dataSink = null
            }
        })

        stateEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                stateSink = events
                notifyState(if (currentSocket?.isConnected == true) "connected" else "disconnected")
            }
            override fun onCancel(arguments: Any?) {
                stateSink = null
            }
        })

        deviceEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                deviceSink = events
            }
            override fun onCancel(arguments: Any?) {
                deviceSink = null
            }
        })
    }

    private val discoveryReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val action = intent?.action ?: return
            when (action) {
                BluetoothDevice.ACTION_FOUND -> {
                    val device: BluetoothDevice? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                    }
                    val rssi = intent.getShortExtra(BluetoothDevice.EXTRA_RSSI, Short.MIN_VALUE).toInt()
                    if (device != null) {
                        val deviceMap = mapOf<String, Any?>(
                            "name" to (device.name ?: "未知设备"),
                            "address" to device.address,
                            "type" to "classic",
                            "bonded" to (device.bondState == BluetoothDevice.BOND_BONDED),
                            "rssi" to rssi
                        )
                        discoveredDevices[device.address] = deviceMap
                        mainHandler.post {
                            deviceSink?.success(discoveredDevices.values.toList())
                        }
                    }
                }
                BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> {
                    mainHandler.post {
                        deviceSink?.success(discoveredDevices.values.toList())
                    }
                }
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSupported" -> {
                result.success(bluetoothAdapter != null)
            }
            "isEnabled" -> {
                result.success(bluetoothAdapter?.isEnabled == true)
            }
            "getBondedDevices" -> {
                getBondedDevices(result)
            }
            "startDiscovery" -> {
                startDiscovery(result)
            }
            "stopDiscovery" -> {
                stopDiscovery(result)
            }
            "connect" -> {
                val address = call.argument<String>("address")
                if (address == null) {
                    result.error("INVALID_ARGUMENT", "Address cannot be null", null)
                } else {
                    connect(address, result)
                }
            }
            "disconnect" -> {
                disconnect(result)
            }
            "send" -> {
                val data = call.argument<String>("data")
                if (data == null) {
                    result.error("INVALID_ARGUMENT", "Data cannot be null", null)
                } else {
                    sendData(data, result)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun getBondedDevices(result: MethodChannel.Result) {
        if (bluetoothAdapter == null) {
            result.success(emptyList<Map<String, Any?>>())
            return
        }
        val bonded = bluetoothAdapter.bondedDevices ?: emptySet()
        val list = bonded.map { device ->
            mapOf(
                "name" to (device.name ?: "未知设备"),
                "address" to device.address,
                "type" to "classic",
                "bonded" to true,
                "rssi" to 0
            )
        }
        result.success(list)
    }

    private fun startDiscovery(result: MethodChannel.Result) {
        if (bluetoothAdapter == null) {
            result.error("BLUETOOTH_UNAVAILABLE", "Bluetooth not supported", null)
            return
        }

        if (!isReceiverRegistered) {
            val filter = IntentFilter().apply {
                addAction(BluetoothDevice.ACTION_FOUND)
                addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
            }
            context.registerReceiver(discoveryReceiver, filter)
            isReceiverRegistered = true
        }

        discoveredDevices.clear()

        // 默认将已配对设备加入列表，确保第一时间看到
        bluetoothAdapter.bondedDevices?.forEach { device ->
            discoveredDevices[device.address] = mapOf(
                "name" to (device.name ?: "未知设备"),
                "address" to device.address,
                "type" to "classic",
                "bonded" to true,
                "rssi" to 0
            )
        }
        deviceSink?.success(discoveredDevices.values.toList())

        if (bluetoothAdapter.isDiscovering) {
            bluetoothAdapter.cancelDiscovery()
        }
        val started = bluetoothAdapter.startDiscovery()
        result.success(started)
    }

    private fun stopDiscovery(result: MethodChannel.Result) {
        if (bluetoothAdapter?.isDiscovering == true) {
            bluetoothAdapter.cancelDiscovery()
        }
        result.success(true)
    }

    private fun connect(address: String, result: MethodChannel.Result) {
        if (bluetoothAdapter == null) {
            result.error("BLUETOOTH_UNAVAILABLE", "Bluetooth not supported", null)
            return
        }

        executor.execute {
            try {
                // 连接前必须停止搜索，否则严重影响 SPP 传输带宽与延迟
                if (bluetoothAdapter.isDiscovering) {
                    bluetoothAdapter.cancelDiscovery()
                }

                notifyState("connecting")

                // 关闭旧连接
                closeSocket()

                val device = bluetoothAdapter.getRemoteDevice(address)
                // 尝试标准 SPP UUID 连接
                var socket: BluetoothSocket? = null
                try {
                    socket = device.createRfcommSocketToServiceRecord(SPP_UUID)
                    socket.connect()
                } catch (e: Exception) {
                    // 部分 Android 固件对 SPP 握手需要使用反射 fallback 建立非安全通道
                    try {
                        val method = device.javaClass.getMethod("createRfcommSocket", Int::class.javaPrimitiveType)
                        socket = method.invoke(device, 1) as BluetoothSocket
                        socket.connect()
                    } catch (e2: Exception) {
                        throw IOException("SPP 连接失败: ${e.message} / ${e2.message}")
                    }
                }

                currentSocket = socket
                outputStream = socket.outputStream
                isReading = true

                notifyState("connected")
                mainHandler.post { result.success(true) }

                // 启动后台读取线程，按行 '\n' 切割
                startReading(socket)

            } catch (e: Exception) {
                closeSocket()
                notifyState("disconnected")
                mainHandler.post {
                    result.error("CONNECT_FAILED", e.message, null)
                }
            }
        }
    }

    private fun startReading(socket: BluetoothSocket) {
        executor.execute {
            try {
                val reader = BufferedReader(InputStreamReader(socket.inputStream, Charsets.UTF_8))
                while (isReading && socket.isConnected) {
                    val line = reader.readLine() ?: break
                    val trimmed = line.trim()
                    if (trimmed.isNotEmpty()) {
                        mainHandler.post {
                            dataSink?.success(trimmed)
                        }
                    }
                }
            } catch (e: Exception) {
                // 读取断开
            } finally {
                if (isReading) {
                    closeSocket()
                    notifyState("disconnected")
                }
            }
        }
    }

    private fun sendData(data: String, result: MethodChannel.Result) {
        val out = outputStream
        if (out == null || currentSocket?.isConnected != true) {
            result.error("NOT_CONNECTED", "Bluetooth SPP socket is not connected", null)
            return
        }

        executor.execute {
            try {
                // 按照交接文档规范，以 \r\n 分帧发送 UTF-8 字节
                val payload = if (data.endsWith("\r\n")) data else if (data.endsWith("\n")) data.replace("\n", "\r\n") else "$data\r\n"
                out.write(payload.toByteArray(Charsets.UTF_8))
                out.flush()
                mainHandler.post { result.success(true) }
            } catch (e: Exception) {
                mainHandler.post {
                    result.error("SEND_FAILED", e.message, null)
                }
            }
        }
    }

    private fun disconnect(result: MethodChannel.Result) {
        executor.execute {
            closeSocket()
            notifyState("disconnected")
            mainHandler.post { result.success(true) }
        }
    }

    private fun closeSocket() {
        isReading = false
        try {
            outputStream?.close()
        } catch (_: Exception) {}
        outputStream = null

        try {
            currentSocket?.close()
        } catch (_: Exception) {}
        currentSocket = null
    }

    private fun notifyState(state: String) {
        mainHandler.post {
            stateSink?.success(state)
        }
    }

    fun cleanUp() {
        if (isReceiverRegistered) {
            try {
                context.unregisterReceiver(discoveryReceiver)
            } catch (_: Exception) {}
            isReceiverRegistered = false
        }
        closeSocket()
    }
}
