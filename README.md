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
  sunmi_external_cloud_printer: ^0.1.0
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
    ..setAlignment(PrintAlignment.center)
    ..setCharacterSize(2, 2)
    ..appendText('RECEIPT\n')
    ..setCharacterSize(1, 1)
    ..setAlignment(PrintAlignment.left)
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

### 4 — Check status and disconnect

```dart
final status = await printer.getStatus();
print('Ready: ${status.isReady} — ${status.description}');

await printer.disconnect();
```

A full working example is available in the [`/example`](example) folder.

## API reference

### `SunmiExternalCloudPrinter`

| Method | Returns | Description |
|---|---|---|
| `scan({int timeoutSeconds})` | `Future<List<DiscoveredPrinter>>` | Scans for nearby printers |
| `connect(String id)` | `Future<bool>` | Connects to a printer by ID |
| `isConnected()` | `Future<bool>` | Whether a printer is currently connected |
| `disconnect()` | `Future<void>` | Disconnects and releases the connection |
| `getStatus()` | `Future<PrinterStatus>` | Returns current printer status |
| `commit(PrintJob job)` | `Future<PrintResult>` | Executes all job commands and flushes to printer |

### `PrintJob` commands

| Method | Description |
|---|---|
| `initStyle()` | Resets all style settings to defaults |
| `setAlignment(PrintAlignment)` | `left`, `center`, or `right` |
| `setCharacterSize(int w, int h)` | Width and height multiplier 1–4 |
| `setBold({required bool enabled})` | Bold on/off |
| `appendText(String text)` | Appends text; use `\n` for line breaks |
| `lineFeed([int lines])` | Feeds blank lines (default 1) |
| `cutPaper({bool partial})` | Full cut (default) or partial cut |
| `printQrCode(String data, {int size, QrErrorLevel errorLevel})` | Prints a QR code |

## Additional information

- **Issues:** [github.com/YaserH25/sunmi_external_cloud_printer/issues](https://github.com/YaserH25/sunmi_external_cloud_printer/issues)
- **Repository:** [github.com/YaserH25/sunmi_external_cloud_printer](https://github.com/YaserH25/sunmi_external_cloud_printer)
- Contributions are welcome — please open an issue before submitting a large PR.
- Responses to issues are provided on a best-effort basis.
