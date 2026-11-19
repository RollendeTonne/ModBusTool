import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Two panes side by side with a draggable divider (mouse, touch and
/// keyboard: focus the handle and use the arrow keys).
class ResizableSplit extends StatefulWidget {
  const new({
    required this.first,
    required this.second,
    this.initialFraction = 0.5,
    this.minFirst = 280,
    this.minSecond = 320,
    this.semanticLabel,
    super.key,
  });

  final Widget first;
  final Widget second;
  final double initialFraction;
  final double minFirst;
  final double minSecond;
  final String? semanticLabel;

  @override
  State<ResizableSplit> createState() => _ResizableSplitState();
}

class _ResizableSplitState extends State<ResizableSplit> {
  static const _handleWidth = 12.0;
  static const _keyboardStep = 0.03;

  late double _fraction = widget.initialFraction;
  bool _hovering = false;

  double _clamp(double fraction, double width) {
    final available = width - _handleWidth;
    if (available <= widget.minFirst + widget.minSecond) return 0.5;
    final min = widget.minFirst / available;
    final max = 1 - widget.minSecond / available;
    return fraction.clamp(min, max);
  }

  static String _percent(double fraction) => '${(fraction * 100).round()} %';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final fraction = _clamp(_fraction, width);
        final firstWidth = (width - _handleWidth) * fraction;

        void move(double delta) =>
            setState(() => _fraction = _clamp(fraction + delta, width));

        return Row(
          children: [
            SizedBox(width: firstWidth, child: widget.first),
            Semantics(
              label: widget.semanticLabel,
              slider: true,
              value: _percent(fraction),
              increasedValue: _percent(_clamp(fraction + _keyboardStep, width)),
              decreasedValue: _percent(_clamp(fraction - _keyboardStep, width)),
              onIncrease: () => move(_keyboardStep),
              onDecrease: () => move(-_keyboardStep),
              child: FocusableActionDetector(
                mouseCursor: SystemMouseCursors.resizeColumn,
                onShowHoverHighlight: (v) => setState(() => _hovering = v),
                shortcuts: const {
                  SingleActivator(LogicalKeyboardKey.arrowLeft): _MoveIntent(
                    -_keyboardStep,
                  ),
                  SingleActivator(LogicalKeyboardKey.arrowRight): _MoveIntent(
                    _keyboardStep,
                  ),
                },
                actions: {
                  _MoveIntent: CallbackAction<_MoveIntent>(
                    onInvoke: (intent) {
                      move(intent.delta);
                      return null;
                    },
                  ),
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (d) => move(d.delta.dx / width),
                  child: SizedBox(
                    width: _handleWidth,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        width: _hovering ? 4 : 1,
                        color: _hovering
                            ? scheme.primary
                            : scheme.outlineVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: widget.second),
          ],
        );
      },
    );
  }
}

class _MoveIntent extends Intent {
  const new(this.delta);

  final double delta;
}
