import 'package:sunmi_external_cloud_printer/src/models.dart';
import 'package:sunmi_external_cloud_printer/src/print_job.dart';
import 'package:sunmi_external_cloud_printer/src/sunmi_external_cloud_printer_api.dart';

export 'models.dart';
export 'print_job.dart' show PrintJob;

/// High-level Dart API for Sunmi external cloud printers (NT21x / NT31x / NT32x).
///
/// **Android only.** Wraps the [SunmiDeviceApi] and
/// [SunmiPrintApi] channels with a clean, model-typed surface.
///
/// Typical usage:
/// ```dart
/// final printer = SunmiExternalCloudPrinter();
///
/// final printers = await printer.scan();
/// if (printers.isEmpty) return;
///
/// final connected = await printer.connect(printers.first.id);
/// if (!connected) return;
///
/// final result = await printer.commit(
///   PrintJob()
///     ..setAlignment(PrintAlignment.center)
///     ..appendText('Hello, Sunmi!\n')
///     ..lineFeed(3)
///     ..cutPaper(),
/// );
/// ```
class SunmiExternalCloudPrinter {
  SunmiExternalCloudPrinter({
    SunmiDeviceApi? deviceApi,
    SunmiPrintApi? printApi,
  }) : _device = deviceApi ?? SunmiDeviceApi(),
       _print = printApi ?? SunmiPrintApi();

  final SunmiDeviceApi _device;
  final SunmiPrintApi _print;

  /// Scans for nearby printers for [timeoutSeconds] and returns the results.
  ///
  /// Connection priority when auto-connecting: USB → LAN → Bluetooth.
  Future<List<DiscoveredPrinter>> scan({int timeoutSeconds = 5}) async {
    final messages = await _device.scanPrinters(timeoutSeconds);
    return messages.map(_fromMessage).toList();
  }

  /// Connects to the printer identified by [id] (returned from [scan]).
  ///
  /// Returns `true` on success.
  Future<bool> connect(String id) => _device.connect(id);

  /// Returns `true` if a printer is currently connected.
  Future<bool> isConnected() async => _device.isConnected();

  /// Disconnects and releases the current printer connection.
  Future<void> disconnect() async => _device.disconnect();

  /// Returns the current status of the connected printer.
  Future<PrinterStatus> getStatus() async {
    final msg = await _device.getStatus();
    return PrinterStatus(isReady: msg.isReady, description: msg.description);
  }

  /// Executes all commands in [job] and flushes the buffer to the printer.
  ///
  /// Returns a [PrintResult] indicating success or failure.
  Future<PrintResult> commit(PrintJob job) async {
    await job.execute(_print);
    final msg = await _print.commit();
    return PrintResult(success: msg.success, message: msg.message);
  }

  // -------------------------------------------------------------------------

  static DiscoveredPrinter _fromMessage(DiscoveredPrinterMessage m) =>
      DiscoveredPrinter(
        id: m.id,
        name: m.name,
        connectionType: m.connectionType,
        address: m.address,
        port: m.port.toInt(),
        mac: m.mac,
        vid: m.vid.toInt(),
        pid: m.pid.toInt(),
      );
}
