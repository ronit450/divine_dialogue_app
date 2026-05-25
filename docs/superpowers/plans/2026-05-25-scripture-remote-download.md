# Scripture Remote Download Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move all scripture JSON files from bundled Flutter assets to Firebase Storage, download them to local device storage on religion selection (in the background after onboarding), and show consistent download-status UI in the Library and Reader screens.

**Architecture:** A new `StorageRepository` handles Firebase Storage downloads to `{documentsDir}/scripture/`. A `DownloadProvider` (Riverpod) tracks per-textId download status and progress. `ScriptureRepository` gains a local-file reader that falls back to `rootBundle` during the migration period. The religion-change trigger lives in `app.dart` via `ref.listen` — no coupling between `ReligionNotifier` and download logic. UI in Library and Reader watches `downloadProvider` and shows consistent progress indicators using the religion accent color.

**Tech Stack:** Firebase Storage (`firebase_storage ^12.x`), `path_provider` (already in pubspec), Riverpod `StateNotifierProvider`, `dart:io` `File`, `LinearProgressIndicator` / `CircularProgressIndicator`.

---

## File Map

| Status | Path | Responsibility |
|---|---|---|
| **Create** | `lib/data/scripture_storage_map.dart` | Static map: textId → list of relative file paths |
| **Create** | `lib/data/storage_repository.dart` | Firebase Storage download + local file existence check |
| **Create** | `lib/providers/download_provider.dart` | Per-textId `DownloadInfo` state + background download logic |
| **Modify** | `lib/data/scripture_repository.dart` | Swap `rootBundle` for local file reader (rootBundle fallback kept until assets removed) |
| **Modify** | `lib/app.dart` | `ref.listen` on religionProvider to trigger background downloads on religion change |
| **Modify** | `lib/features/library/library_screen.dart` | Pass `DownloadInfo?` into `_HeroTextCard` and `_TextListTile`; show progress indicators |
| **Modify** | `lib/features/reader/reader_screen.dart` | Add `_waitingForDownload` flag; show downloading UI; auto-start `_load()` when download completes |
| **Modify** | `pubspec.yaml` | Add `firebase_storage`; (Task 9 only) remove bundled scripture asset declarations |

---

## Task 1: Add `firebase_storage` dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add the package**

Open `pubspec.yaml`. In the `dependencies:` block, after `cloud_firestore: ^5.6.12`, add:

```yaml
  firebase_storage: ^12.3.0
```

- [ ] **Step 2: Install**

```bash
flutter pub get
```

Expected: resolves without version conflicts. If there's a conflict, run `flutter pub outdated` and adjust the version to one compatible with `firebase_core ^3.x`.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add firebase_storage dependency"
```

---

## Task 2: Create `ScriptureStorageMap`

**Files:**
- Create: `lib/data/scripture_storage_map.dart`

This is a pure static mapping with no dependencies. It must match the actual filenames in `assets/data/scripture/` exactly, since they will be mirrored on Firebase Storage.

- [ ] **Step 1: Create the file**

```dart
class ScriptureStorageMap {
  ScriptureStorageMap._();

  static List<String> filesForText(String textId) => switch (textId) {
    'quran'              => const ['quran.json'],
    'bible_nrsv'         => const ['bible.json'],
    'bhagavad_gita'      => const ['gita.json'],
    'guru_granth_sahib'  => _chunks('ggs', 'ggs', 15),
    'dasam_granth'       => _chunks('dasam', 'dasam', 15),
    'bhai_gurdas_vaaran' => _chunks('bgv', 'bgv', 4),
    'valmiki_ramayana'   => _chunks('valmiki_ramayana', 'ramayana', 13),
    'bukhari'            => _chunks('bukhari', 'bukhari', 10),
    'muslim'             => _chunks('muslim', 'muslim', 6),
    'abu_dawud'          => _chunks('abu_dawud', 'abu_dawud', 5),
    'tirmidhi'           => _chunks('tirmidhi', 'tirmidhi', 5),
    'nasai'              => _chunks('nasai', 'nasai', 6),
    'ibn_majah'          => _chunks('ibn_majah', 'ibn_majah', 4),
    _                    => const [],
  };

