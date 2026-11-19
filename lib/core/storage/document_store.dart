import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stores named text documents (JSON) – profiles, register maps.
abstract interface class DocumentStore {
  Future<String?> read(String name);

  Future<void> write(String name, String content);
}

final class FileDocumentStore implements DocumentStore {
  new(this.directory);

  final Directory directory;

  File _file(String name) => File('${directory.path}/$name');

  @override
  Future<String?> read(String name) async {
    final file = _file(name);
    return file.existsSync() ? await file.readAsString() : null;
  }

  /// Write-then-rename so a crash never leaves a half-written file.
  @override
  Future<void> write(String name, String content) async {
    await directory.create(recursive: true);
    final target = _file(name);
    final temp = File('${target.path}.tmp');
    await temp.writeAsString(content, flush: true);
    await temp.rename(target.path);
  }
}

final class InMemoryDocumentStore implements DocumentStore {
  new([Map<String, String>? initial]) : documents = {...?initial};

  final Map<String, String> documents;

  @override
  Future<String?> read(String name) async => documents[name];

  @override
  Future<void> write(String name, String content) async =>
      documents[name] = content;
}

/// Must be overridden in `main` once the app directory is known.
final documentStoreProvider = Provider<DocumentStore>(
  (ref) => throw UnimplementedError('documentStoreProvider not overridden'),
);
