# Modbus Explorer

Plattformübergreifendes Debugging-Werkzeug für **Modbus TCP**, **Modbus RTU**
(seriell) und **RTU über TCP**, gebaut mit Flutter. Kernidee: Rohe
Registerwerte werden gleichzeitig in **allen Datentypen und
Byte-/Wortreihenfolgen** angezeigt, plausible Interpretationen sind
hervorgehoben. So sieht man sofort, wie ein Gerät seine Werte ablegt.

> Screenshots folgen. Platzhalter:
> `docs/screenshots/registers.png` (Rohwerte + Interpretations-Matrix),
> `docs/screenshots/monitor.png` (Telegramm-Monitor mit Frame-Zerlegung),
> `docs/screenshots/mobile.png` (Handy-Layout).

## Funktionen

**Verbindungen**
- Profile für TCP, RTU, RTU über TCP und einen eingebauten Simulator: anlegen,
  bearbeiten, duplizieren, löschen, als Datei exportieren und importieren.
- RTU: automatische Port-Erkennung (USB-Adapter zuerst), Baudrate inkl.
  eigener Werte, Datenbits, Parität, Stoppbits, RTS/DTR-Pegel, Pause zwischen
  Frames (Standard: t3.5 aus der Baudrate).
- Unit-ID, Timeout, Wiederholungen; automatisches Neuverbinden mit Backoff.
- Verständliche, lokalisierte Fehlermeldungen mit Handlungshinweis
  (z. B. „Verbindung abgelehnt – Port prüfen“).

**Register lesen und schreiben**
- FC01–06, 15, 16, 22 (Mask Write), 23 (Read/Write), 43/14 (Device ID).
- Adressierung 0-basiert (Protokoll) oder 1-basiert (4xxxx/3xxxx), die aktive
  Variante ist immer sichtbar.
- Einmal lesen oder pollen; geänderte Werte blinken kurz auf.
- Schreiben mit zweistufigem Schutz: „Schreiben freigeben“ pro Sitzung und
  Bestätigungsdialog mit genauer Beschreibung (abschaltbar).
- Modbus-Exceptions 01–0B im Klartext mit typischer Ursache.

**Interpretation (Herzstück)**
- Matrix Datentyp × Byte-Reihenfolge: INT/UINT 16/32/64, FLOAT32/64, BCD,
  Unix-Zeit 32 Bit (s) / 64 Bit (ms) in ABCD, BADC, CDAB, DCBA
  (64 Bit: ABCDEFGH, BADCFEHG, GHEFCDAB, HGFEDCBA).
- Plausibilitäts-Heuristik (NaN, Inf, Denormal, extreme Größen, Zeitstempel
  außerhalb 2000–2100 …), abschaltbar.
- Aufschlüsselung des Registers (Hex, Binär, Signed/Unsigned, High/Low-Byte,
  ASCII), 16 Bits zum Anklicken (auch zum Schreiben), Text mit Byte-Tausch und
  Kodierung, Skalierung (Faktor, Offset, Nachkommastellen).
- Werte per Klick kopieren, Matrix als TSV/CSV kopieren.

**Register-Map**
- Pro Profil: Label, Einheit, Beschreibung, Datentyp/Byte-Reihenfolge,
  Text- oder Bit-Format, eigene Skalierung.
- Live-Werte mit möglichst wenigen Requests, Suche, Sortierung, Labels in der
  Rohwert-Tabelle; Import und Export als JSON oder CSV.

**Monitor**
- Alle Telegramme (TX/RX) mit Zeit, Funktionscode, Latenz und Status
  (OK, CRC-Fehler, Exception, unerwartet, unvollständig).
- Frame-Zerlegung (MBAP / Unit / FC / Daten / CRC) mit farbigem Hex-Dump und
  CRC-Prüfung; Filter, Pause, Leeren; Export als Text oder CSV (Datei oder
  Zwischenablage).

**Werkzeuge**
- Hex-Rechner: Bytes oder Register in alle Formate und zurück
  (Wert → Register, z. B. 230,1 V als FLOAT32 CDAB), eigene Muster wie `EFGHABCD`.
