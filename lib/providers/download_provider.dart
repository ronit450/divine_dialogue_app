import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/religion.dart';
import '../data/scripture_storage_map.dart';
import '../data/storage_repository.dart';

enum TextDownloadStatus { notDownloaded, downloading, downloaded, failed }

class DownloadInfo {
  final TextDownloadStatus status;
  final double progress; // 0.0–1.0, fraction of files downloaded

  const DownloadInfo({required this.status, this.progress = 0.0});

  DownloadInfo copyWith({TextDownloadStatus? status, double? progress}) => DownloadInfo(
    status: status ?? this.status,
    progress: progress ?? this.progress,
  );
}

final downloadProvider =
    StateNotifierProvider<DownloadNotifier, Map<String, DownloadInfo>>(
  (_) => DownloadNotifier(),
);

class DownloadNotifier extends StateNotifier<Map<String, DownloadInfo>> {
  DownloadNotifier() : super(const {}) {
    _init();
  }

  // Runs on startup — checks local filesystem for all known texts
  // and restores download state without hitting the network.
  Future<void> _init() async {
    final newState = <String, DownloadInfo>{};
    for (final textId in ScriptureStorageMap.allTextIds) {
      final files = ScriptureStorageMap.filesForText(textId);
      final allExist = await StorageRepository.instance.allFilesExist(files);
      newState[textId] = DownloadInfo(
        status: allExist ? TextDownloadStatus.downloaded : TextDownloadStatus.notDownloaded,
        progress: allExist ? 1.0 : 0.0,
      );
    }
    if (!mounted) return;
    state = newState;
  }

  // Kicks off background downloads for all texts of a religion.
  // Skips texts already downloaded or currently downloading.
  Future<void> downloadReligion(List<SacredTextModel> texts) async {
    for (final text in texts) {
      final info = state[text.id];
      if (info?.status == TextDownloadStatus.downloaded ||
          info?.status == TextDownloadStatus.downloading) {
        continue;
      }
      unawaited(_downloadText(text.id));
    }
  }

  void retryText(String textId) {
    if (state[textId]?.status == TextDownloadStatus.failed) {
      unawaited(_downloadText(textId));
    }
  }

  Future<void> _downloadText(String textId) async {
    final files = ScriptureStorageMap.filesForText(textId);
    if (files.isEmpty) return;
    _set(textId, TextDownloadStatus.downloading, 0.0);
    try {
      for (int i = 0; i < files.length; i++) {
        await StorageRepository.instance.downloadFile(files[i]);
        _set(textId, TextDownloadStatus.downloading, (i + 1) / files.length);
      }
      _set(textId, TextDownloadStatus.downloaded, 1.0);
    } on Exception catch (_) {
      _set(textId, TextDownloadStatus.failed, 0.0);
    }
  }

  void _set(String textId, TextDownloadStatus status, double progress) {
    if (!mounted) return;
    state = Map.from(state)..[textId] = DownloadInfo(status: status, progress: progress);
  }
}
