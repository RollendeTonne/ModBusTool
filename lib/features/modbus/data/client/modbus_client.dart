import 'dart:async';
import 'dart:typed_data';

import 'package:modbus_explorer/features/connection/domain/connection_config.dart';
import 'package:modbus_explorer/features/modbus/data/channel/byte_channel.dart';
import 'package:modbus_explorer/features/modbus/data/client/frame_event.dart';
import 'package:modbus_explorer/features/modbus/data/client/modbus_transaction.dart';
import 'package:modbus_explorer/features/modbus/data/codec/framing.dart';
import 'package:modbus_explorer/features/modbus/data/codec/pdu_codec.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_errors.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_limits.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_request.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_response.dart';
import 'package:modbus_explorer/features/modbus/domain/register_table.dart';

/// Modbus master on top of a [ByteChannel] and a [ModbusFraming].
///
/// Requests are strictly sequential: RTU requires it, and many TCP devices
/// and gateways misbehave with pipelined requests.
final class ModbusClient {
  new({
    required ByteChannel channel,
    required ModbusFraming framing,
    this.defaults = const RequestOptions(),
    this.interFrameDelay = Duration.zero,
    this.silenceTimeout = const Duration(milliseconds: 100),
    this._clock = DateTime.now,
  }) : _channel = channel,
       _framing = framing,
       _assembler = framing.newAssembler(expectRequests: false) {
    _subscription = channel.input.listen(_onBytes);
    unawaited(channel.done.then((_) => _onChannelClosed()));
  }

  final ByteChannel _channel;
  final ModbusFraming _framing;
  final DateTime Function() _clock;
  final FrameAssembler _assembler;
  late final StreamSubscription<Uint8List> _subscription;

  final RequestOptions defaults;

  /// Minimum silence before sending (RTU t3.5); zero for TCP.
  final Duration interFrameDelay;

  /// After this much silence, partial frames are discarded (RTU garbage).
  final Duration silenceTimeout;

  final _frames = StreamController<FrameEvent>.broadcast();
  final _transactions = StreamController<ModbusTransaction>.broadcast();
  final _done = Completer<void>();
  final _lineQuiet = Stopwatch()..start();

  Future<void> _queueTail = Future.value();
  _PendingAttempt? _pending;
  Timer? _silenceTimer;
  int _nextTransactionId = 1;
  int _transactionNumber = 0;
  bool _closed = false;

  Stream<FrameEvent> get frames => _frames.stream;
  Stream<ModbusTransaction> get transactions => _transactions.stream;
  Future<void> get done => _done.future;
  bool get isClosed => _closed;
  FrameKind get frameKind => _framing.kind;
  String get description => _channel.description;

