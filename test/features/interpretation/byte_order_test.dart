import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/features/interpretation/domain/byte_order.dart';

void main() {
  group('ByteOrder.of', () {
    const expected = {
      2: ['AB', 'BA', 'AB', 'BA'],
      4: ['ABCD', 'BADC', 'CDAB', 'DCBA'],
      8: ['ABCDEFGH', 'BADCFEHG', 'GHEFCDAB', 'HGFEDCBA'],
    };
    for (final MapEntry(key: width, value: patterns) in expected.entries) {
      for (final (i, family) in ByteOrderFamily.values.indexed) {
        test('$family at $width bytes is ${patterns[i]}', () {
          final order = ByteOrder.of(family, width);
          expect(order.pattern, patterns[i]);
          expect(order.width, width);
        });
      }
    }

    test('rejects unsupported widths', () {
      expect(() => ByteOrder.of(ByteOrderFamily.abcd, 3), throwsArgumentError);
    });
  });

  group('ByteOrder.parse', () {
    test('normalises case and whitespace', () {
      expect(ByteOrder.parse(' cdab ').pattern, 'CDAB');
      expect(ByteOrder.parse('cdab'), ByteOrder.of(ByteOrderFamily.cdab, 4));
    });

    for (final invalid in [
      '',
      'A',
      'ABC',
      'AABB',
      'ABCE',
      'ABCDEFGHI',
      'AB1D',
    ]) {
      test('rejects "$invalid"', () {
        expect(() => ByteOrder.parse(invalid), throwsFormatException);
      });
    }

    test('extended 64-bit orders are valid permutations', () {
      expect(ByteOrder.extended64.map((o) => o.pattern), [
        'EFGHABCD',
        'CDABGHEF',
      ]);
    });
  });

  group('arrange', () {
    test('picks wire bytes in pattern order', () {
      expect(ByteOrder.parse('CDAB').arrange([1, 2, 3, 4]), [3, 4, 1, 2]);
      expect(ByteOrder.parse('DCBA').arrange([1, 2, 3, 4]), [4, 3, 2, 1]);
      expect(ByteOrder.parse('BA').arrange([9, 1, 2], 1), [2, 1]);
    });

    test('throws on too few bytes', () {
      expect(
        () => ByteOrder.parse('ABCD').arrange([1, 2, 3]),
        throwsRangeError,
      );
    });
  });

  group('register/byte conversion', () {
    test('registers split high byte first', () {
      expect(registersToBytes([0x4120, 0x00FF]), [0x41, 0x20, 0x00, 0xFF]);
    });

    test('rejects values outside 16 bit', () {
      expect(() => registersToBytes([0x10000]), throwsRangeError);
      expect(() => registersToBytes([-1]), throwsRangeError);
    });

    test('bytes join into registers, odd byte zero-padded', () {
      expect(bytesToRegisters([0x41, 0x20, 0x7F]), [0x4120, 0x7F00]);
    });
  });
}
