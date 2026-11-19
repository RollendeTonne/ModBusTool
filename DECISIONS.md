# Entscheidungen & Annahmen

Kurzprotokoll der Architektur- und Produktentscheidungen. Neueste unten.

## M1 – Projekt-Setup

| # | Entscheidung | Begründung |
|---|---|---|
| D1 | **Flutter 3.50 / Dart 3.14**, Material über `package:material_ui` | Ab Flutter 3.47 ist `package:flutter/material.dart` deprecated; Material liegt im separaten Package `material_ui`. |
| D2 | Neue Dart-3.14-Konstruktorsyntax (`const new(...)`, `factory forPlatform(...)`) | Wird von `very_good_analysis` 11 erzwungen (`unnecessary_type_name_in_constructor`). |
| D3 | **Riverpod 3 ohne Codegenerator** (`Notifier`/`Provider` von Hand) | Abweichung vom Plan: Der Generator spart bei Riverpod 3 kaum Code, kostet aber `build_runner`-Läufe. `build_runner` kommt erst mit drift (M4) dazu. |
| D4 | `go_router` mit `StatefulShellRoute.indexedStack` | Jeder Tab behält seinen Zustand (Eingaben, Scroll-Position, Live-Log), wenn man wechselt. |
| D5 | Responsives Layout nach M3-Fenstergrößen: < 600 px Bottom-Navigation, 600–1199 px kompakte Rail, ≥ 1200 px ausgeklappte Rail | Material-3-Standard-Breakpoints. |
| D6 | Einstellungen über eine `KeyValueStore`-Abstraktion auf `SharedPreferencesWithCache` | Ohne Plattformkanal testbar (In-Memory-Implementierung). Unbekannte gespeicherte Werte fallen auf die Defaults zurück. |
| D7 | Standardsprache = Systemsprache. Fallback **Englisch**, wenn das System weder Deutsch noch Englisch ist | `supportedLocales` beginnt bewusst mit `en`. |
| D8 | Monospace-Schrift **nicht gebündelt**, stattdessen Fallback-Kette Menlo → SF Mono → Consolas → DejaVu Sans Mono → … → `monospace` | Die App muss offline funktionieren (Inbetriebnahme vor Ort) und jede Plattform hat eine brauchbare Mono-Schrift. `google_fonts` würde zur Laufzeit nachladen. |
| D9 | Semantische Farben als `ThemeExtension` (`AppColors`: changed, implausible, plausible, tx, rx, success, warning) für hell und dunkel getrennt | Einheitliche Farbcodierung in allen Ansichten. Status wird nie nur über Farbe vermittelt (immer zusätzlich Icon oder Text). |
| D10 | **Capability-Matrix**: Desktop = TCP + Serial + lokaler TCP-Server. Android = TCP + Serial (USB-OTG), kein Server. iOS = nur TCP. Web = nichts | Web wird nicht ausgeliefert (keine Raw-Sockets). Die Matrix steckt im `platformCapabilitiesProvider` und lässt sich in Tests überschreiben. |
| D11 | Adressierung standardmäßig **1-basiert** (4xxxx/3xxxx) | Entspricht der Notation der meisten Gerätehandbücher. Umschaltbar, der aktive Modus ist immer sichtbar. |
| D12 | Schreibbestätigung standardmäßig **an** | Schutz vor versehentlichen Schreibzugriffen auf Anlagen. |
| D13 | Platzhalter-Bundle-ID `de.example.modbusExplorer` | Vor einer Veröffentlichung ersetzen. |
| D14 | macOS-Entitlements: `network.client`, `network.server` (Simulator), `device.serial` (RTU) | Die Sandbox bleibt aktiv. |

## M2 – Konvertierungs-Engine