  /// Sends [request] and returns the decoded response.
  ///
  /// Throws [ModbusDeviceException] for exception responses (not retried),
  /// [ModbusTimeoutException] / [ModbusProtocolException] after all retries,
  /// [ModbusConnectionException] if the channel is closed.
  Future<ModbusResponse> execute(
    ModbusRequest request, {
    int? unitId,
    Duration? timeout,
    int? retries,
  }) {
    final options = RequestOptions(
      unitId: unitId ?? defaults.unitId,
      timeout: timeout ?? defaults.timeout,
      retries: retries ?? defaults.retries,
    );
    RangeError.checkValueInInterval(options.unitId, 0, 255, 'unitId');
    final result = _queueTail.then((_) => _run(request, options));
    _queueTail = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  Future<ModbusResponse> _run(
    ModbusRequest request,
    RequestOptions options,
  ) async {
    final number = ++_transactionNumber;
    final startedAt = _clock();
    final total = Stopwatch()..start();
    var attempts = 0;
    Duration? latency;
    ModbusError? lastError;

    void record({ModbusResponse? response, ModbusError? error}) {
      if (_transactions.isClosed) return;
      _transactions.add(
        ModbusTransaction(
          number: number,
          unitId: options.unitId,
          request: request,
          startedAt: startedAt,
          duration: total.elapsed,
          attempts: attempts,
          latency: latency,
          response: response,
          error: error,
        ),
      );
    }

    final pdu = PduCodec.encodeRequest(request);
    final isBroadcast =
        _framing.kind == FrameKind.rtu &&
        options.unitId == ModbusLimits.broadcastUnitId;
    if (isBroadcast && !request.isWrite) {
      throw ArgumentError('Broadcast (unit 0) is only allowed for writes');
    }

    while (attempts <= options.retries) {
      if (_closed) {
        const error = ModbusConnectionException('Connection closed');
        record(error: error);
        throw error;
      }
      attempts++;
      await _waitForQuietLine();
      _discardStaleBytes();

      final transactionId = _takeTransactionId();
      final frame = _framing.encodeFrame(
        unitId: options.unitId,
        pdu: pdu,
        transactionId: transactionId,
      );
      final attempt = _PendingAttempt(
        transactionId: transactionId,
        unitId: options.unitId,
        number: number,
      );
      _pending = isBroadcast ? null : attempt;
      final roundTrip = Stopwatch()..start();
      try {
        await _channel.write(frame);
      } on Object catch (e) {
        _pending = null;
        final error = e is ModbusConnectionException
            ? e
            : ModbusConnectionException('Write failed: $e', cause: e);
        record(error: error);
        throw error;
      }
      _lineQuiet.reset();
      _emitFrame(FrameDirection.tx, frame, transactionNumber: number);

      if (isBroadcast) {
        // Devices need the turnaround time to process a broadcast.
        await Future<void>.delayed(interFrameDelay);
        const response = NoResponseExpected();
        record(response: response);
        return response;
      }

      final ModbusResponse response;
      try {
        final pduBytes = await attempt.completer.future.timeout(
          options.timeout,
        );
        latency = roundTrip.elapsed;
        response = PduCodec.decodeResponse(request, pduBytes);
      } on TimeoutException {
        lastError = ModbusTimeoutException(
          timeout: options.timeout,
          attempts: attempts,
        );
        continue;
      } on ModbusProtocolException catch (e) {
        lastError = e;
        continue;
      } on ModbusConnectionException catch (e) {
        record(error: e);
        rethrow;
      } finally {
        if (identical(_pending, attempt)) _pending = null;
      }

      if (response case ExceptionResponse(:final exceptionCode)) {
        final error = ModbusDeviceException(
          functionCode: request.functionCode.code,
          exceptionCode: exceptionCode,
        );
        record(response: response, error: error);
        throw error;
      }
      record(response: response);
      return response;
    }

    final error = switch (lastError) {
      ModbusTimeoutException() => ModbusTimeoutException(
        timeout: options.timeout,
        attempts: attempts,
      ),
      final e? => e,
      null => ModbusTimeoutException(
        timeout: options.timeout,
        attempts: attempts,
      ),
    };
    record(error: error);
    throw error;
  }

  // ------------------------------------------------------------ convenience

  Future<List<bool>> readCoils(int address, int count, {int? unitId}) =>
      _bits(RegisterTable.coils, address, count, unitId);

  Future<List<bool>> readDiscreteInputs(
    int address,
    int count, {
    int? unitId,
  }) => _bits(RegisterTable.discreteInputs, address, count, unitId);

  Future<List<int>> readHoldingRegisters(
    int address,
    int count, {
    int? unitId,
  }) => _registers(RegisterTable.holdingRegisters, address, count, unitId);

  Future<List<int>> readInputRegisters(int address, int count, {int? unitId}) =>
      _registers(RegisterTable.inputRegisters, address, count, unitId);

  Future<void> writeSingleCoil(
    int address, {
    required bool value,
    int? unitId,
  }) => execute(
    WriteSingleCoilRequest(address: address, value: value),
    unitId: unitId,
  );

  Future<void> writeSingleRegister(int address, int value, {int? unitId}) =>
      execute(
        WriteSingleRegisterRequest(address: address, value: value),
        unitId: unitId,
      );

  Future<void> writeMultipleCoils(
    int address,
    List<bool> values, {
    int? unitId,
  }) => execute(
    WriteMultipleCoilsRequest(address: address, values: values),
    unitId: unitId,
  );

  Future<void> writeMultipleRegisters(
    int address,
    List<int> values, {
    int? unitId,
  }) => execute(
    WriteMultipleRegistersRequest(address: address, values: values),
    unitId: unitId,
  );

  Future<void> maskWriteRegister(
    int address, {
    required int andMask,
    required int orMask,
    int? unitId,
  }) => execute(
    MaskWriteRegisterRequest(
      address: address,
      andMask: andMask,
      orMask: orMask,
    ),
    unitId: unitId,
  );

  Future<List<int>> readWriteMultipleRegisters({
    required int readAddress,
    required int readCount,
    required int writeAddress,
    required List<int> writeValues,
    int? unitId,
  }) async {
    final response = await execute(
      ReadWriteMultipleRegistersRequest(
        readAddress: readAddress,
        readCount: readCount,
        writeAddress: writeAddress,
        writeValues: writeValues,
      ),
      unitId: unitId,
    );
    return (response as ReadRegistersResponse).values;
  }

  Future<DeviceIdentificationResponse> readDeviceIdentification({
    DeviceIdCategory category = DeviceIdCategory.basic,
    int objectId = 0,
    int? unitId,
  }) async => await execute(
    ReadDeviceIdentificationRequest(category: category, objectId: objectId),
    unitId: unitId,
  ) as DeviceIdentificationResponse;

  Future<List<bool>> _bits(
    RegisterTable table,
    int address,
    int count,
    int? unitId,
  ) async {
    final response = await execute(
      ReadBitsRequest(table: table, address: address, count: count),
      unitId: unitId,
    );
    return (response as ReadBitsResponse).values;
  }

  Future<List<int>> _registers(
    RegisterTable table,
    int address,
    int count,
    int? unitId,
  ) async {
    final response = await execute(
      ReadRegistersRequest(table: table, address: address, count: count),
      unitId: unitId,
    );
    return (response as ReadRegistersResponse).values;
  }

  // ---------------------------------------------------------------- internals

  Future<void> close() async {
    if (_frames.isClosed) return;
    await _subscription.cancel();
    await _channel.close();
    _onChannelClosed();
    _silenceTimer?.cancel();
    await _frames.close();
    await _transactions.close();
  }

  int _takeTransactionId() {
    final id = _nextTransactionId;
    _nextTransactionId = id == 0xFFFF ? 1 : id + 1;
    return id;
  }

  Future<void> _waitForQuietLine() async {
    final remaining = interFrameDelay - _lineQuiet.elapsed;
    if (remaining > Duration.zero) await Future<void>.delayed(remaining);
  }

  /// Leftover bytes from a late or broken answer would corrupt the next
  /// response; log them and start clean.
  void _discardStaleBytes() => _assembler
      .flush()
      .whereType<FramingError>()
      .forEach((event) => _emitFramingEvent(event, transactionNumber: null));

  void _onBytes(Uint8List bytes) {
    _lineQuiet.reset();
    _assembler.addBytes(bytes).forEach(_handleEvent);
    _silenceTimer?.cancel();
    if (_assembler.hasPendingBytes) {
      _silenceTimer = Timer(
        silenceTimeout,
        () => _assembler.flush().forEach(_handleEvent),
      );
    }
  }

  void _handleEvent(FramingEvent event) {
    final pending = _pending;
    switch (event) {
      case DecodedFrame():
        final matches =
            pending != null &&
            !pending.completer.isCompleted &&
            switch (_framing.kind) {
              FrameKind.tcp => event.transactionId == pending.transactionId,
              FrameKind.rtu => event.unitId == pending.unitId,
            };
        _emitFrame(
          FrameDirection.rx,
          event.raw,
          status: matches ? FrameStatus.ok : FrameStatus.unexpected,
          transactionNumber: matches ? pending.number : null,
        );
        if (matches) pending.completer.complete(event.pdu);
      case FramingError():
        _emitFramingEvent(event, transactionNumber: pending?.number);
        if (pending != null && !pending.completer.isCompleted) {
          // Fail fast instead of waiting for the timeout; the attempt is
          // retried like a timeout.
          pending.completer.completeError(
            ModbusProtocolException(
              _framingErrorText(event.kind),
              frame: event.raw,
            ),
          );
        }
    }
  }

  void _emitFramingEvent(
    FramingError event, {
    required int? transactionNumber,
  }) {
    _emitFrame(
      FrameDirection.rx,
      event.raw,
      status: switch (event.kind) {
        FramingErrorKind.crcMismatch => FrameStatus.crcError,
        FramingErrorKind.incompleteFrame => FrameStatus.incomplete,
        FramingErrorKind.invalidHeader ||
        FramingErrorKind.unknownFunctionCode ||
        FramingErrorKind.frameTooLong => FrameStatus.malformed,
      },
      transactionNumber: transactionNumber,
    );
  }

  void _emitFrame(
    FrameDirection direction,
    Uint8List bytes, {
    FrameStatus status = FrameStatus.ok,
    int? transactionNumber,
  }) {
    if (_frames.isClosed) return;
    _frames.add(
      FrameEvent(
        timestamp: _clock(),
        direction: direction,
        kind: _framing.kind,
        bytes: bytes,
        status: status,
        transactionNumber: transactionNumber,
      ),
    );
  }

  void _onChannelClosed() {
    if (_closed) return;
    _closed = true;
    final pending = _pending;
    if (pending != null && !pending.completer.isCompleted) {
      pending.completer.completeError(
        const ModbusConnectionException('Connection closed by peer'),
      );
    }
    if (!_done.isCompleted) _done.complete();
  }

  static String _framingErrorText(FramingErrorKind kind) => switch (kind) {
    FramingErrorKind.crcMismatch => 'CRC mismatch',
    FramingErrorKind.invalidHeader => 'Invalid MBAP header',
    FramingErrorKind.unknownFunctionCode => 'Unknown function code in response',
    FramingErrorKind.incompleteFrame => 'Incomplete frame',
    FramingErrorKind.frameTooLong => 'Frame too long',
  };
}

final class _PendingAttempt {
  new({
    required this.transactionId,
    required this.unitId,
    required this.number,
  });

  final int transactionId;
  final int unitId;
  final int number;
  final completer = Completer<Uint8List>();
}
