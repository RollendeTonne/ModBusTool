// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ProtocollExplorer';

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
    return 'ProtocollExplorer $version – debugging tool for Modbus TCP/RTU and MQTT. Data stays on this device.';
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

  @override
  String get netArpEmptyHint =>
      'No MAC addresses received: the system returned an empty ARP table. On macOS, allow local network access for ProtocollExplorer (System Settings → Privacy & Security → Local Network) and scan again.';

  @override
  String get netMacRoutedHint =>
      'No MAC addresses for this range: it is outside this computer\'s local network segment (reached via a router). MAC addresses can only be determined for devices in the same segment.';

  @override
  String get netUseActive => 'Active network';

  @override
  String get netUseActiveTooltip =>
      'Fill in the range of the network currently in use';

  @override
  String get netActiveNone => 'No active network found';

  @override
  String netActiveFound(String iface, String address, String range) {
    return '$iface: $address → $range';
  }

  @override
  String get netActiveMaskUnknown => 'Netmask unknown, assuming /24';

  @override
  String netPortOpenBrowser(String target) {
    return 'Open in browser: $target';
  }

  @override
  String netPortOpenTerminal(String target) {
    return 'Open in terminal: $target';
  }

  @override
  String netPortOpenFiles(String target) {
    return 'Open in file manager: $target';
  }

  @override
  String netPortOpenRemote(String target) {
    return 'Open remote desktop: $target';
  }

  @override
  String netPortOpenOpcUa(String target) {
    return 'Open in OPC UA client: $target';
  }

  @override
  String netPortConnectModbus(int port) {
    return 'Connect via Modbus TCP (port $port)';
  }

  @override
  String netPortCopy(String target) {
    return 'No suitable program known – copy $target';
  }

  @override
  String netPortCopied(String target) {
    return '$target copied';
  }

  @override
  String netPortNoApp(String target) {
    return 'No program found for $target – address copied';
  }

  @override
  String get navTopics => 'Topics';

  @override
  String get moduleModbus => 'Modbus';

  @override
  String get moduleMqtt => 'MQTT';

  @override
  String get moduleSwitchTooltip => 'Switch module (Ctrl/⌘ + Shift + M)';

  @override
  String get mqttProfiles => 'Broker profiles';

  @override
  String get mqttNewProfile => 'New broker profile';

  @override
  String get mqttEditProfile => 'Edit broker profile';

  @override
  String get mqttNoProfiles => 'No broker profiles yet.';

  @override
  String get mqttStatusDisconnected => 'Disconnected';

  @override
  String get mqttStatusConnecting => 'Connecting …';

  @override
  String get mqttStatusConnected => 'Connected';

  @override
  String get mqttStatusReconnecting => 'Reconnecting …';

  @override
  String get mqttStatusError => 'Error';

  @override
  String mqttStatusLabel(String status) {
    return 'MQTT status: $status';
  }

  @override
  String get mqttConnect => 'Connect';

  @override
  String get mqttDisconnect => 'Disconnect';

  @override
  String get mqttCancelReconnect => 'Cancel';

  @override
  String mqttClientIdLabel(String id) {
    return 'Client ID: $id';
  }

  @override
  String mqttReconnectIn(int attempt, int seconds) {
    return 'Attempt $attempt in $seconds s';
  }

  @override
  String get mqttSimulatorBadge => 'Demo broker';

  @override
  String get mqttSimulatorHint =>
      'Built-in demo broker: publishes JSON, binary and retained topics plus \$SYS values. Username “denied” shows a refused connection.';

  @override
  String get mqttFieldType => 'Type';

  @override
  String get mqttTypeBroker => 'Broker';

  @override
  String get mqttTypeSimulator => 'Demo broker';

  @override
  String get mqttFieldTransport => 'Transport';

  @override
  String get mqttFieldWsPath => 'WebSocket path';

  @override
  String get mqttFieldVersion => 'Protocol version';

  @override
  String get mqttFieldClientId => 'Client ID';

  @override
  String get mqttClientIdAuto =>
      'empty = generate a random ID on every connect';

  @override
  String get mqttGenerateClientId => 'Generate client ID';

  @override
  String get mqttFieldUsername => 'Username';

  @override
  String get mqttFieldPassword => 'Password';

  @override
  String get mqttPasswordStored => 'stored – leave empty to keep it';

  @override
  String get mqttPasswordSecure =>
      'stored in the system keychain, not in the profile';

  @override
  String get mqttRemovePassword => 'Delete stored password';

  @override
  String get mqttSectionBroker => 'Broker';

  @override
  String get mqttSectionAuth => 'Authentication';

  @override
  String get mqttSectionSession => 'Session';

  @override
  String get mqttSectionWill => 'Last will';

  @override
  String get mqttSectionTls => 'TLS';

  @override
  String get mqttCleanStart => 'Clean start / clean session';

  @override
  String get mqttCleanStartHint =>
      'Off: the broker keeps the session’s subscriptions and QoS 1/2 messages';

  @override
  String get mqttFieldKeepAlive => 'Keep alive (s)';

  @override
  String get mqttFieldSessionExpiry => 'Session expiry (s, MQTT 5)';

  @override
  String get mqttFieldConnectTimeout => 'Connect timeout (s)';

  @override
  String get mqttAutoReconnect => 'Reconnect automatically';

  @override
  String get mqttWillEnabled => 'Send last will';

  @override
  String get mqttFieldTopic => 'Topic';

  @override
  String get mqttFieldPayload => 'Payload';

  @override
  String get mqttFieldQos => 'QoS';

  @override
  String get mqttRetain => 'Retain';

  @override
  String get mqttTlsVerify =>
      'The server certificate is checked against the system CAs.';

  @override
  String get mqttCaCert => 'Custom CA (PEM)';

  @override
  String get mqttClientCert => 'Client certificate (PEM)';

  @override
  String get mqttClientKey => 'Client private key (PEM)';

  @override
  String get mqttClientKeyStored => 'stored in the keychain';

  @override
  String get mqttClientKeyPassword => 'Key password';

  @override
  String get mqttLoadFile => 'Load file';

  @override
  String get mqttRemove => 'Remove';

  @override
  String get mqttNotSet => 'not set';

  @override
  String get mqttAcceptInvalid => 'Accept invalid certificates';

  @override
  String get mqttAcceptInvalidWarning =>
      'Insecure: the connection is then not protected against eavesdropping or tampering. Only use for test brokers with self-signed certificates.';

  @override
  String get mqttWssCertLimit =>
      'Over WebSocket (wss) the MQTT package does not support a custom CA or client certificates; the system CAs apply.';

  @override
  String get mqttWebOnlyWs => 'Browsers only support WebSocket connections.';

  @override
  String get mqttErrorTitle => 'Connection failed';

  @override
  String get mqttErrorLost => 'Connection to the broker lost';

  @override
  String get mqttFailNetwork =>
      'Broker unreachable. Check host, port and network.';

  @override
  String get mqttFailTls =>
      'TLS error: certificate rejected or handshake failed. Check the CA, host name and port (8883?).';

  @override
  String get mqttFailTimeout => 'Timeout: the broker did not answer in time.';

  @override
  String get mqttFailLost =>
      'The broker closed the connection (e.g. keep alive expired or the same client ID connected elsewhere).';

  @override
  String get mqttFailUnknown => 'Unknown error while connecting.';

  @override
  String mqttFailRefused(String reason, String code) {
    return 'Broker refused: $reason (code $code)';
  }

  @override
  String get connackProtocolVersion => 'unsupported protocol version';

  @override
  String get connackClientId => 'client ID rejected';

  @override
  String get connackServerUnavailable => 'server unavailable';

  @override
  String get connackBadCredentials => 'bad user name or password';

  @override
  String get connackNotAuthorized => 'not authorized';

  @override
  String get connackUnspecified => 'unspecified error';

  @override
  String get connackMalformed => 'malformed packet';

  @override
  String get connackProtocolError => 'protocol error';

  @override
  String get connackImplementation => 'implementation-specific error';

  @override
  String get connackServerBusy => 'server busy';

  @override
  String get connackBanned => 'client banned';

  @override
  String get connackBadAuthMethod => 'bad authentication method';

  @override
  String get connackTopicInvalid => 'topic name invalid (last will)';

  @override
  String get connackPacketTooLarge => 'packet too large';

  @override
  String get connackQuota => 'quota exceeded';

  @override
  String get connackPayloadFormat => 'payload format invalid';

  @override
  String get connackRetainNotSupported => 'retain not supported (last will)';

  @override
  String get connackQosNotSupported => 'QoS not supported (last will)';

  @override
  String get connackUseAnotherServer => 'use another server';

  @override
  String get connackServerMoved => 'server moved';

  @override
  String get connackRateExceeded => 'connection rate exceeded';

  @override
  String get connackUnknown => 'unknown reason';

  @override
  String get mqttNotConnectedHint => 'Not connected to a broker.';

  @override
  String get mqttGoToConnection => 'Go to connection';

  @override
  String get mqttTabMessages => 'Messages';

  @override
  String get mqttTabSubscriptions => 'Subscriptions';

  @override
  String get mqttTabPublish => 'Publish';

  @override
  String mqttMessagesCount(int shown, int total) {
    return '$shown of $total messages';
  }

  @override
  String get mqttNoMessages => 'No messages yet. Check the subscriptions.';

  @override
  String get mqttPause => 'Pause';

  @override
  String get mqttResume => 'Resume';

  @override
  String get mqttClear => 'Clear';

  @override
  String get mqttSubscriptions => 'Subscriptions';

  @override
  String get mqttNoSubscriptions => 'No subscriptions.';

  @override
  String get mqttAddSubscription => 'Subscribe';

  @override
  String get mqttTopicFilter => 'Topic filter';

  @override
  String get mqttTopicFilterHint => 'e.g. home/+/temperature or sensors/#';

  @override
  String get mqttSubscribeAll => 'Subscribe to everything (#)';

  @override
  String get mqttSubscribeAllWarning =>
      '“#” receives every message on the broker. On large or public brokers this can be thousands of messages per second. Subscribe anyway?';

  @override
  String get mqttSubscribeAllConfirm => 'Subscribe';

  @override
  String get mqttMqtt5Options => 'MQTT 5 options';

  @override
  String get mqttNoLocal => 'No local (do not receive own messages)';

  @override
  String get mqttRetainAsPublished => 'Retain as published';

  @override
  String get mqttRetainHandling => 'Retain handling';

  @override
  String get mqttRetainSend => 'send retained on subscribe';

  @override
  String get mqttRetainSendIfNew => 'only for new subscriptions';

  @override
  String get mqttRetainDont => 'do not send';

  @override
  String get mqttSubscriptionEnabled => 'active';

  @override
  String get mqttDeleteSubscription => 'Remove subscription';

  @override
  String get mqttFormat => 'Format';

  @override
  String get mqttPublishAction => 'Publish';

  @override
  String mqttPublishTooltip(String shortcut) {
    return 'Publish ($shortcut)';
  }

  @override
  String mqttPublished(String topic, int bytes) {
    return 'Published to “$topic” ($bytes bytes)';
  }

  @override
  String get mqttClearRetained => 'Clear retained message';

  @override
  String mqttClearRetainedConfirm(String topic) {
    return 'The retained message on “$topic” will be deleted (empty payload with retain). New subscribers will no longer get a stored value.';
  }

  @override
  String mqttClearRetainedDone(String topic) {
    return 'Retained message on “$topic” cleared';
  }

  @override
  String get mqttOverwriteTitle => 'Overwrite an existing topic?';

  @override
  String mqttOverwriteText(String topic) {
    return 'Messages were already received on “$topic”. Publish anyway?';
  }

  @override
  String get mqttDontAskAgain => 'Don’t ask again';

  @override
  String get mqttConfirmOverwrite => 'Ask before publishing to known topics';

  @override
  String get mqttProperties => 'MQTT 5 properties';

  @override
  String get mqttContentType => 'Content type';

  @override
  String get mqttResponseTopic => 'Response topic';

  @override
  String get mqttCorrelationData => 'Correlation data (text)';

  @override
  String get mqttMessageExpiry => 'Message expiry (s)';

  @override
  String get mqttUserProperties => 'User properties (one per line: name=value)';

  @override
  String get mqttPropertiesV311Hint => 'Only available with MQTT 5.';

  @override
  String get mqttTopicErrorEmpty => 'Topic must not be empty';

  @override
  String get mqttTopicErrorWildcard =>
      '+ and # are not allowed when publishing';

  @override
  String get mqttTopicErrorMultiLevel =>
      '# is only allowed alone as the last level';

  @override
  String get mqttTopicErrorSingleLevel => '+ must be a whole level';

  @override
  String get mqttTopicErrorNull => 'Null character not allowed';

  @override
  String get mqttTopicErrorTooLong => 'Topic too long (max. 65535 bytes)';

  @override
  String mqttPayloadInvalid(String error) {
    return 'Invalid payload: $error';
  }

  @override
  String get mqttRx => 'RX';

  @override
  String get mqttTx => 'TX';

  @override
  String get mqttDeleteProfileTitle => 'Delete broker profile?';

  @override
  String mqttDeleteProfileText(String name) {
    return '“$name” and its stored credentials will be deleted.';
  }

  @override
  String mqttProfileCopy(String name) {
    return '$name (copy)';
  }

  @override
  String mqttComingSoonMilestone(String milestone) {
    return 'This area follows in $milestone.';
  }

  @override
  String get mqttTabTree => 'Tree';

  @override
  String get mqttTabDetails => 'Details';

  @override
  String get mqttTreeSearch => 'Filter topics';

  @override
  String mqttTreeSearchTooltip(String shortcut) {
    return 'Filter topics ($shortcut)';
  }

  @override
  String get mqttFilterText => 'Text';

  @override
  String get mqttFilterWildcard => 'Wildcard (+/#)';

  @override
  String get mqttFilterRegex => 'Regex';

  @override
  String get mqttTreeShowSys => 'Show \$SYS';

  @override
  String get mqttTreeOnlyChanged => 'Only changed';

  @override
  String get mqttTreeOnlyChangedTooltip =>
      'Hide topics whose value never changed';

  @override
  String get mqttTreeExpandAll => 'Expand all';

  @override
  String get mqttTreeCollapseAll => 'Collapse all';

  @override
  String get mqttTreeClear => 'Clear tree';

  @override
  String mqttTreeStats(int topics, int messages) {
    return '$topics topics · $messages messages';
  }

  @override
  String get mqttTreeEmpty => 'No topics received yet.';

  @override
  String get mqttTreeNoMatch => 'No topic matches the filter.';

  @override
  String mqttTreeFilterError(String error) {
    return 'Invalid filter: $error';
  }

  @override
  String mqttNodeMessages(int count) {
    return '$count msg';
  }

  @override
  String mqttNodeTopics(int count) {
    return '$count topics';
  }

  @override
  String get mqttEmptyLevel => '(empty)';

  @override
  String get mqttRetainedBadge => 'Retained';

  @override
  String get mqttExpand => 'Expand';

  @override
  String get mqttCollapse => 'Collapse';

  @override
  String get mqttDetailNone => 'Select a topic in the tree.';

  @override
  String get mqttDetailBranch =>
      'No message was received on this level itself.';

  @override
  String get mqttDetailLast => 'Last message';

  @override
  String get mqttDetailReceived => 'Received';

  @override
  String get mqttDetailMessages => 'Messages';

  @override
  String get mqttDetailSubtopics => 'Subtopics';

  @override
  String get mqttDetailSize => 'Size';

  @override
  String get mqttDetailFlags => 'QoS / flags';

  @override
  String get mqttDetailChanged => 'Last changed';

  @override
  String mqttBytes(int count) {
    return '$count bytes';
  }

  @override
  String mqttTruncated(int count) {
    return '… truncated, $count bytes in total';
  }

  @override
  String mqttSecondsAgo(int value) {
    return '$value s ago';
  }

  @override
  String mqttMinutesAgo(int value) {
    return '$value min ago';
  }

  @override
  String mqttHoursAgo(int value) {
    return '$value h ago';
  }

  @override
  String get mqttCopyTopic => 'Copy topic';

  @override
  String get mqttCopyPayload => 'Copy payload';

  @override
  String get mqttCopied => 'Copied';

  @override
  String get mqttUseForPublish => 'Use for publish';

  @override
  String mqttSubscribeSubtree(String filter) {
    return 'Subscribe to $filter';
  }

  @override
  String matrixNeedsBytes(int count) {
    return 'Needs $count bytes';
  }

  @override
  String payloadDetected(String kind) {
    return 'Detected: $kind';
  }

  @override
  String get payloadKindEmpty => 'empty';

  @override
  String get payloadKindJson => 'JSON';

  @override
  String get payloadKindJsonBroken => 'JSON (invalid)';

  @override
  String get payloadKindXml => 'XML';

  @override
  String get payloadKindXmlBroken => 'XML (invalid)';

  @override
  String get payloadKindText => 'Text (UTF-8)';

  @override
  String get payloadKindBase64 => 'Base64';

  @override
  String get payloadKindBinary => 'Binary';

  @override
  String get payloadTabContent => 'Content';

  @override
  String get payloadTabText => 'Text';

  @override
  String get payloadTabHex => 'Hex';

  @override
  String get payloadTabBinary => 'Binary';

  @override
  String get payloadTabMeta => 'Metadata';

  @override
  String get payloadJsonTree => 'Tree';

  @override
  String get payloadJsonPretty => 'Formatted';

  @override
  String get payloadJsonRaw => 'Raw';

  @override
  String payloadPathCopied(String path) {
    return '$path copied';
  }

  @override
  String get payloadCopyPathHint => 'Tap copies the JSON path';

  @override
  String payloadSyntaxError(int line, int column, String message) {
    return 'Syntax error in line $line, column $column: $message';
  }

  @override
  String payloadMoreItems(int count) {
    return '… $count more';
  }

  @override
  String get payloadEmpty => 'Empty payload (0 bytes).';

  @override
  String get payloadBinaryHint => 'Binary data – see Hex and Binary.';

  @override
  String payloadBase64Decoded(int count) {
    return 'Base64 decoded ($count bytes)';
  }

  @override
  String get payloadInterpretDecoded => 'Interpret decoded bytes';

  @override
  String get payloadEncoding => 'Encoding';

  @override
  String get payloadShowMore => 'Show more';

  @override
  String payloadHexLines(int shown, int total) {
    return '$shown of $total lines';
  }

  @override
  String get payloadOffset => 'Offset (byte)';

  @override
  String payloadOffsetHint(int max) {
    return '0 … $max';
  }

  @override
  String payloadWindow(String bytes) {
    return 'Bytes from offset: $bytes';
  }

  @override
  String get payloadSource => 'Source';

  @override
  String get payloadSourcePayload => 'Payload';

  @override
  String get payloadSourceBase64 => 'Base64 decoded';

  @override
  String get payloadEightBit => '8 bit';

  @override
  String get payloadBits => 'Bits (MSB first)';

  @override
  String get payloadNoBytes => 'No bytes from this offset.';

  @override
  String payloadValueCopied(String value) {
    return '$value copied';
  }

  @override
  String get payloadMetaNoV5 =>
      'No MQTT 5 properties (MQTT 3.1.1 or not set by the sender).';

  @override
  String get payloadMetaContentType => 'Content type';

  @override
  String get payloadMetaFormat => 'Payload format';

  @override
  String get payloadMetaFormatUtf8 => 'UTF-8 text (declared by the sender)';

  @override
  String get payloadMetaExpiry => 'Message expiry';

  @override
  String get payloadMetaAlias => 'Topic alias';

  @override
  String get payloadMetaResponse => 'Response topic';

  @override
  String get payloadMetaCorrelation => 'Correlation data';

  @override
  String get payloadMetaUserProps => 'User properties';

  @override
  String get payloadMetaSubIds => 'Subscription identifiers';

  @override
  String payloadMetaSeconds(int value) {
    return '$value s';
  }

  @override
  String get topicTabMessage => 'Message';

  @override
  String get topicTabHistory => 'History';

  @override
  String get topicTabDiff => 'Compare';

  @override
  String get topicTabChart => 'Chart';

  @override
  String get topicTabStats => 'Statistics';

  @override
  String historyCount(int count, int max) {
    return '$count messages stored (max. $max)';
  }

  @override
  String get historyEmpty => 'No history yet.';

  @override
  String historyViewing(String time) {
    return 'Older message from $time';
  }

  @override
  String get historyShowLatest => 'Show latest';

  @override
  String get historyLatest => 'latest';

  @override
  String get diffNeedTwo =>
      'At least two messages in the history are needed to compare.';

  @override
  String get diffOld => 'Old';

  @override
  String get diffNew => 'New';

  @override
  String get diffSwap => 'Swap';

  @override
  String get diffNoChanges => 'No differences.';

  @override
  String diffModeJson(int count) {
    return 'JSON comparison, $count changes';
  }

  @override
  String get diffModeText => 'Text comparison (by line)';

  @override
  String diffModeBytes(int count) {
    return 'Byte comparison, $count differing ranges';
  }

  @override
  String get diffAdded => 'added';

  @override
  String get diffRemoved => 'removed';

  @override
  String get diffChanged => 'changed';

  @override
  String diffByteRun(int offset, String before, String after) {
    return 'Offset $offset: $before → $after';
  }

  @override
  String get chartNoField =>
      'Choose a value for the chart: the chart icon next to a number in the JSON tree, or “Show in chart” in the binary view. Numeric payloads are charted automatically.';

  @override
  String chartField(String field) {
    return 'Value: $field';
  }

  @override
  String get chartClear => 'Clear selection';

  @override
  String get chartNoPoints =>
      'No message in the history has a number at this position yet.';

  @override
  String chartSummary(
    int count,
    String min,
    String max,
    String avg,
    String last,
  ) {
    return '$count points · min $min · max $max · avg $avg · last $last';
  }

  @override
  String get chartShowJson => 'Show in chart';

  @override
  String get chartShowBinary => 'Show in chart';

  @override
  String chartBinaryHint(int offset) {
    return 'Data type and byte order for the chart from offset $offset';
  }

  @override
  String get statsMessages => 'Messages';

  @override
  String get statsFirst => 'First message';

  @override
  String get statsLast => 'Last message';

  @override
  String get statsSinceLast => 'Since last message';

  @override
  String get statsRateOverall => 'Overall rate';

  @override
  String get statsRateRecent => 'Rate last 60 s';

  @override
  String statsRateValue(String value) {
    return '$value/s';
  }

  @override
  String statsRateMinimum(String value) {
    return 'at least $value/s';
  }

  @override
  String get statsAvgSize => 'Avg payload size';

  @override
  String get statsMinMaxSize => 'Min / max';

  @override
  String get statsHistory => 'In history';

  @override
  String get statsHistoryMemory => 'History total';

  @override
  String statsHistoryMemoryValue(int count, String size) {
    return '$count messages, $size';
  }

  @override
  String get settingsMqtt => 'MQTT';

  @override
  String get settingsMqttHistory => 'History per topic';

  @override
  String get settingsMqttHistoryHint =>
      'This many messages per topic are kept for history, comparison and chart.';

  @override
  String get settingsMqttBudget => 'Memory limit for the history';

  @override
  String get settingsMqttBudgetHint =>
      'When reached, the oldest messages of all topics are dropped first; every topic keeps its last value.';

  @override
  String settingsMegabytes(int value) {
    return '$value MB';
  }
}
