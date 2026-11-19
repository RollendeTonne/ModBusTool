import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the current platform can do, so features are hidden instead of
/// crashing when a plugin is unavailable.
@immutable
class PlatformCapabilities {
  const new({
    required this.isDesktop,
    required this.supportsTcp,
    required this.supportsSerial,
    required this.supportsLocalTcpServer,
  });

  factory forPlatform(TargetPlatform platform, {bool isWeb = false}) {
    if (isWeb) {
      // Browsers cannot open raw TCP sockets or serial ports via our plugins.
      return const PlatformCapabilities(
        isDesktop: false,
        supportsTcp: false,
        supportsSerial: false,
        supportsLocalTcpServer: false,
      );
    }
    final isDesktop = switch (platform) {
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.macOS => true,
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia => false,
    };
    return PlatformCapabilities(
      isDesktop: isDesktop,
      supportsTcp: true,
      // Android reaches serial adapters via USB-OTG; iOS has no public API.
      supportsSerial: isDesktop || platform == TargetPlatform.android,
      // Binding a listening socket for the simulator only makes sense where
      // other tools on the same machine can connect to it.
      supportsLocalTcpServer: isDesktop,
    );
  }

  final bool isDesktop;
  final bool supportsTcp;
  final bool supportsSerial;
  final bool supportsLocalTcpServer;

  bool get supportsRtu => supportsSerial;
  bool get supportsRtuOverTcp => supportsTcp;
}

final platformCapabilitiesProvider = Provider<PlatformCapabilities>(
  (ref) =>
      PlatformCapabilities.forPlatform(defaultTargetPlatform, isWeb: kIsWeb),
);
