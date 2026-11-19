import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Captures `Clipboard.setData` calls in widget tests.
class FakeClipboard {
  String? text;

  void install(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          text = (call.arguments as Map)['text'] as String?;
        }
        if (call.method == 'Clipboard.getData') return {'text': text};
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  }
}
