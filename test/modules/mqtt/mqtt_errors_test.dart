import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/modules/mqtt/data/package_session_support.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_config.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_errors.dart';

void main() {
  test('CONNACK codes of both versions map to one reason', () {
    expect(connackReasonV311(4), ConnackReason.badCredentials);
    expect(connackReasonV5(0x86), ConnackReason.badCredentials);
    expect(connackReasonV311(5), ConnackReason.notAuthorized);
    expect(connackReasonV5(0x87), ConnackReason.notAuthorized);
    expect(connackReasonV311(2), ConnackReason.clientIdRejected);
    expect(connackReasonV5(0x85), ConnackReason.clientIdRejected);
    expect(connackReasonV5(0x8A), ConnackReason.banned);
    expect(connackReasonV311(99), ConnackReason.unknown);
    expect(connackReasonV5(0x01), ConnackReason.unknown);
  });

  test('exceptions are classified, also when wrapped in text', () {
    expect(
      failureFrom(const SocketException('x')).kind,
      MqttFailureKind.network,
    );
    expect(
      failureFrom(const HandshakeException('bad')).kind,
      MqttFailureKind.tls,
    );
    expect(
      failureFrom(Exception('Handshake exception to the message broker')).kind,
      MqttFailureKind.tls,
    );
    expect(
      failureFrom(
        Exception('The connection could not be made. Error is SocketException'),
      ).kind,
      MqttFailureKind.network,
    );
    expect(
      failureFrom(Exception('socket timeout')).kind,
      MqttFailureKind.timeout,
    );
    expect(failureFrom(Exception('?')).kind, MqttFailureKind.unknown);
  });

  test('server address and client ID', () {
    expect(serverFor(const MqttConnectionConfig(host: 'h')), 'h');
    expect(
      serverFor(
        const MqttConnectionConfig(
          host: 'h',
          transport: MqttTransport.wss,
          webSocketPath: 'ws',
        ),
      ),
      'wss://h/ws',
    );
    expect(
      const MqttConnectionConfig(
        host: 'h',
        port: 9001,
        transport: MqttTransport.ws,
      ).endpoint,
      'ws://h:9001/mqtt',
    );
    final id = generateClientId();
    expect(id, matches(RegExp(r'^pe-[a-z0-9]{12}$')));
    expect(id.length, lessThanOrEqualTo(23));
  });
}
