# Modbus Explorer

Plattformübergreifendes Debugging-Werkzeug für Modbus TCP/RTU (Flutter). Rohe
Registerwerte werden gleichzeitig in allen gängigen Datentypen und
Byte-/Wortreihenfolgen interpretiert.

> Status: **M1 – Grundgerüst** (Theme, Lokalisierung, Routing, Capabilities).
> Die vollständige Dokumentation folgt mit M7.

## Entwicklung

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d macos   # bzw. windows / linux / <android-device>
```

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

Entscheidungen und Annahmen: siehe [DECISIONS.md](DECISIONS.md).
