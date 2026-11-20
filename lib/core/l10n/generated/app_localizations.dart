import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ProtocollExplorer'**
  String get appTitle;

  /// No description provided for @navConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get navConnection;

  /// No description provided for @navRegisters.
  ///
  /// In en, this message translates to:
  /// **'Registers'**
  String get navRegisters;

  /// No description provided for @navMonitor.
  ///
  /// In en, this message translates to:
  /// **'Monitor'**
  String get navMonitor;

  /// No description provided for @navTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get navTools;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @connectionStatusDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get connectionStatusDisconnected;

  /// No description provided for @connectionStatusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connectionStatusConnecting;

  /// No description provided for @connectionStatusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connectionStatusConnected;

  /// No description provided for @connectionStatusError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get connectionStatusError;

  /// No description provided for @connectionStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Connection status: {status}'**
  String connectionStatusLabel(String status);

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageGerman.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @settingsModbus.
  ///
  /// In en, this message translates to:
  /// **'Modbus'**
  String get settingsModbus;

  /// No description provided for @settingsAddressing.
  ///
  /// In en, this message translates to:
  /// **'Addressing'**
  String get settingsAddressing;

  /// No description provided for @addressingZeroBased.
  ///
  /// In en, this message translates to:
  /// **'0-based (protocol)'**
  String get addressingZeroBased;

  /// No description provided for @addressingOneBased.
  ///
  /// In en, this message translates to:
  /// **'1-based (4xxxx/3xxxx)'**
  String get addressingOneBased;

  /// No description provided for @addressingZeroBasedHint.
  ///
  /// In en, this message translates to:
  /// **'Addresses are shown exactly as sent on the wire (holding register 0 = first register).'**
  String get addressingZeroBasedHint;

  /// No description provided for @addressingOneBasedHint.
  ///
  /// In en, this message translates to:
  /// **'Classic notation: holding register 40001 = protocol address 0.'**
  String get addressingOneBasedHint;

  /// No description provided for @settingsConfirmWrites.
  ///
  /// In en, this message translates to:
  /// **'Confirm write operations'**
  String get settingsConfirmWrites;

  /// No description provided for @settingsConfirmWritesHint.
  ///
  /// In en, this message translates to:
  /// **'Ask before every write request is sent to the device.'**
  String get settingsConfirmWritesHint;

  /// No description provided for @settingsHighlightPlausible.
  ///
  /// In en, this message translates to:
  /// **'Highlight plausible interpretations'**
  String get settingsHighlightPlausible;

  /// No description provided for @settingsHighlightPlausibleHint.
  ///
  /// In en, this message translates to:
  /// **'Heuristic marking of values that look meaningful in the interpretation matrix.'**
  String get settingsHighlightPlausibleHint;

  /// No description provided for @exceptionIllegalFunctionTitle.
  ///
  /// In en, this message translates to:
  /// **'01 Illegal function'**
  String get exceptionIllegalFunctionTitle;

  /// No description provided for @exceptionIllegalFunctionExplanation.
  ///
  /// In en, this message translates to:
  /// **'The device does not support this function code. Try another function (e.g. FC04 instead of FC03) or check the device manual.'**
  String get exceptionIllegalFunctionExplanation;

  /// No description provided for @exceptionIllegalDataAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'02 Illegal data address'**
  String get exceptionIllegalDataAddressTitle;

  /// No description provided for @exceptionIllegalDataAddressExplanation.
  ///
  /// In en, this message translates to:
  /// **'The address range does not exist on the device. Check the start address, the count and the addressing mode (0- vs. 1-based, off-by-one).'**
  String get exceptionIllegalDataAddressExplanation;

  /// No description provided for @exceptionIllegalDataValueTitle.
  ///
  /// In en, this message translates to:
  /// **'03 Illegal data value'**
  String get exceptionIllegalDataValueTitle;

  /// No description provided for @exceptionIllegalDataValueExplanation.
  ///
  /// In en, this message translates to:
  /// **'A value in the request is not allowed, e.g. too many registers at once or a value outside the permitted range.'**
  String get exceptionIllegalDataValueExplanation;

  /// No description provided for @exceptionServerDeviceFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'04 Server device failure'**
  String get exceptionServerDeviceFailureTitle;

  /// No description provided for @exceptionServerDeviceFailureExplanation.
  ///
  /// In en, this message translates to:
  /// **'The device hit an internal error while processing the request. Often caused by reading registers that are reserved or temporarily unavailable.'**
  String get exceptionServerDeviceFailureExplanation;

  /// No description provided for @exceptionAcknowledgeTitle.
  ///
  /// In en, this message translates to:
  /// **'05 Acknowledge'**
  String get exceptionAcknowledgeTitle;

  /// No description provided for @exceptionAcknowledgeExplanation.
  ///
  /// In en, this message translates to:
  /// **'The device accepted the request but needs more time to complete it. Poll again later.'**
  String get exceptionAcknowledgeExplanation;

  /// No description provided for @exceptionServerDeviceBusyTitle.
  ///
  /// In en, this message translates to:
  /// **'06 Server device busy'**
  String get exceptionServerDeviceBusyTitle;

  /// No description provided for @exceptionServerDeviceBusyExplanation.
  ///
  /// In en, this message translates to:
  /// **'The device is busy with a long-running command. Retry later or poll less frequently.'**
  String get exceptionServerDeviceBusyExplanation;

  /// No description provided for @exceptionNegativeAcknowledgeTitle.
  ///
  /// In en, this message translates to:
  /// **'07 Negative acknowledge'**
  String get exceptionNegativeAcknowledgeTitle;

  /// No description provided for @exceptionNegativeAcknowledgeExplanation.
  ///
  /// In en, this message translates to:
  /// **'The device cannot perform the requested program function (legacy code).'**
  String get exceptionNegativeAcknowledgeExplanation;

  /// No description provided for @exceptionMemoryParityErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'08 Memory parity error'**
  String get exceptionMemoryParityErrorTitle;

  /// No description provided for @exceptionMemoryParityErrorExplanation.
  ///
  /// In en, this message translates to:
  /// **'The device detected a parity error in its memory. The device may need servicing.'**
  String get exceptionMemoryParityErrorExplanation;

  /// No description provided for @exceptionGatewayPathUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'0A Gateway path unavailable'**
  String get exceptionGatewayPathUnavailableTitle;

  /// No description provided for @exceptionGatewayPathUnavailableExplanation.
  ///
  /// In en, this message translates to:
  /// **'The gateway could not route the request to the target. Check the gateway configuration and the unit ID.'**
  String get exceptionGatewayPathUnavailableExplanation;

  /// No description provided for @exceptionGatewayTargetFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'0B Gateway target failed to respond'**
  String get exceptionGatewayTargetFailedTitle;

  /// No description provided for @exceptionGatewayTargetFailedExplanation.
  ///
  /// In en, this message translates to:
  /// **'The gateway got no answer from the device behind it. Check unit ID, serial settings and wiring on the serial side.'**
  String get exceptionGatewayTargetFailedExplanation;

  /// No description provided for @exceptionUnknownTitle.
  ///
  /// In en, this message translates to:
  /// **'Exception {code}'**
  String exceptionUnknownTitle(String code);

  /// No description provided for @exceptionUnknownExplanation.
  ///
  /// In en, this message translates to:
  /// **'Non-standard exception code. See the device manual.'**
  String get exceptionUnknownExplanation;

  /// No description provided for @actionConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get actionConnect;

  /// No description provided for @actionDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get actionDisconnect;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get actionDuplicate;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionRetry;

  /// No description provided for @profileCopyName.
  ///
  /// In en, this message translates to:
  /// **'{name} (copy)'**
  String profileCopyName(String name);

  /// No description provided for @profilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection profiles'**
  String get profilesTitle;

  /// No description provided for @profileNew.
  ///
  /// In en, this message translates to:
  /// **'New profile'**
  String get profileNew;

  /// No description provided for @profileEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditTitle;

  /// No description provided for @profileDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete profile?'**
  String get profileDeleteTitle;

  /// No description provided for @profileDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be removed permanently.'**
  String profileDeleteBody(String name);

  /// No description provided for @profileLastUsed.
  ///
  /// In en, this message translates to:
  /// **'Last used {date}'**
  String profileLastUsed(String date);

  /// No description provided for @profileNeverUsed.
  ///
  /// In en, this message translates to:
  /// **'Never used'**
  String get profileNeverUsed;

  /// No description provided for @profilesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No profiles yet. Create one to connect to a device.'**
  String get profilesEmpty;

  /// No description provided for @profileActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get profileActive;

  /// No description provided for @connectionKindTcp.
  ///
  /// In en, this message translates to:
  /// **'Modbus TCP'**
  String get connectionKindTcp;

  /// No description provided for @connectionKindRtu.
  ///
  /// In en, this message translates to:
  /// **'Modbus RTU'**
  String get connectionKindRtu;

  /// No description provided for @connectionKindRtuOverTcp.
  ///
  /// In en, this message translates to:
  /// **'RTU over TCP'**
  String get connectionKindRtuOverTcp;

  /// No description provided for @connectionKindSimulator.
  ///
  /// In en, this message translates to:
  /// **'Simulator'**
  String get connectionKindSimulator;

  /// No description provided for @sectionConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get sectionConnection;

  /// No description provided for @sectionSerial.
  ///
  /// In en, this message translates to:
  /// **'Serial settings'**
  String get sectionSerial;

  /// No description provided for @sectionRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get sectionRequests;

  /// No description provided for @sectionSimulator.
  ///
  /// In en, this message translates to:
  /// **'Simulation'**
  String get sectionSimulator;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// No description provided for @fieldHost.
  ///
  /// In en, this message translates to:
  /// **'Host / IP address'**
  String get fieldHost;

  /// No description provided for @fieldPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get fieldPort;

  /// No description provided for @fieldUnitId.
  ///
  /// In en, this message translates to:
  /// **'Unit/slave ID'**
  String get fieldUnitId;

  /// No description provided for @fieldTimeout.
  ///
  /// In en, this message translates to:
  /// **'Timeout (ms)'**
  String get fieldTimeout;

  /// No description provided for @fieldRetries.
  ///
  /// In en, this message translates to:
  /// **'Retries'**
  String get fieldRetries;

  /// No description provided for @fieldSerialPort.
  ///
  /// In en, this message translates to:
  /// **'Serial port'**
  String get fieldSerialPort;

  /// No description provided for @fieldBaudRate.
  ///
  /// In en, this message translates to:
  /// **'Baud rate'**
  String get fieldBaudRate;

  /// No description provided for @fieldCustomBaudRate.
  ///
  /// In en, this message translates to:
  /// **'Custom baud rate'**
  String get fieldCustomBaudRate;

  /// No description provided for @baudRateCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get baudRateCustom;

  /// No description provided for @fieldDataBits.
  ///
  /// In en, this message translates to:
  /// **'Data bits'**
  String get fieldDataBits;

  /// No description provided for @fieldParity.
  ///
  /// In en, this message translates to:
  /// **'Parity'**
  String get fieldParity;

  /// No description provided for @parityNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get parityNone;

  /// No description provided for @parityEven.
  ///
  /// In en, this message translates to:
  /// **'Even'**
  String get parityEven;

  /// No description provided for @parityOdd.
  ///
  /// In en, this message translates to:
  /// **'Odd'**
  String get parityOdd;

  /// No description provided for @fieldStopBits.
  ///
  /// In en, this message translates to:
  /// **'Stop bits'**
  String get fieldStopBits;

  /// No description provided for @fieldRts.
  ///
  /// In en, this message translates to:
  /// **'RTS line'**
  String get fieldRts;

  /// No description provided for @fieldDtr.
  ///
  /// In en, this message translates to:
  /// **'DTR line'**
  String get fieldDtr;

  /// No description provided for @lineUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Unchanged'**
  String get lineUnchanged;

  /// No description provided for @lineOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get lineOn;

  /// No description provided for @lineOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get lineOff;

  /// No description provided for @fieldInterFrameDelay.
  ///
  /// In en, this message translates to:
  /// **'Inter-frame delay (ms)'**
  String get fieldInterFrameDelay;

  /// No description provided for @interFrameDelayAuto.
  ///
  /// In en, this message translates to:
  /// **'Empty = automatic (t3.5 = {value} ms)'**
  String interFrameDelayAuto(String value);

  /// No description provided for @fieldAutoReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect automatically'**
  String get fieldAutoReconnect;

  /// No description provided for @fieldAutoReconnectHint.
  ///
  /// In en, this message translates to:
  /// **'Retries with increasing delay when the connection drops.'**
  String get fieldAutoReconnectHint;

  /// No description provided for @fieldSimFraming.
  ///
  /// In en, this message translates to:
  /// **'Framing'**
  String get fieldSimFraming;

  /// No description provided for @fieldSimLatency.
  ///
  /// In en, this message translates to:
  /// **'Simulated latency (ms)'**
  String get fieldSimLatency;

  /// No description provided for @fieldSimDrop.
  ///
  /// In en, this message translates to:
  /// **'Lost responses (%)'**
  String get fieldSimDrop;

  /// No description provided for @fieldSimCorrupt.
  ///
  /// In en, this message translates to:
  /// **'Corrupted responses (%)'**
  String get fieldSimCorrupt;

  /// No description provided for @refreshPorts.
  ///
  /// In en, this message translates to:
  /// **'Refresh ports'**
  String get refreshPorts;

  /// No description provided for @noPortsFound.
  ///
  /// In en, this message translates to:
  /// **'No serial ports found'**
  String get noPortsFound;

  /// No description provided for @portNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'{port} (not connected)'**
  String portNotAvailable(String port);

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get validationRequired;

  /// No description provided for @validationRange.
  ///
  /// In en, this message translates to:
  /// **'Must be between {min} and {max}'**
  String validationRange(int min, int max);

  /// No description provided for @validationNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get validationNumber;

  /// No description provided for @statusNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get statusNotConnected;

  /// No description provided for @statusNotConnectedHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a profile and connect.'**
  String get statusNotConnectedHint;

  /// No description provided for @statusConnectedTo.
  ///
  /// In en, this message translates to:
  /// **'Connected to {target}'**
  String statusConnectedTo(String target);

  /// No description provided for @statusConnectingTo.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {target}…'**
  String statusConnectingTo(String target);

  /// No description provided for @statusReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Connection lost – reconnecting (attempt {attempt})…'**
  String statusReconnecting(int attempt);

  /// No description provided for @statusSince.
  ///
  /// In en, this message translates to:
  /// **'since {time}'**
  String statusSince(String time);

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection to {target} failed'**
  String statusFailed(String target);

  /// No description provided for @errorDetails.
  ///
  /// In en, this message translates to:
  /// **'Technical details'**
  String get errorDetails;

  /// No description provided for @errorRefusedTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection refused'**
  String get errorRefusedTitle;

  /// No description provided for @errorRefusedHint.
  ///
  /// In en, this message translates to:
  /// **'The device is reachable, but nothing listens on this port. Check the port number and whether Modbus TCP is enabled on the device.'**
  String get errorRefusedHint;

  /// No description provided for @errorConnectTimeoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Device not reachable'**
  String get errorConnectTimeoutTitle;

  /// No description provided for @errorConnectTimeoutHint.
  ///
  /// In en, this message translates to:
  /// **'No answer to the connection attempt. Check IP address, network cable, subnet and firewall.'**
  String get errorConnectTimeoutHint;

  /// No description provided for @errorHostNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Host not found'**
  String get errorHostNotFoundTitle;

  /// No description provided for @errorHostNotFoundHint.
  ///
  /// In en, this message translates to:
  /// **'The host name could not be resolved. Check the spelling or use the IP address.'**
  String get errorHostNotFoundHint;

  /// No description provided for @errorUnreachableTitle.
  ///
  /// In en, this message translates to:
  /// **'Network unreachable'**
  String get errorUnreachableTitle;

  /// No description provided for @errorUnreachableHint.
  ///
  /// In en, this message translates to:
  /// **'Check the network adapter and the IP/subnet settings of this computer.'**
  String get errorUnreachableHint;

  /// No description provided for @errorPortUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Serial port not available'**
  String get errorPortUnavailableTitle;

  /// No description provided for @errorPortUnavailableHint.
  ///
  /// In en, this message translates to:
  /// **'The port is missing or used by another program. Re-plug the adapter or close other tools.'**
  String get errorPortUnavailableHint;

  /// No description provided for @errorPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get errorPermissionTitle;

  /// No description provided for @errorPermissionHint.
  ///
  /// In en, this message translates to:
  /// **'No permission to use the port. Linux: add your user to the \'dialout\' group. Android: allow USB access.'**
  String get errorPermissionHint;

  /// No description provided for @errorInvalidSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings not supported'**
  String get errorInvalidSettingsTitle;

  /// No description provided for @errorInvalidSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'The adapter does not support these serial settings (baud rate, data bits, parity, stop bits).'**
  String get errorInvalidSettingsHint;

  /// No description provided for @errorUnsupportedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not supported on this platform'**
  String get errorUnsupportedTitle;

  /// No description provided for @errorUnsupportedHint.
  ///
  /// In en, this message translates to:
  /// **'Use Modbus TCP or the simulator on this device.'**
  String get errorUnsupportedHint;

  /// No description provided for @errorClosedTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection lost'**
  String get errorClosedTitle;

  /// No description provided for @errorClosedHint.
  ///
  /// In en, this message translates to:
  /// **'The device, gateway or network closed the connection.'**
  String get errorClosedHint;

  /// No description provided for @errorConnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get errorConnectionTitle;

  /// No description provided for @errorConnectionHint.
  ///
  /// In en, this message translates to:
  /// **'See the technical details below.'**
  String get errorConnectionHint;

  /// No description provided for @errorTimeoutTitle.
  ///
  /// In en, this message translates to:
  /// **'No response'**
  String get errorTimeoutTitle;

  /// No description provided for @errorTimeoutHint.
  ///
  /// In en, this message translates to:
  /// **'No valid answer within {timeout} ms ({attempts} attempt(s)). Check unit ID, serial settings (baud rate, parity) and wiring (A/B swapped?).'**
  String errorTimeoutHint(int timeout, int attempts);

  /// No description provided for @errorProtocolTitle.
  ///
  /// In en, this message translates to:
  /// **'Invalid response'**
  String get errorProtocolTitle;

  /// No description provided for @errorProtocolHint.
  ///
  /// In en, this message translates to:
  /// **'The device answered, but the response is malformed. Possible causes: line noise, wrong framing (TCP vs. RTU over TCP) or a second master on the bus.'**
  String get errorProtocolHint;

  /// No description provided for @errorNotConnectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get errorNotConnectedTitle;

  /// No description provided for @errorNotConnectedHint.
  ///
  /// In en, this message translates to:
  /// **'Connect to a device first.'**
  String get errorNotConnectedHint;

  /// No description provided for @errorWriteLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Writing is locked'**
  String get errorWriteLockedTitle;

  /// No description provided for @errorWriteLockedHint.
  ///
  /// In en, this message translates to:
  /// **'Enable writing first.'**
  String get errorWriteLockedHint;

  /// No description provided for @errorUnexpectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error'**
  String get errorUnexpectedTitle;

  /// No description provided for @simulatorServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Simulator TCP server'**
  String get simulatorServerTitle;

  /// No description provided for @simulatorServerHint.
  ///
  /// In en, this message translates to:
  /// **'Lets other Modbus tools connect to the demo device.'**
  String get simulatorServerHint;

  /// No description provided for @simulatorServerRunning.
  ///
  /// In en, this message translates to:
  /// **'Running on {address}'**
  String simulatorServerRunning(String address);

  /// No description provided for @simulatorServerConnections.
  ///
  /// In en, this message translates to:
  /// **'{count} client(s) connected'**
  String simulatorServerConnections(int count);

  /// No description provided for @simulatorServerStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get simulatorServerStopped;

  /// No description provided for @simulatorServerExpose.
  ///
  /// In en, this message translates to:
  /// **'Reachable from the network'**
  String get simulatorServerExpose;

  /// No description provided for @simulatorServerStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start: {error}'**
  String simulatorServerStartFailed(String error);

  /// No description provided for @tableCoils.
  ///
  /// In en, this message translates to:
  /// **'Coils'**
  String get tableCoils;

  /// No description provided for @tableDiscreteInputs.
  ///
  /// In en, this message translates to:
  /// **'Discrete inputs'**
  String get tableDiscreteInputs;

  /// No description provided for @tableInputRegisters.
  ///
  /// In en, this message translates to:
  /// **'Input registers'**
  String get tableInputRegisters;

  /// No description provided for @tableHoldingRegisters.
  ///
  /// In en, this message translates to:
  /// **'Holding registers'**
  String get tableHoldingRegisters;

  /// No description provided for @fieldStartAddress.
  ///
  /// In en, this message translates to:
  /// **'Start address'**
  String get fieldStartAddress;

  /// No description provided for @fieldCount.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get fieldCount;

  /// No description provided for @fieldUnitIdOverride.
  ///
  /// In en, this message translates to:
  /// **'Unit ID'**
  String get fieldUnitIdOverride;

  /// No description provided for @fieldUnitIdOverrideHint.
  ///
  /// In en, this message translates to:
  /// **'Empty = profile'**
  String get fieldUnitIdOverrideHint;

  /// No description provided for @addressHintProtocol.
  ///
  /// In en, this message translates to:
  /// **'= protocol address {address}'**
  String addressHintProtocol(String address);

  /// No description provided for @addressModeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Addressing mode – change in settings'**
  String get addressModeTooltip;

  /// No description provided for @actionRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get actionRead;

  /// No description provided for @actionReadTooltip.
  ///
  /// In en, this message translates to:
  /// **'Read once ({shortcut})'**
  String actionReadTooltip(String shortcut);

  /// No description provided for @actionStartPolling.
  ///
  /// In en, this message translates to:
  /// **'Poll'**
  String get actionStartPolling;

  /// No description provided for @actionStopPolling.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get actionStopPolling;

  /// No description provided for @fieldPollInterval.
  ///
  /// In en, this message translates to:
  /// **'Interval (ms)'**
  String get fieldPollInterval;

  /// No description provided for @writeUnlockLabel.
  ///
  /// In en, this message translates to:
  /// **'Writing enabled'**
  String get writeUnlockLabel;

  /// No description provided for @writeUnlockTooltip.
  ///
  /// In en, this message translates to:
  /// **'Protection against accidental writes; resets when the app restarts.'**
  String get writeUnlockTooltip;

  /// No description provided for @columnAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get columnAddress;

  /// No description provided for @columnHex.
  ///
  /// In en, this message translates to:
  /// **'Hex'**
  String get columnHex;

  /// No description provided for @columnUnsigned.
  ///
  /// In en, this message translates to:
  /// **'Unsigned'**
  String get columnUnsigned;

  /// No description provided for @columnSigned.
  ///
  /// In en, this message translates to:
  /// **'Signed'**
  String get columnSigned;

  /// No description provided for @columnBinary.
  ///
  /// In en, this message translates to:
  /// **'Binary'**
  String get columnBinary;

  /// No description provided for @columnValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get columnValue;

  /// No description provided for @bitOn.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get bitOn;

  /// No description provided for @bitOff.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get bitOff;

  /// No description provided for @registersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No data yet. Press Read or start polling.'**
  String get registersEmpty;

  /// No description provided for @readStatus.
  ///
  /// In en, this message translates to:
  /// **'{count} values · {latency} ms · {time}'**
  String readStatus(int count, int latency, String time);

  /// No description provided for @pollStatus.
  ///
  /// In en, this message translates to:
  /// **'Polls: {reads} · errors: {errors}'**
  String pollStatus(int reads, int errors);

  /// No description provided for @actionOpenConnections.
  ///
  /// In en, this message translates to:
  /// **'Open connections'**
  String get actionOpenConnections;

  /// No description provided for @actionConnectSimulator.
  ///
  /// In en, this message translates to:
  /// **'Connect to simulator'**
  String get actionConnectSimulator;

  /// No description provided for @writeRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Write register {address}'**
  String writeRegisterTitle(String address);

  /// No description provided for @writeMultipleTitle.
  ///
  /// In en, this message translates to:
  /// **'Write multiple values'**
  String get writeMultipleTitle;

  /// No description provided for @actionWriteMultiple.
  ///
  /// In en, this message translates to:
  /// **'Write multiple…'**
  String get actionWriteMultiple;

  /// No description provided for @actionWriteRow.
  ///
  /// In en, this message translates to:
  /// **'Write value'**
  String get actionWriteRow;

  /// No description provided for @fieldValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get fieldValue;

  /// No description provided for @valueFormatsHint.
  ///
  /// In en, this message translates to:
  /// **'Decimal (-32768…65535), 0x… hex or 0b… binary'**
  String get valueFormatsHint;

  /// No description provided for @fieldValues.
  ///
  /// In en, this message translates to:
  /// **'Values'**
  String get fieldValues;

  /// No description provided for @registerValuesHint.
  ///
  /// In en, this message translates to:
  /// **'Separated by comma or space; decimal, 0x… or 0b…'**
  String get registerValuesHint;

  /// No description provided for @coilValuesHint.
  ///
  /// In en, this message translates to:
  /// **'1/0 or on/off, separated by comma or space'**
  String get coilValuesHint;

  /// No description provided for @useFc16.
  ///
  /// In en, this message translates to:
  /// **'Send as FC16 (for devices without FC06)'**
  String get useFc16;

  /// No description provided for @bitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Bits – click to toggle'**
  String get bitsLabel;

  /// No description provided for @actionWrite.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get actionWrite;

  /// No description provided for @confirmWriteTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm write'**
  String get confirmWriteTitle;

  /// No description provided for @confirmWriteBody.
  ///
  /// In en, this message translates to:
  /// **'Send to unit {unit}?'**
  String confirmWriteBody(int unit);

  /// No description provided for @writeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Written: {summary}'**
  String writeSuccess(String summary);

  /// No description provided for @invalidValue.
  ///
  /// In en, this message translates to:
  /// **'Invalid value'**
  String get invalidValue;

  /// No description provided for @tooManyValues.
  ///
  /// In en, this message translates to:
  /// **'At most {max} values'**
  String tooManyValues(int max);

  /// No description provided for @rangeExceedsAddressSpace.
  ///
  /// In en, this message translates to:
  /// **'Range exceeds address 65535'**
  String get rangeExceedsAddressSpace;

  /// No description provided for @interpretationTitle.
  ///
  /// In en, this message translates to:
  /// **'Interpretation'**
  String get interpretationTitle;

  /// No description provided for @interpretationSelection.
  ///
  /// In en, this message translates to:
  /// **'{range} · {count} register(s)'**
  String interpretationSelection(String range, int count);

  /// No description provided for @interpretationHint.
  ///
  /// In en, this message translates to:
  /// **'Select a register in the table (Shift+click for a range).'**
  String get interpretationHint;

  /// No description provided for @interpretationBitTables.
  ///
  /// In en, this message translates to:
  /// **'Interpretations are available for input and holding registers.'**
  String get interpretationBitTables;

  /// No description provided for @interpretationNoData.
  ///
  /// In en, this message translates to:
  /// **'Read registers to see all interpretations.'**
  String get interpretationNoData;

  /// No description provided for @sectionRegister.
  ///
  /// In en, this message translates to:
  /// **'Register {address}'**
  String sectionRegister(String address);

  /// No description provided for @labelHighByte.
  ///
  /// In en, this message translates to:
  /// **'High byte'**
  String get labelHighByte;

  /// No description provided for @labelLowByte.
  ///
  /// In en, this message translates to:
  /// **'Low byte'**
  String get labelLowByte;

  /// No description provided for @labelAscii.
  ///
  /// In en, this message translates to:
  /// **'ASCII'**
  String get labelAscii;

  /// No description provided for @bitsReadOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Enable writing to toggle bits.'**
  String get bitsReadOnlyHint;

  /// No description provided for @sectionMatrix.
  ///
  /// In en, this message translates to:
  /// **'All interpretations'**
  String get sectionMatrix;

  /// No description provided for @columnType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get columnType;

  /// No description provided for @matrixNeedsRegisters.
  ///
  /// In en, this message translates to:
  /// **'Needs {count} registers'**
  String matrixNeedsRegisters(int count);

  /// No description provided for @matrixDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Same byte order as an earlier column'**
  String get matrixDuplicate;

  /// No description provided for @plausibilityNaN.
  ///
  /// In en, this message translates to:
  /// **'Not a number (NaN)'**
  String get plausibilityNaN;

  /// No description provided for @plausibilityInfinite.
  ///
  /// In en, this message translates to:
  /// **'Infinite'**
  String get plausibilityInfinite;

  /// No description provided for @plausibilityDenormal.
  ///
  /// In en, this message translates to:
  /// **'Denormalized float – almost certainly the wrong byte order'**
  String get plausibilityDenormal;

  /// No description provided for @plausibilityHuge.
  ///
  /// In en, this message translates to:
  /// **'Implausibly large'**
  String get plausibilityHuge;

  /// No description provided for @plausibilityTiny.
  ///
  /// In en, this message translates to:
  /// **'Implausibly small'**
  String get plausibilityTiny;

  /// No description provided for @plausibilityDate.
  ///
  /// In en, this message translates to:
  /// **'Date outside 2000–2100'**
  String get plausibilityDate;

  /// No description provided for @plausibilityNonPrintable.
  ///
  /// In en, this message translates to:
  /// **'Contains non-printable characters'**
  String get plausibilityNonPrintable;

  /// No description provided for @plausibilityInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid value'**
  String get plausibilityInvalid;

  /// No description provided for @plausibilityPlausible.
  ///
  /// In en, this message translates to:
  /// **'Looks plausible'**
  String get plausibilityPlausible;

  /// No description provided for @copiedValue.
  ///
  /// In en, this message translates to:
  /// **'Copied: {value}'**
  String copiedValue(String value);

  /// No description provided for @copiedTable.
  ///
  /// In en, this message translates to:
  /// **'Table copied'**
  String get copiedTable;

  /// No description provided for @actionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// No description provided for @actionAddToMap.
  ///
  /// In en, this message translates to:
  /// **'Add to register map…'**
  String get actionAddToMap;

  /// No description provided for @actionCopyTable.
  ///
  /// In en, this message translates to:
  /// **'Copy table'**
  String get actionCopyTable;

  /// No description provided for @actionCopyCsv.
  ///
  /// In en, this message translates to:
  /// **'Copy as CSV'**
  String get actionCopyCsv;

  /// No description provided for @sectionText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get sectionText;

  /// No description provided for @textSwapBytes.
  ///
  /// In en, this message translates to:
  /// **'Swap bytes (BA)'**
  String get textSwapBytes;

  /// No description provided for @fieldEncoding.
  ///
  /// In en, this message translates to:
  /// **'Encoding'**
  String get fieldEncoding;

  /// No description provided for @sectionScaling.
  ///
  /// In en, this message translates to:
  /// **'Scaling'**
  String get sectionScaling;

  /// No description provided for @fieldFactor.
  ///
  /// In en, this message translates to:
  /// **'Factor'**
  String get fieldFactor;

  /// No description provided for @fieldOffset.
  ///
  /// In en, this message translates to:
  /// **'Offset'**
  String get fieldOffset;

  /// No description provided for @fieldDecimals.
  ///
  /// In en, this message translates to:
  /// **'Decimals'**
  String get fieldDecimals;

  /// No description provided for @scalingHint.
  ///
  /// In en, this message translates to:
  /// **'Shown value = raw × factor + offset'**
  String get scalingHint;

  /// No description provided for @actionReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get actionReset;

  /// No description provided for @viewRaw.
  ///
  /// In en, this message translates to:
  /// **'Raw values'**
  String get viewRaw;

  /// No description provided for @viewMap.
  ///
  /// In en, this message translates to:
  /// **'Register map ({count})'**
  String viewMap(int count);

  /// No description provided for @columnLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get columnLabel;

  /// No description provided for @mapEmpty.
  ///
  /// In en, this message translates to:
  /// **'No entries yet. Select registers, open the menu of a cell in the interpretation table and choose “Add to register map”, or add an entry manually.'**
  String get mapEmpty;

  /// No description provided for @mapNoProfile.
  ///
  /// In en, this message translates to:
  /// **'Create a connection profile first – register maps are stored per profile.'**
  String get mapNoProfile;

  /// No description provided for @mapSearch.
  ///
  /// In en, this message translates to:
  /// **'Search label or address'**
  String get mapSearch;

  /// No description provided for @mapSortAddress.
  ///
  /// In en, this message translates to:
  /// **'By address'**
  String get mapSortAddress;

  /// No description provided for @mapSortLabel.
  ///
  /// In en, this message translates to:
  /// **'By label'**
  String get mapSortLabel;

  /// No description provided for @actionAddEntry.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get actionAddEntry;

  /// No description provided for @actionReadMap.
  ///
  /// In en, this message translates to:
  /// **'Read all'**
  String get actionReadMap;

  /// No description provided for @mapEntryNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New register map entry'**
  String get mapEntryNewTitle;

  /// No description provided for @mapEntryEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get mapEntryEditTitle;

  /// No description provided for @fieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get fieldLabel;

  /// No description provided for @fieldUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get fieldUnit;

  /// No description provided for @fieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get fieldDescription;

  /// No description provided for @fieldTable.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get fieldTable;

  /// No description provided for @fieldAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get fieldAddress;

  /// No description provided for @fieldType.
  ///
  /// In en, this message translates to:
  /// **'Data type'**
  String get fieldType;

  /// No description provided for @fieldByteOrder.
  ///
  /// In en, this message translates to:
  /// **'Byte order'**
  String get fieldByteOrder;

  /// No description provided for @fieldTextRegisters.
  ///
  /// In en, this message translates to:
  /// **'Length (registers)'**
  String get fieldTextRegisters;

  /// No description provided for @fieldBit.
  ///
  /// In en, this message translates to:
  /// **'Bit (0–15)'**
  String get fieldBit;

  /// No description provided for @typeText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get typeText;

  /// No description provided for @typeBit.
  ///
  /// In en, this message translates to:
  /// **'Bit'**
  String get typeBit;

  /// No description provided for @mapEntryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete entry?'**
  String get mapEntryDeleteTitle;

  /// No description provided for @mapEntryDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'\"{label}\" will be removed from the register map.'**
  String mapEntryDeleteBody(String label);

  /// No description provided for @mapReadStatus.
  ///
  /// In en, this message translates to:
  /// **'{count} entries · {time}'**
  String mapReadStatus(int count, String time);

  /// No description provided for @mapEntryCount.
  ///
  /// In en, this message translates to:
  /// **'{count} entries'**
  String mapEntryCount(int count);

  /// No description provided for @actionInterpret.
  ///
  /// In en, this message translates to:
  /// **'Interpret'**
  String get actionInterpret;

  /// No description provided for @mapEntrySaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to register map: {label}'**
  String mapEntrySaved(String label);

  /// No description provided for @mapUnnamed.
  ///
  /// In en, this message translates to:
  /// **'(unnamed)'**
  String get mapUnnamed;

  /// No description provided for @monitorPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get monitorPause;

  /// No description provided for @monitorResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get monitorResume;

  /// No description provided for @monitorClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get monitorClear;

  /// No description provided for @monitorErrorsOnly.
  ///
  /// In en, this message translates to:
  /// **'Errors only'**
  String get monitorErrorsOnly;

  /// No description provided for @monitorAllFunctions.
  ///
  /// In en, this message translates to:
  /// **'All functions'**
  String get monitorAllFunctions;

  /// No description provided for @monitorCopyText.
  ///
  /// In en, this message translates to:
  /// **'Copy as text'**
  String get monitorCopyText;

  /// No description provided for @monitorCopyCsv.
  ///
  /// In en, this message translates to:
  /// **'Copy as CSV'**
  String get monitorCopyCsv;

  /// No description provided for @monitorCopied.
  ///
  /// In en, this message translates to:
  /// **'{count} frames copied'**
  String monitorCopied(int count);

  /// No description provided for @monitorEmpty.
  ///
  /// In en, this message translates to:
  /// **'No frames yet. Read registers or start polling – every request and response appears here.'**
  String get monitorEmpty;

  /// No description provided for @monitorPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused – {count} frames not recorded'**
  String monitorPaused(int count);

  /// No description provided for @monitorCount.
  ///
  /// In en, this message translates to:
  /// **'{shown} of {total} frames'**
  String monitorCount(int shown, int total);

  /// No description provided for @monitorSelectHint.
  ///
  /// In en, this message translates to:
  /// **'Select a frame to see its decoding.'**
  String get monitorSelectHint;

  /// No description provided for @monitorDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Frame details'**
  String get monitorDetailTitle;

  /// No description provided for @monitorHexDump.
  ///
  /// In en, this message translates to:
  /// **'Hex dump'**
  String get monitorHexDump;

  /// No description provided for @monitorFields.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get monitorFields;

  /// No description provided for @monitorTransaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction #{number}'**
  String monitorTransaction(int number);

  /// No description provided for @monitorAttempts.
  ///
  /// In en, this message translates to:
  /// **'{count} attempt(s)'**
  String monitorAttempts(int count);

  /// No description provided for @monitorResultOk.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get monitorResultOk;

  /// No description provided for @monitorCrcValid.
  ///
  /// In en, this message translates to:
  /// **'CRC valid'**
  String get monitorCrcValid;

  /// No description provided for @monitorCrcInvalid.
  ///
  /// In en, this message translates to:
  /// **'CRC invalid'**
  String get monitorCrcInvalid;

  /// No description provided for @columnField.
  ///
  /// In en, this message translates to:
  /// **'Field'**
  String get columnField;

  /// No description provided for @columnBytes.
  ///
  /// In en, this message translates to:
  /// **'Bytes'**
  String get columnBytes;

  /// No description provided for @columnTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get columnTime;

  /// No description provided for @frameStatusOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get frameStatusOk;

  /// No description provided for @frameStatusCrc.
  ///
  /// In en, this message translates to:
  /// **'CRC error'**
  String get frameStatusCrc;

  /// No description provided for @frameStatusMalformed.
  ///
  /// In en, this message translates to:
  /// **'Malformed'**
  String get frameStatusMalformed;

  /// No description provided for @frameStatusUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Unexpected'**
  String get frameStatusUnexpected;

  /// No description provided for @frameStatusIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get frameStatusIncomplete;

  /// No description provided for @frameStatusException.
  ///
  /// In en, this message translates to:
  /// **'Exception'**
  String get frameStatusException;

  /// No description provided for @segmentTransactionId.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get segmentTransactionId;

  /// No description provided for @segmentProtocolId.
  ///
  /// In en, this message translates to:
  /// **'Protocol ID'**
  String get segmentProtocolId;

  /// No description provided for @segmentLength.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get segmentLength;

  /// No description provided for @segmentUnitId.
  ///
  /// In en, this message translates to:
  /// **'Unit ID'**
  String get segmentUnitId;

  /// No description provided for @segmentFunctionCode.
  ///
  /// In en, this message translates to:
  /// **'Function code'**
  String get segmentFunctionCode;

  /// No description provided for @segmentExceptionCode.
  ///
  /// In en, this message translates to:
  /// **'Exception code'**
  String get segmentExceptionCode;

  /// No description provided for @segmentAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get segmentAddress;

  /// No description provided for @segmentCount.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get segmentCount;

  /// No description provided for @segmentByteCount.
  ///
  /// In en, this message translates to:
  /// **'Byte count'**
  String get segmentByteCount;

  /// No description provided for @segmentValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get segmentValue;

  /// No description provided for @segmentValueList.
  ///
  /// In en, this message translates to:
  /// **'Values'**
  String get segmentValueList;

  /// No description provided for @segmentAndMask.
  ///
  /// In en, this message translates to:
  /// **'AND mask'**
  String get segmentAndMask;

  /// No description provided for @segmentOrMask.
  ///
  /// In en, this message translates to:
  /// **'OR mask'**
  String get segmentOrMask;

  /// No description provided for @segmentReadAddress.
  ///
  /// In en, this message translates to:
  /// **'Read address'**
  String get segmentReadAddress;

  /// No description provided for @segmentReadCount.
  ///
  /// In en, this message translates to:
  /// **'Read quantity'**
  String get segmentReadCount;

  /// No description provided for @segmentWriteAddress.
  ///
  /// In en, this message translates to:
  /// **'Write address'**
  String get segmentWriteAddress;

  /// No description provided for @segmentWriteCount.
  ///
  /// In en, this message translates to:
  /// **'Write quantity'**
  String get segmentWriteCount;

  /// No description provided for @segmentMeiType.
  ///
  /// In en, this message translates to:
  /// **'MEI type'**
  String get segmentMeiType;

  /// No description provided for @segmentDeviceIdCode.
  ///
  /// In en, this message translates to:
  /// **'Device ID code'**
  String get segmentDeviceIdCode;

  /// No description provided for @segmentObjectId.
  ///
  /// In en, this message translates to:
  /// **'Object ID'**
  String get segmentObjectId;

  /// No description provided for @segmentConformityLevel.
  ///
  /// In en, this message translates to:
  /// **'Conformity level'**
  String get segmentConformityLevel;

  /// No description provided for @segmentMoreFollows.
  ///
  /// In en, this message translates to:
  /// **'More follows'**
  String get segmentMoreFollows;

  /// No description provided for @segmentNextObjectId.
  ///
  /// In en, this message translates to:
  /// **'Next object ID'**
  String get segmentNextObjectId;

  /// No description provided for @segmentObjectCount.
  ///
  /// In en, this message translates to:
  /// **'Number of objects'**
  String get segmentObjectCount;

  /// No description provided for @segmentObject.
  ///
  /// In en, this message translates to:
  /// **'Object'**
  String get segmentObject;

  /// No description provided for @segmentData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get segmentData;

  /// No description provided for @segmentCrc.
  ///
  /// In en, this message translates to:
  /// **'CRC'**
  String get segmentCrc;

  /// No description provided for @segmentTruncated.
  ///
  /// In en, this message translates to:
  /// **'Truncated'**
  String get segmentTruncated;

  /// No description provided for @segmentTrailing.
  ///
  /// In en, this message translates to:
  /// **'Extra bytes'**
  String get segmentTrailing;

  /// No description provided for @toolsHexCalculator.
  ///
  /// In en, this message translates to:
  /// **'Hex calculator'**
  String get toolsHexCalculator;

  /// No description provided for @toolsScanner.
  ///
  /// In en, this message translates to:
  /// **'Scanner'**
  String get toolsScanner;

  /// No description provided for @toolsStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get toolsStatistics;

  /// No description provided for @toolsTrend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get toolsTrend;

  /// No description provided for @hexInput.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get hexInput;

  /// No description provided for @hexInputHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 41 20 00 00 or 0x41200000'**
  String get hexInputHint;

  /// No description provided for @hexModeBytes.
  ///
  /// In en, this message translates to:
  /// **'Hex bytes'**
  String get hexModeBytes;

  /// No description provided for @hexModeRegisters.
  ///
  /// In en, this message translates to:
  /// **'Registers (hex)'**
  String get hexModeRegisters;

  /// No description provided for @hexModeDecimal.
  ///
  /// In en, this message translates to:
  /// **'Registers (dec)'**
  String get hexModeDecimal;

  /// No description provided for @hexInvalid.
  ///
  /// In en, this message translates to:
  /// **'Cannot read “{token}”'**
  String hexInvalid(String token);

  /// No description provided for @hexOddBytes.
  ///
  /// In en, this message translates to:
  /// **'Odd number of bytes – the last register was padded with 00.'**
  String get hexOddBytes;

  /// No description provided for @hexBytesLabel.
  ///
  /// In en, this message translates to:
  /// **'Bytes'**
  String get hexBytesLabel;

  /// No description provided for @hexRegistersLabel.
  ///
  /// In en, this message translates to:
  /// **'Registers'**
  String get hexRegistersLabel;

  /// No description provided for @hexCustomOrder.
  ///
  /// In en, this message translates to:
  /// **'Custom byte order'**
  String get hexCustomOrder;

  /// No description provided for @hexPattern.
  ///
  /// In en, this message translates to:
  /// **'Pattern'**
  String get hexPattern;

  /// No description provided for @hexPatternHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. EFGHABCD'**
  String get hexPatternHint;

  /// No description provided for @hexEncoder.
  ///
  /// In en, this message translates to:
  /// **'Value → registers'**
  String get hexEncoder;

  /// No description provided for @hexEncodeHint.
  ///
  /// In en, this message translates to:
  /// **'Number; timestamps also as ISO date'**
  String get hexEncodeHint;

  /// No description provided for @hexUseAsInput.
  ///
  /// In en, this message translates to:
  /// **'Use as input'**
  String get hexUseAsInput;

  /// No description provided for @hexCopyRegisters.
  ///
  /// In en, this message translates to:
  /// **'Copy registers'**
  String get hexCopyRegisters;

  /// No description provided for @hexEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter bytes or register values to see all interpretations.'**
  String get hexEmpty;

  /// No description provided for @scanModeSlaves.
  ///
  /// In en, this message translates to:
  /// **'Slave IDs'**
  String get scanModeSlaves;

  /// No description provided for @scanModeRegisters.
  ///
  /// In en, this message translates to:
  /// **'Register range'**
  String get scanModeRegisters;

  /// No description provided for @scanFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get scanFrom;

  /// No description provided for @scanTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get scanTo;

  /// No description provided for @scanProbeAddress.
  ///
  /// In en, this message translates to:
  /// **'Test register'**
  String get scanProbeAddress;

  /// No description provided for @scanTimeout.
  ///
  /// In en, this message translates to:
  /// **'Timeout (ms)'**
  String get scanTimeout;

  /// No description provided for @scanBlockSize.
  ///
  /// In en, this message translates to:
  /// **'Block size'**
  String get scanBlockSize;

  /// No description provided for @scanStart.
  ///
  /// In en, this message translates to:
  /// **'Start scan'**
  String get scanStart;

  /// No description provided for @scanProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total} · {found} found'**
  String scanProgress(int done, int total, int found);

  /// No description provided for @scanFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished after {seconds} s'**
  String scanFinished(String seconds);

  /// No description provided for @scanCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get scanCancelled;

  /// No description provided for @scanNoResults.
  ///
  /// In en, this message translates to:
  /// **'No responses.'**
  String get scanNoResults;

  /// No description provided for @scanUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit {id}'**
  String scanUnit(int id);

  /// No description provided for @scanException.
  ///
  /// In en, this message translates to:
  /// **'Exception {code} – device present'**
  String scanException(String code);

  /// No description provided for @scanTcpHint.
  ///
  /// In en, this message translates to:
  /// **'Note: many Modbus TCP devices answer every unit ID. The scan is most useful behind gateways and on RTU.'**
  String get scanTcpHint;

  /// No description provided for @scanSlowHint.
  ///
  /// In en, this message translates to:
  /// **'Each missing ID waits for the timeout ({total} IDs ≈ {seconds} s at most).'**
  String scanSlowHint(int total, String seconds);

  /// No description provided for @statsRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get statsRequests;

  /// No description provided for @statsErrors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get statsErrors;

  /// No description provided for @statsErrorRate.
  ///
  /// In en, this message translates to:
  /// **'Error rate'**
  String get statsErrorRate;

  /// No description provided for @statsLatencyAvg.
  ///
  /// In en, this message translates to:
  /// **'Avg. latency'**
  String get statsLatencyAvg;

  /// No description provided for @statsLatencyMin.
  ///
  /// In en, this message translates to:
  /// **'Min. latency'**
  String get statsLatencyMin;

  /// No description provided for @statsLatencyMax.
  ///
  /// In en, this message translates to:
  /// **'Max. latency'**
  String get statsLatencyMax;

  /// No description provided for @statsTimeouts.
  ///
  /// In en, this message translates to:
  /// **'Timeouts'**
  String get statsTimeouts;

  /// No description provided for @statsExceptions.
  ///
  /// In en, this message translates to:
  /// **'Exception responses'**
  String get statsExceptions;

  /// No description provided for @statsProtocolErrors.
  ///
  /// In en, this message translates to:
  /// **'Invalid responses'**
  String get statsProtocolErrors;

  /// No description provided for @statsConnectionErrors.
  ///
  /// In en, this message translates to:
  /// **'Connection errors'**
  String get statsConnectionErrors;

  /// No description provided for @statsRetries.
  ///
  /// In en, this message translates to:
  /// **'Retries'**
  String get statsRetries;

  /// No description provided for @statsByFunction.
  ///
  /// In en, this message translates to:
  /// **'By function code'**
  String get statsByFunction;

  /// No description provided for @statsSince.
  ///
  /// In en, this message translates to:
  /// **'Since {time}'**
  String statsSince(String time);

  /// No description provided for @statsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No requests yet.'**
  String get statsEmpty;

  /// No description provided for @trendSelect.
  ///
  /// In en, this message translates to:
  /// **'Values to plot (numeric register map entries, max. {max})'**
  String trendSelect(int max);

  /// No description provided for @trendNoEntries.
  ///
  /// In en, this message translates to:
  /// **'Add numeric entries to the register map to plot them.'**
  String get trendNoEntries;

  /// No description provided for @trendPollMap.
  ///
  /// In en, this message translates to:
  /// **'Poll register map'**
  String get trendPollMap;

  /// No description provided for @trendWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for data – poll the register map.'**
  String get trendWaiting;

  /// No description provided for @trendMaxReached.
  ///
  /// In en, this message translates to:
  /// **'At most {max} values can be plotted.'**
  String trendMaxReached(int max);

  /// No description provided for @actionImport.
  ///
  /// In en, this message translates to:
  /// **'Import…'**
  String get actionImport;

  /// No description provided for @actionExportJson.
  ///
  /// In en, this message translates to:
  /// **'Export as JSON…'**
  String get actionExportJson;

  /// No description provided for @actionExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export as CSV…'**
  String get actionExportCsv;

  /// No description provided for @actionSaveText.
  ///
  /// In en, this message translates to:
  /// **'Save as text file…'**
  String get actionSaveText;

  /// No description provided for @actionSaveCsv.
  ///
  /// In en, this message translates to:
  /// **'Save as CSV file…'**
  String get actionSaveCsv;

  /// No description provided for @exportSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved: {name}'**
  String exportSaved(String name);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import register map'**
  String get importTitle;

  /// No description provided for @importSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} entries read from {file}.'**
  String importSummary(int count, String file);

  /// No description provided for @importSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count} entries could not be read and will be skipped.'**
  String importSkipped(int count);

  /// No description provided for @importAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get importAdd;

  /// No description provided for @importReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace map'**
  String get importReplace;

  /// No description provided for @importNothing.
  ///
  /// In en, this message translates to:
  /// **'{file} contains no readable entries.'**
  String importNothing(String file);

  /// No description provided for @importDone.
  ///
  /// In en, this message translates to:
  /// **'{count} entries imported'**
  String importDone(int count);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailed(String error);

  /// No description provided for @actionExportProfiles.
  ///
  /// In en, this message translates to:
  /// **'Export profiles…'**
  String get actionExportProfiles;

  /// No description provided for @actionImportProfiles.
  ///
  /// In en, this message translates to:
  /// **'Import profiles…'**
  String get actionImportProfiles;

  /// No description provided for @profilesImported.
  ///
  /// In en, this message translates to:
  /// **'{count} profiles imported'**
  String profilesImported(int count);

  /// No description provided for @settingsShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get settingsShortcuts;

  /// No description provided for @shortcutNavigate.
  ///
  /// In en, this message translates to:
  /// **'Switch area'**
  String get shortcutNavigate;

  /// No description provided for @shortcutRead.
  ///
  /// In en, this message translates to:
  /// **'Read once (registers or register map)'**
  String get shortcutRead;

  /// No description provided for @shortcutPoll.
  ///
  /// In en, this message translates to:
  /// **'Start/stop polling'**
  String get shortcutPoll;

  /// No description provided for @shortcutSubmit.
  ///
  /// In en, this message translates to:
  /// **'Confirm dialog / save'**
  String get shortcutSubmit;

  /// No description provided for @shortcutClose.
  ///
  /// In en, this message translates to:
  /// **'Close dialog'**
  String get shortcutClose;

  /// No description provided for @shortcutRange.
  ///
  /// In en, this message translates to:
  /// **'Select a range in the table'**
  String get shortcutRange;

  /// No description provided for @shortcutShiftClick.
  ///
  /// In en, this message translates to:
  /// **'Shift + click'**
  String get shortcutShiftClick;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @aboutText.
  ///
  /// In en, this message translates to:
  /// **'ProtocollExplorer {version} – debugging tool for Modbus TCP/RTU and MQTT. Data stays on this device.'**
  String aboutText(String version);

  /// No description provided for @toolsNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get toolsNetwork;

  /// No description provided for @netScanHint.
  ///
  /// In en, this message translates to:
  /// **'Finds devices by trying to connect to the selected TCP ports (no ping needed). Only scan networks you are permitted to scan.'**
  String get netScanHint;

  /// No description provided for @netScanNoMac.
  ///
  /// In en, this message translates to:
  /// **'MAC addresses are not available on this platform (the system does not expose the ARP table to apps).'**
  String get netScanNoMac;

  /// No description provided for @netRange.
  ///
  /// In en, this message translates to:
  /// **'Address range'**
  String get netRange;

  /// No description provided for @netRangeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 192.168.1.0/24 or 192.168.1.10-50'**
  String get netRangeHint;

  /// No description provided for @netRangeTooLarge.
  ///
  /// In en, this message translates to:
  /// **'At most {max} addresses per scan'**
  String netRangeTooLarge(int max);

  /// No description provided for @netPorts.
  ///
  /// In en, this message translates to:
  /// **'Ports'**
  String get netPorts;

  /// No description provided for @netModbusPorts.
  ///
  /// In en, this message translates to:
  /// **'Verify Modbus on ports'**
  String get netModbusPorts;

  /// No description provided for @netResolveNames.
  ///
  /// In en, this message translates to:
  /// **'Resolve host names'**
  String get netResolveNames;

  /// No description provided for @netStart.
  ///
  /// In en, this message translates to:
  /// **'Scan network'**
  String get netStart;

  /// No description provided for @netPhasePorts.
  ///
  /// In en, this message translates to:
  /// **'Probing ports'**
  String get netPhasePorts;

  /// No description provided for @netPhaseArp.
  ///
  /// In en, this message translates to:
  /// **'Reading MAC addresses'**
  String get netPhaseArp;

  /// No description provided for @netPhaseModbus.
  ///
  /// In en, this message translates to:
  /// **'Identifying Modbus devices'**
  String get netPhaseModbus;

  /// No description provided for @netPhaseHostnames.
  ///
  /// In en, this message translates to:
  /// **'Resolving host names'**
  String get netPhaseHostnames;

  /// No description provided for @netPhaseDone.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get netPhaseDone;

  /// No description provided for @netProgress.
  ///
  /// In en, this message translates to:
  /// **'{phase}: {done} / {total} · {hosts} hosts'**
  String netProgress(String phase, int done, int total, int hosts);

  /// No description provided for @netSummary.
  ///
  /// In en, this message translates to:
  /// **'{hosts} hosts · {modbus} with Modbus · {seconds} s'**
  String netSummary(int hosts, int modbus, String seconds);

  /// No description provided for @netOnlyModbus.
  ///
  /// In en, this message translates to:
  /// **'Only Modbus devices'**
  String get netOnlyModbus;

  /// No description provided for @netThisDevice.
  ///
  /// In en, this message translates to:
  /// **'this device'**
  String get netThisDevice;

  /// No description provided for @netNoMac.
  ///
  /// In en, this message translates to:
  /// **'MAC unknown'**
  String get netNoMac;

  /// No description provided for @netNoHosts.
  ///
  /// In en, this message translates to:
  /// **'No hosts found.'**
  String get netNoHosts;

  /// No description provided for @netModbusVerified.
  ///
  /// In en, this message translates to:
  /// **'Modbus on port {port}'**
  String netModbusVerified(int port);

  /// No description provided for @netModbusException.
  ///
  /// In en, this message translates to:
  /// **'answers with exception {code}'**
  String netModbusException(String code);

  /// No description provided for @netNoOpenPorts.
  ///
  /// In en, this message translates to:
  /// **'no open ports (seen via ARP or refused connection)'**
  String get netNoOpenPorts;

  /// No description provided for @netConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get netConnect;

  /// No description provided for @netProfileCreated.
  ///
  /// In en, this message translates to:
  /// **'Profile “{name}” created and connected'**
  String netProfileCreated(String name);

  /// No description provided for @netExport.
  ///
  /// In en, this message translates to:
  /// **'Export results…'**
  String get netExport;

  /// No description provided for @netScanNoMacSandbox.
  ///
  /// In en, this message translates to:
  /// **'MAC addresses are not available: the macOS app sandbox blocks access to the ARP table.'**
  String get netScanNoMacSandbox;

  /// No description provided for @netArpEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No MAC addresses received: the system returned an empty ARP table. On macOS, allow local network access for ProtocollExplorer (System Settings → Privacy & Security → Local Network) and scan again.'**
  String get netArpEmptyHint;

  /// No description provided for @netMacRoutedHint.
  ///
  /// In en, this message translates to:
  /// **'No MAC addresses for this range: it is outside this computer\'s local network segment (reached via a router). MAC addresses can only be determined for devices in the same segment.'**
  String get netMacRoutedHint;

  /// No description provided for @netUseActive.
  ///
  /// In en, this message translates to:
  /// **'Active network'**
  String get netUseActive;

  /// No description provided for @netUseActiveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Fill in the range of the network currently in use'**
  String get netUseActiveTooltip;

  /// No description provided for @netActiveNone.
  ///
  /// In en, this message translates to:
  /// **'No active network found'**
  String get netActiveNone;

  /// No description provided for @netActiveFound.
  ///
  /// In en, this message translates to:
  /// **'{iface}: {address} → {range}'**
  String netActiveFound(String iface, String address, String range);

  /// No description provided for @netActiveMaskUnknown.
  ///
  /// In en, this message translates to:
  /// **'Netmask unknown, assuming /24'**
  String get netActiveMaskUnknown;

  /// No description provided for @netPortOpenBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser: {target}'**
  String netPortOpenBrowser(String target);

  /// No description provided for @netPortOpenTerminal.
  ///
  /// In en, this message translates to:
  /// **'Open in terminal: {target}'**
  String netPortOpenTerminal(String target);

  /// No description provided for @netPortOpenFiles.
  ///
  /// In en, this message translates to:
  /// **'Open in file manager: {target}'**
  String netPortOpenFiles(String target);

  /// No description provided for @netPortOpenRemote.
  ///
  /// In en, this message translates to:
  /// **'Open remote desktop: {target}'**
  String netPortOpenRemote(String target);

  /// No description provided for @netPortOpenOpcUa.
  ///
  /// In en, this message translates to:
  /// **'Open in OPC UA client: {target}'**
  String netPortOpenOpcUa(String target);

  /// No description provided for @netPortConnectModbus.
  ///
  /// In en, this message translates to:
  /// **'Connect via Modbus TCP (port {port})'**
  String netPortConnectModbus(int port);

  /// No description provided for @netPortCopy.
  ///
  /// In en, this message translates to:
  /// **'No suitable program known – copy {target}'**
  String netPortCopy(String target);

  /// No description provided for @netPortCopied.
  ///
  /// In en, this message translates to:
  /// **'{target} copied'**
  String netPortCopied(String target);

  /// No description provided for @netPortNoApp.
  ///
  /// In en, this message translates to:
  /// **'No program found for {target} – address copied'**
  String netPortNoApp(String target);

  /// No description provided for @navTopics.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get navTopics;

  /// No description provided for @moduleModbus.
  ///
  /// In en, this message translates to:
  /// **'Modbus'**
  String get moduleModbus;

  /// No description provided for @moduleMqtt.
  ///
  /// In en, this message translates to:
  /// **'MQTT'**
  String get moduleMqtt;

  /// No description provided for @moduleSwitchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Switch module (Ctrl/⌘ + Shift + M)'**
  String get moduleSwitchTooltip;

  /// No description provided for @mqttProfiles.
  ///
  /// In en, this message translates to:
  /// **'Broker profiles'**
  String get mqttProfiles;

  /// No description provided for @mqttNewProfile.
  ///
  /// In en, this message translates to:
  /// **'New broker profile'**
  String get mqttNewProfile;

  /// No description provided for @mqttEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit broker profile'**
  String get mqttEditProfile;

  /// No description provided for @mqttNoProfiles.
  ///
  /// In en, this message translates to:
  /// **'No broker profiles yet.'**
  String get mqttNoProfiles;

  /// No description provided for @mqttStatusDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get mqttStatusDisconnected;

  /// No description provided for @mqttStatusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting …'**
  String get mqttStatusConnecting;

  /// No description provided for @mqttStatusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get mqttStatusConnected;

  /// No description provided for @mqttStatusReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting …'**
  String get mqttStatusReconnecting;

  /// No description provided for @mqttStatusError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get mqttStatusError;

  /// No description provided for @mqttStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'MQTT status: {status}'**
  String mqttStatusLabel(String status);

  /// No description provided for @mqttConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get mqttConnect;

  /// No description provided for @mqttDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get mqttDisconnect;

  /// No description provided for @mqttCancelReconnect.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get mqttCancelReconnect;

  /// No description provided for @mqttClientIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Client ID: {id}'**
  String mqttClientIdLabel(String id);

  /// No description provided for @mqttReconnectIn.
  ///
  /// In en, this message translates to:
  /// **'Attempt {attempt} in {seconds} s'**
  String mqttReconnectIn(int attempt, int seconds);

  /// No description provided for @mqttSimulatorBadge.
  ///
  /// In en, this message translates to:
  /// **'Demo broker'**
  String get mqttSimulatorBadge;

  /// No description provided for @mqttSimulatorHint.
  ///
  /// In en, this message translates to:
  /// **'Built-in demo broker: publishes JSON, binary and retained topics plus \$SYS values. Username “denied” shows a refused connection.'**
  String get mqttSimulatorHint;

  /// No description provided for @mqttFieldType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get mqttFieldType;

  /// No description provided for @mqttTypeBroker.
  ///
  /// In en, this message translates to:
  /// **'Broker'**
  String get mqttTypeBroker;

  /// No description provided for @mqttTypeSimulator.
  ///
  /// In en, this message translates to:
  /// **'Demo broker'**
  String get mqttTypeSimulator;

  /// No description provided for @mqttFieldTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get mqttFieldTransport;

  /// No description provided for @mqttFieldWsPath.
  ///
  /// In en, this message translates to:
  /// **'WebSocket path'**
  String get mqttFieldWsPath;

  /// No description provided for @mqttFieldVersion.
  ///
  /// In en, this message translates to:
  /// **'Protocol version'**
  String get mqttFieldVersion;

  /// No description provided for @mqttFieldClientId.
  ///
  /// In en, this message translates to:
  /// **'Client ID'**
  String get mqttFieldClientId;

  /// No description provided for @mqttClientIdAuto.
  ///
  /// In en, this message translates to:
  /// **'empty = generate a random ID on every connect'**
  String get mqttClientIdAuto;

  /// No description provided for @mqttGenerateClientId.
  ///
  /// In en, this message translates to:
  /// **'Generate client ID'**
  String get mqttGenerateClientId;

  /// No description provided for @mqttFieldUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get mqttFieldUsername;

  /// No description provided for @mqttFieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get mqttFieldPassword;

  /// No description provided for @mqttPasswordStored.
  ///
  /// In en, this message translates to:
  /// **'stored – leave empty to keep it'**
  String get mqttPasswordStored;

  /// No description provided for @mqttPasswordSecure.
  ///
  /// In en, this message translates to:
  /// **'stored in the system keychain, not in the profile'**
  String get mqttPasswordSecure;

  /// No description provided for @mqttRemovePassword.
  ///
  /// In en, this message translates to:
  /// **'Delete stored password'**
  String get mqttRemovePassword;

  /// No description provided for @mqttSectionBroker.
  ///
  /// In en, this message translates to:
  /// **'Broker'**
  String get mqttSectionBroker;

  /// No description provided for @mqttSectionAuth.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get mqttSectionAuth;

  /// No description provided for @mqttSectionSession.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get mqttSectionSession;

  /// No description provided for @mqttSectionWill.
  ///
  /// In en, this message translates to:
  /// **'Last will'**
  String get mqttSectionWill;

  /// No description provided for @mqttSectionTls.
  ///
  /// In en, this message translates to:
  /// **'TLS'**
  String get mqttSectionTls;

  /// No description provided for @mqttCleanStart.
  ///
  /// In en, this message translates to:
  /// **'Clean start / clean session'**
  String get mqttCleanStart;

  /// No description provided for @mqttCleanStartHint.
  ///
  /// In en, this message translates to:
  /// **'Off: the broker keeps the session’s subscriptions and QoS 1/2 messages'**
  String get mqttCleanStartHint;

  /// No description provided for @mqttFieldKeepAlive.
  ///
  /// In en, this message translates to:
  /// **'Keep alive (s)'**
  String get mqttFieldKeepAlive;

  /// No description provided for @mqttFieldSessionExpiry.
  ///
  /// In en, this message translates to:
  /// **'Session expiry (s, MQTT 5)'**
  String get mqttFieldSessionExpiry;

  /// No description provided for @mqttFieldConnectTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connect timeout (s)'**
  String get mqttFieldConnectTimeout;

  /// No description provided for @mqttAutoReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect automatically'**
  String get mqttAutoReconnect;

  /// No description provided for @mqttWillEnabled.
  ///
  /// In en, this message translates to:
  /// **'Send last will'**
  String get mqttWillEnabled;

  /// No description provided for @mqttFieldTopic.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get mqttFieldTopic;

  /// No description provided for @mqttFieldPayload.
  ///
  /// In en, this message translates to:
  /// **'Payload'**
  String get mqttFieldPayload;

  /// No description provided for @mqttFieldQos.
  ///
  /// In en, this message translates to:
  /// **'QoS'**
  String get mqttFieldQos;

  /// No description provided for @mqttRetain.
  ///
  /// In en, this message translates to:
  /// **'Retain'**
  String get mqttRetain;

  /// No description provided for @mqttTlsVerify.
  ///
  /// In en, this message translates to:
  /// **'The server certificate is checked against the system CAs.'**
  String get mqttTlsVerify;

  /// No description provided for @mqttCaCert.
  ///
  /// In en, this message translates to:
  /// **'Custom CA (PEM)'**
  String get mqttCaCert;

  /// No description provided for @mqttClientCert.
  ///
  /// In en, this message translates to:
  /// **'Client certificate (PEM)'**
  String get mqttClientCert;

  /// No description provided for @mqttClientKey.
  ///
  /// In en, this message translates to:
  /// **'Client private key (PEM)'**
  String get mqttClientKey;

  /// No description provided for @mqttClientKeyStored.
  ///
  /// In en, this message translates to:
  /// **'stored in the keychain'**
  String get mqttClientKeyStored;

  /// No description provided for @mqttClientKeyPassword.
  ///
  /// In en, this message translates to:
  /// **'Key password'**
  String get mqttClientKeyPassword;

  /// No description provided for @mqttLoadFile.
  ///
  /// In en, this message translates to:
  /// **'Load file'**
  String get mqttLoadFile;

  /// No description provided for @mqttRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get mqttRemove;

  /// No description provided for @mqttNotSet.
  ///
  /// In en, this message translates to:
  /// **'not set'**
  String get mqttNotSet;

  /// No description provided for @mqttAcceptInvalid.
  ///
  /// In en, this message translates to:
  /// **'Accept invalid certificates'**
  String get mqttAcceptInvalid;

  /// No description provided for @mqttAcceptInvalidWarning.
  ///
  /// In en, this message translates to:
  /// **'Insecure: the connection is then not protected against eavesdropping or tampering. Only use for test brokers with self-signed certificates.'**
  String get mqttAcceptInvalidWarning;

  /// No description provided for @mqttWssCertLimit.
  ///
  /// In en, this message translates to:
  /// **'Over WebSocket (wss) the MQTT package does not support a custom CA or client certificates; the system CAs apply.'**
  String get mqttWssCertLimit;

  /// No description provided for @mqttWebOnlyWs.
  ///
  /// In en, this message translates to:
  /// **'Browsers only support WebSocket connections.'**
  String get mqttWebOnlyWs;

  /// No description provided for @mqttErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get mqttErrorTitle;

  /// No description provided for @mqttErrorLost.
  ///
  /// In en, this message translates to:
  /// **'Connection to the broker lost'**
  String get mqttErrorLost;

  /// No description provided for @mqttFailNetwork.
  ///
  /// In en, this message translates to:
  /// **'Broker unreachable. Check host, port and network.'**
  String get mqttFailNetwork;

  /// No description provided for @mqttFailTls.
  ///
  /// In en, this message translates to:
  /// **'TLS error: certificate rejected or handshake failed. Check the CA, host name and port (8883?).'**
  String get mqttFailTls;

  /// No description provided for @mqttFailTimeout.
  ///
  /// In en, this message translates to:
  /// **'Timeout: the broker did not answer in time.'**
  String get mqttFailTimeout;

  /// No description provided for @mqttFailLost.
  ///
  /// In en, this message translates to:
  /// **'The broker closed the connection (e.g. keep alive expired or the same client ID connected elsewhere).'**
  String get mqttFailLost;

  /// No description provided for @mqttFailUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown error while connecting.'**
  String get mqttFailUnknown;

  /// No description provided for @mqttFailRefused.
  ///
  /// In en, this message translates to:
  /// **'Broker refused: {reason} (code {code})'**
  String mqttFailRefused(String reason, String code);

  /// No description provided for @connackProtocolVersion.
  ///
  /// In en, this message translates to:
  /// **'unsupported protocol version'**
  String get connackProtocolVersion;

  /// No description provided for @connackClientId.
  ///
  /// In en, this message translates to:
  /// **'client ID rejected'**
  String get connackClientId;

  /// No description provided for @connackServerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'server unavailable'**
  String get connackServerUnavailable;

  /// No description provided for @connackBadCredentials.
  ///
  /// In en, this message translates to:
  /// **'bad user name or password'**
  String get connackBadCredentials;

  /// No description provided for @connackNotAuthorized.
  ///
  /// In en, this message translates to:
  /// **'not authorized'**
  String get connackNotAuthorized;

  /// No description provided for @connackUnspecified.
  ///
  /// In en, this message translates to:
  /// **'unspecified error'**
  String get connackUnspecified;

  /// No description provided for @connackMalformed.
  ///
  /// In en, this message translates to:
  /// **'malformed packet'**
  String get connackMalformed;

  /// No description provided for @connackProtocolError.
  ///
  /// In en, this message translates to:
  /// **'protocol error'**
  String get connackProtocolError;

  /// No description provided for @connackImplementation.
  ///
  /// In en, this message translates to:
  /// **'implementation-specific error'**
  String get connackImplementation;

  /// No description provided for @connackServerBusy.
  ///
  /// In en, this message translates to:
  /// **'server busy'**
  String get connackServerBusy;

  /// No description provided for @connackBanned.
  ///
  /// In en, this message translates to:
  /// **'client banned'**
  String get connackBanned;

  /// No description provided for @connackBadAuthMethod.
  ///
  /// In en, this message translates to:
  /// **'bad authentication method'**
  String get connackBadAuthMethod;

  /// No description provided for @connackTopicInvalid.
  ///
  /// In en, this message translates to:
  /// **'topic name invalid (last will)'**
  String get connackTopicInvalid;

  /// No description provided for @connackPacketTooLarge.
  ///
  /// In en, this message translates to:
  /// **'packet too large'**
  String get connackPacketTooLarge;

  /// No description provided for @connackQuota.
  ///
  /// In en, this message translates to:
  /// **'quota exceeded'**
  String get connackQuota;

  /// No description provided for @connackPayloadFormat.
  ///
  /// In en, this message translates to:
  /// **'payload format invalid'**
  String get connackPayloadFormat;

  /// No description provided for @connackRetainNotSupported.
  ///
  /// In en, this message translates to:
  /// **'retain not supported (last will)'**
  String get connackRetainNotSupported;

  /// No description provided for @connackQosNotSupported.
  ///
  /// In en, this message translates to:
  /// **'QoS not supported (last will)'**
  String get connackQosNotSupported;

  /// No description provided for @connackUseAnotherServer.
  ///
  /// In en, this message translates to:
  /// **'use another server'**
  String get connackUseAnotherServer;

  /// No description provided for @connackServerMoved.
  ///
  /// In en, this message translates to:
  /// **'server moved'**
  String get connackServerMoved;

  /// No description provided for @connackRateExceeded.
  ///
  /// In en, this message translates to:
  /// **'connection rate exceeded'**
  String get connackRateExceeded;

  /// No description provided for @connackUnknown.
  ///
  /// In en, this message translates to:
  /// **'unknown reason'**
  String get connackUnknown;

  /// No description provided for @mqttNotConnectedHint.
  ///
  /// In en, this message translates to:
  /// **'Not connected to a broker.'**
  String get mqttNotConnectedHint;

  /// No description provided for @mqttGoToConnection.
  ///
  /// In en, this message translates to:
  /// **'Go to connection'**
  String get mqttGoToConnection;

  /// No description provided for @mqttTabMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get mqttTabMessages;

  /// No description provided for @mqttTabSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get mqttTabSubscriptions;

  /// No description provided for @mqttTabPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get mqttTabPublish;

  /// No description provided for @mqttMessagesCount.
  ///
  /// In en, this message translates to:
  /// **'{shown} of {total} messages'**
  String mqttMessagesCount(int shown, int total);

  /// No description provided for @mqttNoMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Check the subscriptions.'**
  String get mqttNoMessages;

  /// No description provided for @mqttPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get mqttPause;

  /// No description provided for @mqttResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get mqttResume;

  /// No description provided for @mqttClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get mqttClear;

  /// No description provided for @mqttSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get mqttSubscriptions;

  /// No description provided for @mqttNoSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions.'**
  String get mqttNoSubscriptions;

  /// No description provided for @mqttAddSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get mqttAddSubscription;

  /// No description provided for @mqttTopicFilter.
  ///
  /// In en, this message translates to:
  /// **'Topic filter'**
  String get mqttTopicFilter;

  /// No description provided for @mqttTopicFilterHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. home/+/temperature or sensors/#'**
  String get mqttTopicFilterHint;

  /// No description provided for @mqttSubscribeAll.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to everything (#)'**
  String get mqttSubscribeAll;

  /// No description provided for @mqttSubscribeAllWarning.
  ///
  /// In en, this message translates to:
  /// **'“#” receives every message on the broker. On large or public brokers this can be thousands of messages per second. Subscribe anyway?'**
  String get mqttSubscribeAllWarning;

  /// No description provided for @mqttSubscribeAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get mqttSubscribeAllConfirm;

  /// No description provided for @mqttMqtt5Options.
  ///
  /// In en, this message translates to:
  /// **'MQTT 5 options'**
  String get mqttMqtt5Options;

  /// No description provided for @mqttNoLocal.
  ///
  /// In en, this message translates to:
  /// **'No local (do not receive own messages)'**
  String get mqttNoLocal;

  /// No description provided for @mqttRetainAsPublished.
  ///
  /// In en, this message translates to:
  /// **'Retain as published'**
  String get mqttRetainAsPublished;

  /// No description provided for @mqttRetainHandling.
  ///
  /// In en, this message translates to:
  /// **'Retain handling'**
  String get mqttRetainHandling;

  /// No description provided for @mqttRetainSend.
  ///
  /// In en, this message translates to:
  /// **'send retained on subscribe'**
  String get mqttRetainSend;

  /// No description provided for @mqttRetainSendIfNew.
  ///
  /// In en, this message translates to:
  /// **'only for new subscriptions'**
  String get mqttRetainSendIfNew;

  /// No description provided for @mqttRetainDont.
  ///
  /// In en, this message translates to:
  /// **'do not send'**
  String get mqttRetainDont;

  /// No description provided for @mqttSubscriptionEnabled.
  ///
  /// In en, this message translates to:
  /// **'active'**
  String get mqttSubscriptionEnabled;

  /// No description provided for @mqttDeleteSubscription.
  ///
  /// In en, this message translates to:
  /// **'Remove subscription'**
  String get mqttDeleteSubscription;

  /// No description provided for @mqttFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get mqttFormat;

  /// No description provided for @mqttPublishAction.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get mqttPublishAction;

  /// No description provided for @mqttPublishTooltip.
  ///
  /// In en, this message translates to:
  /// **'Publish ({shortcut})'**
  String mqttPublishTooltip(String shortcut);

  /// No description provided for @mqttPublished.
  ///
  /// In en, this message translates to:
  /// **'Published to “{topic}” ({bytes} bytes)'**
  String mqttPublished(String topic, int bytes);

  /// No description provided for @mqttClearRetained.
  ///
  /// In en, this message translates to:
  /// **'Clear retained message'**
  String get mqttClearRetained;

  /// No description provided for @mqttClearRetainedConfirm.
  ///
  /// In en, this message translates to:
  /// **'The retained message on “{topic}” will be deleted (empty payload with retain). New subscribers will no longer get a stored value.'**
  String mqttClearRetainedConfirm(String topic);

  /// No description provided for @mqttClearRetainedDone.
  ///
  /// In en, this message translates to:
  /// **'Retained message on “{topic}” cleared'**
  String mqttClearRetainedDone(String topic);

  /// No description provided for @mqttOverwriteTitle.
  ///
  /// In en, this message translates to:
  /// **'Overwrite an existing topic?'**
  String get mqttOverwriteTitle;

  /// No description provided for @mqttOverwriteText.
  ///
  /// In en, this message translates to:
  /// **'Messages were already received on “{topic}”. Publish anyway?'**
  String mqttOverwriteText(String topic);

  /// No description provided for @mqttDontAskAgain.
  ///
  /// In en, this message translates to:
  /// **'Don’t ask again'**
  String get mqttDontAskAgain;

  /// No description provided for @mqttConfirmOverwrite.
  ///
  /// In en, this message translates to:
  /// **'Ask before publishing to known topics'**
  String get mqttConfirmOverwrite;

  /// No description provided for @mqttProperties.
  ///
  /// In en, this message translates to:
  /// **'MQTT 5 properties'**
  String get mqttProperties;

  /// No description provided for @mqttContentType.
  ///
  /// In en, this message translates to:
  /// **'Content type'**
  String get mqttContentType;

  /// No description provided for @mqttResponseTopic.
  ///
  /// In en, this message translates to:
  /// **'Response topic'**
  String get mqttResponseTopic;

  /// No description provided for @mqttCorrelationData.
  ///
  /// In en, this message translates to:
  /// **'Correlation data (text)'**
  String get mqttCorrelationData;

  /// No description provided for @mqttMessageExpiry.
  ///
  /// In en, this message translates to:
  /// **'Message expiry (s)'**
  String get mqttMessageExpiry;

  /// No description provided for @mqttUserProperties.
  ///
  /// In en, this message translates to:
  /// **'User properties (one per line: name=value)'**
  String get mqttUserProperties;

  /// No description provided for @mqttPropertiesV311Hint.
  ///
  /// In en, this message translates to:
  /// **'Only available with MQTT 5.'**
  String get mqttPropertiesV311Hint;

  /// No description provided for @mqttTopicErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Topic must not be empty'**
  String get mqttTopicErrorEmpty;

  /// No description provided for @mqttTopicErrorWildcard.
  ///
  /// In en, this message translates to:
  /// **'+ and # are not allowed when publishing'**
  String get mqttTopicErrorWildcard;

  /// No description provided for @mqttTopicErrorMultiLevel.
  ///
  /// In en, this message translates to:
  /// **'# is only allowed alone as the last level'**
  String get mqttTopicErrorMultiLevel;

  /// No description provided for @mqttTopicErrorSingleLevel.
  ///
  /// In en, this message translates to:
  /// **'+ must be a whole level'**
  String get mqttTopicErrorSingleLevel;

  /// No description provided for @mqttTopicErrorNull.
  ///
  /// In en, this message translates to:
  /// **'Null character not allowed'**
  String get mqttTopicErrorNull;

  /// No description provided for @mqttTopicErrorTooLong.
  ///
  /// In en, this message translates to:
  /// **'Topic too long (max. 65535 bytes)'**
  String get mqttTopicErrorTooLong;

  /// No description provided for @mqttPayloadInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid payload: {error}'**
  String mqttPayloadInvalid(String error);

  /// No description provided for @mqttRx.
  ///
  /// In en, this message translates to:
  /// **'RX'**
  String get mqttRx;

  /// No description provided for @mqttTx.
  ///
  /// In en, this message translates to:
  /// **'TX'**
  String get mqttTx;

  /// No description provided for @mqttDeleteProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete broker profile?'**
  String get mqttDeleteProfileTitle;

  /// No description provided for @mqttDeleteProfileText.
  ///
  /// In en, this message translates to:
  /// **'“{name}” and its stored credentials will be deleted.'**
  String mqttDeleteProfileText(String name);

  /// No description provided for @mqttProfileCopy.
  ///
  /// In en, this message translates to:
  /// **'{name} (copy)'**
  String mqttProfileCopy(String name);

  /// No description provided for @mqttTabTree.
  ///
  /// In en, this message translates to:
  /// **'Tree'**
  String get mqttTabTree;

  /// No description provided for @mqttTabDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get mqttTabDetails;

  /// No description provided for @mqttTreeSearch.
  ///
  /// In en, this message translates to:
  /// **'Filter topics'**
  String get mqttTreeSearch;

  /// No description provided for @mqttTreeSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter topics ({shortcut})'**
  String mqttTreeSearchTooltip(String shortcut);

  /// No description provided for @mqttFilterText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get mqttFilterText;

  /// No description provided for @mqttFilterWildcard.
  ///
  /// In en, this message translates to:
  /// **'Wildcard (+/#)'**
  String get mqttFilterWildcard;

  /// No description provided for @mqttFilterRegex.
  ///
  /// In en, this message translates to:
  /// **'Regex'**
  String get mqttFilterRegex;

  /// No description provided for @mqttTreeShowSys.
  ///
  /// In en, this message translates to:
  /// **'Show \$SYS'**
  String get mqttTreeShowSys;

  /// No description provided for @mqttTreeOnlyChanged.
  ///
  /// In en, this message translates to:
  /// **'Only changed'**
  String get mqttTreeOnlyChanged;

  /// No description provided for @mqttTreeOnlyChangedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Hide topics whose value never changed'**
  String get mqttTreeOnlyChangedTooltip;

  /// No description provided for @mqttTreeExpandAll.
  ///
  /// In en, this message translates to:
  /// **'Expand all'**
  String get mqttTreeExpandAll;

  /// No description provided for @mqttTreeCollapseAll.
  ///
  /// In en, this message translates to:
  /// **'Collapse all'**
  String get mqttTreeCollapseAll;

  /// No description provided for @mqttTreeClear.
  ///
  /// In en, this message translates to:
  /// **'Clear tree'**
  String get mqttTreeClear;

  /// No description provided for @mqttTreeStats.
  ///
  /// In en, this message translates to:
  /// **'{topics} topics · {messages} messages'**
  String mqttTreeStats(int topics, int messages);

  /// No description provided for @mqttTreeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No topics received yet.'**
  String get mqttTreeEmpty;

  /// No description provided for @mqttTreeNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No topic matches the filter.'**
  String get mqttTreeNoMatch;

  /// No description provided for @mqttTreeFilterError.
  ///
  /// In en, this message translates to:
  /// **'Invalid filter: {error}'**
  String mqttTreeFilterError(String error);

  /// No description provided for @mqttNodeMessages.
  ///
  /// In en, this message translates to:
  /// **'{count} msg'**
  String mqttNodeMessages(int count);

  /// No description provided for @mqttNodeTopics.
  ///
  /// In en, this message translates to:
  /// **'{count} topics'**
  String mqttNodeTopics(int count);

  /// No description provided for @mqttEmptyLevel.
  ///
  /// In en, this message translates to:
  /// **'(empty)'**
  String get mqttEmptyLevel;

  /// No description provided for @mqttRetainedBadge.
  ///
  /// In en, this message translates to:
  /// **'Retained'**
  String get mqttRetainedBadge;

  /// No description provided for @mqttExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get mqttExpand;

  /// No description provided for @mqttCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get mqttCollapse;

  /// No description provided for @mqttDetailNone.
  ///
  /// In en, this message translates to:
  /// **'Select a topic in the tree.'**
  String get mqttDetailNone;

  /// No description provided for @mqttDetailBranch.
  ///
  /// In en, this message translates to:
  /// **'No message was received on this level itself.'**
  String get mqttDetailBranch;

  /// No description provided for @mqttDetailLast.
  ///
  /// In en, this message translates to:
  /// **'Last message'**
  String get mqttDetailLast;

  /// No description provided for @mqttDetailReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get mqttDetailReceived;

  /// No description provided for @mqttDetailMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get mqttDetailMessages;

  /// No description provided for @mqttDetailSubtopics.
  ///
  /// In en, this message translates to:
  /// **'Subtopics'**
  String get mqttDetailSubtopics;

  /// No description provided for @mqttDetailSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get mqttDetailSize;

  /// No description provided for @mqttDetailFlags.
  ///
  /// In en, this message translates to:
  /// **'QoS / flags'**
  String get mqttDetailFlags;

  /// No description provided for @mqttDetailChanged.
  ///
  /// In en, this message translates to:
  /// **'Last changed'**
  String get mqttDetailChanged;

  /// No description provided for @mqttBytes.
  ///
  /// In en, this message translates to:
  /// **'{count} bytes'**
  String mqttBytes(int count);

  /// No description provided for @mqttTruncated.
  ///
  /// In en, this message translates to:
  /// **'… truncated, {count} bytes in total'**
  String mqttTruncated(int count);

  /// No description provided for @mqttSecondsAgo.
  ///
  /// In en, this message translates to:
  /// **'{value} s ago'**
  String mqttSecondsAgo(int value);

  /// No description provided for @mqttMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{value} min ago'**
  String mqttMinutesAgo(int value);

  /// No description provided for @mqttHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{value} h ago'**
  String mqttHoursAgo(int value);

  /// No description provided for @mqttCopyTopic.
  ///
  /// In en, this message translates to:
  /// **'Copy topic'**
  String get mqttCopyTopic;

  /// No description provided for @mqttCopyPayload.
  ///
  /// In en, this message translates to:
  /// **'Copy payload'**
  String get mqttCopyPayload;

  /// No description provided for @mqttCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get mqttCopied;

  /// No description provided for @mqttUseForPublish.
  ///
  /// In en, this message translates to:
  /// **'Use for publish'**
  String get mqttUseForPublish;

  /// No description provided for @mqttSubscribeSubtree.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to {filter}'**
  String mqttSubscribeSubtree(String filter);

  /// No description provided for @matrixNeedsBytes.
  ///
  /// In en, this message translates to:
  /// **'Needs {count} bytes'**
  String matrixNeedsBytes(int count);

  /// No description provided for @payloadDetected.
  ///
  /// In en, this message translates to:
  /// **'Detected: {kind}'**
  String payloadDetected(String kind);

  /// No description provided for @payloadKindEmpty.
  ///
  /// In en, this message translates to:
  /// **'empty'**
  String get payloadKindEmpty;

  /// No description provided for @payloadKindJson.
  ///
  /// In en, this message translates to:
  /// **'JSON'**
  String get payloadKindJson;

  /// No description provided for @payloadKindJsonBroken.
  ///
  /// In en, this message translates to:
  /// **'JSON (invalid)'**
  String get payloadKindJsonBroken;

  /// No description provided for @payloadKindXml.
  ///
  /// In en, this message translates to:
  /// **'XML'**
  String get payloadKindXml;

  /// No description provided for @payloadKindXmlBroken.
  ///
  /// In en, this message translates to:
  /// **'XML (invalid)'**
  String get payloadKindXmlBroken;

  /// No description provided for @payloadKindText.
  ///
  /// In en, this message translates to:
  /// **'Text (UTF-8)'**
  String get payloadKindText;

  /// No description provided for @payloadKindBase64.
  ///
  /// In en, this message translates to:
  /// **'Base64'**
  String get payloadKindBase64;

  /// No description provided for @payloadKindBinary.
  ///
  /// In en, this message translates to:
  /// **'Binary'**
  String get payloadKindBinary;

  /// No description provided for @payloadTabContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get payloadTabContent;

  /// No description provided for @payloadTabText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get payloadTabText;

  /// No description provided for @payloadTabHex.
  ///
  /// In en, this message translates to:
  /// **'Hex'**
  String get payloadTabHex;

  /// No description provided for @payloadTabBinary.
  ///
  /// In en, this message translates to:
  /// **'Binary'**
  String get payloadTabBinary;

  /// No description provided for @payloadTabMeta.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get payloadTabMeta;

  /// No description provided for @payloadJsonTree.
  ///
  /// In en, this message translates to:
  /// **'Tree'**
  String get payloadJsonTree;

  /// No description provided for @payloadJsonPretty.
  ///
  /// In en, this message translates to:
  /// **'Formatted'**
  String get payloadJsonPretty;

  /// No description provided for @payloadJsonRaw.
  ///
  /// In en, this message translates to:
  /// **'Raw'**
  String get payloadJsonRaw;

  /// No description provided for @payloadPathCopied.
  ///
  /// In en, this message translates to:
  /// **'{path} copied'**
  String payloadPathCopied(String path);

  /// No description provided for @payloadCopyPathHint.
  ///
  /// In en, this message translates to:
  /// **'Tap copies the JSON path'**
  String get payloadCopyPathHint;

  /// No description provided for @payloadSyntaxError.
  ///
  /// In en, this message translates to:
  /// **'Syntax error in line {line}, column {column}: {message}'**
  String payloadSyntaxError(int line, int column, String message);

  /// No description provided for @payloadMoreItems.
  ///
  /// In en, this message translates to:
  /// **'… {count} more'**
  String payloadMoreItems(int count);

  /// No description provided for @payloadEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty payload (0 bytes).'**
  String get payloadEmpty;

  /// No description provided for @payloadBinaryHint.
  ///
  /// In en, this message translates to:
  /// **'Binary data – see Hex and Binary.'**
  String get payloadBinaryHint;

  /// No description provided for @payloadBase64Decoded.
  ///
  /// In en, this message translates to:
  /// **'Base64 decoded ({count} bytes)'**
  String payloadBase64Decoded(int count);

  /// No description provided for @payloadInterpretDecoded.
  ///
  /// In en, this message translates to:
  /// **'Interpret decoded bytes'**
  String get payloadInterpretDecoded;

  /// No description provided for @payloadEncoding.
  ///
  /// In en, this message translates to:
  /// **'Encoding'**
  String get payloadEncoding;

  /// No description provided for @payloadShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get payloadShowMore;

  /// No description provided for @payloadHexLines.
  ///
  /// In en, this message translates to:
  /// **'{shown} of {total} lines'**
  String payloadHexLines(int shown, int total);

  /// No description provided for @payloadOffset.
  ///
  /// In en, this message translates to:
  /// **'Offset (byte)'**
  String get payloadOffset;

  /// No description provided for @payloadOffsetHint.
  ///
  /// In en, this message translates to:
  /// **'0 … {max}'**
  String payloadOffsetHint(int max);

  /// No description provided for @payloadWindow.
  ///
  /// In en, this message translates to:
  /// **'Bytes from offset: {bytes}'**
  String payloadWindow(String bytes);

  /// No description provided for @payloadSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get payloadSource;

  /// No description provided for @payloadSourcePayload.
  ///
  /// In en, this message translates to:
  /// **'Payload'**
  String get payloadSourcePayload;

  /// No description provided for @payloadSourceBase64.
  ///
  /// In en, this message translates to:
  /// **'Base64 decoded'**
  String get payloadSourceBase64;

  /// No description provided for @payloadEightBit.
  ///
  /// In en, this message translates to:
  /// **'8 bit'**
  String get payloadEightBit;

  /// No description provided for @payloadBits.
  ///
  /// In en, this message translates to:
  /// **'Bits (MSB first)'**
  String get payloadBits;

  /// No description provided for @payloadNoBytes.
  ///
  /// In en, this message translates to:
  /// **'No bytes from this offset.'**
  String get payloadNoBytes;

  /// No description provided for @payloadValueCopied.
  ///
  /// In en, this message translates to:
  /// **'{value} copied'**
  String payloadValueCopied(String value);

  /// No description provided for @payloadMetaNoV5.
  ///
  /// In en, this message translates to:
  /// **'No MQTT 5 properties (MQTT 3.1.1 or not set by the sender).'**
  String get payloadMetaNoV5;

  /// No description provided for @payloadMetaContentType.
  ///
  /// In en, this message translates to:
  /// **'Content type'**
  String get payloadMetaContentType;

  /// No description provided for @payloadMetaFormat.
  ///
  /// In en, this message translates to:
  /// **'Payload format'**
  String get payloadMetaFormat;

  /// No description provided for @payloadMetaFormatUtf8.
  ///
  /// In en, this message translates to:
  /// **'UTF-8 text (declared by the sender)'**
  String get payloadMetaFormatUtf8;

  /// No description provided for @payloadMetaExpiry.
  ///
  /// In en, this message translates to:
  /// **'Message expiry'**
  String get payloadMetaExpiry;

  /// No description provided for @payloadMetaAlias.
  ///
  /// In en, this message translates to:
  /// **'Topic alias'**
  String get payloadMetaAlias;

  /// No description provided for @payloadMetaResponse.
  ///
  /// In en, this message translates to:
  /// **'Response topic'**
  String get payloadMetaResponse;

  /// No description provided for @payloadMetaCorrelation.
  ///
  /// In en, this message translates to:
  /// **'Correlation data'**
  String get payloadMetaCorrelation;

  /// No description provided for @payloadMetaUserProps.
  ///
  /// In en, this message translates to:
  /// **'User properties'**
  String get payloadMetaUserProps;

  /// No description provided for @payloadMetaSubIds.
  ///
  /// In en, this message translates to:
  /// **'Subscription identifiers'**
  String get payloadMetaSubIds;

  /// No description provided for @payloadMetaSeconds.
  ///
  /// In en, this message translates to:
  /// **'{value} s'**
  String payloadMetaSeconds(int value);

  /// No description provided for @topicTabMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get topicTabMessage;

  /// No description provided for @topicTabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get topicTabHistory;

  /// No description provided for @topicTabDiff.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get topicTabDiff;

  /// No description provided for @topicTabChart.
  ///
  /// In en, this message translates to:
  /// **'Chart'**
  String get topicTabChart;

  /// No description provided for @topicTabStats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get topicTabStats;

  /// No description provided for @historyCount.
  ///
  /// In en, this message translates to:
  /// **'{count} messages stored (max. {max})'**
  String historyCount(int count, int max);

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No history yet.'**
  String get historyEmpty;

  /// No description provided for @historyViewing.
  ///
  /// In en, this message translates to:
  /// **'Older message from {time}'**
  String historyViewing(String time);

  /// No description provided for @historyShowLatest.
  ///
  /// In en, this message translates to:
  /// **'Show latest'**
  String get historyShowLatest;

  /// No description provided for @historyLatest.
  ///
  /// In en, this message translates to:
  /// **'latest'**
  String get historyLatest;

  /// No description provided for @diffNeedTwo.
  ///
  /// In en, this message translates to:
  /// **'At least two messages in the history are needed to compare.'**
  String get diffNeedTwo;

  /// No description provided for @diffOld.
  ///
  /// In en, this message translates to:
  /// **'Old'**
  String get diffOld;

  /// No description provided for @diffNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get diffNew;

  /// No description provided for @diffSwap.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get diffSwap;

  /// No description provided for @diffNoChanges.
  ///
  /// In en, this message translates to:
  /// **'No differences.'**
  String get diffNoChanges;

  /// No description provided for @diffModeJson.
  ///
  /// In en, this message translates to:
  /// **'JSON comparison, {count} changes'**
  String diffModeJson(int count);

  /// No description provided for @diffModeText.
  ///
  /// In en, this message translates to:
  /// **'Text comparison (by line)'**
  String get diffModeText;

  /// No description provided for @diffModeBytes.
  ///
  /// In en, this message translates to:
  /// **'Byte comparison, {count} differing ranges'**
  String diffModeBytes(int count);

  /// No description provided for @diffAdded.
  ///
  /// In en, this message translates to:
  /// **'added'**
  String get diffAdded;

  /// No description provided for @diffRemoved.
  ///
  /// In en, this message translates to:
  /// **'removed'**
  String get diffRemoved;

  /// No description provided for @diffChanged.
  ///
  /// In en, this message translates to:
  /// **'changed'**
  String get diffChanged;

  /// No description provided for @diffByteRun.
  ///
  /// In en, this message translates to:
  /// **'Offset {offset}: {before} → {after}'**
  String diffByteRun(int offset, String before, String after);

  /// No description provided for @chartNoField.
  ///
  /// In en, this message translates to:
  /// **'Choose a value for the chart: the chart icon next to a number in the JSON tree, or “Show in chart” in the binary view. Numeric payloads are charted automatically.'**
  String get chartNoField;

  /// No description provided for @chartField.
  ///
  /// In en, this message translates to:
  /// **'Value: {field}'**
  String chartField(String field);

  /// No description provided for @chartClear.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get chartClear;

  /// No description provided for @chartNoPoints.
  ///
  /// In en, this message translates to:
  /// **'No message in the history has a number at this position yet.'**
  String get chartNoPoints;

  /// No description provided for @chartSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} points · min {min} · max {max} · avg {avg} · last {last}'**
  String chartSummary(
    int count,
    String min,
    String max,
    String avg,
    String last,
  );

  /// No description provided for @chartShowJson.
  ///
  /// In en, this message translates to:
  /// **'Show in chart'**
  String get chartShowJson;

  /// No description provided for @chartShowBinary.
  ///
  /// In en, this message translates to:
  /// **'Show in chart'**
  String get chartShowBinary;

  /// No description provided for @chartBinaryHint.
  ///
  /// In en, this message translates to:
  /// **'Data type and byte order for the chart from offset {offset}'**
  String chartBinaryHint(int offset);

  /// No description provided for @statsMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get statsMessages;

  /// No description provided for @statsFirst.
  ///
  /// In en, this message translates to:
  /// **'First message'**
  String get statsFirst;

  /// No description provided for @statsLast.
  ///
  /// In en, this message translates to:
  /// **'Last message'**
  String get statsLast;

  /// No description provided for @statsSinceLast.
  ///
  /// In en, this message translates to:
  /// **'Since last message'**
  String get statsSinceLast;

  /// No description provided for @statsRateOverall.
  ///
  /// In en, this message translates to:
  /// **'Overall rate'**
  String get statsRateOverall;

  /// No description provided for @statsRateRecent.
  ///
  /// In en, this message translates to:
  /// **'Rate last 60 s'**
  String get statsRateRecent;

  /// No description provided for @statsRateValue.
  ///
  /// In en, this message translates to:
  /// **'{value}/s'**
  String statsRateValue(String value);

  /// No description provided for @statsRateMinimum.
  ///
  /// In en, this message translates to:
  /// **'at least {value}/s'**
  String statsRateMinimum(String value);

  /// No description provided for @statsAvgSize.
  ///
  /// In en, this message translates to:
  /// **'Avg payload size'**
  String get statsAvgSize;

  /// No description provided for @statsMinMaxSize.
  ///
  /// In en, this message translates to:
  /// **'Min / max'**
  String get statsMinMaxSize;

  /// No description provided for @statsHistory.
  ///
  /// In en, this message translates to:
  /// **'In history'**
  String get statsHistory;

  /// No description provided for @statsHistoryMemory.
  ///
  /// In en, this message translates to:
  /// **'History total'**
  String get statsHistoryMemory;

  /// No description provided for @statsHistoryMemoryValue.
  ///
  /// In en, this message translates to:
  /// **'{count} messages, {size}'**
  String statsHistoryMemoryValue(int count, String size);

  /// No description provided for @settingsMqtt.
  ///
  /// In en, this message translates to:
  /// **'MQTT'**
  String get settingsMqtt;

  /// No description provided for @settingsMqttHistory.
  ///
  /// In en, this message translates to:
  /// **'History per topic'**
  String get settingsMqttHistory;

  /// No description provided for @settingsMqttHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'This many messages per topic are kept for history, comparison and chart.'**
  String get settingsMqttHistoryHint;

  /// No description provided for @settingsMqttBudget.
  ///
  /// In en, this message translates to:
  /// **'Memory limit for the history'**
  String get settingsMqttBudget;

  /// No description provided for @settingsMqttBudgetHint.
  ///
  /// In en, this message translates to:
  /// **'When reached, the oldest messages of all topics are dropped first; every topic keeps its last value.'**
  String get settingsMqttBudgetHint;

  /// No description provided for @settingsMegabytes.
  ///
  /// In en, this message translates to:
  /// **'{value} MB'**
  String settingsMegabytes(int value);

  /// No description provided for @monitorTopicFilter.
  ///
  /// In en, this message translates to:
  /// **'Topic filter'**
  String get monitorTopicFilter;

  /// No description provided for @monitorPayloadFilter.
  ///
  /// In en, this message translates to:
  /// **'Payload contains'**
  String get monitorPayloadFilter;

  /// No description provided for @monitorPayloadFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Text or hex, e.g. 0A 1B'**
  String get monitorPayloadFilterHint;

  /// No description provided for @monitorRx.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get monitorRx;

  /// No description provided for @monitorTx.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get monitorTx;

  /// No description provided for @monitorEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get monitorEvents;

  /// No description provided for @monitorOnlyRetained.
  ///
  /// In en, this message translates to:
  /// **'Only retained'**
  String get monitorOnlyRetained;

  /// No description provided for @monitorOnlyErrors.
  ///
  /// In en, this message translates to:
  /// **'Only errors'**
  String get monitorOnlyErrors;

  /// No description provided for @monitorNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No entry matches the filter.'**
  String get monitorNoMatch;

  /// No description provided for @monitorBufferSize.
  ///
  /// In en, this message translates to:
  /// **'Buffer size'**
  String get monitorBufferSize;

  /// No description provided for @monitorExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get monitorExport;

  /// No description provided for @monitorExportText.
  ///
  /// In en, this message translates to:
  /// **'As text'**
  String get monitorExportText;

  /// No description provided for @monitorExportCsv.
  ///
  /// In en, this message translates to:
  /// **'As CSV'**
  String get monitorExportCsv;

  /// No description provided for @monitorExportJsonl.
  ///
  /// In en, this message translates to:
  /// **'As JSON Lines (recording)'**
  String get monitorExportJsonl;

  /// No description provided for @monitorExportEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to export.'**
  String get monitorExportEmpty;

  /// No description provided for @monitorMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'{direction} · {topic}'**
  String monitorMessageTitle(String direction, String topic);

  /// No description provided for @eventConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {detail}'**
  String eventConnecting(String detail);

  /// No description provided for @eventConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected ({detail})'**
  String eventConnected(String detail);

  /// No description provided for @eventConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {detail}'**
  String eventConnectFailed(String detail);

  /// No description provided for @eventSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribed: {detail}'**
  String eventSubscribe(String detail);

  /// No description provided for @eventUnsubscribe.
  ///
  /// In en, this message translates to:
  /// **'Unsubscribed: {detail}'**
  String eventUnsubscribe(String detail);

  /// No description provided for @eventDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get eventDisconnect;

  /// No description provided for @eventConnectionLost.
  ///
  /// In en, this message translates to:
  /// **'Connection lost: {detail}'**
  String eventConnectionLost(String detail);

  /// No description provided for @eventReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect scheduled: {detail}'**
  String eventReconnect(String detail);

  /// No description provided for @eventPublishFailed.
  ///
  /// In en, this message translates to:
  /// **'Publish failed: {detail}'**
  String eventPublishFailed(String detail);

  /// No description provided for @eventReplayStarted.
  ///
  /// In en, this message translates to:
  /// **'Replay started: {detail}'**
  String eventReplayStarted(String detail);

  /// No description provided for @eventReplayFinished.
  ///
  /// In en, this message translates to:
  /// **'Replay finished: {detail}'**
  String eventReplayFinished(String detail);

  /// No description provided for @replayTitle.
  ///
  /// In en, this message translates to:
  /// **'Replay a recording'**
  String get replayTitle;

  /// No description provided for @replayLoad.
  ///
  /// In en, this message translates to:
  /// **'Load file (JSON Lines)'**
  String get replayLoad;

  /// No description provided for @replayLoaded.
  ///
  /// In en, this message translates to:
  /// **'{name}: {count} messages, {topics} topics, duration {duration}'**
  String replayLoaded(String name, int count, int topics, String duration);

  /// No description provided for @replaySkipped.
  ///
  /// In en, this message translates to:
  /// **'{count} lines skipped (events or unreadable)'**
  String replaySkipped(int count);

  /// No description provided for @replayNoMessages.
  ///
  /// In en, this message translates to:
  /// **'The file contains no messages.'**
  String get replayNoMessages;

  /// No description provided for @replaySpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get replaySpeed;

  /// No description provided for @replayNoPauses.
  ///
  /// In en, this message translates to:
  /// **'no pauses'**
  String get replayNoPauses;

  /// No description provided for @replayCapPauses.
  ///
  /// In en, this message translates to:
  /// **'Shorten pauses over 10 s to 10 s'**
  String get replayCapPauses;

  /// No description provided for @replayPrefix.
  ///
  /// In en, this message translates to:
  /// **'Topic prefix'**
  String get replayPrefix;

  /// No description provided for @replayPrefixHint.
  ///
  /// In en, this message translates to:
  /// **'added to every topic so live data is not overwritten'**
  String get replayPrefixHint;

  /// No description provided for @replayKeepRetain.
  ///
  /// In en, this message translates to:
  /// **'Keep retain flags'**
  String get replayKeepRetain;

  /// No description provided for @replayKeepRetainHint.
  ///
  /// In en, this message translates to:
  /// **'Off: no retained values are left behind by the replay'**
  String get replayKeepRetainHint;

  /// No description provided for @replayOnlyReceived.
  ///
  /// In en, this message translates to:
  /// **'Only received messages'**
  String get replayOnlyReceived;

  /// No description provided for @replayStart.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get replayStart;

  /// No description provided for @replayConfirm.
  ///
  /// In en, this message translates to:
  /// **'{count} messages will be published to the connected broker “{broker}”. Continue?'**
  String replayConfirm(int count, String broker);

  /// No description provided for @replayRunning.
  ///
  /// In en, this message translates to:
  /// **'Replay: {done} of {total}'**
  String replayRunning(int done, int total);

  /// No description provided for @replayStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get replayStop;

  /// No description provided for @replayNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'Connect to a broker to replay.'**
  String get replayNeedsConnection;

  /// No description provided for @toolsBrokerInfo.
  ///
  /// In en, this message translates to:
  /// **'Broker info'**
  String get toolsBrokerInfo;

  /// No description provided for @toolsTopicTester.
  ///
  /// In en, this message translates to:
  /// **'Topic tester'**
  String get toolsTopicTester;

  /// No description provided for @toolsPayloadConverter.
  ///
  /// In en, this message translates to:
  /// **'Payload converter'**
  String get toolsPayloadConverter;

  /// No description provided for @brokerInfoEmpty.
  ///
  /// In en, this message translates to:
  /// **'No \$SYS data. Not every broker publishes it, and it only arrives with a subscription to \$SYS/#.'**
  String get brokerInfoEmpty;

  /// No description provided for @brokerInfoSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to \$SYS/#'**
  String get brokerInfoSubscribe;

  /// No description provided for @brokerVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get brokerVersion;

  /// No description provided for @brokerUptime.
  ///
  /// In en, this message translates to:
  /// **'Uptime'**
  String get brokerUptime;

  /// No description provided for @brokerClientsConnected.
  ///
  /// In en, this message translates to:
  /// **'Clients connected'**
  String get brokerClientsConnected;

  /// No description provided for @brokerClientsTotal.
  ///
  /// In en, this message translates to:
  /// **'Clients total'**
  String get brokerClientsTotal;

  /// No description provided for @brokerClientsMaximum.
  ///
  /// In en, this message translates to:
  /// **'Clients maximum'**
  String get brokerClientsMaximum;

  /// No description provided for @brokerSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get brokerSubscriptions;

  /// No description provided for @brokerRetained.
  ///
  /// In en, this message translates to:
  /// **'Retained messages'**
  String get brokerRetained;

  /// No description provided for @brokerMessagesReceived.
  ///
  /// In en, this message translates to:
  /// **'Messages received'**
  String get brokerMessagesReceived;

  /// No description provided for @brokerMessagesSent.
  ///
  /// In en, this message translates to:
  /// **'Messages sent'**
  String get brokerMessagesSent;

  /// No description provided for @brokerLoadReceived.
  ///
  /// In en, this message translates to:
  /// **'Received / min (avg 1 min)'**
  String get brokerLoadReceived;

  /// No description provided for @brokerLoadSent.
  ///
  /// In en, this message translates to:
  /// **'Sent / min (avg 1 min)'**
  String get brokerLoadSent;

  /// No description provided for @brokerBytesReceived.
  ///
  /// In en, this message translates to:
  /// **'Bytes received'**
  String get brokerBytesReceived;

  /// No description provided for @brokerBytesSent.
  ///
  /// In en, this message translates to:
  /// **'Bytes sent'**
  String get brokerBytesSent;

  /// No description provided for @brokerHeap.
  ///
  /// In en, this message translates to:
  /// **'Memory (heap)'**
  String get brokerHeap;

  /// No description provided for @testerFilter.
  ///
  /// In en, this message translates to:
  /// **'Topic filter'**
  String get testerFilter;

  /// No description provided for @testerTopics.
  ///
  /// In en, this message translates to:
  /// **'Topics (one per line)'**
  String get testerTopics;

  /// No description provided for @testerMatch.
  ///
  /// In en, this message translates to:
  /// **'matches'**
  String get testerMatch;

  /// No description provided for @testerMatchMulti.
  ///
  /// In en, this message translates to:
  /// **'matches (# from level {level} covers the rest)'**
  String testerMatchMulti(int level);

  /// No description provided for @testerLevelMismatch.
  ///
  /// In en, this message translates to:
  /// **'no match: level {level} differs'**
  String testerLevelMismatch(int level);

  /// No description provided for @testerTooShort.
  ///
  /// In en, this message translates to:
  /// **'no match: topic ends before filter level {level}'**
  String testerTooShort(int level);

  /// No description provided for @testerTooLong.
  ///
  /// In en, this message translates to:
  /// **'no match: topic has more levels than the filter'**
  String get testerTooLong;

  /// No description provided for @testerDollar.
  ///
  /// In en, this message translates to:
  /// **'no match: topics starting with \$ are never matched by a leading + or #'**
  String get testerDollar;

  /// No description provided for @testerInvalidFilter.
  ///
  /// In en, this message translates to:
  /// **'Invalid filter: {error}'**
  String testerInvalidFilter(String error);

  /// No description provided for @testerInvalidTopic.
  ///
  /// In en, this message translates to:
  /// **'Invalid topic: {error}'**
  String testerInvalidTopic(String error);

  /// No description provided for @testerHelp.
  ///
  /// In en, this message translates to:
  /// **'+ stands for exactly one level, # (only at the end) for any number, including the parent level.'**
  String get testerHelp;

  /// No description provided for @converterInput.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get converterInput;

  /// No description provided for @converterDecimal.
  ///
  /// In en, this message translates to:
  /// **'Decimal'**
  String get converterDecimal;

  /// No description provided for @converterCArray.
  ///
  /// In en, this message translates to:
  /// **'C array'**
  String get converterCArray;

  /// No description provided for @converterInvalidUtf8.
  ///
  /// In en, this message translates to:
  /// **'not valid UTF-8'**
  String get converterInvalidUtf8;

  /// No description provided for @converterLength.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get converterLength;

  /// No description provided for @converterInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid input: {error}'**
  String converterInvalid(String error);

  /// No description provided for @converterCopied.
  ///
  /// In en, this message translates to:
  /// **'{label} copied'**
  String converterCopied(String label);

  /// No description provided for @settingsMqttMonitor.
  ///
  /// In en, this message translates to:
  /// **'Monitor buffer'**
  String get settingsMqttMonitor;

  /// No description provided for @settingsMqttMonitorHint.
  ///
  /// In en, this message translates to:
  /// **'The monitor keeps this many messages and events; older ones are dropped.'**
  String get settingsMqttMonitorHint;

  /// No description provided for @mqttMonitorCount.
  ///
  /// In en, this message translates to:
  /// **'{shown} of {total} entries · buffer {capacity}'**
  String mqttMonitorCount(int shown, int total, int capacity);

  /// No description provided for @mqttMonitorEmpty.
  ///
  /// In en, this message translates to:
  /// **'No entries yet.'**
  String get mqttMonitorEmpty;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