- Scanner: Slave-IDs 1–247 und Registerbereiche, mit Fortschritt und Abbruch.
- Netzwerk-Scan: IP-Bereich (CIDR oder von–bis, Vorschlag aus den eigenen
  Netzwerkkarten) nach Geräten durchsuchen; listet IP, Hostname, MAC-Adresse
  und offene gängige Ports (u. a. 502 Modbus, 102 S7, 4840 OPC UA, 44818
  EtherNet/IP, 20000 DNP3, 1883 MQTT, HTTP/HTTPS, SSH). Offene Modbus-Ports
  werden mit einer echten Modbus-Anfrage geprüft (Hersteller/Produkt per
  Device Identification); ein Klick legt ein Profil an und verbindet.
  Ergebnisse als CSV exportierbar.
- Statistik: Anfragen, Fehlerquote, Ø/Min/Max-Latenz, Fehler nach Art und FC.
- Trend-Graph für Werte der Register-Map.

**Allgemein:** Deutsch und Englisch (Systemsprache), helles/dunkles Theme,
responsives Layout (Desktop mehrspaltig mit verstellbaren Panels, Handy
einspaltig), Tastaturkürzel, Screenreader-Beschriftungen, Kontraste nach WCAG AA.

## Plattformen

| Plattform | TCP | RTU seriell | Status |
|---|---|---|---|
| macOS | ✓ | ✓ (libserialport) | gebaut und getestet, inkl. Integrationstests in der App |
| Windows | ✓ | ✓ (libserialport) | Code vorbereitet, hier **nicht** gebaut |
| Linux | ✓ | ✓ (libserialport) | Code vorbereitet, hier **nicht** gebaut |
| Android | ✓ | ✓ USB-OTG (usb_serial) | Release-APK gebaut, im Emulator gestartet und bedient (Verbinden, Lesen, Interpretation); nicht auf echtem Gerät |
| iOS | ✓ | – (keine öffentliche API) | Code vorbereitet, hier **nicht** gebaut |
| Web | – | – | nicht unterstützt (Browser können keine TCP-Sockets öffnen) |

Funktionen, die eine Plattform nicht kann, werden ausgeblendet
(`platformCapabilitiesProvider`).

## Schnellstart ohne Hardware

1. App starten. Beim ersten Start gibt es das Profil **„Simulator (Demo)“**.
2. *Register* → **Mit Simulator verbinden** → **Lesen**.
3. Die ersten acht Holding-Register anklicken: 10.0 steht dort in allen vier
   Byte-Reihenfolgen, die Matrix markiert jeweils die passende Spalte als plausibel.

Andere Modbus-Tools können den Simulator ebenfalls nutzen: *Verbindung* →
**Simulator-TCP-Server** (Desktop, Standard `127.0.0.1:1502`).

## Bauen

Voraussetzungen: **Flutter ≥ 3.50** (Dart ≥ 3.14). Material kommt aus
`package:material_ui` (siehe DECISIONS.md, D1).

```bash
flutter pub get
flutter analyze
flutter test
```

### macOS
- Xcode, **CocoaPods** (für `flutter_libserialport`, das noch kein Swift Package
  Manager kann) sowie `automake` und `libtool` (`brew install automake libtool`).
- `flutter run -d macos` bzw. `flutter build macos --release`
  → `build/macos/Build/Products/Release/Modbus Explorer.app` (ca. 50 MB).
- **Ohne App-Sandbox** (nötig für den Netzwerk-Scan; damit ist kein Vertrieb
  über den Mac App Store möglich). Daten aus der früheren Sandbox-Version
  werden beim ersten Start automatisch übernommen.
- Beim ersten Netzwerkzugriff ins LAN fragt macOS nach der Freigabe für das
  **lokale Netzwerk** (Systemeinstellungen → Datenschutz & Sicherheit →
  Lokales Netzwerk). Ohne Freigabe bleiben u. a. die MAC-Adressen leer.
- Die App ist nicht signiert: auf anderen Macs beim ersten Start
  Rechtsklick → Öffnen. Für eine Verteilung braucht es Developer-ID und Notarisierung.

