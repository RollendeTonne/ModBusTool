import 'package:meta/meta.dart';
import 'package:modbus_explorer/features/network_scan/domain/ipv4.dart';

/// The network the device currently uses (default route), with the real
/// prefix length where the platform reveals it.
@immutable
final class ActiveNetwork {
  const new({
    required this.interface,
    required this.address,
    this.prefixLength,
    this.viaDefaultRoute = false,
  });

  final String interface;
  final Ipv4 address;

  /// `null` if the netmask could not be determined (then /24 is assumed).
  final int? prefixLength;

  /// Chosen from the routing table rather than by name heuristics.
  final bool viaDefaultRoute;

  /// Prefix actually used: the real one, or 24 if unknown or the subnet
  /// would exceed [maxAddresses] hosts.
  int effectivePrefix({int maxAddresses = 4096}) {
    final prefix = prefixLength;
    if (prefix == null) return 24;
    final hosts = prefix >= 31 ? 1 << (32 - prefix) : (1 << (32 - prefix)) - 2;
    return hosts <= maxAddresses ? prefix : 24;
  }

  /// `192.168.1.0/24` style text for the range field.
  String cidr({int maxAddresses = 4096}) {
    final prefix = effectivePrefix(maxAddresses: maxAddresses);
    final mask = prefix == 0 ? 0 : (0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF;
    return '${Ipv4(address.value & mask)}/$prefix';
  }

  /// Range to scan, see [cidr].
  Ipv4Range scanRange({int maxAddresses = 4096}) =>
      Ipv4Range.parse(cidr(maxAddresses: maxAddresses));
}

/// Default-route interface from `route -n get default` (macOS/BSD).
String? parseMacDefaultRoute(String output) => RegExp(
  r'^\s*interface:\s*(\S+)',
  multiLine: true,
).firstMatch(output)?.group(1);

/// Default-route interface from `/proc/net/route` (Linux): the line whose
/// destination and mask are 0.
String? parseLinuxDefaultRoute(String content) {
  for (final line in content.split('\n').skip(1)) {
    final fields = line.trim().split(RegExp(r'\s+'));
    if (fields.length >= 8 &&
        fields[1] == '00000000' &&
        fields[7] == '00000000') {
      return fields[0];
    }
  }
  return null;
}

/// Prefix length for [address] from `ifconfig <if>` (macOS/BSD), whose
/// netmask is hex (`netmask 0xffffff00`).
int? parseIfconfigPrefix(String output, Ipv4 address) {
  final match = RegExp(
    'inet ${RegExp.escape('$address')}\\s+netmask\\s+0x([0-9a-fA-F]{8})',
  ).firstMatch(output);
  if (match == null) return null;
  return prefixFromMask(int.parse(match.group(1)!, radix: 16));
}

/// Prefix length for [address] from `ip -o -4 addr show` (Linux).
int? parseIpAddrPrefix(String output, Ipv4 address) {
  final match = RegExp('inet ${RegExp.escape('$address')}/(\\d{1,2})')
      .firstMatch(output);
  final prefix = match == null ? null : int.parse(match.group(1)!);
  return prefix != null && prefix <= 32 ? prefix : null;
}

/// Contiguous netmask → prefix length; `null` for non-contiguous masks.
int? prefixFromMask(int mask) {
  var prefix = 0;
  var bit = 31;
  while (bit >= 0 && (mask >> bit) & 1 == 1) {
    prefix++;
    bit--;
  }
  // Remaining bits must all be zero.
  return mask & ((1 << (32 - prefix)) - 1) == 0 ? prefix : null;
}

/// Where the routing table is unavailable: physical LAN/WLAN adapters
/// first, VPN/virtual ones last.
int interfaceRank(String name) {
  final n = name.toLowerCase();
  const physical = [
    'en0',
    'eth0',
    'wlan0',
    'wlp',
    'enp',
    'eno',
    'ethernet',
    'wi-fi',
    'wlan',
    'en',
  ];
  const virtual = [
    'utun',
    'tun',
    'tap',
    'ppp',
    'ipsec',
    'bridge',
    'vmnet',
    'vbox',
    'docker',
    'veth',
    'virbr',
    'awdl',
    'llw',
    'zt',
    'tailscale',
    'wg',
  ];
  if (virtual.any(n.startsWith)) return 2;
  if (physical.any(n.startsWith)) return 0;
  return 1;
}

/// Picks the active interface: the default-route one if known, otherwise
/// the best-ranked private, non-link-local address.
({String interface, Ipv4 address})? chooseActiveInterface(
  List<({String interface, Ipv4 address})> candidates, {
  String? defaultRouteInterface,
}) {
  final usable = candidates.where((c) {
    final o = c.address.octets;
    return o[0] != 127 && !(o[0] == 169 && o[1] == 254);
  }).toList();
  if (usable.isEmpty) return null;
  if (defaultRouteInterface != null) {
    final match = usable
        .where((c) => c.interface == defaultRouteInterface)
        .firstOrNull;
    if (match != null) return match;
  }
  usable.sort((a, b) {
    final rank = interfaceRank(a.interface)
        .compareTo(interfaceRank(b.interface));
    if (rank != 0) return rank;
    return (_isPrivate(a.address) ? 0 : 1).compareTo(
      _isPrivate(b.address) ? 0 : 1,
    );
  });
  return usable.first;
}

bool _isPrivate(Ipv4 a) {
  final o = a.octets;
  return o[0] == 10 ||
      (o[0] == 172 && o[1] >= 16 && o[1] <= 31) ||
      (o[0] == 192 && o[1] == 168);
}