  static List<String> _chunks(String dir, String prefix, int count) =>
      List.generate(count, (i) => '$dir/${prefix}_${i.toString().padLeft(3, '0')}.json');

  static const List<String> allTextIds = [
    'quran', 'bible_nrsv', 'bhagavad_gita',
    'guru_granth_sahib', 'dasam_granth', 'bhai_gurdas_vaaran',
    'valmiki_ramayana', 'bukhari', 'muslim', 'abu_dawud',
    'tirmidhi', 'nasai', 'ibn_majah',
  ];
}
```

- [ ] **Step 2: Verify chunk counts match reality**

```bash
ls assets/data/scripture/ggs/ | wc -l            # Expected: 15
ls assets/data/scripture/dasam/ | wc -l          # Expected: 15
ls assets/data/scripture/bgv/ | wc -l            # Expected: 4
ls assets/data/scripture/valmiki_ramayana/ | wc -l  # Expected: 13
ls assets/data/scripture/bukhari/ | wc -l        # Expected: 10
ls assets/data/scripture/muslim/ | wc -l         # Expected: 6
ls assets/data/scripture/abu_dawud/ | wc -l      # Expected: 5
ls assets/data/scripture/tirmidhi/ | wc -l       # Expected: 5
ls assets/data/scripture/nasai/ | wc -l          # Expected: 6
ls assets/data/scripture/ibn_majah/ | wc -l      # Expected: 4
```

If any count is off, update the corresponding number in `_chunks(...)` in `scripture_storage_map.dart`.

- [ ] **Step 3: Run analyzer**

```bash
dart analyze lib/data/scripture_storage_map.dart
```

Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add lib/data/scripture_storage_map.dart
git commit -m "feat: add ScriptureStorageMap — textId to file path mapping"
```

---

## Task 3: Create `StorageRepository`

**Files:**
- Create: `lib/data/storage_repository.dart`

- [ ] **Step 1: Create the file**

```dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

class StorageRepository {
  StorageRepository._();
  static final StorageRepository instance = StorageRepository._();

  Future<String> localFilePath(String relativePath) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/scripture/$relativePath';
  }

  Future<bool> allFilesExist(List<String> relativePaths) async {
    for (final p in relativePaths) {
      final path = await localFilePath(p);
      if (!File(path).existsSync()) return false;
    }
    return true;
  }

  // Downloads a single file from Firebase Storage to local storage.
  // No-ops if the file already exists locally.
  Future<void> downloadFile(String relativePath) async {
    final localPath = await localFilePath(relativePath);
    final localFile = File(localPath);
    if (await localFile.exists()) return;
    await localFile.parent.create(recursive: true);
    final ref = FirebaseStorage.instance.ref('scripture/$relativePath');
    await ref.writeToFile(localFile);
  }
}
```

- [ ] **Step 2: Analyze**

```bash
dart analyze lib/data/storage_repository.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/data/storage_repository.dart
git commit -m "feat: add StorageRepository — Firebase Storage download + local file management"
```

---

## Task 4: Create `DownloadProvider`

**Files:**
- Create: `lib/providers/download_provider.dart`

- [ ] **Step 1: Create the file**

```dart
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
    state = newState;
  }

  // Kicks off background downloads for all texts of a religion.
  // Skips texts already downloaded or currently downloading.
  Future<void> downloadReligion(List<SacredTextModel> texts) async {
    for (final text in texts) {
      final info = state[text.id];
      if (info?.status == TextDownloadStatus.downloaded ||
          info?.status == TextDownloadStatus.downloading) continue;
      unawaited(_downloadText(text.id));
    }
  }

  Future<void> retryText(String textId) async {
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
    } catch (_) {
      _set(textId, TextDownloadStatus.failed, 0.0);
    }
  }

  void _set(String textId, TextDownloadStatus status, double progress) {
    state = Map.from(state)..[textId] = DownloadInfo(status: status, progress: progress);
  }
}
```

