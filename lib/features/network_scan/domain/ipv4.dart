import 'package:meta/meta.dart';

/// IPv4 address as a 32-bit integer, for ranges and sorting.
@immutable
final class Ipv4 implements Comparable<Ipv4> {
  const new(this.value);

  factory parse(String text) {
    final parts = text.trim().split('.');
    if (parts.length != 4) throw FormatException('Not an IPv4 address', text);
    var value = 0;
    for (final part in parts) {
      final octet = int.tryParse(part);
      if (octet == null || octet < 0 || octet > 255 || part.length > 3) {
        throw FormatException('Not an IPv4 address', text);
      }
      value = (value << 8) | octet;
    }
    return Ipv4(value);
  }

  static Ipv4? tryParse(String text) {
    try {
      return Ipv4.parse(text);
    } on FormatException {
      return null;
    }
  }

  final int value;

  List<int> get octets => [
    (value >> 24) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 8) & 0xFF,
    value & 0xFF,
  ];

  @override
  int compareTo(Ipv4 other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) => other is Ipv4 && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => octets.join('.');
}

/// Inclusive address range to scan.
@immutable
final class Ipv4Range {
  new(this.first, this.last) {
    if (last.value < first.value) {
      throw ArgumentError('Range end before start');
    }
  }

  /// Accepts `192.168.1.0/24`, `192.168.1.10-192.168.1.50`,
  /// `192.168.1.10-50` or a single address. For CIDR blocks of /30 and
  /// larger, network and broadcast addresses are excluded.
  factory parse(String text) {
    final input = text.trim();
    if (input.contains('/')) {
      final [address, prefixText] = input.split('/');
      final prefix = int.tryParse(prefixText);
      if (prefix == null || prefix < 0 || prefix > 32) {
        throw FormatException('Invalid prefix length', text);
      }
      final base = Ipv4.parse(address);
      final mask = prefix == 0 ? 0 : (0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF;
      final network = base.value & mask;
      final broadcast = network | (~mask & 0xFFFFFFFF);
      return prefix <= 30
          ? Ipv4Range(Ipv4(network + 1), Ipv4(broadcast - 1))
          : Ipv4Range(Ipv4(network), Ipv4(broadcast));
    }
    if (input.contains('-')) {
      final [start, end] = input.split('-').map((s) => s.trim()).toList();
      final first = Ipv4.parse(start);
      final Ipv4 last;
      if (end.contains('.')) {
        last = Ipv4.parse(end);
      } else {
        // Short form: last octet only.
        final octet = int.tryParse(end);
        if (octet == null || octet < 0 || octet > 255) {
          throw FormatException('Invalid range end', text);
        }
        last = Ipv4((first.value & 0xFFFFFF00) | octet);
      }
      if (last.value < first.value) {
        throw FormatException('Range end before start', text);
      }
      return Ipv4Range(first, last);
    }
    final single = Ipv4.parse(input);
    return Ipv4Range(single, single);
  }

  /// The /24 network around [address] (hosts .1–.254).
  factory around(Ipv4 address) =>
      Ipv4Range.parse('${address.octets.take(3).join('.')}.0/24');

  final Ipv4 first;
  final Ipv4 last;

  int get length => last.value - first.value + 1;

  bool overlaps(Ipv4Range other) =>
      first.value <= other.last.value && last.value >= other.first.value;

  static Ipv4Range? tryParse(String text) {
    try {
      return Ipv4Range.parse(text);
    } on FormatException {
      return null;
    }
  }

  bool contains(Ipv4 address) =>
      address.value >= first.value && address.value <= last.value;

  Iterable<Ipv4> get addresses sync* {
    for (var v = first.value; v <= last.value; v++) {
      yield Ipv4(v);
    }
  }

  @override
  String toString() => length == 1 ? '$first' : '$first–$last';
}