| # | Entscheidung | Begründung |
|---|---|---|
| D15 | Byte-Reihenfolgen als **Permutation** über ein Buchstabenmuster. `A` ist das High-Byte des ersten Registers, das Muster nennt die Bytes des Werts vom höchstwertigen an (`CDAB` = Wert `C D A B` big-endian gelesen) | Eine Implementierung deckt 2, 4 und 8 Byte ab. Beliebige Muster (`EFGHABCD`) lassen sich parsen, z. B. für den Hex-Rechner. |
| D16 | Matrix-Spalten = 4 **Familien** aus zwei unabhängigen Vertauschungen (Wortreihenfolge × Bytes im Register): ABCD, BADC, CDAB, DCBA. Für 64 Bit entsprechen sie ABCDEFGH, BADCFEHG, GHEFCDAB, HGFEDCBA | Die Spalten passen über alle Breiten zusammen. Bei 16 Bit fallen CDAB/DCBA mit AB/BA zusammen und werden als `isDuplicate` markiert, damit die UI sie abschwächen kann. EFGHABCD und CDABGHEF gibt es zusätzlich als `ByteOrder.extended64`. |
| D17 | Spaltennamen sind die **Muster**, nicht „Little Endian Word Swap“ o. ä. | Hersteller benennen dieselbe Reihenfolge unterschiedlich. Das Muster ist eindeutig. |
| D18 | Ganzzahlen intern als `BigInt` | UINT64 bleibt exakt; Dart-`int` ist vorzeichenbehaftet 64 Bit (auf Web nur 53 Bit). |
| D19 | Denormal-Erkennung über die **Rohbits** | Ein float32-Subnormal ist nach der Umwandlung in double normal und wäre am Wert nicht mehr erkennbar. |
| D20 | FLOAT32 wird als **kürzeste Dezimalzahl** angezeigt, die exakt auf denselben float32 zurückführt (`230.1` statt `230.10000610351562`) | Lesbarkeit. Bei Bedarf zeigt die UI zusätzlich die Hex-Bytes. |
| D21 | Plausibilitäts-Heuristik, Stufen implausibel / neutral / plausibel: **implausibel** sind NaN, Inf, Denormal, \|x\| > 1e12 oder < 1e-9, Ganzzahlen > 1e12, Zeitstempel außerhalb 2000–2100, ungültiges BCD, Steuerzeichen. **Plausibel** sind Floats zwischen 1e-3 und 1e7 mit höchstens 4 Nachkommastellen (Rundtrip-Test), 32/64-Bit-Ganzzahlen bis 1e7 und lesbarer Text. 16-Bit-Ganzzahlen sind immer neutral | Falsch gedrehte Bytes landen fast immer bei extremen Größenordnungen oder „voller“ Mantisse. 16 Bit gibt kein Signal her. Die Schwellen stehen in `PlausibilityThresholds`. |
| D22 | UNIX64 = **Millisekunden** (vorzeichenbehaftet), UNIX32 = Sekunden (vorzeichenlos) | 64-Bit-Sekunden-Zeitstempel sind selten, weil Sekunden bis 2106 in 32 Bit passen. ms ist die gängige 64-Bit-Variante (Java/JS). |
| D23 | Skalierung `Wert × Faktor + Offset` wird in `double` gerechnet. Ohne feste Nachkommastellen wird auf 15 signifikante Stellen gerundet | Unterdrückt Binärrauschen (`123.40000000000001`). Skalierte Werte über 2^53 verlieren Präzision; für Anzeigezwecke akzeptabel. |
| D24 | Text: ASCII (Standard), Latin-1, UTF-8; optional Bytes je Register tauschen; abschließende NUL-Bytes werden entfernt | Häufigste Varianten bei Geräte-Strings (Seriennummer, Typ). |
| D25 | **Adresseingabe im 1-basierten Modus**: 5-/6-stellige Zahl mit der Präfixziffer der aktuellen Tabelle = Modicon-Notation (`40001` → 0). Alles andere = schlichte 1-basierte Registernummer (`1` → 0). Hex (`0x…`) ist immer eine schlichte Nummer | Beide Schreibweisen aus Handbüchern funktionieren. Die verbleibende Mehrdeutigkeit (z. B. `40001` bei Input-Registern = Register 40001) ist dokumentiert und getestet. Anzeige: 5 Stellen bis Register 9999, sonst 6 (`465536`). |

## M3 – Transport, Protokoll, Simulator

