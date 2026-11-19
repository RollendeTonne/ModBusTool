import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/modules/modbus/connection/presentation/modbus_error_text.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/channel/socket_channel.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_errors.dart';
import 'package:modbus_explorer/modules/modbus/registers/presentation/registers_controller.dart';

void main() {
  for (final locale in supportedAppLocales) {
    group('describeError (${locale.languageCode})', () {
      final l10n = lookupAppLocalizations(locale);

      test('every connection error kind has its own title and a hint', () {
        final titles = <String>{};
        for (final kind in ConnectionErrorKind.values) {
          final text = describeError(
            l10n,
            ModbusConnectionException('detail', kind: kind),
          );
          expect(text.hint, isNotEmpty);
          expect(text.detail, 'detail');
          titles.add(text.title);
        }
        expect(titles, hasLength(ConnectionErrorKind.values.length));
      });

      test('timeout mentions timeout and attempts', () {
        final text = describeError(
          l10n,
          ModbusTimeoutException(
            timeout: const Duration(milliseconds: 750),
            attempts: 3,
          ),
        );
        expect(text.hint, contains('750'));
        expect(text.hint, contains('3'));
      });

      test('device exception uses the exception explanation', () {
        final text = describeError(
          l10n,
          ModbusDeviceException(functionCode: 3, exceptionCode: 2),
        );
        expect(text.title, startsWith('02'));
      });

      test('protocol, not-connected and unknown errors', () {
        expect(
          describeError(l10n, const ModbusProtocolException('CRC')).detail,
          'CRC',
        );
        expect(describeError(l10n, const NotConnectedError()).detail, isNull);
        expect(describeError(l10n, Exception('x')).detail, contains('x'));
      });
    });
  }

  test('socket errors are classified by message', () {
    (ConnectionErrorKind, String) classify(String message) =>
        describeSocketError(
          SocketException('x', osError: OSError(message, 1)),
          'h',
          1,
        );
    expect(classify('Connection refused').$1, ConnectionErrorKind.refused);
    expect(classify('Operation timed out').$1, ConnectionErrorKind.timeout);
    expect(
      classify('nodename nor servname provided, or not known').$1,
      ConnectionErrorKind.hostNotFound,
    );
    expect(
      classify('Network is unreachable').$1,
      ConnectionErrorKind.unreachable,
    );
    expect(classify('Something odd').$1, ConnectionErrorKind.other);
    expect(classify('Something odd').$2, contains('h:1'));
  });
}
