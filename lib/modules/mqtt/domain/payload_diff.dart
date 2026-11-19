import 'dart:math';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:modbus_explorer/modules/mqtt/domain/payload_analysis.dart';

enum ChangeKind { added, removed, changed }

/// One difference between two JSON documents.
@immutable
final class JsonChange {
  const new(this.kind, this.path, {this.before, this.after});

  final ChangeKind kind;
  final List<Object> path;
  final Object? before;
  final Object? after;

  String get pathText => jsonPath(path);
}

/// Structural differences, depth first; maps by key (sorted), lists by
/// index. A type change (e.g. number → object) is one `changed` entry.
List<JsonChange> diffJson(
  Object? a,
  Object? b, [
  List<Object> path = const [],
]) {
  if (a is Map && b is Map) {
    final keys = {...a.keys, ...b.keys}.map((k) => '$k').toList()..sort();
    return [
      for (final key in keys)
        if (!a.containsKey(key))
          JsonChange(ChangeKind.added, [...path, key], after: b[key])
        else if (!b.containsKey(key))
          JsonChange(ChangeKind.removed, [...path, key], before: a[key])
        else
          ...diffJson(a[key], b[key], [...path, key]),
    ];
  }
  if (a is List && b is List) {
    return [
      for (var i = 0; i < max(a.length, b.length); i++)
        if (i >= a.length)
          JsonChange(ChangeKind.added, [...path, i], after: b[i])
        else if (i >= b.length)
          JsonChange(ChangeKind.removed, [...path, i], before: a[i])
        else
          ...diffJson(a[i], b[i], [...path, i]),
    ];
  }
  if (a is Map || a is List || b is Map || b is List || a != b) {
    return [JsonChange(ChangeKind.changed, path, before: a, after: b)];
  }
  return const [];
}

enum LineOp { same, added, removed }

@immutable
final class DiffLine {
  const new(this.op, this.text);

  final LineOp op;
  final String text;
}

/// Line diff via longest common subsequence. Inputs beyond [maxCells]
/// (lines × lines) fall back to "all removed, all added".
List<DiffLine> diffLines(String a, String b, {int maxCells = 4000000}) {
  final x = a.split('\n');
  final y = b.split('\n');
  if (x.length * y.length > maxCells) {
    return [
      for (final l in x) DiffLine(LineOp.removed, l),
      for (final l in y) DiffLine(LineOp.added, l),
    ];
  }
  // lcs[i][j] = LCS length of x[i..] and y[j..].
  final lcs = List.generate(x.length + 1, (_) => Uint32List(y.length + 1));
  for (var i = x.length - 1; i >= 0; i--) {
    for (var j = y.length - 1; j >= 0; j--) {
      lcs[i][j] = x[i] == y[j]
          ? lcs[i + 1][j + 1] + 1
          : max(lcs[i + 1][j], lcs[i][j + 1]);
    }
  }
  final out = <DiffLine>[];
  var i = 0;
  var j = 0;
  while (i < x.length && j < y.length) {
    if (x[i] == y[j]) {
      out.add(DiffLine(LineOp.same, x[i]));
      i++;
      j++;
    } else if (lcs[i + 1][j] >= lcs[i][j + 1]) {
      out.add(DiffLine(LineOp.removed, x[i++]));
    } else {
      out.add(DiffLine(LineOp.added, y[j++]));
    }
  }
  for (; i < x.length; i++) {
    out.add(DiffLine(LineOp.removed, x[i]));
  }
  for (; j < y.length; j++) {
    out.add(DiffLine(LineOp.added, y[j]));
  }
  return out;
}

/// A run of differing bytes at the same position.
@immutable
final class ByteChange {
  const new(this.offset, this.before, this.after);

  final int offset;

  /// Bytes of the first payload in this run (shorter at its end).
  final Uint8List before;
  final Uint8List after;
}

/// Position-wise comparison, contiguous differences merged; at most
/// [maxRuns] runs.
List<ByteChange> diffBytes(Uint8List a, Uint8List b, {int maxRuns = 500}) {
  final runs = <ByteChange>[];
  final length = max(a.length, b.length);
  var i = 0;
  while (i < length && runs.length < maxRuns) {
    bool differs(int k) => k >= a.length || k >= b.length || a[k] != b[k];
    if (!differs(i)) {
      i++;
      continue;
    }
    final start = i;
    while (i < length && differs(i)) {
      i++;
    }
    runs.add(
      ByteChange(
        start,
        Uint8List.sublistView(a, min(start, a.length), min(i, a.length)),
        Uint8List.sublistView(b, min(start, b.length), min(i, b.length)),
      ),
    );
  }
  return runs;
}

enum DiffMode { json, text, bytes }

/// Picks the comparison that fits both payloads: JSON if both are valid
/// JSON, text if both are text, otherwise bytes.
DiffMode diffModeFor(Uint8List a, Uint8List b) {
  final x = analyzeCached(a);
  final y = analyzeCached(b);
  if (x.isJsonValid && y.isJsonValid) return DiffMode.json;
  bool isText(PayloadAnalysis p) =>
      p.text != null &&
      p.kind != PayloadKind.binary &&
      p.kind != PayloadKind.empty;
  if ((isText(x) || a.isEmpty) && (isText(y) || b.isEmpty)) {
    return DiffMode.text;
  }
  return DiffMode.bytes;
}
