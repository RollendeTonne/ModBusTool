import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a URI in the program the OS registered for its scheme; `false`
/// if none is registered. Injectable so tests never start real programs.
typedef UrlOpener = Future<bool> Function(Uri uri);

Future<bool> _openExternally(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Object {
    return false;
  }
}

final urlOpenerProvider = Provider<UrlOpener>((ref) => _openExternally);
