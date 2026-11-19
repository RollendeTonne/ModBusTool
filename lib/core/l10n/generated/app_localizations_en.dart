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

  @override
  String get monitorPause => 'Pause';

  @override
  String get monitorResume => 'Resume';

  @override
  String get monitorClear => 'Clear';

  @override
  String get monitorErrorsOnly => 'Errors only';

  @override
  String get monitorAllFunctions => 'All functions';

  @override
  String get monitorCopyText => 'Copy as text';

  @override
  String get monitorCopyCsv => 'Copy as CSV';

  @override
  String monitorCopied(int count) {
    return '$count frames copied';
  }

  @override
  String get monitorEmpty =>
      'No frames yet. Read registers or start polling – every request and response appears here.';

  @override
  String monitorPaused(int count) {
    return 'Paused – $count frames not recorded';
  }

  @override
  String monitorCount(int shown, int total) {
    return '$shown of $total frames';
  }

  @override
  String get monitorSelectHint => 'Select a frame to see its decoding.';

  @override
  String get monitorDetailTitle => 'Frame details';

  @override
  String get monitorHexDump => 'Hex dump';

  @override
  String get monitorFields => 'Fields';

  @override
  String monitorTransaction(int number) {
    return 'Transaction #$number';
  }

  @override
  String monitorAttempts(int count) {
    return '$count attempt(s)';
  }

  @override
  String get monitorResultOk => 'Success';

  @override
  String get monitorCrcValid => 'CRC valid';

  @override
  String get monitorCrcInvalid => 'CRC invalid';

  @override
  String get columnField => 'Field';

  @override
  String get columnBytes => 'Bytes';

  @override
  String get columnTime => 'Time';

  @override
  String get frameStatusOk => 'OK';

  @override
  String get frameStatusCrc => 'CRC error';

  @override
  String get frameStatusMalformed => 'Malformed';

  @override
  String get frameStatusUnexpected => 'Unexpected';

  @override
  String get frameStatusIncomplete => 'Incomplete';

  @override
  String get frameStatusException => 'Exception';

  @override
  String get segmentTransactionId => 'Transaction ID';

  @override
  String get segmentProtocolId => 'Protocol ID';

  @override
  String get segmentLength => 'Length';

  @override
  String get segmentUnitId => 'Unit ID';

  @override
  String get segmentFunctionCode => 'Function code';

  @override
  String get segmentExceptionCode => 'Exception code';

  @override
  String get segmentAddress => 'Address';

  @override
  String get segmentCount => 'Quantity';

  @override
  String get segmentByteCount => 'Byte count';

  @override
  String get segmentValue => 'Value';

  @override
  String get segmentValueList => 'Values';

  @override
  String get segmentAndMask => 'AND mask';

  @override
  String get segmentOrMask => 'OR mask';

  @override
  String get segmentReadAddress => 'Read address';

  @override
  String get segmentReadCount => 'Read quantity';

  @override
  String get segmentWriteAddress => 'Write address';

  @override
  String get segmentWriteCount => 'Write quantity';

  @override
  String get segmentMeiType => 'MEI type';

  @override
  String get segmentDeviceIdCode => 'Device ID code';

  @override
  String get segmentObjectId => 'Object ID';

  @override
  String get segmentConformityLevel => 'Conformity level';

  @override
  String get segmentMoreFollows => 'More follows';

  @override
  String get segmentNextObjectId => 'Next object ID';

  @override
  String get segmentObjectCount => 'Number of objects';

  @override
  String get segmentObject => 'Object';

  @override
  String get segmentData => 'Data';

  @override
  String get segmentCrc => 'CRC';

  @override
  String get segmentTruncated => 'Truncated';

  @override
  String get segmentTrailing => 'Extra bytes';

  @override
  String get toolsHexCalculator => 'Hex calculator';

  @override
  String get toolsScanner => 'Scanner';

  @override
  String get toolsStatistics => 'Statistics';

  @override
  String get toolsTrend => 'Trend';

  @override
  String get hexInput => 'Input';

  @override
  String get hexInputHint => 'e.g. 41 20 00 00 or 0x41200000';

  @override
  String get hexModeBytes => 'Hex bytes';

  @override
  String get hexModeRegisters => 'Registers (hex)';

  @override
  String get hexModeDecimal => 'Registers (dec)';

  @override
  String hexInvalid(String token) {
    return 'Cannot read “$token”';
  }

  @override
  String get hexOddBytes =>
      'Odd number of bytes – the last register was padded with 00.';

  @override
  String get hexBytesLabel => 'Bytes';

  @override
  String get hexRegistersLabel => 'Registers';

  @override
  String get hexCustomOrder => 'Custom byte order';

  @override
  String get hexPattern => 'Pattern';

  @override
  String get hexPatternHint => 'e.g. EFGHABCD';

  @override
  String get hexEncoder => 'Value → registers';

  @override
  String get hexEncodeHint => 'Number; timestamps also as ISO date';

  @override
  String get hexUseAsInput => 'Use as input';

  @override
  String get hexCopyRegisters => 'Copy registers';

  @override
  String get hexEmpty =>
      'Enter bytes or register values to see all interpretations.';

  @override
  String get scanModeSlaves => 'Slave IDs';

  @override
  String get scanModeRegisters => 'Register range';

  @override
  String get scanFrom => 'From';

  @override
  String get scanTo => 'To';

  @override
  String get scanProbeAddress => 'Test register';

  @override
  String get scanTimeout => 'Timeout (ms)';

  @override
  String get scanBlockSize => 'Block size';

  @override
  String get scanStart => 'Start scan';

  @override
  String scanProgress(int done, int total, int found) {
    return '$done / $total · $found found';
  }

  @override
  String scanFinished(String seconds) {
    return 'Finished after $seconds s';
  }

  @override
  String get scanCancelled => 'Cancelled';

  @override
  String get scanNoResults => 'No responses.';

  @override
  String scanUnit(int id) {
    return 'Unit $id';
  }

  @override
  String scanException(String code) {
    return 'Exception $code – device present';
  }

  @override
  String get scanTcpHint =>
      'Note: many Modbus TCP devices answer every unit ID. The scan is most useful behind gateways and on RTU.';

  @override
  String scanSlowHint(int total, String seconds) {
    return 'Each missing ID waits for the timeout ($total IDs ≈ $seconds s at most).';
  }

  @override
  String get statsRequests => 'Requests';

  @override
  String get statsErrors => 'Errors';

  @override
  String get statsErrorRate => 'Error rate';

  @override
  String get statsLatencyAvg => 'Avg. latency';

  @override
  String get statsLatencyMin => 'Min. latency';

  @override
  String get statsLatencyMax => 'Max. latency';

  @override
  String get statsTimeouts => 'Timeouts';

  @override
  String get statsExceptions => 'Exception responses';

  @override
  String get statsProtocolErrors => 'Invalid responses';

  @override
  String get statsConnectionErrors => 'Connection errors';

  @override
  String get statsRetries => 'Retries';

  @override
  String get statsByFunction => 'By function code';

  @override
  String statsSince(String time) {
    return 'Since $time';
  }

  @override
  String get statsEmpty => 'No requests yet.';

  @override
  String trendSelect(int max) {
    return 'Values to plot (numeric register map entries, max. $max)';
  }

  @override
  String get trendNoEntries =>
      'Add numeric entries to the register map to plot them.';

  @override
  String get trendPollMap => 'Poll register map';

  @override
  String get trendWaiting => 'Waiting for data – poll the register map.';

  @override
  String trendMaxReached(int max) {
    return 'At most $max values can be plotted.';
  }

  @override
  String get actionImport => 'Import…';

  @override
  String get actionExportJson => 'Export as JSON…';

  @override
  String get actionExportCsv => 'Export as CSV…';

  @override
  String get actionSaveText => 'Save as text file…';

  @override
  String get actionSaveCsv => 'Save as CSV file…';

  @override
  String exportSaved(String name) {
    return 'Saved: $name';
  }

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get importTitle => 'Import register map';

  @override
  String importSummary(int count, String file) {
    return '$count entries read from $file.';
  }

  @override
  String importSkipped(int count) {
    return '$count entries could not be read and will be skipped.';
  }

  @override
  String get importAdd => 'Add';

  @override
  String get importReplace => 'Replace map';

  @override
  String importNothing(String file) {
    return '$file contains no readable entries.';
  }

  @override
  String importDone(int count) {
    return '$count entries imported';
  }

  @override
  String importFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get actionExportProfiles => 'Export profiles…';

  @override
  String get actionImportProfiles => 'Import profiles…';

  @override
  String profilesImported(int count) {
    return '$count profiles imported';
  }

  @override
  String get settingsShortcuts => 'Keyboard shortcuts';

  @override
  String get shortcutNavigate => 'Switch area';

  @override
  String get shortcutRead => 'Read once (registers or register map)';

  @override
  String get shortcutPoll => 'Start/stop polling';

  @override
  String get shortcutSubmit => 'Confirm dialog / save';

  @override
  String get shortcutClose => 'Close dialog';

  @override
  String get shortcutRange => 'Select a range in the table';

  @override
  String get shortcutShiftClick => 'Shift + click';

  @override
  String get settingsAbout => 'About';

  @override
  String aboutText(String version) {
    return 'Modbus Explorer $version – debugging tool for Modbus TCP and RTU. Data stays on this device.';
  }

  @override
  String get toolsNetwork => 'Network';

  @override
  String get netScanHint =>
      'Finds devices by trying to connect to the selected TCP ports (no ping needed). Only scan networks you are permitted to scan.';

  @override
  String get netScanNoMac =>
      'MAC addresses are not available on this platform (the system does not expose the ARP table to apps).';

  @override
  String get netRange => 'Address range';

  @override
  String get netRangeHint => 'e.g. 192.168.1.0/24 or 192.168.1.10-50';

  @override
  String netRangeTooLarge(int max) {
    return 'At most $max addresses per scan';
  }

  @override
  String get netPorts => 'Ports';

  @override
  String get netModbusPorts => 'Verify Modbus on ports';

  @override
  String get netResolveNames => 'Resolve host names';

  @override
  String get netStart => 'Scan network';

  @override
  String get netPhasePorts => 'Probing ports';

  @override
  String get netPhaseArp => 'Reading MAC addresses';

  @override
  String get netPhaseModbus => 'Identifying Modbus devices';

  @override
  String get netPhaseHostnames => 'Resolving host names';

  @override
  String get netPhaseDone => 'Finished';

  @override
  String netProgress(String phase, int done, int total, int hosts) {
    return '$phase: $done / $total · $hosts hosts';
  }

  @override
  String netSummary(int hosts, int modbus, String seconds) {
    return '$hosts hosts · $modbus with Modbus · $seconds s';
  }

  @override
  String get netOnlyModbus => 'Only Modbus devices';

  @override
  String get netThisDevice => 'this device';

  @override
  String get netNoMac => 'MAC unknown';

  @override
  String get netNoHosts => 'No hosts found.';

  @override
  String netModbusVerified(int port) {
    return 'Modbus on port $port';
  }

  @override
  String netModbusException(String code) {
    return 'answers with exception $code';
  }

  @override
  String get netNoOpenPorts =>
      'no open ports (seen via ARP or refused connection)';

  @override
  String get netConnect => 'Connect';

  @override
  String netProfileCreated(String name) {
    return 'Profile “$name” created and connected';
  }

  @override
  String get netExport => 'Export results…';

  @override
  String get netScanNoMacSandbox =>
      'MAC addresses are not available: the macOS app sandbox blocks access to the ARP table.';
}
