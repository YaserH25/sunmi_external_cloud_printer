// Tests for the SunmiExternalCloudPrinter plugin.
// Unit tests require mocking the native APIs since the Android SDK cannot be
// loaded on the host machine. When writing unit tests, inject mock
// SunmiDeviceApi / SunmiPrintApi via the SunmiExternalCloudPrinter constructor.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sunmi_external_cloud_printer/sunmi_external_cloud_printer.dart';
import 'package:sunmi_external_cloud_printer/src/sunmi_external_cloud_printer_api.dart';

void main() {
  test('appendImage forwards bytes and algorithm to print api', () async {
    final api = _FakePrintApi();

    await PrintJob().appendImage(
      Uint8List.fromList([1, 2, 3]),
      algorithm: SunmiImageAlgorithm.dithering,
    ).execute(api);

    expect(api.imageBytes, [1, 2, 3]);
    expect(api.imageAlgorithm, ImageAlgorithmMessage.dithering);
  });
}

final class _FakePrintApi extends SunmiPrintApi {
  Uint8List? imageBytes;
  ImageAlgorithmMessage? imageAlgorithm;

  @override
  Future<void> appendImage(
    Uint8List bytes,
    ImageAlgorithmMessage algorithm,
  ) async {
    imageBytes = bytes;
    imageAlgorithm = algorithm;
  }

  @override
  Future<void> appendText(String text) async {}

  @override
  Future<PrintResultMessage> commit() async =>
      PrintResultMessage(success: true, message: 'ok');

  @override
  Future<void> cutPaper(bool partial) async {}

  @override
  Future<void> initStyle() async {}

  @override
  Future<void> lineFeed(int lines) async {}

  @override
  Future<void> printQrCode(
    String data,
    int size,
    QrErrorLevelMessage errorLevel,
  ) async {}

  @override
  Future<void> setAlignment(PrintAlignmentMessage alignment) async {}

  @override
  Future<void> setBold(bool enabled) async {}

  @override
  Future<void> setCharacterSize(int width, int height) async {}
}
