import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sunmi_external_cloud_printer/sunmi_external_cloud_printer.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SunmiExternalCloudPrinter constructs without error', (
    tester,
  ) async {
    final printer = SunmiExternalCloudPrinter();
    expect(printer, isNotNull);
  });
}
