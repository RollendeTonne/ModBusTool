import 'package:modbus_explorer/core/files/file_exchange.dart';

/// Records saved documents and serves a queue of files to "open".
final class FakeFileExchange implements FileExchange {
  final saved = <({String name, String content, ExchangeFileType type})>[];
  final toOpen = <OpenedTextFile>[];

  @override
  Future<OpenedTextFile?> openText(List<ExchangeFileType> types) async =>
      toOpen.isEmpty ? null : toOpen.removeAt(0);

  @override
  Future<bool> saveText({
    required String suggestedName,
    required String content,
    required ExchangeFileType type,
  }) async {
    saved.add((name: suggestedName, content: content, type: type));
    return true;
  }
}
