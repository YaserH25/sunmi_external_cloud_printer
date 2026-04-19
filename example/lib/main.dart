import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:sunmi_external_cloud_printer/sunmi_external_cloud_printer.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(
    title: 'Sunmi Cloud Printer Example',
    home: PrinterPage(),
  );
}

class PrinterPage extends StatefulWidget {
  const PrinterPage({super.key});
  @override
  State<PrinterPage> createState() => _PrinterPageState();
}

class _PrinterPageState extends State<PrinterPage> {
  final _printer = SunmiExternalCloudPrinter();

  List<SunmiDiscoveredPrinter> _printers = [];
  String _log = '';
  bool _loading = false;

  void _append(String msg) => setState(() => _log = '$_log\n$msg');

  Future<void> _scan() async {
    setState(() {
      _loading = true;
      _log = 'Scanning…';
    });
    final found = await _printer.scan(timeoutSeconds: 5);
    setState(() {
      _printers = found;
      _loading = false;
      _log = found.isEmpty
          ? 'No printers found.'
          : found
                .map((p) => '${p.name} [${p.connectionType}] — ${p.id}')
                .join('\n');
    });
  }

  Future<void> _connect(SunmiDiscoveredPrinter p) async {
    _append('Connecting to ${p.name}…');
    final ok = await _printer.connect(p.id);
    _append(ok ? 'Connected.' : 'Connection failed.');
  }

  Future<void> _printTest() async {
    _append('Sending test receipt…');
    final now = DateTime.now();
    final result = await _printer.commit(
      PrintJob()
        ..initStyle()
        ..setAlignment(SunmiPrintAlignment.center)
        ..setCharacterSize(2, 2)
        ..appendText('SUNMI CLOUD PRINTER\n')
        ..setCharacterSize(1, 1)
        ..setAlignment(SunmiPrintAlignment.left)
        ..appendText('Plugin example app\n')
        ..appendText('Printed at: $now\n')
        ..lineFeed(3)
        ..cutPaper(),
    );
    _append(
      result.success
          ? 'Printed! ${result.message}'
          : 'Failed: ${result.message}',
    );
  }

  Future<void> _printArabic() async {
    _append('Rendering Arabic receipt as image…');
    final imageBytes = await _buildArabicReceiptImageBytes();

    _append('Sending Arabic receipt…');
    final result = await _printer.commit(
      PrintJob()
        ..initStyle()
        ..appendImage(
          imageBytes,
          algorithm: SunmiImageAlgorithm.dithering,
        )
        ..lineFeed(3)
        ..cutPaper(),
    );

    _append(
      result.success
          ? 'Arabic receipt printed. ${result.message}'
          : 'Arabic receipt failed: ${result.message}',
    );
  }

  Future<Uint8List> _buildArabicReceiptImageBytes() async {
    const receiptWidth = 384.0;
    const horizontalPadding = 20.0;
    const verticalPadding = 18.0;
    final contentWidth = receiptWidth - (horizontalPadding * 2);

    TextPainter buildPainter(
      String text,
      TextStyle style, {
      TextAlign textAlign = TextAlign.right,
    }) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textAlign: textAlign,
        textDirection: TextDirection.rtl,
        locale: const Locale('ar'),
      )..layout(maxWidth: contentWidth);
      return painter;
    }

    final titlePainter = buildPainter(
      'فاتورة تجريبية',
      const TextStyle(
        color: Colors.black,
        fontSize: 30,
        fontWeight: FontWeight.w700,
      ),
      textAlign: TextAlign.center,
    );
    final subtitlePainter = buildPainter(
      'مثال على طباعة العربية كصورة',
      const TextStyle(
        color: Colors.black,
        fontSize: 18,
      ),
      textAlign: TextAlign.center,
    );
    final dividerPainter = buildPainter(
      '--------------------------------',
      const TextStyle(color: Colors.black, fontSize: 18),
      textAlign: TextAlign.center,
    );
    final bodyStyle = const TextStyle(color: Colors.black, fontSize: 22);
    final bodyPainters = <TextPainter>[
      buildPainter('العنصر الأول        ١٠٫٠٠ ر.س', bodyStyle),
      buildPainter('العنصر الثاني       ٢٥٫٠٠ ر.س', bodyStyle),
      buildPainter('الإجمالي            ٣٥٫٠٠ ر.س', bodyStyle.copyWith(fontWeight: FontWeight.w700)),
      buildPainter('شكراً لزيارتكم', bodyStyle, textAlign: TextAlign.center),
    ];

    final allPainters = <TextPainter>[
      titlePainter,
      subtitlePainter,
      dividerPainter,
      ...bodyPainters,
    ];
    final receiptHeight = allPainters.fold<double>(
      verticalPadding * 2,
      (sum, painter) => sum + painter.height + 12,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, receiptWidth, receiptHeight),
      Paint()..color = Colors.white,
    );

    var y = verticalPadding;
    for (final painter in allPainters) {
      painter.paint(canvas, Offset(horizontalPadding, y));
      y += painter.height + 12;
    }

    final image = await recorder
        .endRecording()
        .toImage(receiptWidth.toInt(), receiptHeight.ceil());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Failed to encode Arabic receipt image');
    }
    return byteData.buffer.asUint8List();
  }

  Future<void> _disconnect() async {
    await _printer.disconnect();
    _append('Disconnected.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sunmi Cloud Printer')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _loading ? null : _scan,
                  child: const Text('Scan'),
                ),
                ElevatedButton(
                  onPressed: _printTest,
                  child: const Text('Print Test'),
                ),
                ElevatedButton(
                  onPressed: _printArabic,
                  child: const Text('Print Arabic'),
                ),
                ElevatedButton(
                  onPressed: _disconnect,
                  child: const Text('Disconnect'),
                ),
              ],
            ),
          ),
          if (_printers.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView.builder(
                itemCount: _printers.length,
                itemBuilder: (_, i) {
                  final p = _printers[i];
                  return ListTile(
                    title: Text(p.name),
                    subtitle: Text('${p.connectionType} — ${p.id}'),
                    onTap: () => _connect(p),
                  );
                },
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Text(
                _log,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
