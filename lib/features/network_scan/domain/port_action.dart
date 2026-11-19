import 'package:meta/meta.dart';
import 'package:modbus_explorer/features/network_scan/domain/ipv4.dart';

/// What clicking an open port in the scan results does.
@immutable
sealed class PortAction {
  const new();
}

/// Hand the URI to the operating system, which opens the registered
/// program (browser for http/https, Terminal for ssh/telnet, …).
final class OpenUriAction extends PortAction {
  const new(this.uri, this.kind);
  final Uri uri;
  final PortAppKind kind;
}

/// Create a Modbus TCP profile for the port and connect in this app.
final class ConnectModbusAction extends PortAction {
  const new(this.port);
  final int port;
}

/// No suitable program is known: copy `ip:port` to the clipboard.
final class CopyAddressAction extends PortAction {
  const new(this.text);
  final String text;
}

enum PortAppKind { browser, terminal, fileTransfer, remoteDesktop, opcUa }

const _httpPorts = {80, 81, 8000, 8008, 8080, 8081, 8088, 8888};
const _httpsPorts = {443, 4443, 8443};
const _modbusPorts = {502, 503, 1502};

/// Maps an open port to the most suitable action. [isModbus] marks ports
/// that answered a Modbus request, whatever their number.
PortAction portActionFor(Ipv4 address, int port, {bool isModbus = false}) {
  final host = '$address';
  if (isModbus || _modbusPorts.contains(port)) {
    return ConnectModbusAction(port);
  }
  Uri uri(String scheme, int defaultPort) =>
      Uri(scheme: scheme, host: host, port: port == defaultPort ? null : port);
  if (_httpPorts.contains(port)) {
    return OpenUriAction(uri('http', 80), PortAppKind.browser);
  }
  if (_httpsPorts.contains(port)) {
    return OpenUriAction(uri('https', 443), PortAppKind.browser);
  }
  return switch (port) {
    21 => OpenUriAction(uri('ftp', 21), PortAppKind.fileTransfer),
    22 => OpenUriAction(uri('ssh', 22), PortAppKind.terminal),
    23 => OpenUriAction(uri('telnet', 23), PortAppKind.terminal),
    445 => OpenUriAction(uri('smb', 445), PortAppKind.fileTransfer),
    5900 => OpenUriAction(uri('vnc', 5900), PortAppKind.remoteDesktop),
    // RDP (3389) has no URI format Dart can express (`full%20address=…`
    // is not a valid authority), so it falls through to copying.
    // Opens UaExpert & co. if one registered the scheme.
    4840 => OpenUriAction(Uri.parse('opc.tcp://$host:4840'), PortAppKind.opcUa),
    _ => CopyAddressAction('$host:$port'),
  };
}
