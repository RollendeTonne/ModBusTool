import 'package:material_ui/material_ui.dart';

extension ReplacingSnackBar on ScaffoldMessengerState {
  /// Replaces the visible snackbar instead of queueing behind it, so rapid
  /// actions (copying several values) give immediate feedback.
  void showReplacing(String message, {Duration? duration}) {
    removeCurrentSnackBar();
    showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 4),
      ),
    );
  }
}
