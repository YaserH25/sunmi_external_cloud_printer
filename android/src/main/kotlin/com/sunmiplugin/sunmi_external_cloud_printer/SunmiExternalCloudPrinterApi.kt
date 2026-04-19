package com.sunmiplugin.sunmi_external_cloud_printer

// Shared data types and handler interfaces for the Sunmi External Cloud Printer plugin.

enum class ImageAlgorithmMessage(val raw: Int) {
    BINARIZATION(0), DITHERING(1);

    companion object {
        fun ofRaw(raw: Int): ImageAlgorithmMessage = values().first { it.raw == raw }
    }
}

class FlutterError(
    val code: String,
    override val message: String? = null,
    val details: Any? = null,
) : Throwable()

data class DiscoveredPrinterMessage(
    val id: String,
    val name: String,
    val connectionType: String,
    val address: String,
    val port: Long,
    val mac: String,
    val vid: Long,
    val pid: Long,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "id" to id,
        "name" to name,
        "connectionType" to connectionType,
        "address" to address,
        "port" to port,
        "mac" to mac,
        "vid" to vid,
        "pid" to pid,
    )
}

data class PrinterStatusMessage(
    val isReady: Boolean,
    val description: String,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "isReady" to isReady,
        "description" to description,
    )
}

data class PrintResultMessage(
    val success: Boolean,
    val message: String,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "success" to success,
        "message" to message,
    )
}

enum class PrintAlignmentMessage(val raw: Int) {
    LEFT(0), CENTER(1), RIGHT(2);

    companion object {
        fun ofRaw(raw: Int): PrintAlignmentMessage = values().first { it.raw == raw }
    }
}

enum class QrErrorLevelMessage(val raw: Int) {
    L(0), M(1), Q(2), H(3);

    companion object {
        fun ofRaw(raw: Int): QrErrorLevelMessage = values().first { it.raw == raw }
    }
}

interface SunmiDeviceApi {
    fun scanPrinters(timeoutSeconds: Long, callback: (Result<List<DiscoveredPrinterMessage>>) -> Unit)
    fun connect(id: String, callback: (Result<Boolean>) -> Unit)
    fun isConnected(): Boolean
    fun disconnect()
    fun getStatus(callback: (Result<PrinterStatusMessage>) -> Unit)
}

interface SunmiPrintApi {
    fun initStyle()
    fun setAlignment(alignment: PrintAlignmentMessage)
    fun setCharacterSize(width: Long, height: Long)
    fun setBold(enabled: Boolean)
    fun appendText(text: String)
    fun appendImage(bytes: ByteArray, algorithm: ImageAlgorithmMessage)
    fun lineFeed(lines: Long)
    fun cutPaper(partial: Boolean)
    fun printQrCode(data: String, size: Long, errorLevel: QrErrorLevelMessage)
    fun commit(callback: (Result<PrintResultMessage>) -> Unit)
}
