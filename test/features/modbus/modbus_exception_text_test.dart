import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_errors.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_exception_code.dart';
import 'package:modbus_explorer/features/modbus/presentation/modbus_exception_text.dart';

void main() {
  group('exception codes', () {
    test('fromCode covers 01–08, 0A, 0B and nothing else', () {
      final known = [1, 2, 3, 4, 5, 6, 7, 8, 0x0A, 0x0B];
      for (var code = 0; code < 0x20; code++) {
        expect(
          ModbusExceptionCode.fromCode(code) != null,
          known.contains(code),
          reason: 'code $code',
        );
      }
    });

    test('device exception message includes the spec name', () {
      expect(
        ModbusDeviceException(functionCode: 3, exceptionCode: 2).message,
        'Modbus exception 0x02 (ILLEGAL DATA ADDRESS)',
      );
      expect(
        ModbusDeviceException(functionCode: 3, exceptionCode: 0x42).message,
        'Modbus exception 0x42',
      );
    });
  });

  for (final locale in supportedAppLocales) {
    group('localized texts (${locale.languageCode})', () {
      final l10n = lookupAppLocalizations(locale);

      test('every known code has a distinct title and explanation', () {
        final titles = <String>{};
        for (final code in ModbusExceptionCode.values) {
          final text = modbusExceptionText(l10n, code.code);
          expect(text.explanation, isNotEmpty);
          expect(
            text.title,
            startsWith(
              code.code.toRadixString(16).toUpperCase().padLeft(2, '0'),
            ),
          );
          titles.add(text.title);
        }
        expect(titles, hasLength(ModbusExceptionCode.values.length));
      });

      test('unknown codes show the hex value', () {
        expect(modbusExceptionText(l10n, 0x42).title, contains('0x42'));
      });
    });
  }

  test('German explanation for illegal data address mentions addressing', () {
    final text = modbusExceptionText(
      lookupAppLocalizations(const Locale('de')),
      2,
    );
    expect(text.title, '02 Unzulässige Adresse');
    expect(text.explanation, contains('0- oder 1-basiert'));
  });
}
