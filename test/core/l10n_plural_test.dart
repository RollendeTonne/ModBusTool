import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';

/// Counts seen on a real device read "1 topics" before plurals were used.
void main() {
  test('singular and plural in both languages', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final de = lookupAppLocalizations(const Locale('de'));
    expect(en.mqttNodeTopics(1), '1 topic');
    expect(en.mqttNodeTopics(3), '3 topics');
    expect(de.mqttNodeTopics(1), '1 Topic');
    expect(en.mqttTreeStats(1, 1), '1 topic · 1 message');
    expect(de.mqttTreeStats(2, 5), '2 Topics · 5 Nachrichten');
    expect(en.mqttBytes(1), '1 byte');
    expect(de.mqttBytes(63), '63 Bytes');
    expect(en.historyCount(1, 100), '1 message stored (max. 100)');
  });
}