### Windows
- Visual Studio 2022 mit „Desktopentwicklung mit C++“.
- `flutter build windows --release` → `build\windows\x64\runner\Release\`.
- libserialport wird mitgebaut; USB-Seriell-Adapter brauchen ggf. den
  Hersteller-Treiber (FTDI, CH340, CP210x).

### Linux
- `sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev`
  (bzw. die Pakete der Distribution).
- `flutter build linux --release` → `build/linux/x64/release/bundle/`.
- Zugriff auf `/dev/ttyUSB*`: Benutzer in die Gruppe `dialout` aufnehmen
  (`sudo usermod -aG dialout $USER`, neu anmelden).

### Android
- Android SDK inkl. **cmdline-tools**, Lizenzen akzeptieren
  (`flutter doctor --android-licenses`); JDK z. B. aus Android Studio.
- `flutter build apk --release`
  → `build/app/outputs/flutter-apk/app-release.apk` (ca. 59 MB, mit dem
  Debug-Schlüssel signiert – für den Play Store einen eigenen Schlüssel einrichten).
- Zwei Plugins liegen als angepasste Kopie unter `third_party/` (ihre
  Android-Buildskripte sind mit aktuellem Android-Gradle-Plugin inkompatibel),
  `jni`/`jni_flutter` sind gepinnt – siehe `pubspec.yaml` und DECISIONS.md D98–D99.
- RTU über USB-OTG-Adapter (FTDI, CH34x, CP210x, PL2303, CDC). Beim Anstecken
  eines bekannten Adapters bietet Android die App an
  (`res/xml/device_filter.xml`); sonst fragt sie beim Verbinden nach der Erlaubnis.
- Datei-Export läuft über den Teilen-Dialog (Android hat keinen „Speichern
  unter“-Dialog).

### iOS
- Xcode mit Signing-Team. `flutter build ios`.
- Nur TCP. Beim ersten Verbinden fragt iOS nach Zugriff auf das lokale Netzwerk
  (`NSLocalNetworkUsageDescription`).

### App-Icon neu erzeugen
```bash
uvx --with pillow python tool/make_icon.py   # Quellbilder in assets/icon/
dart run flutter_launcher_icons              # Plattform-Icons
```

## Tests

| Ebene | Befehl | Inhalt |
|---|---|---|
| Unit | `flutter test test/features/…` | CRC16, MBAP/RTU-Framing, PDU-Codec, alle Datentyp-/Byte-Order-Konvertierungen (Referenzwerte unabhängig berechnet), Encoder, Adressen, Exceptions, Client mit Simulator (Timeouts, Retries, CRC, verspätete Antworten), Register-Map, Scanner, Statistik |
| Widget | `flutter test` | Interpretations-Matrix, alle Seiten und Abläufe gegen den Simulator, Import/Export, Tastaturkürzel |
| Layout | `test/layout_smoke_test.dart` | alle Seiten auf Deutsch in Handy-, Tablet- und Desktop-Größe (Überläufe lassen den Test scheitern) |
| Barrierefreiheit | `test/core/contrast_test.dart` | Textkontraste ≥ 4,5:1 in beiden Themes |
| Live (nur lesend) | `MODBUS_HOST=<ip> flutter test test_live/` | gegen ein echtes Gerät: Netzwerk-Scan der einen IP, Device ID, FC03/FC04 ab 19000 mit Interpretation; nicht Teil von `flutter test` |
| Integration | `flutter test integration_test -d macos --no-dds` | in der echten App: libserialport (FFI), TCP, Dateipfade, ARP-Zugriff (nur passiv) |

`--no-dds` ist nötig, weil der Debug-Dienst in dieser Umgebung nicht startet.

## Architektur

Feature-first, je Feature `domain/` (reines Dart, ohne Flutter), `data/` und
`presentation/` (Riverpod 3).

```
lib/
  core/            Theme, Lokalisierung (ARB), Routing (go_router), Plattform-
                   Capabilities, Speicher (Key-Value, JSON-Dokumente), Dateien,
                   gemeinsame Widgets
  features/
    connection/    Profile, Verbindungszustand, Editor
    modbus/        Protokoll: Requests/Responses, Fehler, Adressen (domain);
                   Kanäle, Framing, Codec, Client (data)
    interpretation/ Byte-Orders, Decoder/Encoder, Plausibilität, Matrix,
                   Register-Map
    registers/     Rohwert-Tabelle, Lesen/Pollen/Schreiben
    monitor/       Telegramm-Log, Statistik, Frame-Details
    tools/         Hex-Rechner, Scanner, Trend
    simulator/     Demo-Geräte, Endpunkt mit Fehlerinjektion, TCP-Server
    settings/
