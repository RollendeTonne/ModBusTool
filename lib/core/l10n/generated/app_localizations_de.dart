// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'ProtocollExplorer';

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
    return 'ProtocollExplorer $version – Debugging-Werkzeug für Modbus TCP/RTU und MQTT. Alle Daten bleiben auf diesem Gerät.';
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
      'Keine MAC-Adressen erhalten: Das System hat eine leere ARP-Tabelle geliefert. Unter macOS den Zugriff auf das lokale Netzwerk für ProtocollExplorer erlauben (Systemeinstellungen → Datenschutz & Sicherheit → Lokales Netzwerk) und erneut scannen.';

  @override
  String get netMacRoutedHint =>
      'Keine MAC-Adressen für diesen Bereich: Er liegt außerhalb des lokalen Netzsegments dieses Rechners (über einen Router erreichbar). MAC-Adressen lassen sich nur für Geräte im selben Segment ermitteln.';

  @override
  String get netUseActive => 'Aktives Netz';

  @override
  String get netUseActiveTooltip =>
      'Bereich des gerade genutzten Netzwerks eintragen';

  @override
  String get netActiveNone => 'Kein aktives Netzwerk gefunden';

  @override
  String netActiveFound(String iface, String address, String range) {
    return '$iface: $address → $range';
  }

  @override
  String get netActiveMaskUnknown => 'Netzmaske unbekannt, /24 angenommen';

  @override
  String netPortOpenBrowser(String target) {
    return 'Im Browser öffnen: $target';
  }

  @override
  String netPortOpenTerminal(String target) {
    return 'Im Terminal öffnen: $target';
  }

  @override
  String netPortOpenFiles(String target) {
    return 'Im Dateiprogramm öffnen: $target';
  }

  @override
  String netPortOpenRemote(String target) {
    return 'Fernsteuerung öffnen: $target';
  }

  @override
  String netPortOpenOpcUa(String target) {
    return 'Im OPC-UA-Client öffnen: $target';
  }

  @override
  String netPortConnectModbus(int port) {
    return 'Per Modbus TCP verbinden (Port $port)';
  }

  @override
  String netPortCopy(String target) {
    return 'Kein passendes Programm bekannt – $target kopieren';
  }

  @override
  String netPortCopied(String target) {
    return '$target kopiert';
  }

  @override
  String netPortNoApp(String target) {
    return 'Kein Programm für $target gefunden – Adresse kopiert';
  }

  @override
  String get navTopics => 'Topics';

  @override
  String get moduleModbus => 'Modbus';

  @override
  String get moduleMqtt => 'MQTT';

  @override
  String get moduleSwitchTooltip => 'Modul wechseln (Strg/⌘ + Umschalt + M)';

  @override
  String get mqttProfiles => 'Broker-Profile';

  @override
  String get mqttNewProfile => 'Neues Broker-Profil';

  @override
  String get mqttEditProfile => 'Broker-Profil bearbeiten';

  @override
  String get mqttNoProfiles => 'Noch keine Broker-Profile.';

  @override
  String get mqttStatusDisconnected => 'Getrennt';

  @override
  String get mqttStatusConnecting => 'Verbinde …';

  @override
  String get mqttStatusConnected => 'Verbunden';

  @override
  String get mqttStatusReconnecting => 'Neuer Versuch …';

  @override
  String get mqttStatusError => 'Fehler';

  @override
  String mqttStatusLabel(String status) {
    return 'MQTT-Status: $status';
  }

  @override
  String get mqttConnect => 'Verbinden';

  @override
  String get mqttDisconnect => 'Trennen';

  @override
  String get mqttCancelReconnect => 'Abbrechen';

  @override
  String mqttClientIdLabel(String id) {
    return 'Client-ID: $id';
  }

  @override
  String mqttReconnectIn(int attempt, int seconds) {
    return 'Versuch $attempt in $seconds s';
  }

  @override
  String get mqttSimulatorBadge => 'Demo-Broker';

  @override
  String get mqttSimulatorHint =>
      'Eingebauter Demo-Broker: veröffentlicht JSON-, Binär- und Retained-Topics sowie \$SYS-Werte. Benutzername „denied“ zeigt eine abgelehnte Verbindung.';

  @override
  String get mqttFieldType => 'Typ';

  @override
  String get mqttTypeBroker => 'Broker';

  @override
  String get mqttTypeSimulator => 'Demo-Broker';

  @override
  String get mqttFieldTransport => 'Transport';

  @override
  String get mqttFieldWsPath => 'WebSocket-Pfad';

  @override
  String get mqttFieldVersion => 'Protokollversion';

  @override
  String get mqttFieldClientId => 'Client-ID';

  @override
  String get mqttClientIdAuto =>
      'leer = bei jeder Verbindung zufällig erzeugen';

  @override
  String get mqttGenerateClientId => 'Client-ID erzeugen';

  @override
  String get mqttFieldUsername => 'Benutzername';

  @override
  String get mqttFieldPassword => 'Passwort';

  @override
  String get mqttPasswordStored =>
      'gespeichert – leer lassen, um es zu behalten';

  @override
  String get mqttPasswordSecure =>
      'wird im Schlüsselbund des Systems gespeichert, nicht im Profil';

  @override
  String get mqttRemovePassword => 'Gespeichertes Passwort löschen';

  @override
  String get mqttSectionBroker => 'Broker';

  @override
  String get mqttSectionAuth => 'Anmeldung';

  @override
  String get mqttSectionSession => 'Sitzung';

  @override
  String get mqttSectionWill => 'Last Will';

  @override
  String get mqttSectionTls => 'TLS';

  @override
  String get mqttCleanStart => 'Clean Start / Clean Session';

  @override
  String get mqttCleanStartHint =>
      'Aus: Broker behält Abos und QoS-1/2-Nachrichten der Sitzung';

  @override
  String get mqttFieldKeepAlive => 'Keep-Alive (s)';

  @override
  String get mqttFieldSessionExpiry => 'Session Expiry (s, MQTT 5)';

  @override
  String get mqttFieldConnectTimeout => 'Verbindungs-Timeout (s)';

  @override
  String get mqttAutoReconnect => 'Automatisch neu verbinden';

  @override
  String get mqttWillEnabled => 'Last Will senden';

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
      'Serverzertifikat wird gegen die System-CAs geprüft.';

  @override
  String get mqttCaCert => 'Eigene CA (PEM)';

  @override
  String get mqttClientCert => 'Client-Zertifikat (PEM)';

  @override
  String get mqttClientKey => 'Privater Schlüssel des Clients (PEM)';

  @override
  String get mqttClientKeyStored => 'im Schlüsselbund gespeichert';

  @override
  String get mqttClientKeyPassword => 'Passwort des Schlüssels';

  @override
  String get mqttLoadFile => 'Datei laden';

  @override
  String get mqttRemove => 'Entfernen';

  @override
  String get mqttNotSet => 'nicht gesetzt';

  @override
  String get mqttAcceptInvalid => 'Ungültige Zertifikate akzeptieren';

  @override
  String get mqttAcceptInvalidWarning =>
      'Unsicher: Die Verbindung ist dann nicht vor Mitlesen oder Manipulation geschützt. Nur für Test-Broker mit selbstsignierten Zertifikaten verwenden.';

  @override
  String get mqttWssCertLimit =>
      'Über WebSocket (wss) werden eigene CA und Client-Zertifikate vom MQTT-Paket nicht unterstützt; es gelten die System-CAs.';

  @override
  String get mqttWebOnlyWs =>
      'Im Browser sind nur WebSocket-Verbindungen möglich.';

  @override
  String get mqttErrorTitle => 'Verbindung fehlgeschlagen';

  @override
  String get mqttErrorLost => 'Verbindung zum Broker verloren';

  @override
  String get mqttFailNetwork =>
      'Broker nicht erreichbar. Host, Port und Netzwerk prüfen.';

  @override
  String get mqttFailTls =>
      'TLS-Fehler: Zertifikat abgelehnt oder Handshake fehlgeschlagen. CA, Hostname und Port (8883?) prüfen.';

  @override
  String get mqttFailTimeout =>
      'Zeitüberschreitung: Der Broker hat nicht rechtzeitig geantwortet.';

  @override
  String get mqttFailLost =>
      'Der Broker hat die Verbindung getrennt (z. B. Keep-Alive abgelaufen oder gleiche Client-ID an anderer Stelle).';

  @override
  String get mqttFailUnknown => 'Unbekannter Fehler beim Verbinden.';

  @override
  String mqttFailRefused(String reason, String code) {
    return 'Broker lehnt ab: $reason (Code $code)';
  }

  @override
  String get connackProtocolVersion => 'Protokollversion nicht unterstützt';

  @override
  String get connackClientId => 'Client-ID abgelehnt';

  @override
  String get connackServerUnavailable => 'Dienst nicht verfügbar';

  @override
  String get connackBadCredentials => 'Benutzername oder Passwort falsch';

  @override
  String get connackNotAuthorized => 'nicht berechtigt';

  @override
  String get connackUnspecified => 'nicht näher bezeichneter Fehler';

  @override
  String get connackMalformed => 'fehlerhaftes Paket';

  @override
  String get connackProtocolError => 'Protokollfehler';

  @override
  String get connackImplementation => 'implementierungsspezifischer Fehler';

  @override
  String get connackServerBusy => 'Broker ausgelastet';

  @override
  String get connackBanned => 'Client gesperrt';

  @override
  String get connackBadAuthMethod =>
      'Authentifizierungsmethode nicht unterstützt';

  @override
  String get connackTopicInvalid => 'Topic ungültig (Last Will)';

  @override
  String get connackPacketTooLarge => 'Paket zu groß';

  @override
  String get connackQuota => 'Kontingent überschritten';

  @override
  String get connackPayloadFormat => 'Payload-Format ungültig';

  @override
  String get connackRetainNotSupported =>
      'Retain nicht unterstützt (Last Will)';

  @override
  String get connackQosNotSupported => 'QoS nicht unterstützt (Last Will)';

  @override
  String get connackUseAnotherServer => 'anderen Broker verwenden';

  @override
  String get connackServerMoved => 'Broker umgezogen';

  @override
  String get connackRateExceeded => 'zu viele Verbindungsversuche';

  @override
  String get connackUnknown => 'unbekannter Grund';

  @override
  String get mqttNotConnectedHint => 'Nicht mit einem Broker verbunden.';

  @override
  String get mqttGoToConnection => 'Zur Verbindung';

  @override
  String get mqttTabMessages => 'Nachrichten';

  @override
  String get mqttTabSubscriptions => 'Abos';

  @override
  String get mqttTabPublish => 'Publish';

  @override
  String mqttMessagesCount(int shown, int total) {
    return '$shown von $total Nachrichten';
  }

  @override
  String get mqttNoMessages => 'Noch keine Nachrichten. Abonnements prüfen.';

  @override
  String get mqttPause => 'Anhalten';

  @override
  String get mqttResume => 'Fortsetzen';

  @override
  String get mqttClear => 'Leeren';

  @override
  String get mqttSubscriptions => 'Abonnements';

  @override
  String get mqttNoSubscriptions => 'Keine Abonnements.';

  @override
  String get mqttAddSubscription => 'Abonnieren';

  @override
  String get mqttTopicFilter => 'Topic-Filter';

  @override
  String get mqttTopicFilterHint => 'z. B. haus/+/temperatur oder sensoren/#';

  @override
  String get mqttSubscribeAll => 'Alles abonnieren (#)';

  @override
  String get mqttSubscribeAllWarning =>
      '„#“ empfängt jede Nachricht des Brokers. Auf großen oder öffentlichen Brokern können das tausende Nachrichten pro Sekunde sein. Trotzdem abonnieren?';

  @override
  String get mqttSubscribeAllConfirm => 'Abonnieren';

  @override
  String get mqttMqtt5Options => 'MQTT-5-Optionen';

  @override
  String get mqttNoLocal => 'No Local (eigene Nachrichten nicht empfangen)';

  @override
  String get mqttRetainAsPublished => 'Retain As Published';

  @override
  String get mqttRetainHandling => 'Retain Handling';

  @override
  String get mqttRetainSend => 'Retained beim Abo senden';

  @override
  String get mqttRetainSendIfNew => 'nur bei neuem Abo';

  @override
  String get mqttRetainDont => 'nicht senden';

  @override
  String get mqttSubscriptionEnabled => 'aktiv';

  @override
  String get mqttDeleteSubscription => 'Abo entfernen';

  @override
  String get mqttFormat => 'Format';

  @override
  String get mqttPublishAction => 'Veröffentlichen';

  @override
  String mqttPublishTooltip(String shortcut) {
    return 'Veröffentlichen ($shortcut)';
  }

  @override
  String mqttPublished(String topic, int bytes) {
    return 'Auf „$topic“ veröffentlicht ($bytes Bytes)';
  }

  @override
  String get mqttClearRetained => 'Retained Message löschen';

  @override
  String mqttClearRetainedConfirm(String topic) {
    return 'Die Retained Message auf „$topic“ wird gelöscht (leere Payload mit Retain). Neue Abonnenten erhalten dann keinen gespeicherten Wert mehr.';
  }

  @override
  String mqttClearRetainedDone(String topic) {
    return 'Retained Message auf „$topic“ gelöscht';
  }

  @override
  String get mqttOverwriteTitle => 'Bestehendes Topic überschreiben?';

  @override
  String mqttOverwriteText(String topic) {
    return 'Auf „$topic“ wurden bereits Nachrichten empfangen. Wirklich veröffentlichen?';
  }

  @override
  String get mqttDontAskAgain => 'Nicht mehr fragen';

  @override
  String get mqttConfirmOverwrite => 'Vor Publish auf bekannte Topics fragen';

  @override
  String get mqttProperties => 'MQTT-5-Properties';

  @override
  String get mqttContentType => 'Content-Type';

  @override
  String get mqttResponseTopic => 'Response Topic';

  @override
  String get mqttCorrelationData => 'Correlation Data (Text)';

  @override
  String get mqttMessageExpiry => 'Message Expiry (s)';

  @override
  String get mqttUserProperties =>
      'User Properties (eine pro Zeile: name=wert)';

  @override
  String get mqttPropertiesV311Hint => 'Nur mit MQTT 5 verfügbar.';

  @override
  String get mqttTopicErrorEmpty => 'Topic darf nicht leer sein';

  @override
  String get mqttTopicErrorWildcard =>
      'Beim Veröffentlichen sind + und # nicht erlaubt';

  @override
  String get mqttTopicErrorMultiLevel =>
      '# nur als letzte Ebene allein erlaubt';

  @override
  String get mqttTopicErrorSingleLevel => '+ muss eine ganze Ebene sein';

  @override
  String get mqttTopicErrorNull => 'Nullzeichen nicht erlaubt';

  @override
  String get mqttTopicErrorTooLong => 'Topic zu lang (max. 65535 Bytes)';

  @override
  String mqttPayloadInvalid(String error) {
    return 'Payload ungültig: $error';
  }

  @override
  String get mqttRx => 'RX';

  @override
  String get mqttTx => 'TX';

  @override
  String get mqttDeleteProfileTitle => 'Broker-Profil löschen?';

  @override
  String mqttDeleteProfileText(String name) {
    return '„$name“ und die gespeicherten Zugangsdaten werden gelöscht.';
  }

  @override
  String mqttProfileCopy(String name) {
    return '$name (Kopie)';
  }

  @override
  String get mqttTabTree => 'Baum';

  @override
  String get mqttTabDetails => 'Details';

  @override
  String get mqttTreeSearch => 'Topics filtern';

  @override
  String mqttTreeSearchTooltip(String shortcut) {
    return 'Topics filtern ($shortcut)';
  }

  @override
  String get mqttFilterText => 'Text';

  @override
  String get mqttFilterWildcard => 'Wildcard (+/#)';

  @override
  String get mqttFilterRegex => 'Regex';

  @override
  String get mqttTreeShowSys => '\$SYS anzeigen';

  @override
  String get mqttTreeOnlyChanged => 'Nur geänderte';

  @override
  String get mqttTreeOnlyChangedTooltip =>
      'Topics ausblenden, deren Wert sich nie geändert hat';

  @override
  String get mqttTreeExpandAll => 'Alle aufklappen';

  @override
  String get mqttTreeCollapseAll => 'Alle zuklappen';

  @override
  String get mqttTreeClear => 'Baum leeren';

  @override
  String mqttTreeStats(int topics, int messages) {
    String _temp0 = intl.Intl.pluralLogic(
      topics,
      locale: localeName,
      other: '$topics Topics',
      one: '1 Topic',
    );
    String _temp1 = intl.Intl.pluralLogic(
      messages,
      locale: localeName,
      other: '$messages Nachrichten',
      one: '1 Nachricht',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get mqttTreeEmpty => 'Noch keine Topics empfangen.';

  @override
  String get mqttTreeNoMatch => 'Kein Topic passt zum Filter.';

  @override
  String mqttTreeFilterError(String error) {
    return 'Ungültiger Filter: $error';
  }

  @override
  String mqttNodeMessages(int count) {
    return '$count Nachr.';
  }

  @override
  String mqttNodeTopics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Topics',
      one: '1 Topic',
    );
    return '$_temp0';
  }

  @override
  String get mqttEmptyLevel => '(leer)';

  @override
  String get mqttRetainedBadge => 'Retained';

  @override
  String get mqttExpand => 'Aufklappen';

  @override
  String get mqttCollapse => 'Zuklappen';

  @override
  String get mqttDetailNone => 'Ein Topic im Baum auswählen.';

  @override
  String get mqttDetailBranch =>
      'Auf dieser Ebene selbst kam noch keine Nachricht.';

  @override
  String get mqttDetailLast => 'Letzte Nachricht';

  @override
  String get mqttDetailReceived => 'Empfangen';

  @override
  String get mqttDetailMessages => 'Nachrichten';

  @override
  String get mqttDetailSubtopics => 'Unter-Topics';

  @override
  String get mqttDetailSize => 'Größe';

  @override
  String get mqttDetailFlags => 'QoS / Flags';

  @override
  String get mqttDetailChanged => 'Zuletzt geändert';

  @override
  String mqttBytes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bytes',
      one: '1 Byte',
    );
    return '$_temp0';
  }

  @override
  String mqttTruncated(int count) {
    return '… gekürzt, $count Bytes insgesamt';
  }

  @override
  String mqttSecondsAgo(int value) {
    return 'vor $value s';
  }

  @override
  String mqttMinutesAgo(int value) {
    return 'vor $value min';
  }

  @override
  String mqttHoursAgo(int value) {
    return 'vor $value h';
  }

  @override
  String get mqttCopyTopic => 'Topic kopieren';

  @override
  String get mqttCopyPayload => 'Payload kopieren';

  @override
  String get mqttCopied => 'Kopiert';

  @override
  String get mqttUseForPublish => 'In Publish übernehmen';

  @override
  String mqttSubscribeSubtree(String filter) {
    return '$filter abonnieren';
  }

  @override
  String matrixNeedsBytes(int count) {
    return 'Benötigt $count Bytes';
  }

  @override
  String payloadDetected(String kind) {
    return 'Erkannt: $kind';
  }

  @override
  String get payloadKindEmpty => 'leer';

  @override
  String get payloadKindJson => 'JSON';

  @override
  String get payloadKindJsonBroken => 'JSON (fehlerhaft)';

  @override
  String get payloadKindXml => 'XML';

  @override
  String get payloadKindXmlBroken => 'XML (fehlerhaft)';

  @override
  String get payloadKindText => 'Text (UTF-8)';

  @override
  String get payloadKindBase64 => 'Base64';

  @override
  String get payloadKindBinary => 'Binär';

  @override
  String get payloadTabContent => 'Inhalt';

  @override
  String get payloadTabText => 'Text';

  @override
  String get payloadTabHex => 'Hex';

  @override
  String get payloadTabBinary => 'Binär';

  @override
  String get payloadTabMeta => 'Metadaten';

  @override
  String get payloadJsonTree => 'Baum';

  @override
  String get payloadJsonPretty => 'Formatiert';

  @override
  String get payloadJsonRaw => 'Roh';

  @override
  String payloadPathCopied(String path) {
    return '$path kopiert';
  }

  @override
  String get payloadCopyPathHint => 'Tippen kopiert den JSON-Pfad';

  @override
  String payloadSyntaxError(int line, int column, String message) {
    return 'Syntaxfehler in Zeile $line, Spalte $column: $message';
  }

  @override
  String payloadMoreItems(int count) {
    return '… $count weitere';
  }

  @override
  String get payloadEmpty => 'Leere Payload (0 Bytes).';

  @override
  String get payloadBinaryHint => 'Binärdaten – siehe Hex und Binär.';

  @override
  String payloadBase64Decoded(int count) {
    return 'Base64 dekodiert ($count Bytes)';
  }

  @override
  String get payloadInterpretDecoded => 'Dekodierte Bytes interpretieren';

  @override
  String get payloadEncoding => 'Zeichensatz';

  @override
  String get payloadShowMore => 'Mehr anzeigen';

  @override
  String payloadHexLines(int shown, int total) {
    return '$shown von $total Zeilen';
  }

  @override
  String get payloadOffset => 'Offset (Byte)';

  @override
  String payloadOffsetHint(int max) {
    return '0 … $max';
  }

  @override
  String payloadWindow(String bytes) {
    return 'Bytes ab Offset: $bytes';
  }

  @override
  String get payloadSource => 'Quelle';

  @override
  String get payloadSourcePayload => 'Payload';

  @override
  String get payloadSourceBase64 => 'Base64 dekodiert';

  @override
  String get payloadEightBit => '8 Bit';

  @override
  String get payloadBits => 'Bits (MSB zuerst)';

  @override
  String get payloadNoBytes => 'Keine Bytes ab diesem Offset.';

  @override
  String payloadValueCopied(String value) {
    return '$value kopiert';
  }

  @override
  String get payloadMetaNoV5 =>
      'Keine MQTT-5-Properties (MQTT 3.1.1 oder vom Absender nicht gesetzt).';

  @override
  String get payloadMetaContentType => 'Content-Type';

  @override
  String get payloadMetaFormat => 'Payload-Format';

  @override
  String get payloadMetaFormatUtf8 => 'UTF-8-Text (vom Absender angegeben)';

  @override
  String get payloadMetaExpiry => 'Message Expiry';

  @override
  String get payloadMetaAlias => 'Topic Alias';

  @override
  String get payloadMetaResponse => 'Response Topic';

  @override
  String get payloadMetaCorrelation => 'Correlation Data';

  @override
  String get payloadMetaUserProps => 'User Properties';

  @override
  String get payloadMetaSubIds => 'Subscription Identifier';

  @override
  String payloadMetaSeconds(int value) {
    return '$value s';
  }

  @override
  String get topicTabMessage => 'Nachricht';

  @override
  String get topicTabHistory => 'Verlauf';

  @override
  String get topicTabDiff => 'Vergleich';

  @override
  String get topicTabChart => 'Graph';

  @override
  String get topicTabStats => 'Statistik';

  @override
  String historyCount(int count, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Nachrichten',
      one: '1 Nachricht',
    );
    return '$_temp0 gespeichert (max. $max)';
  }

  @override
  String get historyEmpty => 'Noch kein Verlauf.';

  @override
  String historyViewing(String time) {
    return 'Ältere Nachricht von $time';
  }

  @override
  String get historyShowLatest => 'Neueste anzeigen';

  @override
  String get historyLatest => 'neueste';

  @override
  String get diffNeedTwo =>
      'Zum Vergleichen werden mindestens zwei Nachrichten im Verlauf benötigt.';

  @override
  String get diffOld => 'Alt';

  @override
  String get diffNew => 'Neu';

  @override
  String get diffSwap => 'Tauschen';

  @override
  String get diffNoChanges => 'Keine Unterschiede.';

  @override
  String diffModeJson(int count) {
    return 'JSON-Vergleich, $count Änderungen';
  }

  @override
  String get diffModeText => 'Text-Vergleich (zeilenweise)';

  @override
  String diffModeBytes(int count) {
    return 'Byte-Vergleich, $count abweichende Bereiche';
  }

  @override
  String get diffAdded => 'hinzugefügt';

  @override
  String get diffRemoved => 'entfernt';

  @override
  String get diffChanged => 'geändert';

  @override
  String diffByteRun(int offset, String before, String after) {
    return 'Offset $offset: $before → $after';
  }

  @override
  String get chartNoField =>
      'Wert für den Graph wählen: im JSON-Baum das Graph-Symbol neben einer Zahl, in der Binär-Ansicht „Im Graph anzeigen“. Zahlen als Payload werden automatisch dargestellt.';

  @override
  String chartField(String field) {
    return 'Wert: $field';
  }

  @override
  String get chartClear => 'Auswahl aufheben';

  @override
  String get chartNoPoints =>
      'Im Verlauf hat noch keine Nachricht einen Zahlenwert an dieser Stelle.';

  @override
  String chartSummary(
    int count,
    String min,
    String max,
    String avg,
    String last,
  ) {
    return '$count Punkte · min $min · max $max · Ø $avg · zuletzt $last';
  }

  @override
  String get chartShowJson => 'Im Graph anzeigen';

  @override
  String get chartShowBinary => 'Im Graph anzeigen';

  @override
  String chartBinaryHint(int offset) {
    return 'Datentyp und Byte-Order für den Verlauf ab Offset $offset';
  }

  @override
  String get statsMessages => 'Nachrichten';

  @override
  String get statsFirst => 'Erste Nachricht';

  @override
  String get statsLast => 'Letzte Nachricht';

  @override
  String get statsSinceLast => 'Seit letzter Nachricht';

  @override
  String get statsRateOverall => 'Rate gesamt';

  @override
  String get statsRateRecent => 'Rate letzte 60 s';

  @override
  String statsRateValue(String value) {
    return '$value/s';
  }

  @override
  String statsRateMinimum(String value) {
    return 'mind. $value/s';
  }

  @override
  String get statsAvgSize => 'Ø Payload-Größe';

  @override
  String get statsMinMaxSize => 'Min / Max';

  @override
  String get statsHistory => 'Im Verlauf';

  @override
  String get statsHistoryMemory => 'Verlauf gesamt';

  @override
  String statsHistoryMemoryValue(int count, String size) {
    return '$count Nachrichten, $size';
  }

  @override
  String get settingsMqtt => 'MQTT';

  @override
  String get settingsMqttHistory => 'Verlauf pro Topic';

  @override
  String get settingsMqttHistoryHint =>
      'So viele Nachrichten je Topic stehen für Verlauf, Vergleich und Graph bereit.';

  @override
  String get settingsMqttBudget => 'Speicherlimit für den Verlauf';

  @override
  String get settingsMqttBudgetHint =>
      'Wird es erreicht, fallen die ältesten Nachrichten aller Topics zuerst weg; der letzte Wert jedes Topics bleibt.';

  @override
  String settingsMegabytes(int value) {
    return '$value MB';
  }

  @override
  String get monitorTopicFilter => 'Topic-Filter';

  @override
  String get monitorPayloadFilter => 'Payload enthält';

  @override
  String get monitorPayloadFilterHint => 'Text oder Hex, z. B. 0A 1B';

  @override
  String get monitorRx => 'Empfangen';

  @override
  String get monitorTx => 'Gesendet';

  @override
  String get monitorEvents => 'Ereignisse';

  @override
  String get monitorOnlyRetained => 'Nur Retained';

  @override
  String get monitorOnlyErrors => 'Nur Fehler';

  @override
  String get monitorNoMatch => 'Kein Eintrag passt zum Filter.';

  @override
  String get monitorBufferSize => 'Puffergröße';

  @override
  String get monitorExport => 'Exportieren';

  @override
  String get monitorExportText => 'Als Text';

  @override
  String get monitorExportCsv => 'Als CSV';

  @override
  String get monitorExportJsonl => 'Als JSON Lines (Aufzeichnung)';

  @override
  String get monitorExportEmpty => 'Nichts zu exportieren.';

  @override
  String monitorMessageTitle(String direction, String topic) {
    return '$direction · $topic';
  }

  @override
  String eventConnecting(String detail) {
    return 'Verbinde mit $detail';
  }

  @override
  String eventConnected(String detail) {
    return 'Verbunden ($detail)';
  }

  @override
  String eventConnectFailed(String detail) {
    return 'Verbindung fehlgeschlagen: $detail';
  }

  @override
  String eventSubscribe(String detail) {
    return 'Abonniert: $detail';
  }

  @override
  String eventUnsubscribe(String detail) {
    return 'Abo beendet: $detail';
  }

  @override
  String get eventDisconnect => 'Getrennt';

  @override
  String eventConnectionLost(String detail) {
    return 'Verbindung verloren: $detail';
  }

  @override
  String eventReconnect(String detail) {
    return 'Neuer Versuch geplant: $detail';
  }

  @override
  String eventPublishFailed(String detail) {
    return 'Publish fehlgeschlagen: $detail';
  }

  @override
  String eventReplayStarted(String detail) {
    return 'Replay gestartet: $detail';
  }

  @override
  String eventReplayFinished(String detail) {
    return 'Replay beendet: $detail';
  }

  @override
  String get replayTitle => 'Aufzeichnung abspielen';

  @override
  String get replayLoad => 'Datei laden (JSON Lines)';

  @override
  String replayLoaded(String name, int count, int topics, String duration) {
    return '$name: $count Nachrichten, $topics Topics, Dauer $duration';
  }

  @override
  String replaySkipped(int count) {
    return '$count Zeilen übersprungen (Ereignisse oder unlesbar)';
  }

  @override
  String get replayNoMessages => 'Die Datei enthält keine Nachrichten.';

  @override
  String get replaySpeed => 'Geschwindigkeit';

  @override
  String get replayNoPauses => 'ohne Pausen';

  @override
  String get replayCapPauses => 'Pausen über 10 s auf 10 s kürzen';

  @override
  String get replayPrefix => 'Topic-Präfix';

  @override
  String get replayPrefixHint =>
      'vor jedes Topic, damit Live-Daten nicht überschrieben werden';

  @override
  String get replayKeepRetain => 'Retain-Flags beibehalten';

  @override
  String get replayKeepRetainHint =>
      'Aus: es bleiben keine Retained-Werte vom Replay zurück';

  @override
  String get replayOnlyReceived => 'Nur empfangene Nachrichten';

  @override
  String get replayStart => 'Abspielen';

  @override
  String replayConfirm(int count, String broker) {
    return '$count Nachrichten werden an den verbundenen Broker „$broker“ gesendet. Fortfahren?';
  }

  @override
  String replayRunning(int done, int total) {
    return 'Replay: $done von $total';
  }

  @override
  String get replayStop => 'Stoppen';

  @override
  String get replayNeedsConnection =>
      'Für ein Replay mit einem Broker verbinden.';

  @override
  String get toolsBrokerInfo => 'Broker-Info';

  @override
  String get toolsTopicTester => 'Topic-Tester';

  @override
  String get toolsPayloadConverter => 'Payload-Konverter';

  @override
  String get brokerInfoEmpty =>
      'Keine \$SYS-Daten. Nicht jeder Broker veröffentlicht sie, und sie kommen nur mit einem Abo auf \$SYS/# an.';

  @override
  String get brokerInfoSubscribe => '\$SYS/# abonnieren';

  @override
  String get brokerVersion => 'Version';

  @override
  String get brokerUptime => 'Laufzeit';

  @override
  String get brokerClientsConnected => 'Clients verbunden';

  @override
  String get brokerClientsTotal => 'Clients gesamt';

  @override
  String get brokerClientsMaximum => 'Clients maximal';

  @override
  String get brokerSubscriptions => 'Abonnements';

  @override
  String get brokerRetained => 'Retained Messages';

  @override
  String get brokerMessagesReceived => 'Nachrichten empfangen';

  @override
  String get brokerMessagesSent => 'Nachrichten gesendet';

  @override
  String get brokerLoadReceived => 'Empfangen / min (Ø 1 min)';

  @override
  String get brokerLoadSent => 'Gesendet / min (Ø 1 min)';

  @override
  String get brokerBytesReceived => 'Bytes empfangen';

  @override
  String get brokerBytesSent => 'Bytes gesendet';

  @override
  String get brokerHeap => 'Speicher (Heap)';

  @override
  String get testerFilter => 'Topic-Filter';

  @override
  String get testerTopics => 'Topics (eins pro Zeile)';

  @override
  String get testerMatch => 'passt';

  @override
  String testerMatchMulti(int level) {
    return 'passt (# ab Ebene $level deckt den Rest ab)';
  }

  @override
  String testerLevelMismatch(int level) {
    return 'passt nicht: Ebene $level unterscheidet sich';
  }

  @override
  String testerTooShort(int level) {
    return 'passt nicht: Topic endet vor Ebene $level des Filters';
  }

  @override
  String get testerTooLong =>
      'passt nicht: Topic hat mehr Ebenen als der Filter';

  @override
  String get testerDollar =>
      'passt nicht: Topics mit \$ am Anfang werden von + oder # an erster Stelle nie erfasst';

  @override
  String testerInvalidFilter(String error) {
    return 'Filter ungültig: $error';
  }

  @override
  String testerInvalidTopic(String error) {
    return 'Topic ungültig: $error';
  }

  @override
  String get testerHelp =>
      '+ steht für genau eine Ebene, # (nur am Ende) für beliebig viele einschließlich der übergeordneten Ebene.';

  @override
  String get converterInput => 'Eingabe';

  @override
  String get converterDecimal => 'Dezimal';

  @override
  String get converterCArray => 'C-Array';

  @override
  String get converterInvalidUtf8 => 'kein gültiges UTF-8';

  @override
  String get converterLength => 'Länge';

  @override
  String converterInvalid(String error) {
    return 'Ungültige Eingabe: $error';
  }

  @override
  String converterCopied(String label) {
    return '$label kopiert';
  }

  @override
  String get settingsMqttMonitor => 'Monitor-Puffer';

  @override
  String get settingsMqttMonitorHint =>
      'So viele Nachrichten und Ereignisse hält der Monitor; ältere fallen weg.';

  @override
  String mqttMonitorCount(int shown, int total, int capacity) {
    return '$shown von $total Einträgen · Puffer $capacity';
  }

  @override
  String get mqttMonitorEmpty => 'Noch keine Einträge.';

  @override
  String get mqttTemplates => 'Vorlagen';

  @override
  String get mqttTemplatesEmpty => 'Noch keine Vorlagen.';

  @override
  String get mqttTemplateSave => 'Als Vorlage speichern';

  @override
  String get mqttTemplateName => 'Name der Vorlage';

  @override
  String mqttTemplateSaved(String name) {
    return 'Vorlage „$name“ gespeichert';
  }

  @override
  String mqttTemplateLoaded(String name) {
    return 'Vorlage „$name“ geladen';
  }

  @override
  String mqttTemplateDeleted(String name) {
    return 'Vorlage „$name“ gelöscht';
  }

  @override
  String get mqttTemplateReplaceHint =>
      'Eine Vorlage mit gleichem Namen wird ersetzt.';

  @override
  String netPortConnectMqtt(int port) {
    return 'MQTT-Profil anlegen und verbinden (Port $port)';
  }

  @override
  String netMqttProfileCreated(String name) {
    return 'MQTT-Profil „$name“ angelegt';
  }

  @override
  String get shortcutModule => 'Modul wechseln (Modbus ↔ MQTT)';

  @override
  String get shortcutMqttFilter => 'MQTT: Topic-Baum bzw. Monitor filtern';

  @override
  String get shortcutMqttClear => 'MQTT: Monitor leeren';

  @override
  String get shortcutMqttPublish =>
      'MQTT: veröffentlichen (im Publish-Bereich)';
}
