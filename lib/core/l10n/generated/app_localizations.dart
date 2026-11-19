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

  /// No description provided for @connectionPageDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage Modbus TCP, RTU and RTU-over-TCP connection profiles.'**
  String get connectionPageDescription;

  /// No description provided for @registersPageDescription.
  ///
  /// In en, this message translates to:
  /// **'Read and write registers, view every interpretation and maintain the register map.'**
  String get registersPageDescription;

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

  /// No description provided for @availableTransports.
  ///
  /// In en, this message translates to:
  /// **'Available on this platform'**
  String get availableTransports;

  /// No description provided for @transportTcp.
  ///
  /// In en, this message translates to:
  /// **'Modbus TCP'**
  String get transportTcp;

  /// No description provided for @transportRtu.
  ///
  /// In en, this message translates to:
  /// **'Modbus RTU (serial)'**
  String get transportRtu;

  /// No description provided for @transportRtuOverTcp.
  ///
  /// In en, this message translates to:
  /// **'Modbus RTU over TCP'**
  String get transportRtuOverTcp;

  /// No description provided for @transportUnavailableHint.
  ///
  /// In en, this message translates to:
  /// **'Serial ports are not available on this platform.'**
  String get transportUnavailableHint;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'available'**
  String get available;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'not available'**
  String get unavailable;

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
