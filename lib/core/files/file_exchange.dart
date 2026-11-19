import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

@immutable
final class ExchangeFileType {
  const new({
    required this.label,
    required this.extension,
    required this.mimeType,
    required this.uti,
  });

  static const json = ExchangeFileType(
    label: 'JSON',
    extension: 'json',
    mimeType: 'application/json',
    uti: 'public.json',
  );
  static const csv = ExchangeFileType(
    label: 'CSV',
    extension: 'csv',
    mimeType: 'text/csv',
    uti: 'public.comma-separated-values-text',
  );
  static const text = ExchangeFileType(
    label: 'Text',
    extension: 'txt',
    mimeType: 'text/plain',
    uti: 'public.plain-text',
  );

  final String label;
  final String extension;
  final String mimeType;

  /// macOS/iOS uniform type identifier.
  final String uti;

  XTypeGroup get typeGroup => XTypeGroup(
    label: label,
    extensions: [extension],
    mimeTypes: [mimeType],
    uniformTypeIdentifiers: [uti],
  );
}

@immutable
final class OpenedTextFile {
  const new({required this.name, required this.content});

  final String name;
  final String content;

  String get extension {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  }
}

/// Opening and saving text documents, independent of platform dialogs.
abstract interface class FileExchange {
  /// `null` if the user cancelled.
  Future<OpenedTextFile?> openText(List<ExchangeFileType> types);

  /// `false` if the user cancelled.
  Future<bool> saveText({
    required String suggestedName,
    required String content,
    required ExchangeFileType type,
  });
}

/// UTF-8 BOM so Excel detects the encoding of CSV files (umlauts in labels).
const _bom = '﻿';

String withBomFor(ExchangeFileType type, String content) =>
    type == ExchangeFileType.csv ? '$_bom$content' : content;

String stripBom(String content) =>
    content.startsWith(_bom) ? content.substring(1) : content;

/// Save dialogs on desktop; the share sheet on Android/iOS, which have no
/// "save as" dialog.
final class PlatformFileExchange implements FileExchange {
  const new();

  static bool get _hasSaveDialog => switch (defaultTargetPlatform) {
    TargetPlatform.macOS ||
    TargetPlatform.windows ||
    TargetPlatform.linux => true,
    _ => false,
  };

  @override
  Future<OpenedTextFile?> openText(List<ExchangeFileType> types) async {
    final file = await openFile(
      acceptedTypeGroups: [for (final t in types) t.typeGroup],
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return OpenedTextFile(
      name: file.name,
      content: stripBom(utf8.decode(bytes, allowMalformed: true)),
    );
  }

  @override
  Future<bool> saveText({
    required String suggestedName,
    required String content,
    required ExchangeFileType type,
  }) async {
    final bytes = Uint8List.fromList(utf8.encode(withBomFor(type, content)));
    if (_hasSaveDialog) {
      final location = await getSaveLocation(
        suggestedName: suggestedName,
        acceptedTypeGroups: [type.typeGroup],
      );
      if (location == null) return false;
      var path = location.path;
      if (!path.toLowerCase().endsWith('.${type.extension}')) {
        path = '$path.${type.extension}';
      }
      await File(path).writeAsBytes(bytes, flush: true);
      return true;
    }
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: type.mimeType)],
        fileNameOverrides: [suggestedName],
      ),
    );
    return result.status != ShareResultStatus.dismissed;
  }
}

final fileExchangeProvider = Provider<FileExchange>(
  (ref) => const PlatformFileExchange(),
);

/// `modbus-log_2026-11-19_1405` style names that sort chronologically.
String timestampedFileName(String base, String extension, [DateTime? now]) {
  final t = now ?? DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${base}_${t.year}-${two(t.month)}-${two(t.day)}_'
      '${two(t.hour)}${two(t.minute)}.$extension';
}
