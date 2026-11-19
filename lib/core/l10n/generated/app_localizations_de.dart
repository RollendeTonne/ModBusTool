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
  String get monitorPageDescription =>
      'Live-Protokoll aller Telegramme mit Hex-Dump und Frame-Dekodierung.';

  @override
  String get toolsPageDescription =>
      'Hex-Rechner, Slave-/Register-Scanner und Statistik.';

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

  @override
  String get actionConnect => 'Verbinden';

  @override
  String get actionDisconnect => 'Trennen';

  @override
  String get actionCancel => 'Abbrechen';

  @override
  String get actionSave => 'Speichern';

  @override
  String get actionDelete => 'Löschen';

  @override
  String get actionDuplicate => 'Duplizieren';

  @override
  String get actionEdit => 'Bearbeiten';

  @override
  String get actionRetry => 'Erneut versuchen';

  @override
  String profileCopyName(String name) {
    return '$name (Kopie)';
  }

  @override
  String get profilesTitle => 'Verbindungsprofile';

  @override
  String get profileNew => 'Neues Profil';

  @override
  String get profileEditTitle => 'Profil bearbeiten';

  @override
  String get profileDeleteTitle => 'Profil löschen?';

  @override
  String profileDeleteBody(String name) {
    return '„$name“ wird dauerhaft entfernt.';
  }

  @override
  String profileLastUsed(String date) {
    return 'Zuletzt verwendet $date';
  }

  @override
  String get profileNeverUsed => 'Noch nie verwendet';

  @override
  String get profilesEmpty =>
      'Noch keine Profile. Lege eines an, um dich mit einem Gerät zu verbinden.';

  @override
  String get profileActive => 'Aktiv';

  @override
  String get connectionKindTcp => 'Modbus TCP';

  @override
  String get connectionKindRtu => 'Modbus RTU';

  @override
  String get connectionKindRtuOverTcp => 'RTU über TCP';

  @override
  String get connectionKindSimulator => 'Simulator';

  @override
  String get sectionConnection => 'Verbindung';

  @override
  String get sectionSerial => 'Serielle Einstellungen';

  @override
  String get sectionRequests => 'Anfragen';

  @override
  String get sectionSimulator => 'Simulation';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldHost => 'Host / IP-Adresse';

  @override
  String get fieldPort => 'Port';

  @override
  String get fieldUnitId => 'Unit-/Slave-ID';

  @override
  String get fieldTimeout => 'Timeout (ms)';

  @override
  String get fieldRetries => 'Wiederholungen';

  @override
  String get fieldSerialPort => 'Serielle Schnittstelle';

  @override
  String get fieldBaudRate => 'Baudrate';

  @override
  String get fieldCustomBaudRate => 'Eigene Baudrate';

  @override
  String get baudRateCustom => 'Eigene…';

  @override
  String get fieldDataBits => 'Datenbits';

  @override
  String get fieldParity => 'Parität';

  @override
  String get parityNone => 'Keine';

  @override
  String get parityEven => 'Gerade';

  @override
  String get parityOdd => 'Ungerade';

  @override
  String get fieldStopBits => 'Stoppbits';

  @override
  String get fieldRts => 'RTS-Leitung';

  @override
  String get fieldDtr => 'DTR-Leitung';

  @override
  String get lineUnchanged => 'Unverändert';

  @override
  String get lineOn => 'Ein';

  @override
  String get lineOff => 'Aus';

  @override
  String get fieldInterFrameDelay => 'Pause zwischen Frames (ms)';

  @override
  String interFrameDelayAuto(String value) {
    return 'Leer = automatisch (t3.5 = $value ms)';
  }

  @override
  String get fieldAutoReconnect => 'Automatisch neu verbinden';

  @override
  String get fieldAutoReconnectHint =>
      'Versucht es bei Verbindungsabbruch mit wachsender Pause erneut.';

  @override
  String get fieldSimFraming => 'Framing';

  @override
  String get fieldSimLatency => 'Simulierte Latenz (ms)';

  @override
  String get fieldSimDrop => 'Verlorene Antworten (%)';

  @override
  String get fieldSimCorrupt => 'Verfälschte Antworten (%)';

  @override
  String get refreshPorts => 'Ports aktualisieren';

  @override
  String get noPortsFound => 'Keine seriellen Schnittstellen gefunden';

  @override
  String portNotAvailable(String port) {
    return '$port (nicht angeschlossen)';
  }

  @override
  String get validationRequired => 'Pflichtfeld';

  @override
  String validationRange(int min, int max) {
    return 'Muss zwischen $min und $max liegen';
  }

  @override
  String get validationNumber => 'Bitte eine Zahl eingeben';

  @override
  String get statusNotConnected => 'Nicht verbunden';

  @override
  String get statusNotConnectedHint => 'Profil auswählen und verbinden.';

  @override
  String statusConnectedTo(String target) {
    return 'Verbunden mit $target';
  }

  @override
  String statusConnectingTo(String target) {
    return 'Verbinde mit $target…';
  }

  @override
  String statusReconnecting(int attempt) {
    return 'Verbindung verloren – neuer Versuch ($attempt)…';
  }

  @override
  String statusSince(String time) {
    return 'seit $time';
  }

  @override
  String statusFailed(String target) {
    return 'Verbindung zu $target fehlgeschlagen';
  }

  @override
  String get errorDetails => 'Technische Details';

  @override
  String get errorRefusedTitle => 'Verbindung abgelehnt';

  @override
  String get errorRefusedHint =>
      'Das Gerät ist erreichbar, aber auf diesem Port lauscht nichts. Portnummer prüfen und ob Modbus TCP im Gerät aktiviert ist.';

  @override
  String get errorConnectTimeoutTitle => 'Gerät nicht erreichbar';

  @override
  String get errorConnectTimeoutHint =>
      'Keine Antwort auf den Verbindungsaufbau. IP-Adresse, Netzwerkkabel, Subnetz und Firewall prüfen.';

  @override
  String get errorHostNotFoundTitle => 'Host nicht gefunden';

  @override
  String get errorHostNotFoundHint =>
      'Der Hostname konnte nicht aufgelöst werden. Schreibweise prüfen oder die IP-Adresse verwenden.';

  @override
  String get errorUnreachableTitle => 'Netzwerk nicht erreichbar';

  @override
  String get errorUnreachableHint =>
      'Netzwerkadapter und IP-/Subnetz-Einstellungen dieses Rechners prüfen.';

  @override
  String get errorPortUnavailableTitle =>
      'Serielle Schnittstelle nicht verfügbar';

  @override
  String get errorPortUnavailableHint =>
      'Der Port fehlt oder wird von einem anderen Programm benutzt. Adapter neu einstecken oder andere Tools schließen.';

  @override
  String get errorPermissionTitle => 'Zugriff verweigert';

  @override
  String get errorPermissionHint =>
      'Keine Berechtigung für den Port. Linux: Benutzer zur Gruppe „dialout“ hinzufügen. Android: USB-Zugriff erlauben.';

  @override
  String get errorInvalidSettingsTitle => 'Einstellungen nicht unterstützt';

  @override
  String get errorInvalidSettingsHint =>
      'Der Adapter unterstützt diese seriellen Einstellungen nicht (Baudrate, Datenbits, Parität, Stoppbits).';

  @override
  String get errorUnsupportedTitle => 'Auf dieser Plattform nicht unterstützt';

  @override
  String get errorUnsupportedHint =>
      'Auf diesem Gerät Modbus TCP oder den Simulator verwenden.';

  @override
  String get errorClosedTitle => 'Verbindung verloren';

  @override
  String get errorClosedHint =>
      'Gerät, Gateway oder Netzwerk haben die Verbindung beendet.';

  @override
  String get errorConnectionTitle => 'Verbindung fehlgeschlagen';

  @override
  String get errorConnectionHint => 'Siehe technische Details.';

  @override
  String get errorTimeoutTitle => 'Keine Antwort';

  @override
  String errorTimeoutHint(int timeout, int attempts) {
    return 'Keine gültige Antwort innerhalb von $timeout ms ($attempts Versuch(e)). Unit-ID, serielle Einstellungen (Baudrate, Parität) und Verkabelung (A/B vertauscht?) prüfen.';
  }

  @override
  String get errorProtocolTitle => 'Ungültige Antwort';

  @override
  String get errorProtocolHint =>
      'Das Gerät hat geantwortet, aber die Antwort ist fehlerhaft. Mögliche Ursachen: Störungen, falsches Framing (TCP vs. RTU über TCP) oder ein zweiter Master am Bus.';

  @override
  String get errorNotConnectedTitle => 'Nicht verbunden';

  @override
  String get errorNotConnectedHint => 'Zuerst mit einem Gerät verbinden.';

  @override
  String get errorWriteLockedTitle => 'Schreiben ist gesperrt';

  @override
  String get errorWriteLockedHint => 'Zuerst das Schreiben freigeben.';

  @override
  String get errorUnexpectedTitle => 'Unerwarteter Fehler';

  @override
  String get simulatorServerTitle => 'Simulator-TCP-Server';

  @override
  String get simulatorServerHint =>
      'Andere Modbus-Tools können sich mit dem Demo-Gerät verbinden.';

  @override
  String simulatorServerRunning(String address) {
    return 'Läuft auf $address';
  }

  @override
  String simulatorServerConnections(int count) {
    return '$count Client(s) verbunden';
  }

  @override
  String get simulatorServerStopped => 'Gestoppt';

  @override
  String get simulatorServerExpose => 'Im Netzwerk erreichbar';

  @override
  String simulatorServerStartFailed(String error) {
    return 'Start fehlgeschlagen: $error';
  }

  @override
  String get tableCoils => 'Coils';

  @override
  String get tableDiscreteInputs => 'Diskrete Eingänge';

  @override
  String get tableInputRegisters => 'Input-Register';

  @override
  String get tableHoldingRegisters => 'Holding-Register';

  @override
  String get fieldStartAddress => 'Startadresse';

  @override
  String get fieldCount => 'Anzahl';

  @override
  String get fieldUnitIdOverride => 'Unit-ID';

  @override
  String get fieldUnitIdOverrideHint => 'Leer = Profil';

  @override
  String addressHintProtocol(String address) {
    return '= Protokolladresse $address';
  }

  @override
  String get addressModeTooltip =>
      'Adressierung – in den Einstellungen änderbar';

  @override
  String get actionRead => 'Lesen';

  @override
  String actionReadTooltip(String shortcut) {
    return 'Einmal lesen ($shortcut)';
  }

  @override
  String get actionStartPolling => 'Pollen';

  @override
  String get actionStopPolling => 'Stoppen';

  @override
  String get fieldPollInterval => 'Intervall (ms)';

  @override
  String get writeUnlockLabel => 'Schreiben freigegeben';

  @override
  String get writeUnlockTooltip =>
      'Schutz vor versehentlichem Schreiben; nach einem Neustart wieder gesperrt.';

  @override
  String get columnAddress => 'Adresse';

  @override
  String get columnHex => 'Hex';

  @override
  String get columnUnsigned => 'Unsigned';

  @override
  String get columnSigned => 'Signed';

  @override
  String get columnBinary => 'Binär';

  @override
  String get columnValue => 'Wert';

  @override
  String get bitOn => 'EIN';

  @override
  String get bitOff => 'AUS';

  @override
  String get registersEmpty =>
      'Noch keine Daten. „Lesen“ drücken oder Polling starten.';

  @override
  String readStatus(int count, int latency, String time) {
    return '$count Werte · $latency ms · $time';
  }

  @override
  String pollStatus(int reads, int errors) {
    return 'Abfragen: $reads · Fehler: $errors';
  }

  @override
  String get actionOpenConnections => 'Zu den Verbindungen';

  @override
  String get actionConnectSimulator => 'Mit Simulator verbinden';

  @override
  String writeRegisterTitle(String address) {
    return 'Register $address schreiben';
  }

  @override
  String get writeMultipleTitle => 'Mehrere Werte schreiben';

  @override
  String get actionWriteMultiple => 'Mehrere schreiben…';

  @override
  String get actionWriteRow => 'Wert schreiben';

  @override
  String get fieldValue => 'Wert';

  @override
  String get valueFormatsHint =>
      'Dezimal (-32768…65535), 0x… hex oder 0b… binär';

  @override
  String get fieldValues => 'Werte';

  @override
  String get registerValuesHint =>
      'Durch Komma oder Leerzeichen getrennt; dezimal, 0x… oder 0b…';

  @override
  String get coilValuesHint =>
      '1/0 oder ein/aus, durch Komma oder Leerzeichen getrennt';

  @override
  String get useFc16 => 'Als FC16 senden (für Geräte ohne FC06)';

  @override
  String get bitsLabel => 'Bits – zum Umschalten klicken';

  @override
  String get actionWrite => 'Schreiben';

  @override
  String get confirmWriteTitle => 'Schreiben bestätigen';

  @override
  String confirmWriteBody(int unit) {
    return 'An Unit $unit senden?';
  }

  @override
  String writeSuccess(String summary) {
    return 'Geschrieben: $summary';
  }

  @override
  String get invalidValue => 'Ungültiger Wert';

  @override
  String tooManyValues(int max) {
    return 'Höchstens $max Werte';
  }

  @override
  String get rangeExceedsAddressSpace => 'Bereich überschreitet Adresse 65535';
}
