/// Numeric/temporal interpretations that span a fixed number of bytes.
///
/// Variable-length text is handled separately by `decodeText`.
enum DataType {
  int16('INT16', 2),
  uint16('UINT16', 2),
  int32('INT32', 4),
  uint32('UINT32', 4),
  float32('FLOAT32', 4),
  int64('INT64', 8),
  uint64('UINT64', 8),
  float64('FLOAT64', 8),
  bcd16('BCD16', 2),
  bcd32('BCD32', 4),

  /// Seconds since 1970-01-01 UTC, unsigned.
  unixTime32('UNIX32 (s)', 4),

  /// Milliseconds since 1970-01-01 UTC, signed – the common 64-bit variant
  /// (Java/JS epoch millis); seconds would fit in 32 bit anyway.
  unixTime64Ms('UNIX64 (ms)', 8);

  new(this.technicalName, this.byteWidth);

  /// Language-neutral name shown in the matrix.
  final String technicalName;
  final int byteWidth;

  int get registerCount => byteWidth ~/ 2;

  bool get isFloat => this == float32 || this == float64;
}
