package com.sunmiplugin.sunmi_external_cloud_printer

import android.graphics.BitmapFactory
import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

// ---------------------------------------------------------------------------
// Sunmi Cloud Printer SDK — com.sunmi:external-printerlibrary2
// Docs: https://developer.sunmi.com/docs/en-US/cdixeghjk491/xfzxeghjk491
// ---------------------------------------------------------------------------
import com.sunmi.externalprinterlibrary2.ConnectCallback
import com.sunmi.externalprinterlibrary2.ResultCallback
import com.sunmi.externalprinterlibrary2.SearchCallback
import com.sunmi.externalprinterlibrary2.SearchMethod
import com.sunmi.externalprinterlibrary2.StatusCallback
import com.sunmi.externalprinterlibrary2.SunmiPrinterManager
import com.sunmi.externalprinterlibrary2.printer.CloudPrinter
import com.sunmi.externalprinterlibrary2.printer.CloudPrinterInfo
import com.sunmi.externalprinterlibrary2.style.AlignStyle
import com.sunmi.externalprinterlibrary2.style.CloudPrinterStatus
import com.sunmi.externalprinterlibrary2.style.ErrorLevel
import com.sunmi.externalprinterlibrary2.style.ImageAlgorithm

/** Flutter plugin entry point for the Sunmi External Cloud Printer SDK. */
class SunmiExternalCloudPrinterPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private var channel: MethodChannel? = null
    private var deviceHandler: SunmiDeviceHandler? = null
    private var printHandler: SunmiPrintHandler? = null
    // Holds an SDK init error so it can be surfaced to Dart rather than crashing the app.
    private var initError: String? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // Register the channel first so Dart calls always get a proper reply.
        channel = MethodChannel(binding.binaryMessenger, "com.sunmiplugin.sunmi_external_cloud_printer")
        channel!!.setMethodCallHandler(this)

        try {
            val manager = SunmiManagerAccessor.get()
            val state = SharedPrinterState()
            deviceHandler = SunmiDeviceHandler(binding.applicationContext, manager, state)
            printHandler = SunmiPrintHandler(state)
        } catch (e: Exception) {
            initError = "Sunmi SDK init failed: ${e.message}"
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        deviceHandler = null
        printHandler = null
        initError = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val err = initError
        if (err != null) {
            result.error("SDK_INIT_FAILED", err, null)
            return
        }
        val device = deviceHandler ?: run { result.error("NOT_INIT", "Plugin not initialized", null); return }
        val print = printHandler ?: run { result.error("NOT_INIT", "Plugin not initialized", null); return }

        when (call.method) {
            // -- Device API --
            "scanPrinters" -> {
                val timeout = (call.argument<Int>("timeoutSeconds") ?: 5).toLong()
                device.scanPrinters(timeout) { res ->
                    res.fold(
                        onSuccess = { list -> result.success(list.map { it.toMap() }) },
                        onFailure = { e -> result.error("SCAN_ERROR", e.message, null) },
                    )
                }
            }
            "connect" -> {
                val id = call.argument<String>("id")!!
                device.connect(id) { res ->
                    res.fold(
                        onSuccess = { connected -> result.success(connected) },
                        onFailure = { e ->
                            val code = if (e is FlutterError) e.code else "CONNECT_ERROR"
                            result.error(code, e.message, null)
                        },
                    )
                }
            }
            "isConnected" -> result.success(device.isConnected())
            "disconnect" -> { device.disconnect(); result.success(null) }
            "getStatus" -> {
                device.getStatus { res ->
                    res.fold(
                        onSuccess = { status -> result.success(status.toMap()) },
                        onFailure = { e -> result.error("STATUS_ERROR", e.message, null) },
                    )
                }
            }

            // -- Print API --
            "initStyle" -> runPrint(result) { print.initStyle() }
            "setAlignment" -> {
                val idx = call.argument<Int>("alignment") ?: 0
                runPrint(result) { print.setAlignment(PrintAlignmentMessage.ofRaw(idx)) }
            }
            "setCharacterSize" -> {
                val w = (call.argument<Int>("width") ?: 1).toLong()
                val h = (call.argument<Int>("height") ?: 1).toLong()
                runPrint(result) { print.setCharacterSize(w, h) }
            }
            "setBold" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                runPrint(result) { print.setBold(enabled) }
            }
            "appendText" -> {
                val text = call.argument<String>("text") ?: ""
                runPrint(result) { print.appendText(text) }
            }
            "appendImage" -> {
                val bytes = call.argument<ByteArray>("bytes") ?: byteArrayOf()
                val algorithm = ImageAlgorithmMessage.ofRaw(call.argument<Int>("algorithm") ?: 0)
                runPrint(result) { print.appendImage(bytes, algorithm) }
            }
            "lineFeed" -> {
                val lines = (call.argument<Int>("lines") ?: 1).toLong()
                runPrint(result) { print.lineFeed(lines) }
            }
            "cutPaper" -> {
                val partial = call.argument<Boolean>("partial") ?: false
                runPrint(result) { print.cutPaper(partial) }
            }
            "printQrCode" -> {
                val data = call.argument<String>("data") ?: ""
                val size = (call.argument<Int>("size") ?: 6).toLong()
                val level = QrErrorLevelMessage.ofRaw(call.argument<Int>("errorLevel") ?: 1)
                runPrint(result) { print.printQrCode(data, size, level) }
            }
            "commit" -> {
                print.commit { res ->
                    res.fold(
                        onSuccess = { pr -> result.success(pr.toMap()) },
                        onFailure = { e -> result.error("PRINT_ERROR", e.message, null) },
                    )
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun runPrint(result: MethodChannel.Result, block: () -> Unit) {
        try {
            block()
            result.success(null)
        } catch (e: FlutterError) {
            result.error(e.code, e.message, null)
        } catch (e: Exception) {
            result.error("PRINT_ERROR", e.message, null)
        }
    }
}

// ---------------------------------------------------------------------------
// Shared mutable state between device and print handlers
// ---------------------------------------------------------------------------

internal class SharedPrinterState {
    val discovered: MutableMap<String, CloudPrinter> = mutableMapOf()
    @Volatile var connected: CloudPrinter? = null
}

// ---------------------------------------------------------------------------
// Device handler
// ---------------------------------------------------------------------------

internal class SunmiDeviceHandler(
    private val context: Context,
    private val manager: SunmiPrinterManager,
    private val state: SharedPrinterState,
) : SunmiDeviceApi {

    private val mainHandler = Handler(Looper.getMainLooper())
    private val searchMethods = listOf(SearchMethod.USB, SearchMethod.LAN, SearchMethod.BT)

    override fun scanPrinters(
        timeoutSeconds: Long,
        callback: (Result<List<DiscoveredPrinterMessage>>) -> Unit,
    ) {
        val found: MutableMap<String, Pair<DiscoveredPrinterMessage, CloudPrinter>> = mutableMapOf()

        val searchCallback = object : SearchCallback {
            override fun onFound(printer: CloudPrinter) {
                val info = printer.getCloudPrinterInfo()
                val id = buildId(info)
                synchronized(found) { found.putIfAbsent(id, Pair(infoToMessage(info, id), printer)) }
            }
        }

        for (method in searchMethods) {
            try { manager.searchCloudPrinter(context, method, searchCallback) } catch (_: Exception) {}
        }

        mainHandler.postDelayed({
            for (method in searchMethods) {
                try { manager.stopSearch(context, method) } catch (_: Exception) {}
            }
            synchronized(found) {
                synchronized(state.discovered) {
                    state.discovered.clear()
                    found.forEach { (id, pair) -> state.discovered[id] = pair.second }
                }
            }
            val list = synchronized(found) { found.values.map { it.first } }
            callback(Result.success(list))
        }, timeoutSeconds * 1_000L)
    }

    override fun connect(id: String, callback: (Result<Boolean>) -> Unit) {
        val printer = synchronized(state.discovered) { state.discovered[id] }
            ?: run {
                callback(Result.failure(FlutterError("NOT_FOUND", "Printer '$id' not found. Run scanPrinters first.", null)))
                return
            }

        if (printer.isConnected()) {
            state.connected = printer
            callback(Result.success(true))
            return
        }

        val called = AtomicBoolean(false)
        printer.connect(context, object : ConnectCallback {
            override fun onConnect() {
                if (called.compareAndSet(false, true)) {
                    state.connected = printer
                    mainHandler.post { callback(Result.success(true)) }
                }
            }
            override fun onFailed(error: String?) {
                if (called.compareAndSet(false, true)) {
                    mainHandler.post { callback(Result.success(false)) }
                }
            }
            override fun onDisConnect() {
                if (state.connected == printer) state.connected = null
            }
        })
    }

    override fun isConnected(): Boolean = state.connected?.isConnected() ?: false

    override fun disconnect() {
        state.connected?.release(context)
        state.connected = null
    }

    override fun getStatus(callback: (Result<PrinterStatusMessage>) -> Unit) {
        val printer = state.connected
            ?: run {
                callback(Result.success(PrinterStatusMessage(false, "No printer connected")))
                return
            }
        printer.getDeviceState(object : StatusCallback {
            override fun onResult(status: CloudPrinterStatus) {
                mainHandler.post {
                    callback(Result.success(PrinterStatusMessage(
                        isReady = status == CloudPrinterStatus.RUNNING,
                        description = describeStatus(status),
                    )))
                }
            }
        })
    }

    private fun buildId(info: CloudPrinterInfo): String = when {
        !info.address.isNullOrEmpty() -> "lan:${info.address}:${info.port}"
        !info.mac.isNullOrEmpty() -> "bt:${info.mac}"
        else -> "usb:${info.vid}:${info.pid}"
    }

    private fun infoToMessage(info: CloudPrinterInfo, id: String): DiscoveredPrinterMessage =
        DiscoveredPrinterMessage(
            id = id,
            name = info.name ?: "",
            connectionType = when {
                !info.address.isNullOrEmpty() -> "LAN"
                !info.mac.isNullOrEmpty() -> "Bluetooth"
                else -> "USB"
            },
            address = info.address ?: "",
            port = info.port.toLong(),
            mac = info.mac ?: "",
            vid = info.vid.toLong(),
            pid = info.pid.toLong(),
        )

    private fun describeStatus(status: CloudPrinterStatus): String = when (status) {
        CloudPrinterStatus.RUNNING -> "Ready"
        CloudPrinterStatus.OFFLINE -> "Offline"
        CloudPrinterStatus.UNKNOWN -> "Unknown"
        CloudPrinterStatus.NEAR_OUT_PAPER -> "Paper running low"
        CloudPrinterStatus.OUT_PAPER -> "Out of paper"
        CloudPrinterStatus.JAM_PAPER -> "Paper jam"
        CloudPrinterStatus.PICK_PAPER -> "Paper not taken"
        CloudPrinterStatus.COVER -> "Cover open"
        CloudPrinterStatus.OVER_HOT -> "Printer overheated"
        CloudPrinterStatus.MOTOR_HOT -> "Motor overheated"
        else -> "Unknown status: $status"
    }
}

// ---------------------------------------------------------------------------
// Print handler
// ---------------------------------------------------------------------------

internal class SunmiPrintHandler(private val state: SharedPrinterState) : SunmiPrintApi {

    private val mainHandler = Handler(Looper.getMainLooper())

    private fun requirePrinter(): CloudPrinter =
        state.connected ?: throw FlutterError("NOT_CONNECTED", "No printer connected", null)

    private fun runCmd(block: (CloudPrinter) -> Unit) {
        try { block(requirePrinter()) }
        catch (e: FlutterError) { throw e }
        catch (e: Exception) { throw FlutterError("PRINT_ERROR", e.message ?: "Unknown error", null) }
    }

    override fun initStyle() = runCmd { it.initStyle() }

    override fun setAlignment(alignment: PrintAlignmentMessage) = runCmd {
        it.setAlignment(when (alignment) {
            PrintAlignmentMessage.LEFT -> AlignStyle.LEFT
            PrintAlignmentMessage.CENTER -> AlignStyle.CENTER
            PrintAlignmentMessage.RIGHT -> AlignStyle.RIGHT
        })
    }

    override fun setCharacterSize(width: Long, height: Long) =
        runCmd { it.setCharacterSize(width.toInt(), height.toInt()) }

    override fun setBold(enabled: Boolean) = runCmd { it.setBoldMode(enabled) }

    override fun appendText(text: String) = runCmd { it.appendText(text) }

    override fun appendImage(bytes: ByteArray, algorithm: ImageAlgorithmMessage) = runCmd { printer ->
        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            ?: throw FlutterError("INVALID_IMAGE", "Image bytes could not be decoded on Android", null)
        printer.printImage(bitmap, when (algorithm) {
            ImageAlgorithmMessage.BINARIZATION -> ImageAlgorithm.BINARIZATION
            ImageAlgorithmMessage.DITHERING -> ImageAlgorithm.DITHERING
        })
    }

    override fun lineFeed(lines: Long) = runCmd { it.lineFeed(lines.toInt()) }

    // SDK: cutPaper(full) — true = full cut, false = half cut
    // Dart API: partial=false means full cut → invert
    override fun cutPaper(partial: Boolean) = runCmd { it.cutPaper(!partial) }

    override fun printQrCode(data: String, size: Long, errorLevel: QrErrorLevelMessage) = runCmd {
        it.printQrcode(data, size.toInt(), when (errorLevel) {
            QrErrorLevelMessage.L -> ErrorLevel.L
            QrErrorLevelMessage.M -> ErrorLevel.M
            QrErrorLevelMessage.Q -> ErrorLevel.Q
            QrErrorLevelMessage.H -> ErrorLevel.H
        })
    }

    override fun commit(callback: (Result<PrintResultMessage>) -> Unit) {
        val printer = try { requirePrinter() } catch (e: FlutterError) {
            callback(Result.success(PrintResultMessage(false, e.message ?: "Not connected")))
            return
        }
        try {
            printer.commitTransBuffer(object : ResultCallback {
                override fun onComplete() {
                    mainHandler.post { callback(Result.success(PrintResultMessage(true, "Printed successfully."))) }
                }
                override fun onFailed(status: CloudPrinterStatus) {
                    val desc = when (status) {
                        CloudPrinterStatus.OFFLINE -> "Offline"
                        CloudPrinterStatus.OUT_PAPER -> "Out of paper"
                        CloudPrinterStatus.JAM_PAPER -> "Paper jam"
                        CloudPrinterStatus.COVER -> "Cover open"
                        CloudPrinterStatus.OVER_HOT -> "Printer overheated"
                        else -> status.name
                    }
                    mainHandler.post { callback(Result.success(PrintResultMessage(false, "Print failed: $desc"))) }
                }
            })
        } catch (e: Exception) {
            callback(Result.success(PrintResultMessage(false, e.message ?: "Unknown error")))
        }
    }
}

// ---------------------------------------------------------------------------
// SDK singleton accessor
// ---------------------------------------------------------------------------

internal object SunmiManagerAccessor {
    fun get(): SunmiPrinterManager {
        // Try the public static getInstance() first (standard SDK singleton).
        // Fall back to reflection for older/minified builds.
        return try {
            SunmiPrinterManager::class.java
                .getMethod("getInstance")
                .invoke(null) as SunmiPrinterManager
        } catch (_: Exception) {
            try {
                val enumClass = SunmiPrinterManager::class.java.declaredClasses
                    .find { it.simpleName == "SingletonEnum" }
                    ?: error("SingletonEnum not found")
                val singletonField = enumClass.getDeclaredField("SINGLETON").apply { isAccessible = true }
                val singleton = singletonField.get(null)
                val getInstance = enumClass.getDeclaredMethod("getInstance").apply { isAccessible = true }
                getInstance.invoke(singleton) as SunmiPrinterManager
            } catch (e: Exception) {
                throw IllegalStateException("Unable to access SunmiPrinterManager singleton", e)
            }
        }
    }
}
