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