- [ ] **Step 2: Analyze**

```bash
dart analyze lib/providers/download_provider.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/providers/download_provider.dart
git commit -m "feat: add DownloadProvider — per-text background download state management"
```

---

## Task 5: Modify `ScriptureRepository` to read local files

**Files:**
- Modify: `lib/data/scripture_repository.dart`

Add a `_readFile(relativePath)` helper that checks local documents directory first, then falls back to `rootBundle`. The fallback is removed in Task 9.

- [ ] **Step 1: Update imports at the top of `scripture_repository.dart`**

Replace:
```dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../core/models/scripture.dart';
```

With:
```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../core/models/scripture.dart';
```

- [ ] **Step 2: Add `_readFile` helper inside `ScriptureRepository` class**

Add this method inside `ScriptureRepository`, after the `_loadPagedText` method (after the closing `}` of `_loadPagedText` around line 69):

```dart
  // Reads a scripture file from local storage if present, otherwise falls
  // back to the bundled asset. The rootBundle fallback is removed in Task 9.
  Future<String> _readFile(String relativePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final local = File('${dir.path}/scripture/$relativePath');
    if (await local.exists()) return local.readAsString();
    return rootBundle.loadString('assets/data/scripture/$relativePath');
  }
```

- [ ] **Step 3: Update `_loadChunk` (line ~77)**

Change:
```dart
    final raw = await rootBundle.loadString('assets/data/scripture/$dir/${prefix}_$label.json');
```

To:
```dart
    final raw = await _readFile('$dir/${prefix}_$label.json');
```

- [ ] **Step 4: Update `_loadRamayanaChunk` (line ~107)**

Change:
```dart
    final raw = await rootBundle.loadString('assets/data/scripture/$dir/${prefix}_$label.json');
```
To:
```dart
    final raw = await _readFile('$dir/${prefix}_$label.json');
```

- [ ] **Step 5: Update `_loadHadithChunk` (line ~135)**

Change:
```dart
    final raw = await rootBundle.loadString('assets/data/scripture/$dir/${prefix}_$label.json');
```
To:
```dart
    final raw = await _readFile('$dir/${prefix}_$label.json');
```

- [ ] **Step 6: Update `_loadQuran` (line ~157)**

Change:
```dart
    final raw = await rootBundle.loadString('assets/data/scripture/quran.json');
```
To:
```dart
    final raw = await _readFile('quran.json');
```

- [ ] **Step 7: Update `_loadGita` (line ~183)**

Change:
```dart
    final raw = await rootBundle.loadString('assets/data/scripture/gita.json');
```
To:
```dart
    final raw = await _readFile('gita.json');
```

- [ ] **Step 8: Update `_loadBible` (line ~207)**

Change:
```dart
    final raw = await rootBundle.loadString('assets/data/scripture/bible.json');
```
To:
```dart
    final raw = await _readFile('bible.json');
```

- [ ] **Step 9: Analyze and hot-reload test**

```bash
dart analyze lib/data/scripture_repository.dart
```

Expected: no issues. Hot-reload the app and open any scripture — it should still work because `_readFile` falls back to `rootBundle` while the files are still bundled.

- [ ] **Step 10: Commit**

```bash
git add lib/data/scripture_repository.dart
git commit -m "feat: scripture_repository reads local files first, falls back to asset bundle"
```

---

## Task 6: Trigger background downloads on religion change

**Files:**
- Modify: `lib/app.dart`

When the selected religion changes (onboarding completion OR profile religion switch), kick off background downloads for all that religion's texts. This lives in `app.dart` so `ReligionNotifier` stays free of download concerns.

- [ ] **Step 1: Update `app.dart`**

