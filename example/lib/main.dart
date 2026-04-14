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

  List<DiscoveredPrinter> _printers = [];
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

  Future<void> _connect(DiscoveredPrinter p) async {
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
        ..setAlignment(PrintAlignment.center)
        ..setCharacterSize(2, 2)
        ..appendText('SUNMI CLOUD PRINTER\n')
        ..setCharacterSize(1, 1)
        ..setAlignment(PrintAlignment.left)
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