| # | Entscheidung | Begründung |
|---|---|---|
| D26 | **Eigene Protokollschicht** statt `modbus_client*` (pub.dev-Stand 19.11.2026: `modbus_client` 1.4.5, gepflegt) | Der Monitor braucht jedes Rohframe (TX/RX) mit Zeitstempel, auch kaputte oder verspätete Frames, CRC-Status und Zuordnung zur Transaktion. Die Packages kapseln genau das weg. RTU over TCP, Fault-Injection und ein Simulator mit demselben Codec gehen nur mit eigener Schicht. Der Umfang ist überschaubar (~1.500 Zeilen) und vollständig getestet. |
| D27 | Schichten: `ByteChannel` (Socket / Serial / In-Memory) → `ModbusFraming` (MBAP oder RTU, inkl. Frame-Assembler) → `ModbusClient` (Queue, Retries, Timeouts) | Jede Kombination ist möglich, z. B. RTU-Framing über Socket = RTU over TCP. Tests laufen ohne Hardware über In-Memory-Kanäle. |
| D28 | Requests strikt **sequenziell**, auch bei TCP | RTU verlangt es. Viele TCP-Geräte und -Gateways vertragen kein Pipelining. Für ein Debug-Werkzeug ist die Nachvollziehbarkeit wichtiger als der Durchsatz. |
| D29 | **Retries** bei Timeout, CRC-Fehler und fehlerhafter Antwort. Exception-Antworten werden **nicht** wiederholt | Das Gerät hat geantwortet, eine Wiederholung ändert nichts. CRC-Fehler führen sofort zum nächsten Versuch statt erst nach dem Timeout. |
| D30 | TCP: Antworten werden über die **Transaction-ID** zugeordnet. Verspätete Antworten erscheinen im Log als „unexpected“ und werden verworfen | Verhindert, dass nach einem Timeout die Antwort des vorigen Requests als aktuelle gilt. |
| D31 | RTU: Frame-Länge aus FC und Byte-Count statt reinem t3.5-Timing. Rest-Bytes werden vor jedem Request und nach 100 ms Stille verworfen (und geloggt). Vor dem Senden wird mindestens t3.5 gewartet (ab 19200 Baud fest 1,75 ms) | USB-Seriell-Adapter puffern (FTDI-Latenz bis 16 ms), deshalb ist Timing allein unzuverlässig. Bei RTU over TCP pauschal 5 ms. |
| D32 | RTU-Broadcast (Unit 0) nur für Schreibzugriffe, ohne Antwort (`NoResponseExpected`). Bei TCP ist Unit 0 eine normale Adresse | Entspricht der Spezifikation. Viele TCP-Geräte interpretieren 0/255 als „dieses Gerät“, der Simulator ebenfalls. |
| D33 | Modbus TCP hat **keine Integritätsprüfung** auf Modbus-Ebene | Durch einen Test belegt: Verfälschte Nutzdaten kommen bei TCP unbemerkt an, bei RTU greift die CRC. Gehört so auch in die Doku. |
| D34 | Serial-Standardwerte **19200 8E1** (Modbus-Spec). RS485-Richtungsumschaltung wird nicht per Software gesteuert; RTS/DTR können auf festen Pegel gesetzt werden | Software-Umschaltung aus Dart ist zeitlich nicht präzise genug. Gängige USB-RS485-Adapter schalten automatisch um. |
| D35 | macOS-Serial über `flutter_libserialport`. Es braucht **CocoaPods**, weil es noch kein SPM unterstützt | CocoaPods 1.17 läuft auf dieser Maschine mit dem portablen Ruby von Homebrew (System-Ruby 2.6 ist zu alt, `brew install cocoapods` hätte LLVM aus dem Quellcode gebaut). Startskript: `~/.local/bin/pod`. Für den Pod-Build sind zusätzlich `automake` und `libtool` nötig. |
| D36 | Android-Serial über `usb_serial` (FTDI, CH34x, CP210x, PL2303, CDC) | Implementiert und analysiert, aber **noch nicht gebaut**, weil die Android cmdline-tools fehlen. |
| D37 | **Simulator**: Geräte-Bank (Unit 1 = Demo-Gerät, Unit 2 = Zähler) teilen sich alle Simulator-Verbindungen, Schreibzugriffe bleiben also erhalten. Unbekannte Unit-IDs antworten nicht (realistisch für den Slave-Scan). Register 1000–1009 liefern Exception 04. Adressen ab 2000 liefern Exception 02 | Damit lassen sich alle Fehlerpfade ohne Hardware vorführen. |
| D38 | Simulator-TCP-Server standardmäßig auf **127.0.0.1:1502** | Port 502 braucht unter macOS und Linux Root-Rechte. Auf Wunsch auch im Netzwerk erreichbar. |
| D39 | Fault-Injection: Latenz, Drop- und Korruptionswahrscheinlichkeit (Demo) sowie deterministische Zähler `dropNext`/`corruptNext` (Tests) | Reproduzierbare Tests für Timeout und Retry. |
| D40 | Exception-Texte (01–08, 0A, 0B) sind lokalisiert und nennen die **typische Ursache** (z. B. bei 02 den Hinweis auf 0- oder 1-basierte Adressierung) | Hilft bei der Inbetriebnahme mehr als der reine Spezifikationsname. |

