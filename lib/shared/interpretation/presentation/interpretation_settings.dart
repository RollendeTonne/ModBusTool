import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:modbus_explorer/shared/interpretation/domain/scaling.dart';
import 'package:modbus_explorer/shared/interpretation/domain/text_decoder.dart';

/// Session settings of the interpretation panel.
@immutable
final class InterpretationSettings {
  const new({
    this.scaling = Scaling.identity,
    this.textSwapBytes = false,
    this.textEncoding = TextEncoding.ascii,
  });

  final Scaling scaling;
  final bool textSwapBytes;
  final TextEncoding textEncoding;

  InterpretationSettings copyWith({
    Scaling? scaling,
    bool? textSwapBytes,
    TextEncoding? textEncoding,
  }) => InterpretationSettings(
    scaling: scaling ?? this.scaling,
    textSwapBytes: textSwapBytes ?? this.textSwapBytes,
    textEncoding: textEncoding ?? this.textEncoding,
  );
}

final class InterpretationSettingsController
    extends Notifier<InterpretationSettings> {
  @override
  InterpretationSettings build() => const InterpretationSettings();

  void setScaling(Scaling scaling) => state = state.copyWith(scaling: scaling);

  void setTextSwapBytes({required bool swap}) =>
      state = state.copyWith(textSwapBytes: swap);

  void setTextEncoding(TextEncoding encoding) =>
      state = state.copyWith(textEncoding: encoding);
}

final interpretationSettingsProvider =
    NotifierProvider<InterpretationSettingsController, InterpretationSettings>(
      InterpretationSettingsController.new,
    );
