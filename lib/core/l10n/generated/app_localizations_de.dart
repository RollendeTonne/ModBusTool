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

  @override
  String get interpretationTitle => 'Interpretation';

  @override
  String interpretationSelection(String range, int count) {
    return '$range · $count Register';
  }

  @override
  String get interpretationHint =>
      'Register in der Tabelle auswählen (Umschalt+Klick für einen Bereich).';

  @override
  String get interpretationBitTables =>
      'Interpretationen gibt es für Input- und Holding-Register.';

  @override
  String get interpretationNoData =>
      'Register lesen, um alle Interpretationen zu sehen.';

  @override
  String sectionRegister(String address) {
    return 'Register $address';
  }

  @override
  String get labelHighByte => 'High-Byte';

  @override
  String get labelLowByte => 'Low-Byte';

  @override
  String get labelAscii => 'ASCII';

  @override
  String get bitsReadOnlyHint =>
      'Zum Umschalten der Bits das Schreiben freigeben.';

  @override
  String get sectionMatrix => 'Alle Interpretationen';

  @override
  String get columnType => 'Typ';

  @override
  String matrixNeedsRegisters(int count) {
    return 'Benötigt $count Register';
  }

  @override
  String get matrixDuplicate =>
      'Gleiche Byte-Reihenfolge wie eine vorherige Spalte';

  @override
  String get plausibilityNaN => 'Keine Zahl (NaN)';

  @override
  String get plausibilityInfinite => 'Unendlich';

  @override
  String get plausibilityDenormal =>
      'Denormalisierte Zahl – fast sicher falsche Byte-Reihenfolge';

  @override
  String get plausibilityHuge => 'Unplausibel groß';

  @override
  String get plausibilityTiny => 'Unplausibel klein';

  @override
  String get plausibilityManyDigits =>
      'Viele signifikante Stellen – eher unwahrscheinlich';

  @override
  String get plausibilityDate => 'Datum außerhalb 2000–2100';

  @override
  String get plausibilityNonPrintable => 'Enthält nicht druckbare Zeichen';

  @override
  String get plausibilityInvalid => 'Ungültiger Wert';

  @override
  String get plausibilityPlausible => 'Wirkt plausibel';

  @override
  String copiedValue(String value) {
    return 'Kopiert: $value';
  }

  @override
  String get copiedTable => 'Tabelle kopiert';

  @override
  String get actionCopy => 'Kopieren';

  @override
  String get actionAddToMap => 'Zur Register-Map hinzufügen…';

  @override
  String get actionCopyTable => 'Tabelle kopieren';

  @override
  String get actionCopyCsv => 'Als CSV kopieren';

  @override
  String get sectionText => 'Text';

  @override
  String get textSwapBytes => 'Bytes tauschen (BA)';

  @override
  String get fieldEncoding => 'Kodierung';

  @override
  String get sectionScaling => 'Skalierung';

  @override
  String get fieldFactor => 'Faktor';

  @override
  String get fieldOffset => 'Offset';

  @override
  String get fieldDecimals => 'Nachkommastellen';

  @override
  String get scalingHint => 'Angezeigter Wert = Rohwert × Faktor + Offset';

  @override
  String get actionReset => 'Zurücksetzen';

  @override
  String get viewRaw => 'Rohwerte';

  @override
  String viewMap(int count) {
    return 'Register-Map ($count)';
  }

  @override
  String get columnLabel => 'Label';

  @override
  String get mapEmpty =>
      'Noch keine Einträge. Register auswählen, in der Interpretationstabelle das Menü einer Zelle öffnen und „Zur Register-Map hinzufügen“ wählen – oder einen Eintrag von Hand anlegen.';

  @override
  String get mapNoProfile =>
      'Zuerst ein Verbindungsprofil anlegen – Register-Maps werden pro Profil gespeichert.';

  @override
  String get mapSearch => 'Label oder Adresse suchen';

  @override
  String get mapSortAddress => 'Nach Adresse';

  @override
  String get mapSortLabel => 'Nach Label';

  @override
  String get actionAddEntry => 'Eintrag hinzufügen';

  @override
  String get actionReadMap => 'Alle lesen';

  @override
  String get mapEntryNewTitle => 'Neuer Eintrag';

  @override
  String get mapEntryEditTitle => 'Eintrag bearbeiten';

  @override
  String get fieldLabel => 'Label';

  @override
  String get fieldUnit => 'Einheit';

  @override
  String get fieldDescription => 'Beschreibung';

  @override
  String get fieldTable => 'Tabelle';

  @override
  String get fieldAddress => 'Adresse';

  @override
  String get fieldType => 'Datentyp';

  @override
  String get fieldByteOrder => 'Byte-Reihenfolge';

  @override
  String get fieldTextRegisters => 'Länge (Register)';

  @override
  String get fieldBit => 'Bit (0–15)';

  @override
  String get typeText => 'Text';

  @override
  String get typeBit => 'Bit';

  @override
  String get mapEntryDeleteTitle => 'Eintrag löschen?';

  @override
  String mapEntryDeleteBody(String label) {
    return '„$label“ wird aus der Register-Map entfernt.';
  }

  @override
  String mapReadStatus(int count, String time) {
    return '$count Einträge · $time';
  }

  @override
  String mapEntryCount(int count) {
    return '$count Einträge';
  }

  @override
  String get actionInterpret => 'Interpretieren';

  @override
  String mapEntrySaved(String label) {
    return 'In Register-Map gespeichert: $label';
  }

  @override
  String get mapUnnamed => '(ohne Namen)';

  @override
  String get monitorPause => 'Pausieren';

  @override
  String get monitorResume => 'Fortsetzen';

  @override
  String get monitorClear => 'Leeren';

  @override
  String get monitorErrorsOnly => 'Nur Fehler';

  @override
  String get monitorAllFunctions => 'Alle Funktionen';

  @override
  String get monitorCopyText => 'Als Text kopieren';

  @override
  String get monitorCopyCsv => 'Als CSV kopieren';

  @override
  String monitorCopied(int count) {
    return '$count Telegramme kopiert';
  }

  @override
  String get monitorEmpty =>
      'Noch keine Telegramme. Register lesen oder Polling starten – jede Anfrage und Antwort erscheint hier.';

  @override
  String monitorPaused(int count) {
    return 'Pausiert – $count Telegramme nicht aufgezeichnet';
  }

  @override
  String monitorCount(int shown, int total) {
    return '$shown von $total Telegrammen';
  }

  @override
  String get monitorSelectHint =>
      'Telegramm auswählen, um die Dekodierung zu sehen.';

  @override
  String get monitorDetailTitle => 'Telegramm-Details';

  @override
  String get monitorHexDump => 'Hex-Dump';

  @override
  String get monitorFields => 'Felder';

  @override
  String monitorTransaction(int number) {
    return 'Transaktion #$number';
  }

  @override
  String monitorAttempts(int count) {
    return '$count Versuch(e)';
  }

  @override
  String get monitorResultOk => 'Erfolgreich';

  @override
  String get monitorCrcValid => 'CRC gültig';

  @override
  String get monitorCrcInvalid => 'CRC ungültig';

  @override
  String get columnField => 'Feld';

  @override
  String get columnBytes => 'Bytes';

  @override
  String get columnTime => 'Zeit';

  @override
  String get frameStatusOk => 'OK';

  @override
  String get frameStatusCrc => 'CRC-Fehler';

  @override
  String get frameStatusMalformed => 'Fehlerhaft';

  @override
  String get frameStatusUnexpected => 'Unerwartet';

  @override
  String get frameStatusIncomplete => 'Unvollständig';

  @override
  String get frameStatusException => 'Exception';

  @override
  String get segmentTransactionId => 'Transaktions-ID';

  @override
  String get segmentProtocolId => 'Protokoll-ID';

  @override
  String get segmentLength => 'Länge';

  @override
  String get segmentUnitId => 'Unit-ID';

  @override
  String get segmentFunctionCode => 'Funktionscode';

  @override
  String get segmentExceptionCode => 'Exception-Code';

  @override
  String get segmentAddress => 'Adresse';

  @override
  String get segmentCount => 'Anzahl';

  @override
  String get segmentByteCount => 'Byte-Anzahl';

  @override
  String get segmentValue => 'Wert';

  @override
  String get segmentValueList => 'Werte';

  @override
  String get segmentAndMask => 'AND-Maske';

  @override
  String get segmentOrMask => 'OR-Maske';

  @override
  String get segmentReadAddress => 'Leseadresse';

  @override
  String get segmentReadCount => 'Leseanzahl';

  @override
  String get segmentWriteAddress => 'Schreibadresse';

  @override
  String get segmentWriteCount => 'Schreibanzahl';

  @override
  String get segmentMeiType => 'MEI-Typ';

  @override
  String get segmentDeviceIdCode => 'Device-ID-Code';

  @override
  String get segmentObjectId => 'Objekt-ID';

  @override
  String get segmentConformityLevel => 'Konformitätsstufe';

  @override
  String get segmentMoreFollows => 'Weitere folgen';

  @override
  String get segmentNextObjectId => 'Nächste Objekt-ID';

  @override
  String get segmentObjectCount => 'Anzahl Objekte';

  @override
  String get segmentObject => 'Objekt';

  @override
  String get segmentData => 'Daten';

  @override
  String get segmentCrc => 'CRC';

  @override
  String get segmentTruncated => 'Abgeschnitten';

  @override
  String get segmentTrailing => 'Überzählige Bytes';

  @override
  String get toolsHexCalculator => 'Hex-Rechner';

  @override
  String get toolsScanner => 'Scanner';

  @override
  String get toolsStatistics => 'Statistik';

  @override
  String get toolsTrend => 'Trend';

  @override
  String get hexInput => 'Eingabe';

  @override
  String get hexInputHint => 'z. B. 41 20 00 00 oder 0x41200000';

  @override
  String get hexModeBytes => 'Hex-Bytes';

  @override
  String get hexModeRegisters => 'Register (hex)';

  @override
  String get hexModeDecimal => 'Register (dez)';

  @override
  String hexInvalid(String token) {
    return '„$token“ ist nicht lesbar';
  }

  @override
  String get hexOddBytes =>
      'Ungerade Byte-Anzahl – das letzte Register wurde mit 00 aufgefüllt.';

  @override
  String get hexBytesLabel => 'Bytes';

  @override
  String get hexRegistersLabel => 'Register';

  @override
  String get hexCustomOrder => 'Eigene Byte-Reihenfolge';

  @override
  String get hexPattern => 'Muster';

  @override
  String get hexPatternHint => 'z. B. EFGHABCD';

  @override
  String get hexEncoder => 'Wert → Register';

  @override
  String get hexEncodeHint => 'Zahl; Zeitstempel auch als ISO-Datum';

  @override
  String get hexUseAsInput => 'Als Eingabe übernehmen';

  @override
  String get hexCopyRegisters => 'Register kopieren';

  @override
  String get hexEmpty =>
      'Bytes oder Registerwerte eingeben, um alle Interpretationen zu sehen.';

  @override
  String get scanModeSlaves => 'Slave-IDs';

  @override
  String get scanModeRegisters => 'Registerbereich';

  @override
  String get scanFrom => 'Von';

  @override
  String get scanTo => 'Bis';

  @override
  String get scanProbeAddress => 'Test-Register';

  @override
  String get scanTimeout => 'Timeout (ms)';

  @override
  String get scanBlockSize => 'Blockgröße';

  @override
  String get scanStart => 'Scan starten';

  @override
  String scanProgress(int done, int total, int found) {
    return '$done / $total · $found gefunden';
  }

  @override
  String scanFinished(String seconds) {
    return 'Fertig nach $seconds s';
  }

  @override
  String get scanCancelled => 'Abgebrochen';

  @override
  String get scanNoResults => 'Keine Antworten.';

  @override
  String scanUnit(int id) {
    return 'Unit $id';
  }

  @override
  String scanException(String code) {
    return 'Exception $code – Gerät vorhanden';
  }

  @override
  String get scanTcpHint =>
      'Hinweis: Viele Modbus-TCP-Geräte antworten auf jede Unit-ID. Der Scan ist vor allem hinter Gateways und bei RTU aussagekräftig.';

  @override
  String scanSlowHint(int total, String seconds) {
    return 'Jede fehlende ID wartet den Timeout ab ($total IDs ≈ höchstens $seconds s).';
  }

  @override
  String get statsRequests => 'Anfragen';

  @override
  String get statsErrors => 'Fehler';

  @override
  String get statsErrorRate => 'Fehlerquote';

  @override
  String get statsLatencyAvg => 'Ø Latenz';

  @override
  String get statsLatencyMin => 'Min. Latenz';

  @override
  String get statsLatencyMax => 'Max. Latenz';

  @override
  String get statsTimeouts => 'Timeouts';

  @override
  String get statsExceptions => 'Exception-Antworten';

  @override
  String get statsProtocolErrors => 'Ungültige Antworten';

  @override
  String get statsConnectionErrors => 'Verbindungsfehler';

  @override
  String get statsRetries => 'Wiederholungen';

  @override
  String get statsByFunction => 'Nach Funktionscode';

  @override
  String statsSince(String time) {
    return 'Seit $time';
  }

  @override
  String get statsEmpty => 'Noch keine Anfragen.';

  @override
  String trendSelect(int max) {
    return 'Werte für den Graph (numerische Register-Map-Einträge, max. $max)';
  }

  @override
  String get trendNoEntries =>
      'Numerische Einträge zur Register-Map hinzufügen, um sie darzustellen.';

  @override
  String get trendPollMap => 'Register-Map pollen';

  @override
  String get trendWaiting => 'Warte auf Daten – Register-Map pollen.';

  @override
  String trendMaxReached(int max) {
    return 'Es lassen sich höchstens $max Werte darstellen.';
  }

  @override
  String get actionImport => 'Importieren…';

  @override
  String get actionExportJson => 'Als JSON exportieren…';

  @override
  String get actionExportCsv => 'Als CSV exportieren…';

  @override
  String get actionSaveText => 'Als Textdatei speichern…';

  @override
  String get actionSaveCsv => 'Als CSV-Datei speichern…';

  @override
  String exportSaved(String name) {
    return 'Gespeichert: $name';
  }

  @override
  String exportFailed(String error) {
    return 'Export fehlgeschlagen: $error';
  }

  @override
  String get importTitle => 'Register-Map importieren';

  @override
  String importSummary(int count, String file) {
    return '$count Einträge aus $file gelesen.';
  }

  @override
  String importSkipped(int count) {
    return '$count Einträge sind nicht lesbar und werden übersprungen.';
  }

  @override
  String get importAdd => 'Hinzufügen';

  @override
  String get importReplace => 'Map ersetzen';

  @override
  String importNothing(String file) {
    return '$file enthält keine lesbaren Einträge.';
  }

  @override
  String importDone(int count) {
    return '$count Einträge importiert';
  }

  @override
  String importFailed(String error) {
    return 'Import fehlgeschlagen: $error';
  }

  @override
  String get actionExportProfiles => 'Profile exportieren…';

  @override
  String get actionImportProfiles => 'Profile importieren…';

  @override
  String profilesImported(int count) {
    return '$count Profile importiert';
  }

  @override
  String get settingsShortcuts => 'Tastaturkürzel';

  @override
  String get shortcutNavigate => 'Bereich wechseln';

  @override
  String get shortcutRead => 'Einmal lesen (Register oder Register-Map)';

  @override
  String get shortcutPoll => 'Polling starten/stoppen';

  @override
  String get shortcutSubmit => 'Dialog bestätigen / speichern';

  @override
  String get shortcutClose => 'Dialog schließen';

  @override
  String get shortcutRange => 'Bereich in der Tabelle auswählen';

  @override
  String get shortcutShiftClick => 'Umschalt + Klick';

  @override
  String get settingsAbout => 'Über';

  @override
  String aboutText(String version) {
    return 'Modbus Explorer $version – Debugging-Werkzeug für Modbus TCP und RTU. Alle Daten bleiben auf diesem Gerät.';
  }

  @override
  String get toolsNetwork => 'Netzwerk';

  @override
  String get netScanHint =>
      'Findet Geräte durch Verbindungsversuche auf die gewählten TCP-Ports (kein Ping nötig). Nur Netze scannen, für die du berechtigt bist.';

  @override
  String get netScanNoMac =>
      'MAC-Adressen sind auf dieser Plattform nicht verfügbar (das System gibt die ARP-Tabelle nicht an Apps heraus).';

  @override
  String get netRange => 'Adressbereich';

  @override
  String get netRangeHint => 'z. B. 192.168.1.0/24 oder 192.168.1.10-50';

  @override
  String netRangeTooLarge(int max) {
    return 'Höchstens $max Adressen pro Scan';
  }

  @override
  String get netPorts => 'Ports';

  @override
  String get netModbusPorts => 'Modbus prüfen auf Ports';

  @override
  String get netResolveNames => 'Hostnamen auflösen';

  @override
  String get netStart => 'Netzwerk scannen';

  @override
  String get netPhasePorts => 'Prüfe Ports';

  @override
  String get netPhaseArp => 'Lese MAC-Adressen';

  @override
  String get netPhaseModbus => 'Identifiziere Modbus-Geräte';

  @override
  String get netPhaseHostnames => 'Löse Hostnamen auf';

  @override
  String get netPhaseDone => 'Fertig';

  @override
  String netProgress(String phase, int done, int total, int hosts) {
    return '$phase: $done / $total · $hosts Hosts';
  }

  @override
  String netSummary(int hosts, int modbus, String seconds) {
    return '$hosts Hosts · $modbus mit Modbus · $seconds s';
  }

  @override
  String get netOnlyModbus => 'Nur Modbus-Geräte';

  @override
  String get netThisDevice => 'dieses Gerät';

  @override
  String get netNoMac => 'MAC unbekannt';

  @override
  String get netNoHosts => 'Keine Hosts gefunden.';

  @override
  String netModbusVerified(int port) {
    return 'Modbus auf Port $port';
  }

  @override
  String netModbusException(String code) {
    return 'antwortet mit Exception $code';
  }

  @override
  String get netNoOpenPorts =>
      'keine offenen Ports (über ARP bzw. abgelehnte Verbindung gefunden)';

  @override
  String get netConnect => 'Verbinden';

  @override
  String netProfileCreated(String name) {
    return 'Profil „$name“ angelegt und verbunden';
  }

  @override
  String get netExport => 'Ergebnisse exportieren…';

  @override
  String get netScanNoMacSandbox =>
      'MAC-Adressen sind nicht verfügbar: Die macOS-App-Sandbox sperrt den Zugriff auf die ARP-Tabelle.';

  @override
  String get netArpEmptyHint =>
      'Keine MAC-Adressen erhalten: Das System hat eine leere ARP-Tabelle geliefert. Unter macOS den Zugriff auf das lokale Netzwerk für Modbus Explorer erlauben (Systemeinstellungen → Datenschutz & Sicherheit → Lokales Netzwerk) und erneut scannen.';
}
