import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
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
    return '${await _basePath()}/scripture/$relativePath';
  }

  Future<bool> allFilesExist(List<String> relativePaths) async {
    final base = await _basePath();
    for (final p in relativePaths) {
      if (!File('$base/scripture/$p').existsSync()) return false;
    }
    return true;
  }

  // Downloads a single file from Firebase Storage to local storage.
  // No-ops if the file already exists locally.
  Future<void> downloadFile(String relativePath) async {
    final base = await _basePath();
    final localFile = File('$base/scripture/$relativePath');
    if (await localFile.exists()) return;
    await localFile.parent.create(recursive: true);
    final ref = FirebaseStorage.instance.ref('scripture/$relativePath');
    await ref.writeToFile(localFile);
  }
}
