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
  /// **'Modbus Explorer'**
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

  /// No description provided for @plannedFeatureMilestone.
  ///
  /// In en, this message translates to:
  /// **'Planned for milestone {milestone}'**
  String plannedFeatureMilestone(String milestone);

  /// No description provided for @monitorPageDescription.
  ///
  /// In en, this message translates to:
  /// **'Live log of all frames with hex dump and frame decoding.'**
  String get monitorPageDescription;

  /// No description provided for @toolsPageDescription.
  ///
  /// In en, this message translates to:
  /// **'Hex calculator, slave/register scanner and statistics.'**
  String get toolsPageDescription;

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
