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
  String get monitorPageDescription =>
      'Live log of all frames with hex dump and frame decoding.';

  @override
  String get toolsPageDescription =>
      'Hex calculator, slave/register scanner and statistics.';

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

  @override
  String get actionConnect => 'Connect';

  @override
  String get actionDisconnect => 'Disconnect';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionDuplicate => 'Duplicate';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionRetry => 'Try again';

  @override
  String profileCopyName(String name) {
    return '$name (copy)';
  }

  @override
  String get profilesTitle => 'Connection profiles';

  @override
  String get profileNew => 'New profile';

  @override
  String get profileEditTitle => 'Edit profile';

  @override
  String get profileDeleteTitle => 'Delete profile?';

  @override
  String profileDeleteBody(String name) {
    return '\"$name\" will be removed permanently.';
  }

  @override
  String profileLastUsed(String date) {
    return 'Last used $date';
  }

  @override
  String get profileNeverUsed => 'Never used';

  @override
  String get profilesEmpty =>
      'No profiles yet. Create one to connect to a device.';

  @override
  String get profileActive => 'Active';

  @override
  String get connectionKindTcp => 'Modbus TCP';

  @override
  String get connectionKindRtu => 'Modbus RTU';

  @override
  String get connectionKindRtuOverTcp => 'RTU over TCP';

  @override
  String get connectionKindSimulator => 'Simulator';

  @override
  String get sectionConnection => 'Connection';

  @override
  String get sectionSerial => 'Serial settings';

  @override
  String get sectionRequests => 'Requests';

  @override
  String get sectionSimulator => 'Simulation';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldHost => 'Host / IP address';

  @override
  String get fieldPort => 'Port';

  @override
  String get fieldUnitId => 'Unit/slave ID';

  @override
  String get fieldTimeout => 'Timeout (ms)';

  @override
  String get fieldRetries => 'Retries';

  @override
  String get fieldSerialPort => 'Serial port';

  @override
  String get fieldBaudRate => 'Baud rate';

  @override
  String get fieldCustomBaudRate => 'Custom baud rate';

  @override
  String get baudRateCustom => 'Custom…';

  @override
  String get fieldDataBits => 'Data bits';

  @override
  String get fieldParity => 'Parity';

  @override
  String get parityNone => 'None';

  @override
  String get parityEven => 'Even';

  @override
  String get parityOdd => 'Odd';

  @override
  String get fieldStopBits => 'Stop bits';

  @override
  String get fieldRts => 'RTS line';

  @override
  String get fieldDtr => 'DTR line';

  @override
  String get lineUnchanged => 'Unchanged';

  @override
  String get lineOn => 'On';

  @override
  String get lineOff => 'Off';

  @override
  String get fieldInterFrameDelay => 'Inter-frame delay (ms)';

  @override
  String interFrameDelayAuto(String value) {
    return 'Empty = automatic (t3.5 = $value ms)';
  }

  @override
  String get fieldAutoReconnect => 'Reconnect automatically';

  @override
  String get fieldAutoReconnectHint =>
      'Retries with increasing delay when the connection drops.';

  @override
  String get fieldSimFraming => 'Framing';

  @override
  String get fieldSimLatency => 'Simulated latency (ms)';

  @override
  String get fieldSimDrop => 'Lost responses (%)';

  @override
  String get fieldSimCorrupt => 'Corrupted responses (%)';

  @override
  String get refreshPorts => 'Refresh ports';

  @override
  String get noPortsFound => 'No serial ports found';

  @override
  String portNotAvailable(String port) {
    return '$port (not connected)';
  }

  @override
  String get validationRequired => 'Required';

  @override
  String validationRange(int min, int max) {
    return 'Must be between $min and $max';
  }

  @override
  String get validationNumber => 'Enter a number';

  @override
  String get statusNotConnected => 'Not connected';

  @override
  String get statusNotConnectedHint => 'Choose a profile and connect.';

  @override
  String statusConnectedTo(String target) {
    return 'Connected to $target';
  }

  @override
  String statusConnectingTo(String target) {
    return 'Connecting to $target…';
  }

  @override
  String statusReconnecting(int attempt) {
    return 'Connection lost – reconnecting (attempt $attempt)…';
  }

  @override
  String statusSince(String time) {
    return 'since $time';
  }

  @override
  String statusFailed(String target) {
    return 'Connection to $target failed';
  }

  @override
  String get errorDetails => 'Technical details';

  @override
  String get errorRefusedTitle => 'Connection refused';

  @override
  String get errorRefusedHint =>
      'The device is reachable, but nothing listens on this port. Check the port number and whether Modbus TCP is enabled on the device.';

  @override
  String get errorConnectTimeoutTitle => 'Device not reachable';

  @override
  String get errorConnectTimeoutHint =>
      'No answer to the connection attempt. Check IP address, network cable, subnet and firewall.';

  @override
  String get errorHostNotFoundTitle => 'Host not found';

  @override
  String get errorHostNotFoundHint =>
      'The host name could not be resolved. Check the spelling or use the IP address.';

  @override
  String get errorUnreachableTitle => 'Network unreachable';

  @override
  String get errorUnreachableHint =>
      'Check the network adapter and the IP/subnet settings of this computer.';

  @override
  String get errorPortUnavailableTitle => 'Serial port not available';

  @override
  String get errorPortUnavailableHint =>
      'The port is missing or used by another program. Re-plug the adapter or close other tools.';

  @override
  String get errorPermissionTitle => 'Access denied';

  @override
  String get errorPermissionHint =>
      'No permission to use the port. Linux: add your user to the \'dialout\' group. Android: allow USB access.';

  @override
  String get errorInvalidSettingsTitle => 'Settings not supported';

  @override
  String get errorInvalidSettingsHint =>
      'The adapter does not support these serial settings (baud rate, data bits, parity, stop bits).';

  @override
  String get errorUnsupportedTitle => 'Not supported on this platform';

  @override
  String get errorUnsupportedHint =>
      'Use Modbus TCP or the simulator on this device.';

  @override
  String get errorClosedTitle => 'Connection lost';

  @override
  String get errorClosedHint =>
      'The device, gateway or network closed the connection.';

  @override
  String get errorConnectionTitle => 'Connection failed';

  @override
  String get errorConnectionHint => 'See the technical details below.';

  @override
  String get errorTimeoutTitle => 'No response';

  @override
  String errorTimeoutHint(int timeout, int attempts) {
    return 'No valid answer within $timeout ms ($attempts attempt(s)). Check unit ID, serial settings (baud rate, parity) and wiring (A/B swapped?).';
  }

  @override
  String get errorProtocolTitle => 'Invalid response';

  @override
  String get errorProtocolHint =>
      'The device answered, but the response is malformed. Possible causes: line noise, wrong framing (TCP vs. RTU over TCP) or a second master on the bus.';

  @override
  String get errorNotConnectedTitle => 'Not connected';

  @override
  String get errorNotConnectedHint => 'Connect to a device first.';

  @override
  String get errorWriteLockedTitle => 'Writing is locked';

  @override
  String get errorWriteLockedHint => 'Enable writing first.';

  @override
  String get errorUnexpectedTitle => 'Unexpected error';

  @override
  String get simulatorServerTitle => 'Simulator TCP server';

  @override
  String get simulatorServerHint =>
      'Lets other Modbus tools connect to the demo device.';

  @override
  String simulatorServerRunning(String address) {
    return 'Running on $address';
  }

  @override
  String simulatorServerConnections(int count) {
    return '$count client(s) connected';
  }

  @override
  String get simulatorServerStopped => 'Stopped';

  @override
  String get simulatorServerExpose => 'Reachable from the network';

  @override
  String simulatorServerStartFailed(String error) {
    return 'Could not start: $error';
  }

  @override
  String get tableCoils => 'Coils';

  @override
  String get tableDiscreteInputs => 'Discrete inputs';

  @override
  String get tableInputRegisters => 'Input registers';

  @override
  String get tableHoldingRegisters => 'Holding registers';

  @override
  String get fieldStartAddress => 'Start address';

  @override
  String get fieldCount => 'Count';

  @override
  String get fieldUnitIdOverride => 'Unit ID';

  @override
  String get fieldUnitIdOverrideHint => 'Empty = profile';

  @override
  String addressHintProtocol(String address) {
    return '= protocol address $address';
  }

  @override
  String get addressModeTooltip => 'Addressing mode – change in settings';

  @override
  String get actionRead => 'Read';

  @override
  String actionReadTooltip(String shortcut) {
    return 'Read once ($shortcut)';
  }

  @override
  String get actionStartPolling => 'Poll';

  @override
  String get actionStopPolling => 'Stop';

  @override
  String get fieldPollInterval => 'Interval (ms)';

  @override
  String get writeUnlockLabel => 'Writing enabled';

  @override
  String get writeUnlockTooltip =>
      'Protection against accidental writes; resets when the app restarts.';

  @override
  String get columnAddress => 'Address';

  @override
  String get columnHex => 'Hex';

  @override
  String get columnUnsigned => 'Unsigned';

  @override
  String get columnSigned => 'Signed';

  @override
  String get columnBinary => 'Binary';

  @override
  String get columnValue => 'Value';

  @override
  String get bitOn => 'ON';

  @override
  String get bitOff => 'OFF';

  @override
  String get registersEmpty => 'No data yet. Press Read or start polling.';

  @override
  String readStatus(int count, int latency, String time) {
    return '$count values · $latency ms · $time';
  }

  @override
  String pollStatus(int reads, int errors) {
    return 'Polls: $reads · errors: $errors';
  }

  @override
  String get actionOpenConnections => 'Open connections';

  @override
  String get actionConnectSimulator => 'Connect to simulator';

  @override
  String writeRegisterTitle(String address) {
    return 'Write register $address';
  }

  @override
  String get writeMultipleTitle => 'Write multiple values';

  @override
  String get actionWriteMultiple => 'Write multiple…';

  @override
  String get actionWriteRow => 'Write value';

  @override
  String get fieldValue => 'Value';

  @override
  String get valueFormatsHint =>
      'Decimal (-32768…65535), 0x… hex or 0b… binary';

  @override
  String get fieldValues => 'Values';

  @override
  String get registerValuesHint =>
      'Separated by comma or space; decimal, 0x… or 0b…';

  @override
  String get coilValuesHint => '1/0 or on/off, separated by comma or space';

  @override
  String get useFc16 => 'Send as FC16 (for devices without FC06)';

  @override
  String get bitsLabel => 'Bits – click to toggle';

  @override
  String get actionWrite => 'Write';

  @override
  String get confirmWriteTitle => 'Confirm write';

  @override
  String confirmWriteBody(int unit) {
    return 'Send to unit $unit?';
  }

  @override
  String writeSuccess(String summary) {
    return 'Written: $summary';
  }

  @override
  String get invalidValue => 'Invalid value';

  @override
  String tooManyValues(int max) {
    return 'At most $max values';
  }

  @override
  String get rangeExceedsAddressSpace => 'Range exceeds address 65535';

  @override
  String get interpretationTitle => 'Interpretation';

  @override
  String interpretationSelection(String range, int count) {
    return '$range · $count register(s)';
  }

  @override
  String get interpretationHint =>
      'Select a register in the table (Shift+click for a range).';

  @override
  String get interpretationBitTables =>
      'Interpretations are available for input and holding registers.';

  @override
  String get interpretationNoData =>
      'Read registers to see all interpretations.';

  @override
  String sectionRegister(String address) {
    return 'Register $address';
  }

  @override
  String get labelHighByte => 'High byte';

  @override
  String get labelLowByte => 'Low byte';

  @override
  String get labelAscii => 'ASCII';

  @override
  String get bitsReadOnlyHint => 'Enable writing to toggle bits.';

  @override
  String get sectionMatrix => 'All interpretations';

  @override
  String get columnType => 'Type';

  @override
  String matrixNeedsRegisters(int count) {
    return 'Needs $count registers';
  }

  @override
  String get matrixDuplicate => 'Same byte order as an earlier column';

  @override
  String get plausibilityNaN => 'Not a number (NaN)';

  @override
  String get plausibilityInfinite => 'Infinite';

  @override
  String get plausibilityDenormal =>
      'Denormalized float – almost certainly the wrong byte order';

  @override
  String get plausibilityHuge => 'Implausibly large';

  @override
  String get plausibilityTiny => 'Implausibly small';

  @override
  String get plausibilityManyDigits =>
      'Many significant digits – rather unlikely';

  @override
  String get plausibilityDate => 'Date outside 2000–2100';

  @override
  String get plausibilityNonPrintable => 'Contains non-printable characters';

  @override
  String get plausibilityInvalid => 'Invalid value';

  @override
  String get plausibilityPlausible => 'Looks plausible';

  @override
  String copiedValue(String value) {
    return 'Copied: $value';
  }

  @override
  String get copiedTable => 'Table copied';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionAddToMap => 'Add to register map…';

  @override
  String get actionCopyTable => 'Copy table';

  @override
  String get actionCopyCsv => 'Copy as CSV';

  @override
  String get sectionText => 'Text';

  @override
  String get textSwapBytes => 'Swap bytes (BA)';

  @override
  String get fieldEncoding => 'Encoding';

  @override
  String get sectionScaling => 'Scaling';

  @override
  String get fieldFactor => 'Factor';

  @override
  String get fieldOffset => 'Offset';

  @override
  String get fieldDecimals => 'Decimals';

  @override
  String get scalingHint => 'Shown value = raw × factor + offset';

  @override
  String get actionReset => 'Reset';

  @override
  String get viewRaw => 'Raw values';

  @override
  String viewMap(int count) {
    return 'Register map ($count)';
  }

  @override
  String get columnLabel => 'Label';

  @override
  String get mapEmpty =>
      'No entries yet. Select registers, open the menu of a cell in the interpretation table and choose “Add to register map”, or add an entry manually.';

  @override
  String get mapNoProfile =>
      'Create a connection profile first – register maps are stored per profile.';

  @override
  String get mapSearch => 'Search label or address';

  @override
  String get mapSortAddress => 'By address';

  @override
  String get mapSortLabel => 'By label';

  @override
  String get actionAddEntry => 'Add entry';

  @override
  String get actionReadMap => 'Read all';

  @override
  String get mapEntryNewTitle => 'New register map entry';

  @override
  String get mapEntryEditTitle => 'Edit entry';

  @override
  String get fieldLabel => 'Label';

  @override
  String get fieldUnit => 'Unit';

  @override
  String get fieldDescription => 'Description';

  @override
  String get fieldTable => 'Table';

  @override
  String get fieldAddress => 'Address';

  @override
  String get fieldType => 'Data type';

  @override
  String get fieldByteOrder => 'Byte order';

  @override
  String get fieldTextRegisters => 'Length (registers)';

  @override
  String get fieldBit => 'Bit (0–15)';

  @override
  String get typeText => 'Text';

  @override
  String get typeBit => 'Bit';

  @override
  String get mapEntryDeleteTitle => 'Delete entry?';

  @override
  String mapEntryDeleteBody(String label) {
    return '\"$label\" will be removed from the register map.';
  }

  @override
  String mapReadStatus(int count, String time) {
    return '$count entries · $time';
  }

  @override
  String mapEntryCount(int count) {
    return '$count entries';
  }

  @override
  String get actionInterpret => 'Interpret';

  @override
  String mapEntrySaved(String label) {
    return 'Saved to register map: $label';
  }

  @override
  String get mapUnnamed => '(unnamed)';
}
