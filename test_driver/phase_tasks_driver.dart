import 'package:integration_test/integration_test_driver.dart';

// Upper levels contain multiple long sources; each native audio task has its
// own shorter timeout. This host deadline covers the complete selected level.
Future<void> main() => integrationDriver(timeout: const Duration(minutes: 60));
