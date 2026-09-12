import 'package:integration_test/integration_test_driver.dart';
import 'phase_native_receipt.dart';

Future<void> main() => integrationDriver(
  timeout: const Duration(minutes: 60),
  responseDataCallback: (data) async {
    validatePhaseNativeReceipt(data);
    await writeResponseData(data);
  },
);
