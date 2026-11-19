import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_errors.dart';
import 'package:modbus_explorer/features/modbus/presentation/modbus_exception_text.dart';
import 'package:modbus_explorer/features/registers/presentation/registers_controller.dart';

/// Localized title + hint for any error the app shows, plus the technical
/// detail (English, from the transport) where it adds information.
({String title, String hint, String? detail}) describeError(
  AppLocalizations l10n,
  Object error,
) {
  switch (error) {
    case ModbusDeviceException(:final exceptionCode):
      final text = modbusExceptionText(l10n, exceptionCode);
      return (title: text.title, hint: text.explanation, detail: error.message);
    case ModbusTimeoutException(:final timeout, :final attempts):
      return (
        title: l10n.errorTimeoutTitle,
        hint: l10n.errorTimeoutHint(timeout.inMilliseconds, attempts),
        detail: null,
      );
    case ModbusProtocolException(:final message):
      return (
        title: l10n.errorProtocolTitle,
        hint: l10n.errorProtocolHint,
        detail: message,
      );
    case ModbusConnectionException(:final kind, :final message):
      final (title, hint) = switch (kind) {
        ConnectionErrorKind.refused => (
          l10n.errorRefusedTitle,
          l10n.errorRefusedHint,
        ),
        ConnectionErrorKind.timeout => (
          l10n.errorConnectTimeoutTitle,
          l10n.errorConnectTimeoutHint,
        ),
        ConnectionErrorKind.hostNotFound => (
          l10n.errorHostNotFoundTitle,
          l10n.errorHostNotFoundHint,
        ),
        ConnectionErrorKind.unreachable => (
          l10n.errorUnreachableTitle,
          l10n.errorUnreachableHint,
        ),
        ConnectionErrorKind.portUnavailable => (
          l10n.errorPortUnavailableTitle,
          l10n.errorPortUnavailableHint,
        ),
        ConnectionErrorKind.permissionDenied => (
          l10n.errorPermissionTitle,
          l10n.errorPermissionHint,
        ),
        ConnectionErrorKind.invalidSettings => (
          l10n.errorInvalidSettingsTitle,
          l10n.errorInvalidSettingsHint,
        ),
        ConnectionErrorKind.unsupported => (
          l10n.errorUnsupportedTitle,
          l10n.errorUnsupportedHint,
        ),
        ConnectionErrorKind.closed => (
          l10n.errorClosedTitle,
          l10n.errorClosedHint,
        ),
        ConnectionErrorKind.other => (
          l10n.errorConnectionTitle,
          l10n.errorConnectionHint,
        ),
      };
      return (title: title, hint: hint, detail: message);
    case NotConnectedError():
      return (
        title: l10n.errorNotConnectedTitle,
        hint: l10n.errorNotConnectedHint,
        detail: null,
      );
    case StateError(:final message) when message.contains('locked'):
      return (
        title: l10n.errorWriteLockedTitle,
        hint: l10n.errorWriteLockedHint,
        detail: null,
      );
    default:
      return (
        title: l10n.errorUnexpectedTitle,
        hint: '',
        detail: error.toString(),
      );
  }
}
