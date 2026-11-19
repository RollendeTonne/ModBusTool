import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/features/network_scan/domain/arp_parser.dart';
import 'package:modbus_explorer/features/network_scan/domain/ipv4.dart';
import 'package:modbus_explorer/features/network_scan/domain/known_ports.dart';

void main() {
  group('Ipv4', () {
    test('parses, formats and compares', () {
      final a = Ipv4.parse('192.168.1.20');
      expect(a.toString(), '192.168.1.20');
      expect(a.value, 0xC0A80114);
      expect(a.compareTo(Ipv4.parse('192.168.1.3')), greaterThan(0));
    });

    for (final bad in [
      '',
      '1.2.3',
      '1.2.3.4.5',
      '256.1.1.1',
      'a.b.c.d',
      '1.2.3.0004',
    ]) {
      test('rejects "$bad"', () {
        expect(() => Ipv4.parse(bad), throwsFormatException);
        expect(Ipv4.tryParse(bad), isNull);
      });
    }
  });

  group('Ipv4Range', () {
    test('/24 excludes network and broadcast', () {
      final range = Ipv4Range.parse('192.168.1.77/24');
      expect(range.first.toString(), '192.168.1.1');
      expect(range.last.toString(), '192.168.1.254');
      expect(range.length, 254);
    });

    test('/31 and /32 keep all addresses', () {
      expect(Ipv4Range.parse('10.0.0.4/31').length, 2);
      expect(Ipv4Range.parse('10.0.0.4/32').length, 1);
    });

    test('/22 spans several third octets', () {
      final range = Ipv4Range.parse('10.1.4.0/22');
      expect(range.first.toString(), '10.1.4.1');
      expect(range.last.toString(), '10.1.7.254');
    });

    test('dash ranges, short form and single address', () {
      expect(
        Ipv4Range.parse('192.168.1.10 - 192.168.1.12').addresses
            .map((a) => '$a'),
        ['192.168.1.10', '192.168.1.11', '192.168.1.12'],
      );
      expect(Ipv4Range.parse('192.168.1.10-20').length, 11);
      expect(Ipv4Range.parse('10.0.0.5').length, 1);
    });

    test('around() gives the /24 hosts', () {
      final range = Ipv4Range.around(Ipv4.parse('172.16.5.9'));
      expect('$range', '172.16.5.1–172.16.5.254');
      expect(range.contains(Ipv4.parse('172.16.5.9')), isTrue);
      expect(range.contains(Ipv4.parse('172.16.6.1')), isFalse);
    });

    for (final bad in [
      '1.2.3.4/33',
      '1.2.3.4/x',
      '10.0.0.9-10.0.0.1',
      '10.0.0.1-300',
      'x',
    ]) {
      test('rejects "$bad"', () {
        expect(() => Ipv4Range.parse(bad), throwsFormatException);
      });
    }
  });

  group('ARP tables', () {
    test('macOS arp -an (leading zeros dropped, incomplete entries)', () {
      const output = '''
? (192.168.1.1) at 0:11:32:a:bb:c on en0 ifscope [ethernet]
? (192.168.1.20) at (incomplete) on en0 ifscope [ethernet]
? (192.168.1.255) at ff:ff:ff:ff:ff:ff on en0 ifscope [ethernet]
? (224.0.0.251) at 1:0:5e:0:0:fb on en0 ifscope permanent [ethernet]
plc.local (192.168.1.50) at 00:1d:9c:12:34:56 on en0 ifscope [ethernet]
''';
      expect(parseArpTable(output), {
        Ipv4.parse('192.168.1.1'): '00:11:32:0A:BB:0C',
        Ipv4.parse('192.168.1.50'): '00:1D:9C:12:34:56',
      });
    });

    test('Linux /proc/net/arp', () {
      const output = '''
IP address       HW type     Flags       HW address            Mask     Device
192.168.0.1      0x1         0x2         a4:91:b1:00:11:22     *        eth0
192.168.0.7      0x1         0x0         00:00:00:00:00:00     *        eth0
''';
      expect(parseArpTable(output), {
        Ipv4.parse('192.168.0.1'): 'A4:91:B1:00:11:22',
      });
    });

    test('Windows arp -a', () {
      const output = '''
Interface: 10.0.0.15 --- 0xb
  Internet Address      Physical Address      Type
  10.0.0.1              00-50-56-c0-00-08     dynamic
  10.0.0.255            ff-ff-ff-ff-ff-ff     static
''';
      expect(parseArpTable(output), {
        Ipv4.parse('10.0.0.1'): '00:50:56:C0:00:08',
      });
    });

    test('normalizeMac', () {
      expect(normalizeMac('0-1d-9C-1-2-3'), '00:1D:9C:01:02:03');
    });
  });

  group('port lists', () {
    test('parses lists and small ranges', () {
      expect(parsePortList('502, 80 80;22'), [22, 80, 502]);
      expect(parsePortList('500-503'), [500, 501, 502, 503]);
    });

    test('rejects invalid or oversized input', () {
      expect(parsePortList(''), isNull);
      expect(parsePortList('0'), isNull);
      expect(parsePortList('70000'), isNull);
      expect(parsePortList('1-5000'), isNull);
      expect(parsePortList('http'), isNull);
    });

    test('names of well-known ports', () {
      expect(portName(502), 'Modbus');
      expect(portName(44818), 'EtherNet/IP');
      expect(portName(12345), isNull);
      expect(defaultScanPorts, contains(502));
    });
  });
}