## M4 – Verbindungsverwaltung, Lesen und Schreiben

| # | Entscheidung | Begründung |
|---|---|---|
| D41 | **Abweichung vom Plan:** Profile (und künftig Register-Maps) als **versionierte JSON-Dateien** im App-Support-Verzeichnis, nicht drift/SQLite | Die Datenmengen sind klein (Dutzende Profile, Maps mit einigen hundert Einträgen). Für Import/Export (M7) ist dasselbe Format nutzbar, es braucht keinen Codegenerator und keine native SQLite-Bibliothek; nach den CocoaPods-Erfahrungen in M3 zählt jede vermiedene native Abhängigkeit. Geschrieben wird atomar (tmp + rename). Defekte Einträge werden beim Laden übersprungen statt alles zu verwerfen. |
| D42 | Beim ersten Start wird ein Profil „Simulator (Demo)“ angelegt. Eine bewusst geleerte Liste wird nicht erneut befüllt | Die App funktioniert sofort ohne Hardware. |
| D43 | Verbindungszustand als Zustandsautomat (Getrennt → Verbinde → Verbunden / Fehlgeschlagen). Eine Generationsnummer verwirft veraltete asynchrone Ergebnisse. **Auto-Reconnect** pro Profil, Backoff 1 s, 2 s, 5 s, dann alle 10 s, bis „Trennen“ | Robust bei Kabelabzug und Geräteneustart, ohne Endlosschleifen beim manuellen Trennen. |
| D44 | **Schreibschutz in zwei Stufen:** Schalter „Schreiben freigeben“ pro Sitzung (nach Neustart wieder gesperrt) und Bestätigungsdialog mit genauer Beschreibung (FC, Adresse, Werte, Unit). Der Dialog lässt sich in den Einstellungen abschalten | Schutz vor versehentlichen Schreibzugriffen auf laufende Anlagen. |
| D45 | Polling misst das Intervall von Start zu Start. Läuft eine Anfrage länger als das Intervall, startet die nächste direkt danach statt sich zu stapeln | Die Busauslastung bleibt kontrollierbar. |
| D46 | Änderungsmarkierung: Geänderte Werte blinken 1,5 s und blenden aus. Die Zeitstempel liegen im Snapshot, sodass die Markierung auch nach dem Scrollen passt | Spezifikation „kurz hervorheben“. |
| D47 | Registerseite als durchgehend scrollende Sliver-Ansicht mit fixiertem Tabellenkopf und virtualisierten Zeilen | Auf dem Handy nimmt die Abfrageleiste viel Höhe ein. Bis 2000 Coils bleiben flüssig. |
| D48 | Fehlermeldungen = lokalisierte Kategorie + Handlungshinweis, dazu aufklappbare technische Details (englisch, vom Transport) | Verständlich für Inbetriebnehmer, trotzdem alle Infos für die Fehlersuche. |
| D49 | Port-Suche mit 5-s-Timeout. USB-Adapter (Vendor-ID vorhanden) stehen oben und werden vorausgewählt | Auf macOS liefert libserialport auch Bluetooth- und Debug-Ports. Ein hängender Treiber blockiert den Editor nicht. |
| D50 | Tastenkürzel: Strg/⌘+R oder F5 = Lesen, Strg/⌘+Enter = Dialog absenden bzw. Profil speichern | Desktop-Bedienung wie gefordert, Rest in M7. |
| D51 | Einzelregister optional als **FC16** senden | Manche Geräte unterstützen kein FC06. |
| D52 | Integrationstests in der echten Desktop-App: `flutter test integration_test -d macos --no-dds` | Prüft FFI (libserialport), Sandbox-Netzwerk und Dateipfade. `--no-dds` ist nötig, weil der Debug-Dienst hier nicht startet. |

## M5 – Interpretations-Matrix und Register-Map

