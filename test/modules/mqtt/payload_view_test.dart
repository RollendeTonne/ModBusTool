import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_config.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_message.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/payload_view.dart';

MqttMessageRecord record(
  List<int> payload, {
  MqttMessageProperties properties = MqttMessageProperties.none,
}) => MqttMessageRecord(
  direction: MqttDirection.received,
  topic: 't',
  payload: Uint8List.fromList(payload),
  timestamp: DateTime(2026, 11, 19, 12),
  qos: MqttQosLevel.atLeastOnce,
  retain: true,
  properties: properties,
);

List<int> utf(String s) => utf8.encode(s);

void main() {
  late List<String> clipboard;

  setUp(() => clipboard = []);

  Future<void> show(
    WidgetTester tester,
    MqttMessageRecord r, {
    String topic = 't',
  }) async {
    tester.view
      ..physicalSize = const Size(1000, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PayloadView(record: r, topic: topic),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openTab(WidgetTester tester, String name) async {
    await tester.tap(find.byKey(Key('payload.tab.$name')));
    await tester.pumpAndSettle();
  }

  String box(WidgetTester tester, String key) => tester
      .widget<SelectableText>(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(SelectableText),
        ),
      )
      .data!;

  testWidgets('JSON: tree, copy path, collapse, pretty print', (tester) async {
    await show(
      tester,
      record(utf('{"sensor":{"temp":21.5,"tags":["a","b"]},"ok":true}')),
    );
    expect(find.text('Detected: JSON'), findsOneWidget);
    expect(find.byKey(const Key(r'json.$.sensor.temp')), findsOneWidget);

    await tester.tap(find.byKey(const Key(r'json.$.sensor.temp')));
    await tester.pump();
    expect(clipboard.last, r'$.sensor.temp');
    expect(find.text(r'$.sensor.temp copied'), findsOneWidget);

    // Depth 2 starts collapsed; expand the array.
    expect(find.byKey(const Key(r'json.$.sensor.tags[0]')), findsNothing);
    await tester.tap(find.byKey(const Key(r'json.toggle.$.sensor.tags')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key(r'json.$.sensor.tags[1]')));
    await tester.pump();
    expect(clipboard.last, r'$.sensor.tags[1]');

    // Collapse the object.
    await tester.tap(find.byKey(const Key(r'json.toggle.$.sensor')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key(r'json.$.sensor.temp')), findsNothing);

    await tester.tap(find.text('Formatted'));
    await tester.pumpAndSettle();
    expect(
      box(tester, 'payload.jsonPretty'),
      contains('  "sensor": {\n    "temp": 21.5'),
    );
  });

  testWidgets('JSON syntax error is marked with a caret', (tester) async {
    await show(tester, record(utf('{\n  "a": 1,\n  "b": x\n}')));
    expect(find.text('Detected: JSON (invalid)'), findsOneWidget);
    expect(
      find.textContaining('Syntax error in line 3, column 8'),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('payload.syntaxCaret'))).data,
      '  "b": x\n       ^',
    );
  });

  testWidgets('binary: matrix over bytes, offset, 8 bit, bits', (tester) async {
    // FF then 12.5 as FLOAT32 big endian.
    await show(tester, record([0xFF, 0x41, 0x48, 0x00, 0x00]));
    expect(find.text('Detected: Binary'), findsOneWidget);
    expect(find.byKey(const Key('payload.binary')), findsOneWidget);
    expect(find.text('INT8 -1'), findsOneWidget);
    expect(find.text('UINT8 255'), findsOneWidget);

    await tester.tap(find.byKey(const Key('payload.offset.up')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('payload.window'))).data,
      'Bytes from offset: 41 48 00 00',
    );
    final float = find.descendant(
      of: find.byKey(const Key('matrix.float32.abcd')),
      matching: find.text('12.5'),
    );
    expect(float, findsOneWidget);
    await tester.tap(float);
    await tester.pump();
    expect(clipboard.last, '12.5');
    // 64-bit types need more bytes.
    expect(find.byTooltip('Needs 8 bytes'), findsWidgets);
    expect(box(tester, 'payload.bits'), contains('0x41   0100 0001'));

    // Offset field accepts typing and clamps.
    await tester.enterText(find.byKey(const Key('payload.offset')), '99');
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('payload.window'))).data,
      'Bytes from offset: 00',
    );
  });

  testWidgets('text tab switches encodings', (tester) async {
    await show(tester, record([0x47, 0xFC, 0x6E])); // Latin-1 "Gün"
    await openTab(tester, 'text');
    expect(box(tester, 'payload.decodedText'), 'G�n');
    await tester.tap(find.text('Latin-1'));
    await tester.pumpAndSettle();
    expect(box(tester, 'payload.decodedText'), 'Gün');
  });

  testWidgets('hex dump with ASCII column', (tester) async {
    await show(tester, record(utf('Hello')));
    await openTab(tester, 'hex');
    expect(box(tester, 'payload.hex'), startsWith('00000000  48 65 6C 6C 6F'));
    expect(box(tester, 'payload.hex'), endsWith('│Hello'));
  });

  testWidgets('base64 is decoded and can be interpreted', (tester) async {
    await show(
      tester,
      record(utf(base64.encode([0x41, 0x48, 0, 0, 1, 2, 3, 4]))),
    );
    expect(find.text('Detected: Base64'), findsOneWidget);
    expect(find.text('Base64 decoded (8 bytes)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('payload.interpretDecoded')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('payload.window'))).data,
      startsWith('Bytes from offset: 41 48 00 00'),
    );
  });

  testWidgets('XML pretty print', (tester) async {
    await show(tester, record(utf('<a><b>1</b></a>')));
    expect(find.text('Detected: XML'), findsOneWidget);
    expect(box(tester, 'payload.xml'), '<a>\n  <b>\n    1\n  </b>\n</a>');
  });

  testWidgets('metadata tab shows MQTT 5 properties', (tester) async {
    await show(
      tester,
      record(
        utf('x'),
        properties: MqttMessageProperties(
          contentType: 'text/plain',
          responseTopic: 'reply/to',
          correlationData: Uint8List.fromList(utf('req-7')),
          messageExpiry: const Duration(seconds: 90),
          userProperties: const [('site', 'hall 1')],
          payloadIsUtf8: true,
        ),
      ),
    );
    await openTab(tester, 'meta');
    final meta = find.byKey(const Key('payload.meta'));
    for (final text in [
      'text/plain',
      'reply/to',
      'req-7',
      '90 s',
      'hall 1',
      'site',
    ]) {
      expect(
        find.descendant(of: meta, matching: find.text(text)),
        findsOneWidget,
        reason: text,
      );
    }
    expect(find.textContaining('No MQTT 5 properties'), findsNothing);
  });

  testWidgets('a new topic resets to the best tab', (tester) async {
    await show(tester, record(utf('{"a":1}')));
    await openTab(tester, 'hex');
    // Same topic, new value: tab stays.
    await show(tester, record(utf('{"a":2}')));
    expect(find.byKey(const Key('payload.hex')), findsOneWidget);
    // Another (binary) topic: binary tab.
    await show(tester, record([0, 1, 2]), topic: 'other');
    expect(find.byKey(const Key('payload.binary')), findsOneWidget);
  });
}
