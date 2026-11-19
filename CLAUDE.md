# Protocol Explorer (working title; package `modbus_explorer`)

Flutter debugging tool with two modules: Modbus (done) and MQTT (M9–M14).
Read DECISIONS.md before changing behaviour; add an entry for every
non-obvious decision (German, table row `| Dnnn | decision | reason |`).

## Toolchain
- Flutter 3.50 / Dart 3.14 from `~/homebrew/bin` (`export PATH=~/homebrew/bin:$PATH`).
- CocoaPods wrapper in `~/.local/bin` (needed for macOS/iOS builds).
- After every change: `flutter analyze` (must be clean) and `flutter test`.
- `dart fix --apply .` then `dart format lib test` fixes most lints.

## Conventions
- Import `package:material_ui/material_ui.dart`, not `flutter/material.dart`.
- Dart 3.14 constructor syntax (enforced by very_good_analysis 11):
  `const new(...)`, `new name(...)`, `factory name(...)`.
- Riverpod 3 without codegen (`Notifier`, `AsyncNotifier`, `Provider`);
  check `ref.mounted` after awaits.
- Structure: `core/` infra · `shared/` cross-module logic (interpretation
  engine, profile store) · `features/` app-wide (settings, network scan) ·
  `modules/modbus|mqtt/<feature>/{domain,data,presentation}`. `domain/` is
  pure Dart.
- Strings in `lib/core/l10n/arb/app_{de,en}.arb` (edit JSON, then
  `flutter gen-l10n`); placeholders described in the EN file.
- Widget tests: never touch real network/processes – inject (e.g.
  `connectionFactoryProvider` with `tcpConnect`, `urlOpenerProvider`,
  `activeNetworkDetectorProvider`). Overflow errors fail tests;
  `test/layout_smoke_test.dart` renders all pages in German.

## Rules
- Real-device tests: read-only, only `MODBUS_HOST=<ip> flutter test test_live/`.
- Never commit real device/network IPs.
- Push to GitHub after each milestone (project-specific permission).
