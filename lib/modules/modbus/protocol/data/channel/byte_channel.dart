import 'dart:async';
import 'dart:typed_data';

/// Bidirectional byte pipe underneath the Modbus framing: a TCP socket, a
/// serial port or an in-memory pipe.
abstract interface class ByteChannel {
  Stream<Uint8List> get input;

  Future<void> write(Uint8List data);

  Future<void> close();

  /// Completes when the channel closes, from either side.
  Future<void> get done;

  /// Human-readable endpoint, e.g. `192.168.0.10:502` or `/dev/ttyUSB0`.
  String get description;
}

/// Two connected in-memory channels; bytes written to one arrive at the
/// other. Used for the in-process simulator and tests.
final class InMemoryChannel implements ByteChannel {
  new _(this.description);

  static (InMemoryChannel, InMemoryChannel) pair({
    String description = 'in-memory',
  }) {
    final a = InMemoryChannel._(description);
    final b = InMemoryChannel._(description);
    a._peer = b;
    b._peer = a;
    return (a, b);
  }

  @override
  final String description;

  final _controller = StreamController<Uint8List>();
  final _done = Completer<void>();
  late InMemoryChannel _peer;

  @override
  Stream<Uint8List> get input => _controller.stream;

  @override
  Future<void> get done => _done.future;

  bool get isClosed => _done.isCompleted;

  @override
  Future<void> write(Uint8List data) async {
    if (isClosed) throw StateError('Channel closed');
    if (!_peer.isClosed) _peer._controller.add(Uint8List.fromList(data));
  }

  @override
  Future<void> close() async {
    _closeLocal();
    _peer._closeLocal();
  }

  void _closeLocal() {
    if (isClosed) return;
    _done.complete();
    unawaited(_controller.close());
  }
}