Replace the entire file with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/religion_provider.dart';
import 'providers/download_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    ref.listen<ReligionState>(religionProvider, (prev, next) {
      if (next.selectedReligion != null &&
          prev?.selectedReligion?.id != next.selectedReligion?.id) {
        ref
            .read(downloadProvider.notifier)
            .downloadReligion(next.selectedReligion!.texts);
      }
    });

    return MaterialApp.router(
      title: 'Divine Chat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
dart analyze lib/app.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/app.dart
git commit -m "feat: trigger background scripture download when religion changes"
```

---

## Task 7: Library screen — download status on cards

**Files:**
- Modify: `lib/features/library/library_screen.dart`

Show download state on the hero card and list tiles. Both widgets stay `StatelessWidget` — `LibraryScreen` passes `DownloadInfo?` down as a parameter.

- [ ] **Step 1: Add `downloadProvider` import**

Add after the existing imports in `library_screen.dart`:
```dart
import '../../providers/download_provider.dart';
```

- [ ] **Step 2: Watch `downloadProvider` in `LibraryScreen.build`**

After the line `final planState = ref.watch(readingPlanProvider);`, add:

```dart
    final downloadState = ref.watch(downloadProvider);
```

- [ ] **Step 3: Pass `downloadInfo` to `_HeroTextCard`**

Find the `_HeroTextCard(` call and add the new parameter:

```dart
                  return _HeroTextCard(
                    text: primaryText,
                    religion: activeReligion,
                    accent: accent,
                    isSelected: primaryText.id == state.selectedText?.id,
                    downloadInfo: downloadState[primaryText.id],
                  );
```

- [ ] **Step 4: Pass `downloadInfo` to `_TextListTile`**

Find the `_TextListTile(` call and add:

```dart
                      child: _TextListTile(
                        text: text,
                        accent: accent,
                        fg: fg,
                        muted: muted,
                        line: line,
                        surface: surface,
                        onTap: () => context.push('/read/${text.id}'),
                        plan: planState.planForText(text.id),
                        downloadInfo: downloadState[text.id],
                      ),
```

- [ ] **Step 5: Update `_HeroTextCard` to accept and show `downloadInfo`**

Add `downloadInfo` field and constructor parameter to `_HeroTextCard`:

```dart
class _HeroTextCard extends StatelessWidget {
  const _HeroTextCard({
    required this.text,
    required this.religion,
    required this.accent,
    required this.isSelected,
    this.downloadInfo,
  });

  final SacredTextModel text;
  final ReligionModel religion;
  final Color accent;
  final bool isSelected;
  final DownloadInfo? downloadInfo;
```

In `_HeroTextCard.build`, replace the bottom section of the `Column` — from `const SizedBox(height: 22),` to the end — with:

```dart
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isSelected ? 'CONTINUE READING' : 'BEGIN READING',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white,
                        fontSize: 9,
                        letterSpacing: 1.5,
                      ),
                    ),
                    _downloadTrailing(),
                  ],
                ),
                if (downloadInfo?.status == TextDownloadStatus.downloading) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: downloadInfo!.progress > 0 ? downloadInfo.progress : null,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                      minHeight: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'DOWNLOADING · ${(downloadInfo.progress * 100).round()}%',
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 8,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
```

Add this helper method inside `_HeroTextCard`:

```dart
  Widget _downloadTrailing() {
    if (downloadInfo?.status == TextDownloadStatus.downloading) {
      return SizedBox(
        width: 32, height: 32,
        child: Center(
          child: SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(
              value: downloadInfo!.progress > 0 ? downloadInfo.progress : null,
              color: Colors.white,
              strokeWidth: 1.5,
            ),
          ),
        ),
      );
    }
    if (downloadInfo?.status == TextDownloadStatus.notDownloaded) {
      return Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.cloud_download_outlined, color: Colors.white, size: 16),
      );
    }
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
    );
  }
