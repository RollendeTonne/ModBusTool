import 'dart:io';

/// The macOS build used to run in the App Sandbox, which keeps data in
/// `~/Library/Containers/<bundle id>/`. Without the sandbox the app uses
/// the regular locations, so existing profiles, register maps and settings
/// are copied over once.
final class SandboxMigration {
  new({
    required this.home,
    required this.bundleId,
    required this.supportDirectory,
    this.runProcess = Process.run,
  });

  final String home;
  final String bundleId;

  /// The (unsandboxed) application support directory.
  final Directory supportDirectory;
  final Future<ProcessResult> Function(String, List<String>) runProcess;

  static const markerName = '.migrated-from-sandbox';

  Directory get _container =>
      Directory('$home/Library/Containers/$bundleId/Data/Library');

  /// Copies documents that don't exist yet and imports settings if the
  /// unsandboxed preferences domain is still empty. Runs once; failures
  /// are swallowed so a broken migration never blocks the app start.
  Future<List<String>> run() async {
    final marker = File('${supportDirectory.path}/$markerName');
    if (marker.existsSync()) return const [];
    final migrated = <String>[];
    try {
      final oldSupport = Directory(
        '${_container.path}/Application Support/$bundleId',
      );
      if (oldSupport.existsSync()) {
        await supportDirectory.create(recursive: true);
        for (final entity in oldSupport.listSync()) {
          if (entity is! File || !entity.path.endsWith('.json')) continue;
          final name = entity.uri.pathSegments.last;
          final target = File('${supportDirectory.path}/$name');
          if (target.existsSync()) continue;
          await entity.copy(target.path);
          migrated.add(name);
        }
      }
      final oldPrefs = File('${_container.path}/Preferences/$bundleId.plist');
      if (oldPrefs.existsSync()) {
        // `defaults import` goes through cfprefsd; copying the plist file
        // directly could be overwritten by a cached copy.
        final existing = await runProcess('defaults', ['read', bundleId]);
        if (existing.exitCode != 0) {
          final result = await runProcess('defaults', [
            'import',
            bundleId,
            oldPrefs.path,
          ]);
          if (result.exitCode == 0) migrated.add('$bundleId.plist');
        }
      }
      await supportDirectory.create(recursive: true);
      await marker.writeAsString(DateTime.now().toIso8601String());
    } on Object {
      // Leave without marker: the next start tries again.
    }
    return migrated;
  }
}