| # | Entscheidung | Begründung |
|---|---|---|
| D53 | Die Matrix beginnt am **ersten markierten Register** und nimmt die folgenden Register dazu, bis 32/64-Bit-Typen gefüllt sind (mindestens 4, sofern gelesen). Text nutzt genau die Markierung | Ein Klick auf ein Register genügt, um alle Breiten zu sehen. Für Strings bestimmt die Markierung die Länge. |
| D54 | Skalierung in der Interpretationsansicht gilt sitzungsweit für alle numerischen Zellen. Jeder Map-Eintrag hat zusätzlich seine **eigene** Skalierung (Faktor, Offset, Nachkommastellen) | Beim Erkunden reicht ein globaler Faktor. „Pro Interpretation“ wird über die gespeicherten Einträge erfüllt. |
| D55 | Plausibilitäts-Darstellung: plausibel = fett, grün hinterlegt (abschaltbar); unplausibel = grau-kursiv; doppelte 16-Bit-Spalten abgeschwächt. Der Tooltip nennt Muster, umgeordnete Bytes und den Grund | Status wird nicht nur über Farbe vermittelt. Screenreader bekommen Wert und Grund als Label. |
| D56 | Bedienung der Zellen: Tippen kopiert den Wert; Rechtsklick oder langes Drücken öffnet das Menü „Kopieren / Zur Register-Map hinzufügen“. Kopieren der ganzen Matrix als TSV (für Tabellenkalkulationen) oder CSV | Schnell für den häufigsten Fall. Das Kontextmenü funktioniert auch auf Touch-Geräten. |
| D57 | Register-Map **pro Verbindungsprofil** in `register_maps.json`. Formate: Zahl (Datentyp + Byte-Reihenfolge), Text (Länge, Byte-Tausch, Kodierung), Bit (Coil/Diskreter Eingang oder einzelnes Bit eines Registers) | Maps gehören zu einem Gerät. Einzelne Bits in Statuswörtern sind in der Praxis häufig. |
| D58 | Map lesen: Bereiche mit Lücken ≤ 8 werden zu Blöcken zusammengefasst (Grenzen 125 Register / 2000 Bits). Ein fehlerhafter Block (z. B. Exception 02) markiert nur seine eigenen Einträge als fehlerhaft | Wenige Requests, und ein falsch eingetragenes Register legt nicht die ganze Ansicht lahm. |
| D59 | CSV: Trennzeichen `;`, Dezimalpunkt im Export, Komma wird beim Import akzeptiert, Adressen 0-basiert. Der Codec (JSON/CSV) ist fertig und getestet; die Dateiauswahl für Import/Export kommt in M7 | `;` öffnet sich in deutschem Excel korrekt. 0-basierte Adressen machen Dateien unabhängig von der Anzeigeeinstellung. |
| D60 | Layout: ab 1100 px Breite und 600 px Höhe stehen Rohwerte und Interpretation nebeneinander, getrennt durch einen **eigenen** ziehbaren Teiler (Maus, Touch, Pfeiltasten, Screenreader-Slider). Darunter öffnet ein Tipp auf eine Zeile ein Bottom-Sheet | Kein zusätzliches Package für ~100 Zeilen Code. Auf dem Handy bleibt die Tabelle voll lesbar. |
| D61 | Ist eine Map vorhanden, hat die Label-Spalte in der Rohwert-Tabelle Vorrang vor den Spalten Signed und Binär | Die Interpretationsansicht zeigt Signed/Binär ohnehin. Labels helfen bei der Orientierung mehr. |
| D62 | Werte in der Rohwert-Tabelle sind normaler Text, nicht markierbar. Ein Tipp wählt die Zeile aus, Umschalt+Tipp einen Bereich | Markierbarer Text hat Taps abgefangen, die Zeilenauswahl funktionierte dann nicht. Kopieren geht über die Interpretation. |
| D63 | Snackbars ersetzen die aktuelle Meldung, statt sich anzustellen | Nach mehreren schnellen Kopieraktionen kamen Meldungen sonst sekundenlang verspätet. |
| D64 | **Bit-Ansicht** in der Interpretationsansicht: 16 Bits des markierten Registers als Chips. Bei freigegebenem Schreiben schaltet ein Klick das Bit (FC06, mit Bestätigung) | Erfüllt „Bits als anklickbare Toggles für Write“ ohne eigene dritte Ansicht. |
