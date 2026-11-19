import 'package:flutter/widgets.dart';
import 'package:modbus_explorer/core/l10n/generated/app_localizations.dart';

export 'package:modbus_explorer/core/l10n/generated/app_localizations.dart';

/// English first: Flutter falls back to the first entry when the system
/// language is neither German nor English.
const supportedAppLocales = [Locale('en'), Locale('de')];

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
