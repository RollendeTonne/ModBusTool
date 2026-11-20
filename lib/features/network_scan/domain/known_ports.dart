/// TCP ports worth checking on industrial and office networks.
const knownPorts = <int, String>{
  21: 'FTP',
  22: 'SSH',
  23: 'Telnet',
  80: 'HTTP',
  102: 'S7comm',
  443: 'HTTPS',
  502: 'Modbus',
  503: 'Modbus',
  1502: 'Modbus',
  1883: 'MQTT',
  8883: 'MQTT/TLS',
  4840: 'OPC UA',
  8080: 'HTTP',
  20000: 'DNP3',
  44818: 'EtherNet/IP',
};

const defaultScanPorts = [
  21,
  22,
  23,
  80,
  102,
  443,
  502,
  1883,
  8883,
  4840,
  8080,
  20000,
  44818,
];

/// Ports on which an open socket is verified with a Modbus request.
const defaultModbusPorts = [502, 503, 1502];

String? portName(int port) => knownPorts[port];

/// Parses `502, 80 8080` into sorted unique ports; `null` if invalid.
List<int>? parsePortList(String text) {
  final ports = <int>{};
  for (final token in text.split(RegExp(r'[\s,;]+'))) {
    if (token.isEmpty) continue;
    final range = token.split('-');
    if (range.length == 2) {
      final from = int.tryParse(range[0]);
      final to = int.tryParse(range[1]);
      if (from == null || to == null || from < 1 || to > 65535 || from > to) {
        return null;
      }
      if (to - from > 1024) return null; // keep scans bounded
      for (var p = from; p <= to; p++) {
        ports.add(p);
      }
      continue;
    }
    final port = int.tryParse(token);
    if (port == null || port < 1 || port > 65535) return null;
    ports.add(port);
  }
  return ports.isEmpty ? null : (ports.toList()..sort());
}