```

- [ ] **Step 6: Update `_TextListTile` to accept and show `downloadInfo`**

Add `downloadInfo` field and constructor parameter to `_TextListTile`:

```dart
class _TextListTile extends StatelessWidget {
  const _TextListTile({
    required this.text,
    required this.accent,
    required this.fg,
    required this.muted,
    required this.line,
    required this.surface,
    required this.onTap,
    this.plan,
    this.downloadInfo,
  });

  // ... existing fields ...
  final DownloadInfo? downloadInfo;
```

Replace the trailing `Icon(Icons.chevron_right_rounded, color: muted, size: 20)` at the end of the `Row` in `build` with a call to a helper:

```dart
            _tileTrailing(),
```

Add this helper inside `_TextListTile`:

```dart
  Widget _tileTrailing() {
    if (downloadInfo?.status == TextDownloadStatus.downloading) {
      return SizedBox(
        width: 20, height: 20,
        child: CircularProgressIndicator(
          value: downloadInfo!.progress > 0 ? downloadInfo.progress : null,
          color: accent,
          strokeWidth: 1.5,
        ),
      );
    }
    if (downloadInfo?.status == TextDownloadStatus.notDownloaded) {
      return Icon(Icons.cloud_download_outlined, color: muted, size: 20);
    }
    if (downloadInfo?.status == TextDownloadStatus.failed) {
      return Icon(Icons.refresh_rounded, color: muted, size: 20);
    }
    return Icon(Icons.chevron_right_rounded, color: muted, size: 20);
  }
```

- [ ] **Step 7: Analyze**

```bash
dart analyze lib/features/library/library_screen.dart
```

Expected: no issues.

- [ ] **Step 8: Commit**

```bash
git add lib/features/library/library_screen.dart
git commit -m "feat: library screen shows download progress on text cards"
```

---

## Task 8: Reader screen — downloading state

**Files:**
- Modify: `lib/features/reader/reader_screen.dart`

When a text is not yet downloaded, show a centered downloading screen instead of the reader. Auto-start the reader when the download completes.

- [ ] **Step 1: Add `downloadProvider` import**

Add after the existing imports:
```dart
import '../../providers/download_provider.dart';
```

- [ ] **Step 2: Add `_waitingForDownload` field to `_ReaderScreenState`**

After the existing fields (`_loading`, `_error`, etc.), add:

```dart
  bool _waitingForDownload = false;
```

- [ ] **Step 3: Update `initState` to gate on download status**

Find the `else` block in `initState` that calls `_load()` (the block that runs when `_meta != null`):

Current:
```dart
    } else {
      _load();
    }
```

Replace with:
```dart
    } else {
      final downloadStatus = ref.read(downloadProvider)[widget.textId]?.status;
      if (downloadStatus == null || downloadStatus == TextDownloadStatus.downloaded) {
        _load();
      } else {
        setState(() {
          _loading = false;
          _waitingForDownload = true;
        });
      }
    }
```

- [ ] **Step 4: Add `ref.listen` in `build` to auto-start `_load()` when download completes**

At the very top of `_ReaderScreenState.build`, before the first `return` or `if` statement, add:

```dart
    ref.listen<Map<String, DownloadInfo>>(downloadProvider, (prev, next) {
      final prevStatus = prev?[widget.textId]?.status;
      final nextStatus = next[widget.textId]?.status;
      if (_waitingForDownload &&
          prevStatus != TextDownloadStatus.downloaded &&
          nextStatus == TextDownloadStatus.downloaded) {
        setState(() => _waitingForDownload = false);
        _load();
      }
    });
```

- [ ] **Step 5: Insert downloading UI check in `build`**

In `build`, after the existing `if (_error != null) return ...` check (and before the main scaffold), add:

```dart
    if (_waitingForDownload) {
      final info = ref.watch(downloadProvider)[widget.textId];
      return _buildDownloadingScaffold(context, info);
    }
