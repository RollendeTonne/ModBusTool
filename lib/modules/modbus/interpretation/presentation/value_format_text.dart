import 'package:modbus_explorer/modules/modbus/interpretation/domain/register_map_entry.dart';

/// Compact technical description, e.g. `FLOAT32 ABCD`, `TEXT ×8 BA`.
String describeFormat(ValueFormat format) => switch (format) {
  NumericFormat(:final type, :final order) =>
    '${type.technicalName} ${order.pattern}',
  TextFormat(:final registerCount, :final swapBytes, :final encoding) =>
    'TEXT ×$registerCount ${swapBytes ? 'BA' : 'AB'} '
        '${encoding.name.toUpperCase()}',
  BitFormat(:final bit) => bit == null ? 'BIT' : 'BIT $bit',
};
