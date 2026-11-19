import 'dart:collection';
import 'dart:math';

/// Fixed-capacity FIFO: adding beyond [capacity] drops the oldest items.
/// O(1) add, indexed access oldest-first.
final class RingBuffer<T> extends ListBase<T> {
  new(int capacity)
    : assert(capacity > 0, 'capacity must be positive'),
      _items = List<T?>.filled(capacity, null);

  List<T?> _items;
  int _start = 0;
  int _length = 0;
  int _totalAdded = 0;

  int get capacity => _items.length;

  /// Number of items ever added, including the dropped ones.
  int get totalAdded => _totalAdded;

  @override
  int get length => _length;

  @override
  set length(int newLength) =>
      throw UnsupportedError('RingBuffer has a fixed capacity');

  @override
  T operator [](int index) {
    RangeError.checkValidIndex(index, this, 'index', _length);
    return _items[(_start + index) % capacity] as T;
  }

  @override
  void operator []=(int index, T value) {
    RangeError.checkValidIndex(index, this, 'index', _length);
    _items[(_start + index) % capacity] = value;
  }

  @override
  void add(T element) {
    _totalAdded++;
    if (_length < capacity) {
      _items[(_start + _length) % capacity] = element;
      _length++;
    } else {
      _items[_start] = element;
      _start = (_start + 1) % capacity;
    }
  }

  @override
  void addAll(Iterable<T> iterable) => iterable.forEach(add);

  @override
  void clear() {
    _items = List<T?>.filled(capacity, null);
    _start = 0;
    _length = 0;
  }

  /// New buffer with [newCapacity] keeping the newest items.
  RingBuffer<T> resized(int newCapacity) => RingBuffer<T>(newCapacity)
    ..addAll(skip(max(0, _length - newCapacity)))
    .._totalAdded = _totalAdded;
}
