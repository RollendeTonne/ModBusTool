# Modbus Explorer

Plattformübergreifendes Debugging-Werkzeug für Modbus TCP/RTU (Flutter). Rohe
Registerwerte werden gleichzeitig in allen gängigen Datentypen und
Byte-/Wortreihenfolgen interpretiert.

> Status: **M4** – Verbindungsprofile, Lesen/Pollen und Schreiben in der Oberfläche, Modbus-Transport (TCP/RTU/RTU over TCP) und Simulator. Interpretations-Matrix folgt in M5.
> Die vollständige Dokumentation folgt mit M7.

## Entwicklung

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d macos   # bzw. windows / linux / <android-device>

# Integrationstests in der echten Desktop-App (Serial-FFI, Sandbox, Pfade)
flutter test integration_test -d macos --no-dds
```

### Bedienung (Stand M4)

1. **Verbindung:** Profil anlegen (TCP, RTU, RTU über TCP oder Simulator) und
   auf „Verbinden“ klicken. Beim ersten Start gibt es schon ein Simulator-Profil.
2. **Register:** Tabelle, Startadresse und Anzahl wählen, dann „Lesen“
   (Strg/⌘+R, F5) oder „Pollen“. Geänderte Werte blinken kurz auf.
3. **Schreiben:** Erst „Schreiben freigeben“ einschalten, dann das Stift-Symbol
   (Register), den Schalter (Coils) oder „Mehrere schreiben…“ benutzen.
   Jeder Schreibzugriff wird vorher bestätigt (abschaltbar in den Einstellungen).

### macOS: CocoaPods

`flutter_libserialport` (serielle Schnittstellen) braucht auf macOS CocoaPods
sowie `automake` und `libtool` (`brew install automake libtool`). Ist `pod`
nicht vorhanden, bricht `flutter build macos` mit „CocoaPods not installed“
ab. Siehe DECISIONS.md, D35.

Lokalisierungen liegen in `lib/core/l10n/arb/` und werden beim Build
automatisch generiert (`flutter gen-l10n` für manuelle Läufe).

## Architektur (Kurzfassung)

Feature-first, jeweils `domain/` (reines Dart), `data/`, `presentation/`:

```
lib/
  core/       l10n, theme, routing, platform (Capabilities), storage, widgets
  features/   connection, modbus, interpretation, registers, monitor, tools,
              simulator, settings
```

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

Unit 2 ist ein kleiner Zähler (Input-Register 0/2/4: 230.1 V, 5.25 A, 49.98 Hz).
Alle anderen Unit-IDs antworten nicht.

Entscheidungen und Annahmen: siehe [DECISIONS.md](DECISIONS.md).
