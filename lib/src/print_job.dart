import 'package:sunmi_external_cloud_printer/src/models.dart';
import 'package:sunmi_external_cloud_printer/src/sunmi_external_cloud_printer_api.dart';
import 'dart:typed_data';

/// Builds a buffered sequence of print commands to send in a single
/// [SunmiExternalCloudPrinter.commit] call.
///
/// ```dart
/// final job = PrintJob()
///   ..setAlignment(SunmiPrintAlignment.center)
///   ..setCharacterSize(2, 2)
///   ..appendText('Receipt\n')
///   ..setCharacterSize(1, 1)
///   ..setAlignment(SunmiPrintAlignment.left)
///   ..appendText('Total: 100 SAR\n')
///   ..lineFeed(3)
///   ..cutPaper();
///
/// final result = await printer.commit(job);
/// ```
final class PrintJob {
  final List<_PrintCommand> _commands = [];

  /// Resets all style settings to defaults.
  PrintJob initStyle() {
    _commands.add(_InitStyle());
    return this;
  }

  /// Sets text alignment.
  PrintJob setAlignment(SunmiPrintAlignment alignment) {
    _commands.add(_SetAlignment(alignment));
    return this;
  }

  /// Sets character width and height multiplier (1–4).
  PrintJob setCharacterSize(int width, int height) {
    _commands.add(_SetCharacterSize(width, height));
    return this;
  }

  /// Enables or disables bold text.
  PrintJob setBold({required bool enabled}) {
    _commands.add(_SetBold(enabled));
    return this;
  }

  /// Sets the text decoding mode used by the printer firmware.
  ///
  /// Experimental: this may help with some scripts, but does not guarantee
  /// Arabic shaping or RTL layout on the printer.
  PrintJob setEncodeMode(SunmiEncodeType type) {
    _commands.add(_SetEncodeMode(type));
    return this;
  }

  /// Selects the printer font library for non-ASCII/CJK characters.
  ///
  /// Experimental: actual glyph coverage depends on printer firmware and any
  /// preloaded third-party fonts.
  PrintJob selectOtherCharFont(int select) {
    _commands.add(_SelectOtherCharFont(select));
    return this;
  }

  /// Sets the font size for the printer's "other character" vector font.
  ///
  /// Experimental: only applies when the printer uses a compatible vector font.
  PrintJob setOtherSize(int size) {
    _commands.add(_SetOtherSize(size));
    return this;
  }

  /// Appends [text] to the print buffer. Include `\n` for line breaks.
  PrintJob appendText(String text) {
    _commands.add(_AppendText(text));
    return this;
  }

  /// Appends raw printer bytes directly to the print buffer.
  ///
  /// Experimental: use only if you know the target printer's ESC/POS behavior.
  PrintJob appendRawData(Uint8List data) {
    _commands.add(_AppendRawData(data));
    return this;
  }

  /// Appends an image to the print buffer.
  ///
  /// Pass PNG, JPG, or other Android-decodable image bytes. This is the
  /// recommended path for Arabic and other scripts that require shaping.
  PrintJob appendImage(
    Uint8List bytes, {
    SunmiImageAlgorithm algorithm = SunmiImageAlgorithm.binarization,
  }) {
    _commands.add(_AppendImage(bytes, algorithm));
    return this;
  }

  /// Feeds [lines] blank lines. Defaults to 1.
  PrintJob lineFeed([int lines = 1]) {
    _commands.add(_LineFeed(lines));
    return this;
  }

  /// Cuts the paper. [partial] = false means full cut.
  PrintJob cutPaper({bool partial = false}) {
    _commands.add(_CutPaper(partial));
    return this;
  }

  /// Prints a QR code for [data] at [size] (1–16) with [errorLevel].
  PrintJob printQrCode(
    String data, {
    int size = 6,
    SunmiQrErrorLevel errorLevel = SunmiQrErrorLevel.m,
  }) {
    _commands.add(_PrintQrCode(data, size, errorLevel));
    return this;
  }

  /// Executes all buffered commands on [printApi].
  Future<void> execute(SunmiPrintApi printApi) async {
    for (final cmd in _commands) {
      await cmd.execute(printApi);
    }
  }
}

// ---------------------------------------------------------------------------
// Internal command types
// ---------------------------------------------------------------------------

sealed class _PrintCommand {
  Future<void> execute(SunmiPrintApi api);
}

final class _InitStyle extends _PrintCommand {
  @override
  Future<void> execute(SunmiPrintApi api) => api.initStyle();
}

