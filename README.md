# sunmi_external_cloud_printer

A Flutter plugin for Sunmi external cloud printers — **NT21x, NT31x, and NT32x** series — over **USB, LAN, and Bluetooth**. Android only.

## Features

- Scan for nearby Sunmi cloud printers (USB, LAN, Bluetooth)
- Connect and disconnect by printer ID
- Query printer status (`isReady`, description)
- Build and commit rich print jobs with a fluent `PrintJob` API:
  - Text alignment (left / center / right)
  - Character size multiplier (width × height, 1–4)
  - Bold text
  - Fixed-width column rows for label/value printing
  - Bitmap/image printing for Arabic-safe output
  - Line feeds
  - Full or partial paper cut
  - QR code printing (size 1–16, four error-correction levels)

## Getting started

**Prerequisites**

- Android only (iOS is not supported by Sunmi hardware)
- Flutter `>=3.3.0`, Dart SDK `>=3.8.1`
- A physical Sunmi NT21x, NT31x, or NT32x device

**Add the dependency**

```yaml
dependencies:
  sunmi_external_cloud_printer: ^0.4.0
```

Then run:

```sh
flutter pub get
```

No additional Android permissions are required beyond those already declared by the plugin.

## Usage

### 1 — Scan for printers

```dart
import 'package:sunmi_external_cloud_printer/sunmi_external_cloud_printer.dart';

final printer = SunmiExternalCloudPrinter();

final printers = await printer.scan(timeoutSeconds: 5);
for (final p in printers) {
  print('${p.name} [${p.connectionType}] — ${p.id}');
}
```

### 2 — Connect

```dart
final connected = await printer.connect(printers.first.id);
if (!connected) {
  print('Connection failed');
  return;
}
```

### 3 — Build and commit a print job

```dart
final result = await printer.commit(
  PrintJob()
    ..initStyle()
    ..setAlignment(SunmiPrintAlignment.center)
    ..setCharacterSize(2, 2)
    ..appendText('RECEIPT\n')
    ..setCharacterSize(1, 1)
    ..setAlignment(SunmiPrintAlignment.left)
    ..appendText('Item 1 ............... 10.00\n')
    ..appendText('Item 2 ............... 25.00\n')
    ..setBold(enabled: true)
    ..appendText('Total ................ 35.00\n')
    ..setBold(enabled: false)
    ..printQrCode('https://example.com/order/123', size: 6)
    ..lineFeed(3)
    ..cutPaper(),
);

if (result.success) {
  print('Printed: ${result.message}');
} else {
  print('Error: ${result.message}');
}
```

### 3.1 — Print label/value on one line

```dart
final result = await printer.commit(
  PrintJob()
    ..initStyle()
    ..printColumnsText(
      ['Total', '35.00'],
      [12, 12],
      [SunmiPrintAlignment.left, SunmiPrintAlignment.right],
    )
    ..printColumnsText(
      ['Tax', '5.00'],
      [12, 12],
      [SunmiPrintAlignment.left, SunmiPrintAlignment.right],
    )
    ..lineFeed(2)
    ..cutPaper(),
);
```

Use `printColumnsText()` when the label should start at the left edge and the
value should end at the right edge of the same row. The three lists must have
the same length, and each width must be a positive character width.

### 4 — Check status and disconnect

```dart
final status = await printer.getStatus();
print('Ready: ${status.isReady} — ${status.description}');

await printer.disconnect();
```

A full working example is available in the [`/example`](example) folder.

## Connection types

The plugin supports three physical connection modes. When `scan()` is called, all three are probed simultaneously. Each discovered printer exposes its type via `SunmiDiscoveredPrinter.connectionType` (`"USB"`, `"LAN"`, or `"Bluetooth"`).

### USB

- Plug the printer into the Android device's USB-A or USB-C (OTG) port.
- No pairing or network configuration is required.
- `SunmiDiscoveredPrinter.vid` and `.pid` hold the USB vendor ID and product ID respectively (useful for filtering specific hardware).
- The plugin holds a USB device claim for the duration of the connection; call `disconnect()` to release it before the app goes to the background if you need to share the port.
- **Priority:** USB connections are preferred when auto-selecting (USB → LAN → Bluetooth).

### LAN (Local Area Network)

- Printer and device must be on the **same Wi-Fi or Ethernet segment**.
- `SunmiDiscoveredPrinter.address` contains the printer's IPv4 address and `.port` contains the TCP port (default `9100`).
- Static IP assignment on the printer is recommended for production deployments to avoid address changes between scans.
- Discovery uses UDP broadcast; ensure the network does not block broadcast traffic between subnets.
- The connection is a persistent TCP socket; if the socket drops (e.g. DHCP lease renewal), call `disconnect()` then `connect()` again.

