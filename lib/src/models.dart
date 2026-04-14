/// Public model types for the Sunmi External Cloud Printer plugin.
library;

/// A printer discovered during a scan.
final class DiscoveredPrinter {
  const DiscoveredPrinter({
    required this.id,
    required this.name,
    required this.connectionType,
    required this.address,
    required this.port,
    required this.mac,
    required this.vid,
    required this.pid,
  });

  /// Unique identifier used to reference this printer in [SunmiExternalCloudPrinter.connect].
  final String id;

  /// Human-readable printer name.
  final String name;

  /// Connection medium: `"USB"`, `"LAN"`, or `"Bluetooth"`.
  final String connectionType;

  /// IP address (LAN only).
  final String address;

  /// TCP port (LAN only).
  final int port;

  /// Bluetooth MAC address (Bluetooth only).
  final String mac;

  /// USB vendor ID (USB only).
  final int vid;

  /// USB product ID (USB only).
  final int pid;

  @override
  String toString() =>
      'DiscoveredPrinter(id: $id, name: $name, type: $connectionType)';
}

/// Current status of a connected printer.
final class PrinterStatus {
  const PrinterStatus({required this.isReady, required this.description});

  /// Whether the printer is ready to accept print jobs.
  final bool isReady;

  /// Human-readable status description.
  final String description;

  @override
  String toString() =>
      'PrinterStatus(isReady: $isReady, description: $description)';
}

/// Result of a committed print job.
final class PrintResult {
  const PrintResult({required this.success, required this.message});

  /// Whether the job printed successfully.
  final bool success;

  /// Human-readable outcome message.
  final String message;

  @override
  String toString() => 'PrintResult(success: $success, message: $message)';
}

/// Text alignment choices.
enum PrintAlignment { left, center, right }

/// QR code error correction level.
enum QrErrorLevel { l, m, q, h }
