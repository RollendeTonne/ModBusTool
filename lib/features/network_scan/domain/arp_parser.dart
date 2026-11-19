import 'package:modbus_explorer/features/network_scan/domain/ipv4.dart';

final _ip = RegExp(r'(\d{1,3}(?:\.\d{1,3}){3})');

/// MAC with `:` or `-`, 1–2 hex digits per octet (macOS drops leading 0).
final _mac = RegExp(r'\b([0-9a-fA-F]{1,2}(?:[:-][0-9a-fA-F]{1,2}){5})\b');

/// Parses ARP tables of macOS/BSD (`arp -an`), Linux (`/proc/net/arp`,
/// `ip neigh`) and Windows (`arp -a`) into IP → normalised MAC.
/// Incomplete, broadcast and multicast entries are skipped.
Map<Ipv4, String> parseArpTable(String output) {
  final result = <Ipv4, String>{};
  for (final line in output.split('\n')) {
    final ipMatch = _ip.firstMatch(line);
    final macMatch = _mac.firstMatch(line);
    if (ipMatch == null || macMatch == null) continue;
    final ip = Ipv4.tryParse(ipMatch.group(1)!);
    if (ip == null) continue;
    final mac = normalizeMac(macMatch.group(1)!);
    if (mac == '00:00:00:00:00:00' || mac == 'FF:FF:FF:FF:FF:FF') continue;
    // Multicast MACs (01:00:5E:…) belong to group addresses, not hosts.
    if (int.parse(mac.substring(0, 2), radix: 16) & 1 == 1) continue;
    result[ip] = mac;
  }
  return result;
}

/// `0:11:2-...` → `00:11:02:…`, upper case, colon separated.
String normalizeMac(String mac) => mac
    .split(RegExp('[:-]'))
    .map((o) => o.padLeft(2, '0').toUpperCase())
    .join(':');
