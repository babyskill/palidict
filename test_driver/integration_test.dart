import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String name, List<int> imageBytes, [Map<String, Object?>? args]) async {
      final dir = Directory('.agy/runs/shots/final');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final file = File('${dir.path}/$name.png');
      await file.writeAsBytes(imageBytes);
      return true;
    },
  );
}
