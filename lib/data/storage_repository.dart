import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StorageRepository {
  StorageRepository._();
  static final StorageRepository instance = StorageRepository._();

  String? _docsPath;

  Future<String> _basePath() async {
    _docsPath ??= (await getApplicationDocumentsDirectory()).path;
    return _docsPath!;
  }

  Future<String> localFilePath(String relativePath) async {
    return _safePath(await _basePath(), relativePath);
  }

  Future<bool> allFilesExist(List<String> relativePaths) async {
    final base = await _basePath();
    for (final rel in relativePaths) {
      if (!File(_safePath(base, rel)).existsSync()) return false;
    }
    return true;
  }

  String _safePath(String base, String relativePath) {
    final resolved = p.normalize('$base/scripture/$relativePath');
    if (!resolved.startsWith('$base/scripture')) {
      throw ArgumentError('Invalid scripture path: $relativePath');
    }
    return resolved;
  }

  // Downloads a single file from Firebase Storage to local storage.
  // No-ops if the file already exists locally.
  Future<void> downloadFile(String relativePath) async {
    final base = await _basePath();
    final localFile = File(_safePath(base, relativePath));
    if (await localFile.exists()) return;
    await localFile.parent.create(recursive: true);
    final ref = FirebaseStorage.instance.ref('scripture/$relativePath');
    await ref.writeToFile(localFile);
  }
}
