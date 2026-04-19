import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel(
  'com.sunmiplugin.sunmi_external_cloud_printer',
);

enum PrintAlignmentMessage { left, center, right }

enum ImageAlgorithmMessage { binarization, dithering }

enum EncodeTypeMessage { ascii, gb18030, big5, shiftJis, jis0208, ksc5601, utf8 }

enum QrErrorLevelMessage { l, m, q, h }

class DiscoveredPrinterMessage {
  DiscoveredPrinterMessage({
    required this.id,
    required this.name,
    required this.connectionType,
    required this.address,
    required this.port,
    required this.mac,
    required this.vid,
    required this.pid,
  });

  final String id;
  final String name;
  final String connectionType;
  final String address;
  final int port;
  final String mac;
  final int vid;
  final int pid;

  static DiscoveredPrinterMessage fromMap(Map<Object?, Object?> map) {
    return DiscoveredPrinterMessage(
      id: map['id'] as String,
      name: map['name'] as String,
      connectionType: map['connectionType'] as String,
      address: map['address'] as String,
      port: (map['port'] as num).toInt(),
      mac: map['mac'] as String,
      vid: (map['vid'] as num).toInt(),
      pid: (map['pid'] as num).toInt(),
    );
  }
}

class PrinterStatusMessage {
  PrinterStatusMessage({required this.isReady, required this.description});

  final bool isReady;
  final String description;

  static PrinterStatusMessage fromMap(Map<Object?, Object?> map) {
    return PrinterStatusMessage(
      isReady: map['isReady'] as bool,
      description: map['description'] as String,
    );
  }
}

class PrintResultMessage {
  PrintResultMessage({required this.success, required this.message});

  final bool success;
  final String message;

  static PrintResultMessage fromMap(Map<Object?, Object?> map) {
    return PrintResultMessage(
      success: map['success'] as bool,
      message: map['message'] as String,
    );
  }
}

class SunmiDeviceApi {
  Future<List<DiscoveredPrinterMessage>> scanPrinters(
    int timeoutSeconds,
  ) async {
    final List<Object?> result = await _channel.invokeMethod('scanPrinters', {
      'timeoutSeconds': timeoutSeconds,
    });
    return result
        .cast<Map<Object?, Object?>>()
        .map(DiscoveredPrinterMessage.fromMap)
        .toList();
  }

  Future<bool> connect(String id) async {
    final bool result = await _channel.invokeMethod('connect', {'id': id});
    return result;
  }

  Future<bool> isConnected() async {
    final bool result = await _channel.invokeMethod('isConnected');
    return result;
  }

  Future<void> disconnect() async {
    await _channel.invokeMethod('disconnect');
  }

  Future<PrinterStatusMessage> getStatus() async {
    final Map<Object?, Object?> map = await _channel.invokeMethod('getStatus');
    return PrinterStatusMessage.fromMap(map);
  }
}

class SunmiPrintApi {
  Future<void> initStyle() async {
    await _channel.invokeMethod('initStyle');
  }

  Future<void> setAlignment(PrintAlignmentMessage alignment) async {
    await _channel.invokeMethod('setAlignment', {'alignment': alignment.index});
  }

  Future<void> setCharacterSize(int width, int height) async {
    await _channel.invokeMethod('setCharacterSize', {
      'width': width,
      'height': height,
    });
  }

  Future<void> setBold(bool enabled) async {
    await _channel.invokeMethod('setBold', {'enabled': enabled});
  }

  Future<void> setEncodeMode(EncodeTypeMessage type) async {
    await _channel.invokeMethod('setEncodeMode', {'type': type.index});
  }

  Future<void> selectOtherCharFont(int select) async {
    await _channel.invokeMethod('selectOtherCharFont', {'select': select});
  }

  Future<void> setOtherSize(int size) async {
    await _channel.invokeMethod('setOtherSize', {'size': size});
  }

  Future<void> appendText(String text) async {
    await _channel.invokeMethod('appendText', {'text': text});
  }

  Future<void> appendRawData(Uint8List data) async {
    await _channel.invokeMethod('appendRawData', {'data': data});
  }

  Future<void> appendImage(
    Uint8List bytes,
    ImageAlgorithmMessage algorithm,
  ) async {
    await _channel.invokeMethod('appendImage', {
      'bytes': bytes,
      'algorithm': algorithm.index,
    });
  }

  Future<void> lineFeed(int lines) async {
    await _channel.invokeMethod('lineFeed', {'lines': lines});
  }

  Future<void> cutPaper(bool partial) async {
    await _channel.invokeMethod('cutPaper', {'partial': partial});
  }

  Future<void> printQrCode(
    String data,
    int size,
    QrErrorLevelMessage errorLevel,
  ) async {
    await _channel.invokeMethod('printQrCode', {
      'data': data,
      'size': size,
      'errorLevel': errorLevel.index,
    });
  }

  Future<PrintResultMessage> commit() async {
    final Map<Object?, Object?> map = await _channel.invokeMethod('commit');
    return PrintResultMessage.fromMap(map);
  }
}
