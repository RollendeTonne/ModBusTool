import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

/// What a payload most likely is.
enum PayloadKind { empty, json, xml, text, base64, binary }

/// Where a JSON/XML document is broken, 1-based line/column.
@immutable
final class SyntaxIssue {
  const new({
    required this.message,
    required this.offset,
    required this.line,
    required this.column,
  });

  /// Location of [offset] in [text].
  factory at(String text, int offset, String message) {
    final clamped = offset.clamp(0, text.length);
    final before = text.substring(0, clamped);
    final line = '\n'.allMatches(before).length + 1;
    final lineStart = before.lastIndexOf('\n') + 1;
    return SyntaxIssue(
      message: message,
      offset: clamped,
      line: line,
      column: clamped - lineStart + 1,
    );
  }

  final String message;
  final int offset;
  final int line;
  final int column;

  /// The broken line of [text].
  String lineOf(String text) {
    final lines = text.split('\n');
    return line - 1 < lines.length ? lines[line - 1] : '';
  }
}

/// Result of [analyzePayload]. Computed once per message (see
/// [analyzeCached]); large payloads are not re-parsed on every rebuild.
@immutable
final class PayloadAnalysis {
  const new({
    required this.kind,
    this.text,
    this.json,
    this.syntaxIssue,
    this.base64Decoded,
  });

  final PayloadKind kind;

  /// Strict UTF-8 decoding, `null` for invalid UTF-8.
  final String? text;

  /// Parsed JSON (object or array) for [PayloadKind.json] without error.
  final Object? json;

  /// JSON/XML that looks like a document but does not parse.
  final SyntaxIssue? syntaxIssue;

  /// Bytes behind a [PayloadKind.base64] text.
  final Uint8List? base64Decoded;

  bool get isJsonValid => kind == PayloadKind.json && syntaxIssue == null;
}

final _cache = Expando<PayloadAnalysis>('payloadAnalysis');

/// [analyzePayload] memoized per payload instance.
PayloadAnalysis analyzeCached(Uint8List payload, {String? contentType}) =>
    _cache[payload] ??= analyzePayload(payload, contentType: contentType);

final _base64Chars = RegExp(r'^[A-Za-z0-9+/]+={0,2}$');
final _xmlStart = RegExp('^<[?!A-Za-z_]');
final _controlChars = RegExp('[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]');

/// Auto-detection, in this order: empty, invalid UTF-8 or control
/// characters → binary; `{`/`[` (or content type JSON) → JSON, also when
/// broken (with location); `<tag` → XML; Base64 text → Base64; else text.
PayloadAnalysis analyzePayload(Uint8List payload, {String? contentType}) {
  if (payload.isEmpty) return const PayloadAnalysis(kind: PayloadKind.empty);
  final String text;
  try {
    text = utf8.decode(payload);
  } on FormatException {
    return const PayloadAnalysis(kind: PayloadKind.binary);
  }
  if (_controlChars.hasMatch(text)) {
    return PayloadAnalysis(kind: PayloadKind.binary, text: text);
  }
  final trimmed = text.trim();
  final declaredJson = contentType?.toLowerCase().contains('json') ?? false;
  if (trimmed.startsWith('{') || trimmed.startsWith('[') || declaredJson) {
    try {
      final value = jsonDecode(text);
      // Bare numbers/strings are valid JSON but read better as text.
      if (value is Map || value is List || declaredJson) {
        return PayloadAnalysis(kind: PayloadKind.json, text: text, json: value);
      }
    } on FormatException catch (e) {
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        return PayloadAnalysis(
          kind: PayloadKind.json,
          text: text,
          syntaxIssue: SyntaxIssue.at(text, e.offset ?? 0, e.message),
        );
      }
    }
  }
  if (_xmlStart.hasMatch(trimmed) && trimmed.endsWith('>')) {
    return PayloadAnalysis(
      kind: PayloadKind.xml,
      text: text,
      syntaxIssue: checkXml(text),
    );
  }
  final base64 = _tryBase64(trimmed);
  if (base64 != null) {
    return PayloadAnalysis(
      kind: PayloadKind.base64,
      text: text,
      base64Decoded: base64,
    );
  }
  return PayloadAnalysis(kind: PayloadKind.text, text: text);
}

