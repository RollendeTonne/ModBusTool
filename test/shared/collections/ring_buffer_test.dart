import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/shared/collections/ring_buffer.dart';

void main() {
  test('keeps the newest items in order', () {
    final buffer = RingBuffer<int>(3)..addAll([1, 2, 3, 4, 5]);
    expect(buffer, [3, 4, 5]);
    expect(buffer.length, 3);
    expect(buffer.totalAdded, 5);
    expect(buffer.first, 3);
    expect(buffer.last, 5);
  });

  test('partially filled and indexed access', () {
    final buffer = RingBuffer<String>(4)..addAll(['a', 'b']);
    expect(buffer, ['a', 'b']);
    expect(() => buffer[2], throwsRangeError);
    buffer[1] = 'B';
    expect(buffer, ['a', 'B']);
  });

  test('clear and resize keep the newest', () {
    final buffer = RingBuffer<int>(5)..addAll(List.generate(8, (i) => i));
    expect(buffer.resized(2), [6, 7]);
    expect(buffer.resized(10), [3, 4, 5, 6, 7]);
    expect(buffer.resized(2).totalAdded, 8);
    buffer.clear();
    expect(buffer, isEmpty);
    buffer.add(42);
    expect(buffer, [42]);
  });

  test('cannot grow', () {
    expect(() => RingBuffer<int>(2).length = 5, throwsUnsupportedError);
  });
}