### Bluetooth

- Supports Bluetooth Classic (SPP profile). Bluetooth LE is **not** supported.
- Pair the printer with the Android device via **Settings → Bluetooth** before scanning — the plugin does not handle the pairing handshake.
- `SunmiDiscoveredPrinter.mac` holds the Bluetooth MAC address (e.g. `"AA:BB:CC:DD:EE:FF"`).
- Bluetooth range is typically 5–10 m; signal drops will cause the connection to time out. Add retry logic in production apps.
- Android 12+ requires the `BLUETOOTH_CONNECT` and `BLUETOOTH_SCAN` runtime permissions. Declare and request them in your app before calling `scan()`.

## API reference

### `SunmiExternalCloudPrinter`

| Method | Returns | Description |
|---|---|---|
| `scan({int timeoutSeconds})` | `Future<List<SunmiDiscoveredPrinter>>` | Scans for nearby printers |
| `connect(String id)` | `Future<bool>` | Connects to a printer by ID |
| `isConnected()` | `Future<bool>` | Whether a printer is currently connected |
| `disconnect()` | `Future<void>` | Disconnects and releases the connection |
| `getStatus()` | `Future<SunmiPrinterStatus>` | Returns current printer status |
| `commit(PrintJob job)` | `Future<SunmiPrintResult>` | Executes all job commands and flushes to printer |

### `PrintJob` commands

| Method | Description |
|---|---|
| `initStyle()` | Resets all style settings to defaults |
| `setAlignment(SunmiPrintAlignment)` | `left`, `center`, or `right` |
| `setCharacterSize(int w, int h)` | Width and height multiplier 1–4 |
| `setBold({required bool enabled})` | Bold on/off |
| `setEncodeMode(SunmiEncodeType)` | Experimental printer text encoding control |
| `selectOtherCharFont(int select)` | Experimental font selection for non-ASCII/CJK characters |
| `setOtherSize(int size)` | Experimental size control for other-character vector fonts |
| `appendText(String text)` | Appends text; use `\n` for line breaks |
| `printColumnsText(List<String> texts, List<int> widths, List<SunmiPrintAlignment> alignments)` | Prints one row using fixed-width columns |
| `appendRawData(Uint8List data)` | Experimental raw printer bytes / ESC-POS pass-through |
| `appendImage(Uint8List bytes, {SunmiImageAlgorithm algorithm})` | Appends a bitmap image from encoded bytes |
| `lineFeed([int lines])` | Feeds blank lines (default 1) |
| `cutPaper({bool partial})` | Full cut (default) or partial cut |
| `printQrCode(String data, {int size, SunmiQrErrorLevel errorLevel})` | Prints a QR code |

## Arabic text

The printer SDK text mode may not shape Arabic correctly. For Arabic receipts,
render the text in Flutter and send it as an image instead of using
`appendText()`.

```dart
final Uint8List arabicReceiptBytes = ...; // PNG/JPG bytes rendered in Flutter

final result = await printer.commit(
  PrintJob()
    ..appendImage(arabicReceiptBytes)
    ..lineFeed(3)
    ..cutPaper(),
);
```

`appendImage()` accepts encoded image bytes that Android can decode, such as
PNG and JPG. `SunmiImageAlgorithm.binarization` is the default; if your output
looks harsh on gradients, try `SunmiImageAlgorithm.dithering`.

## Experimental text-mode controls

The Sunmi SDK exposes text-mode knobs that may help on some firmware, but they
do not guarantee Arabic shaping or RTL layout. Use them only for device-specific
testing.

```dart
final result = await printer.commit(
  PrintJob()
    ..initStyle()
    ..setEncodeMode(SunmiEncodeType.utf8)
    ..selectOtherCharFont(1)
    ..setOtherSize(28)
    ..appendText('مرحبا\n')
    ..lineFeed(3)
    ..cutPaper(),
);
```

Notes:

- `SunmiEncodeType.utf8` only changes byte decoding in the printer pipeline.
- `selectOtherCharFont()` depends on printer firmware and any preloaded fonts.
- `appendRawData()` is intended for controlled ESC/POS experiments.
- If Arabic still prints as disconnected or garbled glyphs, use `appendImage()` instead.

## Additional information

- **Issues:** [github.com/YaserH25/sunmi_external_cloud_printer/issues](https://github.com/YaserH25/sunmi_external_cloud_printer/issues)
- **Repository:** [github.com/YaserH25/sunmi_external_cloud_printer](https://github.com/YaserH25/sunmi_external_cloud_printer)
- Contributions are welcome — please open an issue before submitting a large PR.
- Responses to issues are provided on a best-effort basis.