/// Base64 only when it is very likely: valid alphabet and length, at least
/// 8 characters, and either padding or a mix of upper case, lower case and
/// digits/`+`/`/` – so words, numbers and hex strings stay text.
Uint8List? _tryBase64(String s) {
  if (s.length < 8 || s.length % 4 != 0 || !_base64Chars.hasMatch(s)) {
    return null;
  }
  final padded = s.endsWith('=');
  final mixed =
      s.contains(RegExp('[A-Z]')) &&
      s.contains(RegExp('[a-z]')) &&
      s.contains(RegExp('[0-9+/]'));
  if (!padded && !mixed) return null;
  try {
    return base64.decode(s);
  } on FormatException {
    return null;
  }
}

/// Minimal well-formedness check: tags balanced and properly nested,
/// one root element. No DTD/namespace validation.
SyntaxIssue? checkXml(String text) {
  final tag = RegExp(
    r'<(/?)([A-Za-z_][\w.\-:]*)[^>]*?(/?)>|<\?.*?\?>|<!--.*?-->|<!\[CDATA\[.*?\]\]>|<![^>]*>',
    dotAll: true,
  );
  final stack = <(String, int)>[];
  var roots = 0;
  for (final m in tag.allMatches(text)) {
    final name = m.group(2);
    if (name == null) continue; // declaration, comment, CDATA
    final closing = m.group(1) == '/';
    final selfClosing = m.group(3) == '/';
    if (closing) {
      if (stack.isEmpty || stack.last.$1 != name) {
        final expected = stack.isEmpty ? null : stack.last.$1;
        return SyntaxIssue.at(
          text,
          m.start,
          expected == null
              ? 'Unexpected closing tag </$name>'
              : 'Expected </$expected>, found </$name>',
        );
      }
      stack.removeLast();
    } else {
      if (stack.isEmpty) roots++;
      if (roots > 1) {
        return SyntaxIssue.at(text, m.start, 'More than one root element');
      }
      if (!selfClosing) stack.add((name, m.start));
    }
  }
  if (stack.isNotEmpty) {
    return SyntaxIssue.at(
      text,
      stack.last.$2,
      'Element <${stack.last.$1}> is not closed',
    );
  }
  return null;
}

/// Indents XML by element depth (one element/text per line). Leaves the
/// input unchanged if it is not well-formed.
String prettyXml(String text) {
  if (checkXml(text) != null) return text;
  final tokens = RegExp('<[^>]+>|[^<]+').allMatches(text.trim());
  final out = StringBuffer();
  var depth = 0;
  for (final t in tokens) {
    final token = t[0]!.trim();
    if (token.isEmpty) continue;
    final closing = token.startsWith('</');
    final opening =
        token.startsWith('<') &&
        !closing &&
        !token.endsWith('/>') &&
        !token.startsWith('<?') &&
        !token.startsWith('<!');
    if (closing) depth = (depth - 1).clamp(0, 1 << 20);
    out
      ..write('  ' * depth)
      ..writeln(token);
    if (opening) depth++;
  }
  return out.toString().trimRight();
}

// ---------------------------------------------------------------- JSON path

/// `$.sensor.temp`, `$.list[2]`, `$['key with space']` (JSONPath notation).
String jsonPath(List<Object> segments) {
  final out = StringBuffer(r'$');
  final identifier = RegExp(r'^[A-Za-z_$][A-Za-z0-9_$]*$');
  for (final s in segments) {
    if (s is int) {
      out.write('[$s]');
    } else if (identifier.hasMatch('$s')) {
      out.write('.$s');
    } else {
      out.write("['${'$s'.replaceAll(r'\', r'\\').replaceAll("'", r"\'")}']");
    }
  }
  return out.toString();
}

/// Parses what [jsonPath] produces; `null` for anything else.
List<Object>? parseJsonPath(String path) {
  if (!path.startsWith(r'$')) return null;
  final segments = <Object>[];
  final token = RegExp(
    r"""\.([A-Za-z_$][A-Za-z0-9_$]*)|\[(\d+)\]|\['((?:[^'\\]|\\.)*)'\]""",
  );
  var position = 1;
  while (position < path.length) {
    final m = token.matchAsPrefix(path, position);
    if (m == null) return null;
    if (m.group(1) != null) {
      segments.add(m.group(1)!);
    } else if (m.group(2) != null) {
      segments.add(int.parse(m.group(2)!));
    } else {
      segments.add(
        m.group(3)!.replaceAllMapped(RegExp(r'\\(.)'), (x) => x.group(1)!),
      );
    }
    position = m.end;
  }
  return segments;
}

