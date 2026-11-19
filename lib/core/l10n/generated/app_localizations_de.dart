// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Modbus Explorer';

  @override
  String get navConnection => 'Verbindung';

  @override
  String get navRegisters => 'Register';

  @override
  String get navMonitor => 'Monitor';

  @override
  String get navTools => 'Werkzeuge';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get connectionStatusDisconnected => 'Getrennt';

  @override
  String get connectionStatusConnecting => 'Verbinde…';

  @override
  String get connectionStatusConnected => 'Verbunden';

  @override
  String get connectionStatusError => 'Fehler';

  @override
  String connectionStatusLabel(String status) {
    return 'Verbindungsstatus: $status';
  }

  @override
  String plannedFeatureMilestone(String milestone) {
    return 'Geplant für Meilenstein $milestone';
  }

  @override
  String get connectionPageDescription =>
      'Verbindungsprofile für Modbus TCP, RTU und RTU über TCP verwalten.';

  @override
  String get registersPageDescription =>
      'Register lesen und schreiben, alle Interpretationen ansehen und die Register-Map pflegen.';

  @override
  String get monitorPageDescription =>
      'Live-Protokoll aller Telegramme mit Hex-Dump und Frame-Dekodierung.';

  @override
  String get toolsPageDescription =>
      'Hex-Rechner, Slave-/Register-Scanner und Statistik.';

  @override
  String get availableTransports => 'Auf dieser Plattform verfügbar';

  @override
  String get transportTcp => 'Modbus TCP';

  @override
  String get transportRtu => 'Modbus RTU (seriell)';

  @override
  String get transportRtuOverTcp => 'Modbus RTU über TCP';

  @override
  String get transportUnavailableHint =>
      'Serielle Schnittstellen sind auf dieser Plattform nicht verfügbar.';

  @override
  String get available => 'verfügbar';

  @override
  String get unavailable => 'nicht verfügbar';

  @override
  String get settingsAppearance => 'Darstellung';

  @override
  String get settingsTheme => 'Farbschema';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get languageSystem => 'System';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsModbus => 'Modbus';

  @override
  String get settingsAddressing => 'Adressierung';

  @override
  String get addressingZeroBased => '0-basiert (Protokoll)';

  @override
  String get addressingOneBased => '1-basiert (4xxxx/3xxxx)';

  @override
  String get addressingZeroBasedHint =>
      'Adressen werden so angezeigt, wie sie im Telegramm stehen (Holding-Register 0 = erstes Register).';

  @override
  String get addressingOneBasedHint =>
      'Klassische Notation: Holding-Register 40001 = Protokolladresse 0.';

  @override
  String get settingsConfirmWrites => 'Schreibzugriffe bestätigen';

  @override
  String get settingsConfirmWritesHint =>
      'Vor jedem Schreib-Request an das Gerät nachfragen.';

  @override
  String get settingsHighlightPlausible =>
      'Plausible Interpretationen hervorheben';

  @override
  String get settingsHighlightPlausibleHint =>
      'Heuristische Markierung sinnvoll aussehender Werte in der Interpretations-Matrix.';

  @override
  String get exceptionIllegalFunctionTitle => '01 Unzulässige Funktion';

  @override
  String get exceptionIllegalFunctionExplanation =>
      'Das Gerät unterstützt diesen Funktionscode nicht. Andere Funktion versuchen (z. B. FC04 statt FC03) oder Gerätehandbuch prüfen.';

  @override
  String get exceptionIllegalDataAddressTitle => '02 Unzulässige Adresse';

  @override
  String get exceptionIllegalDataAddressExplanation =>
      'Der Adressbereich existiert im Gerät nicht. Startadresse, Anzahl und Adressierung (0- oder 1-basiert, um eins verschoben) prüfen.';

  @override
  String get exceptionIllegalDataValueTitle => '03 Unzulässiger Wert';

  @override
  String get exceptionIllegalDataValueExplanation =>
      'Ein Wert in der Anfrage ist nicht erlaubt, z. B. zu viele Register auf einmal oder ein Wert außerhalb des zulässigen Bereichs.';

  @override
  String get exceptionServerDeviceFailureTitle => '04 Gerätefehler';

  @override
  String get exceptionServerDeviceFailureExplanation =>
      'Im Gerät ist bei der Verarbeitung ein interner Fehler aufgetreten. Häufige Ursache: reservierte oder vorübergehend nicht verfügbare Register.';

  @override
  String get exceptionAcknowledgeTitle => '05 Bestätigt, in Bearbeitung';

  @override
  String get exceptionAcknowledgeExplanation =>
      'Das Gerät hat die Anfrage angenommen, braucht aber länger. Später erneut abfragen.';

  @override
  String get exceptionServerDeviceBusyTitle => '06 Gerät beschäftigt';

  @override
  String get exceptionServerDeviceBusyExplanation =>
      'Das Gerät arbeitet gerade einen längeren Befehl ab. Später wiederholen oder seltener pollen.';

  @override
  String get exceptionNegativeAcknowledgeTitle => '07 Nicht ausführbar';

  @override
  String get exceptionNegativeAcknowledgeExplanation =>
      'Das Gerät kann die angeforderte Programmfunktion nicht ausführen (veralteter Code).';

  @override
  String get exceptionMemoryParityErrorTitle => '08 Speicher-Paritätsfehler';

  @override
  String get exceptionMemoryParityErrorExplanation =>
      'Das Gerät hat einen Paritätsfehler im Speicher erkannt. Das Gerät muss evtl. gewartet werden.';

  @override
  String get exceptionGatewayPathUnavailableTitle =>
      '0A Gateway-Pfad nicht verfügbar';

  @override
  String get exceptionGatewayPathUnavailableExplanation =>
      'Das Gateway konnte die Anfrage nicht weiterleiten. Gateway-Konfiguration und Unit-ID prüfen.';

  @override
  String get exceptionGatewayTargetFailedTitle =>
      '0B Zielgerät antwortet nicht';

  @override
  String get exceptionGatewayTargetFailedExplanation =>
      'Das Gateway hat vom Gerät dahinter keine Antwort bekommen. Unit-ID, serielle Einstellungen und Verkabelung auf der seriellen Seite prüfen.';

  @override
  String exceptionUnknownTitle(String code) {
    return 'Exception $code';
  }

  @override
  String get exceptionUnknownExplanation =>
      'Nicht standardisierter Exception-Code. Siehe Gerätehandbuch.';
}
