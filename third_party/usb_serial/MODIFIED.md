# Local copy of usb_serial 0.5.2

Only the Android build script was changed; the Java and Dart code is
unmodified.

- `android/build.gradle`: removed the `buildscript` block (it pinned Android
  Gradle Plugin 4.1, which conflicts with the app's AGP 9), removed the
  shut-down `jcenter()` repository, `lintOptions` → `lint {}`,
  `compileSdkVersion 33` → `compileSdk 36`, Java 8 → 17, explicit
  `androidx.annotation` compile dependency. The JitPack repository for
  `com.github.felHR85:UsbSerial` is declared in the app's
  `android/build.gradle.kts`.
- Removed the Gradle wrapper, `example/` and `test/`.

Licence: BSD (see LICENSE). Remove this copy and the `dependency_overrides`
entry once upstream supports current Android tooling.
