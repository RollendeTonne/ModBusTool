# Local copy of flutter_libserialport 0.6.0

Unmodified except:

- Android platform removed from `pubspec.yaml` and the `android/` directory
  deleted. Its Gradle script uses the shut-down `jcenter()` repository and an
  outdated Android Gradle Plugin, which breaks every Android build of the app.
  Modbus Explorer uses `usb_serial` on Android, so nothing is lost.
- `example/` and `test/` removed.

Licence: MIT (see LICENSE); the bundled libserialport C library is LGPL-3.0.
Remove this copy and the `dependency_overrides` entry once upstream fixes
its Android build.