final class _SetAlignment extends _PrintCommand {
  _SetAlignment(this.alignment);
  final SunmiPrintAlignment alignment;
  @override
  Future<void> execute(SunmiPrintApi api) =>
      api.setAlignment(_toMessage(alignment));
}

final class _SetCharacterSize extends _PrintCommand {
  _SetCharacterSize(this.width, this.height);
  final int width;
  final int height;
  @override
  Future<void> execute(SunmiPrintApi api) =>
      api.setCharacterSize(width, height);
}

final class _SetBold extends _PrintCommand {
  _SetBold(this.enabled);
  final bool enabled;
  @override
  Future<void> execute(SunmiPrintApi api) => api.setBold(enabled);
}

final class _SetEncodeMode extends _PrintCommand {
  _SetEncodeMode(this.type);
  final SunmiEncodeType type;
  @override
  Future<void> execute(SunmiPrintApi api) => api.setEncodeMode(_toEncodeType(type));
}

final class _SelectOtherCharFont extends _PrintCommand {
  _SelectOtherCharFont(this.select);
  final int select;
  @override
  Future<void> execute(SunmiPrintApi api) => api.selectOtherCharFont(select);
}

final class _SetOtherSize extends _PrintCommand {
  _SetOtherSize(this.size);
  final int size;
  @override
  Future<void> execute(SunmiPrintApi api) => api.setOtherSize(size);
}

final class _AppendText extends _PrintCommand {
  _AppendText(this.text);
  final String text;
  @override
  Future<void> execute(SunmiPrintApi api) => api.appendText(text);
}

final class _AppendRawData extends _PrintCommand {
  _AppendRawData(this.data);
  final Uint8List data;
  @override
  Future<void> execute(SunmiPrintApi api) => api.appendRawData(data);
}

final class _AppendImage extends _PrintCommand {
  _AppendImage(this.bytes, this.algorithm);
  final Uint8List bytes;
  final SunmiImageAlgorithm algorithm;
  @override
  Future<void> execute(SunmiPrintApi api) =>
      api.appendImage(bytes, _toImageAlgorithm(algorithm));
}

final class _LineFeed extends _PrintCommand {
  _LineFeed(this.lines);
  final int lines;
  @override
  Future<void> execute(SunmiPrintApi api) => api.lineFeed(lines);
}

final class _CutPaper extends _PrintCommand {
  _CutPaper(this.partial);
  final bool partial;
  @override
  Future<void> execute(SunmiPrintApi api) => api.cutPaper(partial);
}

final class _PrintQrCode extends _PrintCommand {
  _PrintQrCode(this.data, this.size, this.errorLevel);
  final String data;
  final int size;
  final SunmiQrErrorLevel errorLevel;
  @override
  Future<void> execute(SunmiPrintApi api) =>
      api.printQrCode(data, size, _toErrorLevel(errorLevel));
}

// ---------------------------------------------------------------------------
// Enum converters
// ---------------------------------------------------------------------------

PrintAlignmentMessage _toMessage(SunmiPrintAlignment a) => switch (a) {
  SunmiPrintAlignment.left => PrintAlignmentMessage.left,
  SunmiPrintAlignment.center => PrintAlignmentMessage.center,
  SunmiPrintAlignment.right => PrintAlignmentMessage.right,
};

ImageAlgorithmMessage _toImageAlgorithm(SunmiImageAlgorithm a) => switch (a) {
  SunmiImageAlgorithm.binarization => ImageAlgorithmMessage.binarization,
  SunmiImageAlgorithm.dithering => ImageAlgorithmMessage.dithering,
};

EncodeTypeMessage _toEncodeType(SunmiEncodeType t) => switch (t) {
  SunmiEncodeType.ascii => EncodeTypeMessage.ascii,
  SunmiEncodeType.gb18030 => EncodeTypeMessage.gb18030,
  SunmiEncodeType.big5 => EncodeTypeMessage.big5,
  SunmiEncodeType.shiftJis => EncodeTypeMessage.shiftJis,
  SunmiEncodeType.jis0208 => EncodeTypeMessage.jis0208,
  SunmiEncodeType.ksc5601 => EncodeTypeMessage.ksc5601,
  SunmiEncodeType.utf8 => EncodeTypeMessage.utf8,
};

QrErrorLevelMessage _toErrorLevel(SunmiQrErrorLevel l) => switch (l) {
  SunmiQrErrorLevel.l => QrErrorLevelMessage.l,
  SunmiQrErrorLevel.m => QrErrorLevelMessage.m,
  SunmiQrErrorLevel.q => QrErrorLevelMessage.q,
  SunmiQrErrorLevel.h => QrErrorLevelMessage.h,
};
