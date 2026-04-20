## 0.4.0

* Added `PrintJob.printColumnsText(...)` for fixed-width multi-column receipt rows.
* Added native Android method-channel support for Sunmi SDK `printColumnsText(...)`.
* Added argument validation for column text, width, and alignment payloads.
* Expanded README usage examples for left-label/right-value printing.

## 0.3.0

* Added bitmap/image printing support via `PrintJob.appendImage(...)`.
* Added `SunmiImageAlgorithm` to control printer image rasterization.
* Added Arabic-safe printing guidance and example flow by rendering receipts as images in Flutter.
* Added experimental text-mode controls for `setEncodeMode`, `selectOtherCharFont`, `setOtherSize`, and `appendRawData`.

## 0.2.0

* Renamed public model classes to `Sunmi`-prefixed names: `SunmiDiscoveredPrinter`, `SunmiPrinterStatus`, `SunmiPrintResult`, `SunmiPrintAlignment`, `SunmiQrErrorLevel`.
* Expanded README with detailed connection-type documentation (USB, LAN, Bluetooth).

## 0.1.0

* Initial release of the Sunmi External Cloud Printer plugin.
* Support for USB, LAN, and Bluetooth connectivity on Android.
* Support for Sunmi NT21x, NT31x, and NT32x printer models.
* Printer discovery via `discoverPrinters()`.
* Print text, QR codes, barcodes, and images.
* Configurable print alignment, QR error correction level, and paper cut options.
* `PrintJob` builder API for composing multi-element print jobs.
* `PrinterStatus` and `PrintResult` models for status and result handling.

## 0.0.1

* TODO: Describe initial release.