```

**Transport in drei Schichten:**

```
ByteChannel            Socket · libserialport · usb_serial · In-Memory
    ↓ Bytes
ModbusFraming          MBAP (TCP) · RTU (CRC, Längenerkennung)
    ↓ Frames
ModbusClient           Queue · Timeouts · Retries · Transaction-IDs
                       → frames / transactions (Monitor, Statistik)
```

Jede Kombination ist möglich, z. B. RTU-Framing über einen Socket = RTU über
TCP. Der Simulator nutzt denselben Codec und hängt über einen In-Memory-Kanal
direkt am Client, so lässt sich die ganze App ohne Hardware testen.

**Warum eine eigene Protokollschicht statt `modbus_client`:** Der Monitor
braucht jedes Rohframe (auch kaputte und verspätete) mit Zeitstempel,
CRC-Status und Zuordnung zur Transaktion. Dazu RTU über TCP, Fehlerinjektion und
ein Simulator mit demselben Codec. Das Package kapselt genau das weg. Die
eigene Schicht ist überschaubar und vollständig getestet (DECISIONS.md, D26).

**Byte-Reihenfolgen** sind Permutationen über ein Buchstabenmuster: `A` ist das
High-Byte des ersten Registers, `CDAB` heißt „Wert = Bytes C D A B,
big-endian gelesen“. Eine Implementierung deckt 16, 32 und 64 Bit sowie
beliebige Muster ab.

## Daten und Formate

Alles bleibt lokal. Gespeichert im App-Support-Verzeichnis
(macOS: `~/Library/Application Support/de.example.modbusExplorer/`):

- `connection_profiles.json` – Verbindungsprofile (versioniert)
- `register_maps.json` – Register-Maps pro Profil (versioniert)
- Einstellungen über `shared_preferences`

**Register-Map als CSV** (Trennzeichen `;`, UTF-8 mit BOM, Adressen 0-basiert):

```
table;address;label;unit;type;order;registers;bit;factor;offset;decimals;description
holdingRegisters;52;Spannung L1;V;float32;ABCD;;;;;;
holdingRegisters;70;Temperatur;°C;int16;AB;;;0.1;0;1;
holdingRegisters;30;Seriennummer;;text;BA;8;;;;;
holdingRegisters;60;Alarm;;bit;;;3;;;;
coils;0;Pumpe;;bit;;;;;;;
```

`table`: `coils`, `discreteInputs`, `inputRegisters`, `holdingRegisters`.
`type`: `int16`, `uint16`, `int32`, `uint32`, `float32`, `int64`, `uint64`,
`float64`, `bcd16`, `bcd32`, `unixTime32`, `unixTime64Ms`, `text`, `bit`.
Beim Import werden auch Dezimalkommas akzeptiert; unlesbare Zeilen werden
übersprungen und gemeldet.

## Demo-Gerät (Simulator)

Verbindungstyp „Simulator“ (alle Plattformen) oder TCP-Server auf
`127.0.0.1:1502` (Desktop). Unit 1, Holding-Register:

| Adresse (0-basiert) | Inhalt |
|---|---|
| 0 / 2 / 4 / 6 | FLOAT32 10.0 in ABCD / CDAB / BADC / DCBA |
| 10 / 14 | FLOAT64 π in ABCDEFGH / HGFEDCBA |
| 20 | UINT32 123456 (ABCD) |
| 22 | INT32 −123456 (CDAB) |
| 24 | INT16 −1234 |
| 25 | BCD 1234 |
| 26 | UINT64 1234567890123 |
| 30–37 | Text „Modbus Explorer“ |
| 40 / 42 | Unix-Zeit 32 Bit s / 64 Bit ms (live) |
| 50 / 51 | Zähler / Sinus × 1000 (live) |
| 52 / 54 | FLOAT32 Spannung ~230 V (ABCD) / Frequenz ~50 Hz (CDAB), live |
| 60 | Statuswort 0xA50F |
| 70 | Temperatur × 10 (INT16, live) |
| 1000–1009 | antworten mit Exception 04 |
| ≥ 2000 | antworten mit Exception 02 |

Input-Register: 0 Temperatur (FLOAT32, live), 2 Luftdruck 1013.25 (FLOAT32),
4 Drehzahl (UINT16, live). Unit 2 ist ein kleiner Zähler (Input-Register
0/2/4: 230.1 V, 5.25 A, 49.98 Hz). Alle anderen Unit-IDs antworten nicht. Im
Profil lassen sich Latenz sowie verlorene und verfälschte Antworten simulieren.

## Tastaturkürzel

| Kürzel (macOS: ⌘ statt Strg) | Aktion |
|---|---|
| Strg + 1 … 5 | Bereich wechseln |
| Strg + R / F5 | einmal lesen (Register oder Register-Map) |
| Strg + P | Polling starten/stoppen |
| Strg + Enter | Dialog bestätigen / Profil speichern |
| Esc | Dialog schließen |
| Umschalt + Klick | Bereich in der Tabelle auswählen |

## Mit echter Hardware geprüft

Ein **Janitza-UMG-Messgerät** über Modbus TCP (geroutet erreichbar), nur
lesend: Netzwerk-Scan findet es in ~1,5 s (offen: 21, 22, 80, 443, 502, 8080;
Modbus per Registerlesen bestätigt – FC43 beantwortet das Gerät nicht).
FC03/FC04 ab Register 19000 liefern FLOAT32 in ABCD: Spannungen L–N ~230 V,
L–L ~399 V; die Matrix markiert genau diese Interpretation als plausibel.
Antwortzeit ~95 ms (Mac) bzw. ~108 ms (Android-Emulator). Die Prüfung lief
über die Bibliothek und durch die Android-App im Emulator.

## Bekannte Einschränkungen

- Windows, Linux, Android und iOS sind vorbereitet, aber in dieser Umgebung
  nicht gebaut; serielle Schnittstellen sind nicht an echter Hardware getestet.
- RS485-Richtungsumschaltung erfolgt nicht per Software; die meisten
  USB-RS485-Adapter schalten automatisch (RTS/DTR können fest gesetzt werden).
- Modbus TCP hat keine eigene Prüfsumme: verfälschte Nutzdaten sind auf
  Modbus-Ebene nicht erkennbar (bei RTU greift die CRC).
- Netzwerk-Scan ohne Ping: Apps können kein ICMP senden. Hosts werden per
  TCP-Verbindungsversuch erkannt (auch eine Ablehnung zeigt einen lebenden
  Host) und, wo möglich, über die ARP-Tabelle. Geräte, die alle geprüften
  Ports stumm verwerfen und nicht im ARP-Cache stehen, bleiben unsichtbar.
- MAC-Adressen gibt es grundsätzlich nur für Geräte im **selben Netzsegment**
  (ARP endet am Router); bei gerouteten Bereichen zeigt die App das an.
- MAC-Adressen im Netzwerk-Scan nur auf dem Desktop; Android 10+ und iOS
  sperren die ARP-Tabelle. Unter macOS liefert `arp` aus der App heraus in
  dieser Umgebung trotz abgeschalteter Sandbox keine Einträge (im Terminal
  schon); vermutete Ursache ist die fehlende Freigabe „Lokales Netzwerk“ –
  das ließ sich hier nicht überprüfen. Bleibt die Tabelle leer, zeigt die App
  einen Hinweis.
- Subnetzmasken liefert Dart nicht; der Netzwerk-Scan schlägt /24 vor, der
  Bereich ist frei editierbar (max. 4096 Adressen).
- Keine separate Sitzungsaufzeichnung; das Log (bis 5000 Telegramme) lässt
  sich als Text/CSV speichern.
- Windows: keine Mindestfenstergröße (macOS und Linux haben eine).
- Platzhalter-Bundle-ID `de.example.modbusExplorer` vor einer Veröffentlichung ersetzen.

Alle Entscheidungen und Annahmen: [DECISIONS.md](DECISIONS.md).
