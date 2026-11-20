import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/features/network_scan/domain/ipv4.dart';
import 'package:modbus_explorer/features/network_scan/domain/port_action.dart';

void main() {
  final ip = Ipv4.parse('192.168.1.10');

  String? uriOf(int port) => switch (portActionFor(ip, port)) {
    OpenUriAction(:final uri) => '$uri',
    _ => null,
  };

  test('web ports open the browser, default ports without suffix', () {
    expect(uriOf(80), 'http://192.168.1.10');
    expect(uriOf(8080), 'http://192.168.1.10:8080');
    expect(uriOf(443), 'https://192.168.1.10');
    expect(uriOf(8443), 'https://192.168.1.10:8443');
    expect((portActionFor(ip, 80) as OpenUriAction).kind, PortAppKind.browser);
  });

  test('other protocols use their URI schemes', () {
    expect(uriOf(22), 'ssh://192.168.1.10');
    expect(uriOf(23), 'telnet://192.168.1.10');
    expect(uriOf(21), 'ftp://192.168.1.10');
    expect(uriOf(5900), 'vnc://192.168.1.10');
    expect(uriOf(445), 'smb://192.168.1.10');
    expect(uriOf(4840), 'opc.tcp://192.168.1.10:4840');
  });

  test('Modbus ports connect in the app, also verified non-standard ones', () {
    expect(portActionFor(ip, 502), isA<ConnectModbusAction>());
    expect(portActionFor(ip, 1502), isA<ConnectModbusAction>());
    final custom = portActionFor(ip, 10502, isModbus: true);
    expect((custom as ConnectModbusAction).port, 10502);
  });

  test('MQTT ports create a broker profile (TLS on 8883)', () {
    final plain = portActionFor(ip, 1883) as ConnectMqttAction;
    expect(plain.port, 1883);
    expect(plain.tls, isFalse);
    expect((portActionFor(ip, 8883) as ConnectMqttAction).tls, isTrue);
  });

  test('ports without a known program copy ip:port', () {
    for (final port in [102, 3389, 20000, 44818, 12345]) {
      expect(
        (portActionFor(ip, port) as CopyAddressAction).text,
        '192.168.1.10:$port',
      );
    }
  });
}
