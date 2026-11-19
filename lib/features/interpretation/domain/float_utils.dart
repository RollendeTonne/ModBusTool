import 'dart:typed_data';

final _float32Buffer = Float32List(1);

/// Rounds a double to the nearest float32.
double toFloat32(double value) {
  _float32Buffer[0] = value;
  return _float32Buffer[0];
}

/// Smallest normal magnitudes; anything non-zero below is subnormal.
const minNormalFloat32 = 1.1754943508222875e-38;
const minNormalFloat64 = 2.2250738585072014e-308;
