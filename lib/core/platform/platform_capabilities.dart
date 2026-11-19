import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Why MAC addresses cannot be shown, if they cannot.
enum MacAddressLimit {
  /// Android 10+ and iOS deny apps access to the ARP table.
  platform,

  /// The macOS App Sandbox silently hides the routing table from `arp`.
  sandbox,
}

/// What the current platform can do, so features are hidden instead of
/// crashing when a plugin is unavailable.
@immutable
class PlatformCapabilities {
  const new({
    required this.isDesktop,
    required this.supportsTcp,
    required this.supportsSerial,
    required this.supportsLocalTcpServer,
    this.macAddressLimit,
  });

  factory forPlatform(
    TargetPlatform platform, {
    bool isWeb = false,
    bool isSandboxed = false,
  }) {
    if (isWeb) {
      // Browsers cannot open raw TCP sockets or serial ports via our plugins.
      return const PlatformCapabilities(
        isDesktop: false,
        supportsTcp: false,
        supportsSerial: false,
        supportsLocalTcpServer: false,
        macAddressLimit: MacAddressLimit.platform,
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
      macAddressLimit: !isDesktop
          ? MacAddressLimit.platform
          : isSandboxed && platform == TargetPlatform.macOS
          ? MacAddressLimit.sandbox
          : null,
    );
  }

  final bool isDesktop;
  final bool supportsTcp;
  final bool supportsSerial;
  final bool supportsLocalTcpServer;
  final MacAddressLimit? macAddressLimit;

  bool get supportsRtu => supportsSerial;
  bool get supportsRtuOverTcp => supportsTcp;

  /// MQTT over plain TCP/TLS sockets; browsers only offer WebSockets.
  bool get supportsMqttSockets => supportsTcp;

  /// Reading the ARP table (MAC addresses of scanned hosts).
  bool get supportsMacAddresses => macAddressLimit == null;
}

/// macOS sets this variable for every sandboxed process.
bool _isSandboxed() =>
    !kIsWeb && Platform.environment.containsKey('APP_SANDBOX_CONTAINER_ID');

final platformCapabilitiesProvider = Provider<PlatformCapabilities>(
  (ref) => PlatformCapabilities.forPlatform(
    defaultTargetPlatform,
    isWeb: kIsWeb,
    isSandboxed: _isSandboxed(),
  ),
);
