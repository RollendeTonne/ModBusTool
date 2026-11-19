import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/core/platform/platform_capabilities.dart';

void main() {
  group('PlatformCapabilities', () {
    for (final platform in [
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.linux,
    ]) {
      test('$platform is desktop with serial and local server', () {
        final caps = PlatformCapabilities.forPlatform(platform);
        expect(caps.isDesktop, isTrue);
        expect(caps.supportsTcp, isTrue);
        expect(caps.supportsRtu, isTrue);
        expect(caps.supportsLocalTcpServer, isTrue);
      });
    }

    test('Android supports serial via USB-OTG but no local server', () {
      final caps = PlatformCapabilities.forPlatform(TargetPlatform.android);
      expect(caps.isDesktop, isFalse);
      expect(caps.supportsRtu, isTrue);
      expect(caps.supportsLocalTcpServer, isFalse);
    });

    test('iOS is TCP only', () {
      final caps = PlatformCapabilities.forPlatform(TargetPlatform.iOS);
      expect(caps.supportsTcp, isTrue);
      expect(caps.supportsRtuOverTcp, isTrue);
      expect(caps.supportsRtu, isFalse);
    });

    test('web supports no transport', () {
      final caps = PlatformCapabilities.forPlatform(
        TargetPlatform.macOS,
        isWeb: true,
      );
      expect(caps.supportsTcp, isFalse);
      expect(caps.supportsSerial, isFalse);
    });
  });

  group('MAC address support', () {
    test('desktop without sandbox reads the ARP table', () {
      for (final p in [
        TargetPlatform.linux,
        TargetPlatform.windows,
        TargetPlatform.macOS,
      ]) {
        expect(
          PlatformCapabilities.forPlatform(p).supportsMacAddresses,
          isTrue,
        );
      }
    });

    test('sandboxed macOS cannot, other sandboxes are ignored', () {
      final mac = PlatformCapabilities.forPlatform(
        TargetPlatform.macOS,
        isSandboxed: true,
      );
      expect(mac.macAddressLimit, MacAddressLimit.sandbox);
      expect(
        PlatformCapabilities.forPlatform(
          TargetPlatform.linux,
          isSandboxed: true,
        ).supportsMacAddresses,
        isTrue,
      );
    });

    test('mobile platforms cannot', () {
      for (final p in [TargetPlatform.android, TargetPlatform.iOS]) {
        expect(
          PlatformCapabilities.forPlatform(p).macAddressLimit,
          MacAddressLimit.platform,
        );
      }
    });
  });
}
