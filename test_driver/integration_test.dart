import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Saves PNGs from [IntegrationTestWidgetsFlutterBinding.takeScreenshot].
Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final file = File('build/screenshots_raw/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      // ignore: avoid_print
      print('Screenshot saved: ${file.path}');
      return true;
    },
  );
}