```

- [ ] **Step 6: Add `_buildDownloadingScaffold` method**

Add this method to `_ReaderScreenState`:

```dart
  Widget _buildDownloadingScaffold(BuildContext context, DownloadInfo? info) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final accent = _meta != null
        ? ReligionColors.accent(_meta!.religionId)
        : (isDark ? AppColors.nightFg : AppColors.boneFg);

    final progress = info?.progress ?? 0.0;
    final isFailed = info?.status == TextDownloadStatus.failed;
    final isDownloading = info?.status == TextDownloadStatus.downloading;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48, height: 48,
                child: isFailed
                    ? Icon(Icons.cloud_off_rounded, color: muted, size: 32)
                    : CircularProgressIndicator(
                        value: isDownloading && progress > 0 ? progress : null,
                        color: accent,
                        strokeWidth: 2,
                      ),
              ),
              const SizedBox(height: 28),
              Text(
                isFailed ? 'DOWNLOAD FAILED' : 'DOWNLOADING SCRIPTURE',
                style: GoogleFonts.jetBrainsMono(
                  color: muted,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isFailed
                    ? 'Check your connection'
                    : isDownloading && progress > 0
                        ? '${(progress * 100).round()}%'
                        : _meta?.title ?? '',
                style: GoogleFonts.cormorantGaramond(
                  color: fg,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (isFailed) ...[
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    setState(() => _waitingForDownload = true);
                    ref.read(downloadProvider.notifier).retryText(widget.textId);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: accent.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'RETRY',
                      style: GoogleFonts.jetBrainsMono(
                        color: accent,
                        fontSize: 10,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
```

Note: `ReligionColors.accent` is already imported via `'../../core/models/religion.dart'` which is in `reader_screen.dart`'s existing imports. If it's not, add `import '../../core/models/religion.dart';`.

- [ ] **Step 7: Analyze**

```bash
dart analyze lib/features/reader/reader_screen.dart
```

Expected: no issues. Fix any import issues (e.g. `ReligionColors` location).

- [ ] **Step 8: Commit**

```bash
git add lib/features/reader/reader_screen.dart
git commit -m "feat: reader screen shows downloading state when scripture not yet available"
```

---

## Task 9: Upload to Firebase Storage + remove bundled assets

Do this **after** confirming Tasks 1–8 are working. This permanently removes the bundled files and makes the app depend on Firebase Storage.

- [ ] **Step 1: Configure Firebase Storage security rules**

In Firebase Console → Storage → Rules:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /scripture/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if false;
    }
  }
}
```

- [ ] **Step 2: Upload all scripture files**

From the project root (where `assets/` lives). Replace `YOUR_BUCKET` with the bucket name from Firebase Console → Storage (format: `your-project.appspot.com`):

```bash
# Single-file texts
firebase storage:upload assets/data/scripture/quran.json  scripture/quran.json  --bucket YOUR_BUCKET
firebase storage:upload assets/data/scripture/bible.json  scripture/bible.json  --bucket YOUR_BUCKET
firebase storage:upload assets/data/scripture/gita.json   scripture/gita.json   --bucket YOUR_BUCKET

# Chunked texts — run for each directory
for dir in ggs dasam bgv valmiki_ramayana bukhari muslim abu_dawud tirmidhi nasai ibn_majah; do
  for f in assets/data/scripture/$dir/*.json; do
    name=$(basename "$f")
    firebase storage:upload "$f" "scripture/$dir/$name" --bucket YOUR_BUCKET
  done
done
```

- [ ] **Step 3: Verify upload counts**

```bash
firebase storage:ls scripture/ggs/ --bucket YOUR_BUCKET | wc -l     # Expected: 15
firebase storage:ls scripture/dasam/ --bucket YOUR_BUCKET | wc -l   # Expected: 15
firebase storage:ls scripture/bukhari/ --bucket YOUR_BUCKET | wc -l # Expected: 10
```

- [ ] **Step 4: Remove scripture asset declarations from `pubspec.yaml`**

In `pubspec.yaml` under `flutter: assets:`, keep only:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/data/texts_catalog.json
    - assets/data/daily_verses.json
    - .env
```

Delete these lines:
```yaml
    - assets/data/scripture/quran.json
    - assets/data/scripture/bible.json
    - assets/data/scripture/gita.json
    - assets/data/scripture/ggs/
    - assets/data/scripture/dasam/
    - assets/data/scripture/bgv/
    - assets/data/scripture/bukhari/
    - assets/data/scripture/muslim/
    - assets/data/scripture/abu_dawud/
    - assets/data/scripture/tirmidhi/
    - assets/data/scripture/nasai/
    - assets/data/scripture/ibn_majah/
    - assets/data/scripture/valmiki_ramayana/
```

- [ ] **Step 5: Remove the rootBundle fallback from `ScriptureRepository._readFile`**

In `lib/data/scripture_repository.dart`, replace `_readFile`:

```dart
  Future<String> _readFile(String relativePath) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/scripture/$relativePath').readAsString();
  }
```

Also remove `import 'package:flutter/services.dart';` — `rootBundle` is no longer used.

- [ ] **Step 6: Analyze**

```bash
dart analyze lib/
```

Expected: no issues.

- [ ] **Step 7: Full rebuild and end-to-end test**

```bash
flutter clean && flutter pub get
flutter run
```

Test flow:
1. Fresh install — go through onboarding, select Islam, tap Continue.
2. App navigates to Home immediately (no waiting).
3. Open Library — Quran card shows `DOWNLOADING · x%`, Bukhari shows cloud icon.
4. Progress updates in real-time.
5. Quran completes → card transitions to normal arrow, tap → reader opens.
6. Tap Bukhari while still downloading → see downloading scaffold with progress.
7. Bukhari completes → reader auto-opens.
8. Force-quit + reopen app → all Islam texts show as downloaded instantly (filesystem check).

- [ ] **Step 8: Delete the bundled scripture files from repo**

```bash
rm assets/data/scripture/quran.json assets/data/scripture/bible.json assets/data/scripture/gita.json
rm -rf assets/data/scripture/ggs/ assets/data/scripture/dasam/ assets/data/scripture/bgv/
rm -rf assets/data/scripture/bukhari/ assets/data/scripture/muslim/ assets/data/scripture/abu_dawud/
rm -rf assets/data/scripture/tirmidhi/ assets/data/scripture/nasai/ assets/data/scripture/ibn_majah/
rm -rf assets/data/scripture/valmiki_ramayana/
```

- [ ] **Step 9: Final commit**

```bash
git add -A
git commit -m "feat: move scripture files to Firebase Storage, remove from app bundle

Reduces initial app download by ~93MB. Files are downloaded on first 
religion selection and cached permanently in local storage."
```

---

## Self-Review

**Spec coverage:**
- ✅ Religion select → immediate redirect, no waiting on onboarding screen (`completeOnboarding` navigates immediately, `ref.listen` in `app.dart` fires download in background)
- ✅ Background download with no blocking (`unawaited` in `downloadReligion`)
- ✅ "If downloading" → consistent UI in Library (progress bar + %) and Reader (downloading scaffold with same accent color + jetBrainsMono %)
- ✅ "If not downloaded" → cloud icon on Library cards; reader shows downloading screen
- ✅ Religion change triggers download for new religion (same `ref.listen` path)
- ✅ One-time download per text — skips if `downloaded` or `downloading`
- ✅ App restart restores state from filesystem without re-downloading

**Type consistency:**
- `DownloadInfo` — used identically in Tasks 4, 7, 8
- `TextDownloadStatus.{notDownloaded,downloading,downloaded,failed}` — 4 values, used consistently across all files
- `downloadReligion(List<SacredTextModel>)` — matches `SacredTextModel` from `religion.dart`, called with `selectedReligion!.texts`
- `ScriptureStorageMap.filesForText(textId)` — returns `List<String>`, consumed by `StorageRepository.allFilesExist` and `_downloadText`
- `ReligionColors.accent(religionId)` — already used in `library_screen.dart`, present in `religion.dart`