/// Value at [segments] in [json]; `(false, null)` if the path does not
/// exist (distinguishes a missing key from an explicit `null`).
(bool, Object?) valueAt(Object? json, List<Object> segments) {
  var current = json;
  for (final s in segments) {
    if (s is int && current is List && s >= 0 && s < current.length) {
      current = current[s];
    } else if (s is String && current is Map && current.containsKey(s)) {
      current = current[s];
    } else {
      return (false, null);
    }
  }
  return (true, current);
}

// ------------------------------------------------------------------- text

enum TextEncoding { utf8, ascii, latin1 }

/// Decodes for display: invalid UTF-8 and non-ASCII bytes become U+FFFD.
String decodeText(Uint8List bytes, TextEncoding encoding) => switch (encoding) {
  TextEncoding.utf8 => utf8.decode(bytes, allowMalformed: true),
  TextEncoding.ascii => String.fromCharCodes(
    bytes.map((b) => b < 0x80 ? b : 0xFFFD),
  ),
  TextEncoding.latin1 => latin1.decode(bytes),
};

// --------------------------------------------------------------- hex dump

@immutable
final class HexDumpLine {
  const new(this.offset, this.hex, this.ascii);

  final int offset;

  /// `48 65 6C …`, padded to the full line width.
  final String hex;

  /// Printable ASCII, `.` for everything else.
  final String ascii;

  String get offsetLabel =>
      offset.toRadixString(16).padLeft(8, '0').toUpperCase();
}

/// Classic hex dump; [maxLines] bounds very large payloads.
List<HexDumpLine> hexDump(
  Uint8List bytes, {
  int bytesPerLine = 16,
  int? maxLines,
}) {
  final lines = <HexDumpLine>[];
  for (var offset = 0; offset < bytes.length; offset += bytesPerLine) {
    if (maxLines != null && lines.length >= maxLines) break;
    final end = (offset + bytesPerLine).clamp(0, bytes.length);
    final chunk = bytes.sublist(offset, end);
    final hex = List.generate(
      bytesPerLine,
      (i) => i < chunk.length
          ? chunk[i].toRadixString(16).padLeft(2, '0').toUpperCase()
          : '  ',
    );
    // Extra gap after 8 bytes for readability.
    final hexText = bytesPerLine == 16
        ? '${hex.sublist(0, 8).join(' ')}  ${hex.sublist(8).join(' ')}'
        : hex.join(' ');
    final ascii = String.fromCharCodes(
      chunk.map((b) => b >= 0x20 && b < 0x7F ? b : 0x2E),
    );
    lines.add(HexDumpLine(offset, hexText, ascii));
  }
  return lines;
}

// ----------------------------------------------------------------- binary

/// Bytes of [payload] from [offset], at most [length] (null = to the end).
Uint8List byteWindow(Uint8List payload, int offset, [int? length]) {
  final start = offset.clamp(0, payload.length);
  final end = length == null
      ? payload.length
      : (start + length).clamp(start, payload.length);
  return Uint8List.sublistView(payload, start, end);
}

/// `(int8, uint8)` of the byte at [offset], `null` past the end. The shared
/// engine starts at 16 bit (Modbus registers); single bytes need no byte
/// order.
(int, int)? byteValues(Uint8List payload, int offset) {
  if (offset < 0 || offset >= payload.length) return null;
  final b = payload[offset];
  return (b >= 0x80 ? b - 0x100 : b, b);
}

/// Bits of [count] bytes from [offset], most significant bit first:
/// `[[1,0,0,…], …]` one list per byte.
List<List<int>> bitsOf(Uint8List payload, int offset, int count) => [
  for (var i = offset; i < offset + count && i < payload.length; i++)
    [for (var bit = 7; bit >= 0; bit--) (payload[i] >> bit) & 1],
];
