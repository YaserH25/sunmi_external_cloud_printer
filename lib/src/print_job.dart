import 'package:sunmi_external_cloud_printer/src/models.dart';
import 'package:sunmi_external_cloud_printer/src/sunmi_external_cloud_printer_api.dart';

/// Builds a buffered sequence of print commands to send in a single
/// [SunmiExternalCloudPrinter.commit] call.
///
/// ```dart
/// final job = PrintJob()
///   ..setAlignment(PrintAlignment.center)
///   ..setCharacterSize(2, 2)
///   ..appendText('Receipt\n')
///   ..setCharacterSize(1, 1)
///   ..setAlignment(PrintAlignment.left)
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
  PrintJob setAlignment(PrintAlignment alignment) {
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

  /// Appends [text] to the print buffer. Include `\n` for line breaks.
  PrintJob appendText(String text) {
    _commands.add(_AppendText(text));
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
    QrErrorLevel errorLevel = QrErrorLevel.m,
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
  final PrintAlignment alignment;
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

final class _AppendText extends _PrintCommand {
  _AppendText(this.text);
  final String text;
  @override
  Future<void> execute(SunmiPrintApi api) => api.appendText(text);
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
  final QrErrorLevel errorLevel;
  @override
  Future<void> execute(SunmiPrintApi api) =>
      api.printQrCode(data, size, _toErrorLevel(errorLevel));
}

// ---------------------------------------------------------------------------
// Enum converters
// ---------------------------------------------------------------------------

PrintAlignmentMessage _toMessage(PrintAlignment a) => switch (a) {
  PrintAlignment.left => PrintAlignmentMessage.left,
  PrintAlignment.center => PrintAlignmentMessage.center,
  PrintAlignment.right => PrintAlignmentMessage.right,
};

QrErrorLevelMessage _toErrorLevel(QrErrorLevel l) => switch (l) {
  QrErrorLevel.l => QrErrorLevelMessage.l,
  QrErrorLevel.m => QrErrorLevelMessage.m,
  QrErrorLevel.q => QrErrorLevelMessage.q,
  QrErrorLevel.h => QrErrorLevelMessage.h,
};
