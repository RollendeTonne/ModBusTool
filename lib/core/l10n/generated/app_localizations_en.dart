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

  @override
  String get exceptionIllegalFunctionTitle => '01 Illegal function';

  @override
  String get exceptionIllegalFunctionExplanation =>
      'The device does not support this function code. Try another function (e.g. FC04 instead of FC03) or check the device manual.';

  @override
  String get exceptionIllegalDataAddressTitle => '02 Illegal data address';

  @override
  String get exceptionIllegalDataAddressExplanation =>
      'The address range does not exist on the device. Check the start address, the count and the addressing mode (0- vs. 1-based, off-by-one).';

  @override
  String get exceptionIllegalDataValueTitle => '03 Illegal data value';

  @override
  String get exceptionIllegalDataValueExplanation =>
      'A value in the request is not allowed, e.g. too many registers at once or a value outside the permitted range.';

  @override
  String get exceptionServerDeviceFailureTitle => '04 Server device failure';

  @override
  String get exceptionServerDeviceFailureExplanation =>
      'The device hit an internal error while processing the request. Often caused by reading registers that are reserved or temporarily unavailable.';

  @override
  String get exceptionAcknowledgeTitle => '05 Acknowledge';

  @override
  String get exceptionAcknowledgeExplanation =>
      'The device accepted the request but needs more time to complete it. Poll again later.';

  @override
  String get exceptionServerDeviceBusyTitle => '06 Server device busy';

  @override
  String get exceptionServerDeviceBusyExplanation =>
      'The device is busy with a long-running command. Retry later or poll less frequently.';

  @override
  String get exceptionNegativeAcknowledgeTitle => '07 Negative acknowledge';

  @override
  String get exceptionNegativeAcknowledgeExplanation =>
      'The device cannot perform the requested program function (legacy code).';

  @override
  String get exceptionMemoryParityErrorTitle => '08 Memory parity error';

  @override
  String get exceptionMemoryParityErrorExplanation =>
      'The device detected a parity error in its memory. The device may need servicing.';

  @override
  String get exceptionGatewayPathUnavailableTitle =>
      '0A Gateway path unavailable';

  @override
  String get exceptionGatewayPathUnavailableExplanation =>
      'The gateway could not route the request to the target. Check the gateway configuration and the unit ID.';

  @override
  String get exceptionGatewayTargetFailedTitle =>
      '0B Gateway target failed to respond';

  @override
  String get exceptionGatewayTargetFailedExplanation =>
      'The gateway got no answer from the device behind it. Check unit ID, serial settings and wiring on the serial side.';

  @override
  String exceptionUnknownTitle(String code) {
    return 'Exception $code';
  }

  @override
  String get exceptionUnknownExplanation =>
      'Non-standard exception code. See the device manual.';
}
