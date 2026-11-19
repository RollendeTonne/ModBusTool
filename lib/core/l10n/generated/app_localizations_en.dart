// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Modbus Explorer';

  @override
  String get navConnection => 'Connection';

  @override
  String get navRegisters => 'Registers';

  @override
  String get navMonitor => 'Monitor';

  @override
  String get navTools => 'Tools';

  @override
  String get navSettings => 'Settings';

  @override
  String get connectionStatusDisconnected => 'Disconnected';

  @override
  String get connectionStatusConnecting => 'Connecting…';

  @override
  String get connectionStatusConnected => 'Connected';

  @override
  String get connectionStatusError => 'Error';

  @override
  String connectionStatusLabel(String status) {
    return 'Connection status: $status';
  }

  @override
  String plannedFeatureMilestone(String milestone) {
    return 'Planned for milestone $milestone';
  }

  @override
  String get connectionPageDescription =>
      'Manage Modbus TCP, RTU and RTU-over-TCP connection profiles.';

  @override
  String get registersPageDescription =>
      'Read and write registers, view every interpretation and maintain the register map.';

  @override
  String get monitorPageDescription =>
      'Live log of all frames with hex dump and frame decoding.';

  @override
  String get toolsPageDescription =>
      'Hex calculator, slave/register scanner and statistics.';

  @override
  String get availableTransports => 'Available on this platform';

  @override
  String get transportTcp => 'Modbus TCP';

  @override
  String get transportRtu => 'Modbus RTU (serial)';

  @override
  String get transportRtuOverTcp => 'Modbus RTU over TCP';

  @override
  String get transportUnavailableHint =>
      'Serial ports are not available on this platform.';

  @override
  String get available => 'available';

  @override
  String get unavailable => 'not available';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsModbus => 'Modbus';

  @override
  String get settingsAddressing => 'Addressing';

  @override
  String get addressingZeroBased => '0-based (protocol)';

  @override
  String get addressingOneBased => '1-based (4xxxx/3xxxx)';

  @override
  String get addressingZeroBasedHint =>
      'Addresses are shown exactly as sent on the wire (holding register 0 = first register).';

  @override
  String get addressingOneBasedHint =>
      'Classic notation: holding register 40001 = protocol address 0.';

  @override
  String get settingsConfirmWrites => 'Confirm write operations';

  @override
  String get settingsConfirmWritesHint =>
      'Ask before every write request is sent to the device.';

  @override
  String get settingsHighlightPlausible =>
      'Highlight plausible interpretations';

  @override
  String get settingsHighlightPlausibleHint =>
      'Heuristic marking of values that look meaningful in the interpretation matrix.';
}
