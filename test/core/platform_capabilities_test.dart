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
}
