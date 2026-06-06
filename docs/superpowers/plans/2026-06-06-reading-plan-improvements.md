# Reading Plan UX Improvements — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix six reading-plan UX issues: "Pagess" typo, first-click arrow bug, scroll-to-top on page change, Quran 8-ayaat page division with precise surah mapping, "Continue Plan / Browse" popup when opening a book with an active plan, and a bookmark feature (last-read unit shown on plan cards).

**Architecture:** Quran gets a new `QuranPageMapper` utility that maps between 8-ayaat pages (1–780) and surahs (1–114). The `ReadingPlan` model gains a `lastReadUnit` field. The reader saves that field on every navigation and on dispose. All other fixes are surgical 1–5 line changes.

**Tech Stack:** Flutter 3.x, Riverpod StateNotifier, SharedPreferences (local), Firestore (remote), GoRouter.

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `lib/core/models/quran_page_mapper.dart` | **Create** | Static page↔surah lookup (6236 verses, 8/page = 780 pages) |
| `lib/core/models/reading_plan.dart` | **Modify** | Add `lastReadUnit` field; change Quran count 604 → 780 |
| `lib/providers/reading_plan_provider.dart` | **Modify** | Add `updateLastRead()` method |
| `lib/features/reader/reader_screen.dart` | **Modify** | ScrollController; HitTestBehavior; typo fix; save lastReadUnit; Quran end-card comparison |
| `lib/features/library/library_screen.dart` | **Modify** | Typo fix (line 581); "Continue Plan / Browse" popup; QuranPageMapper for navigation |

---

## Task 1: Fix "Pagess" Typo

**Files:**
- Modify: `lib/features/reader/reader_screen.dart` (lines ~1140, ~1203)
- Modify: `lib/features/library/library_screen.dart` (line ~581)

All `unitLabel` values in `TextReadingMeta._labels` are already plural ("pages", "angs", "chapters", etc.). Every place that appends an extra `S` or `s` creates a double-plural.

- [ ] **Step 1: Fix reader_screen.dart line ~1140**

In `_TodayBanner.build`, find:
```dart
'${plan.unitLabel.toUpperCase()}S ${plan.todayStartUnit}–${plan.todayEndUnit}',
```
Change to:
```dart
'${plan.unitLabel.toUpperCase()} ${plan.todayStartUnit}–${plan.todayEndUnit}',
```

- [ ] **Step 2: Fix reader_screen.dart line ~1203**

In `_EndCard.build`, find:
```dart
'Day ${plan.dayNumber} · ${plan.unitLabel}s ${plan.todayStartUnit}–${plan.todayEndUnit}',
```
Change to:
```dart
'Day ${plan.dayNumber} · ${plan.unitLabel} ${plan.todayStartUnit}–${plan.todayEndUnit}',
```

- [ ] **Step 3: Fix library_screen.dart line ~581**

In `_PlanHeroCard.build`, find:
```dart
'TODAY · ${plan.unitLabel.toUpperCase()}S ${plan.todayStartUnit}–${plan.todayEndUnit}',
```
Change to:
```dart
'TODAY · ${plan.unitLabel.toUpperCase()} ${plan.todayStartUnit}–${plan.todayEndUnit}',
```

- [ ] **Step 4: Verify**

Run: `dart analyze lib/`
Expected: zero new warnings.
Run the app and open a reading plan with textId `quran`. The banner in the reader should show "PAGES 1–3" not "PAGESS 1–3". Check the library hero card too.

- [ ] **Step 5: Commit**

```bash
git add lib/features/reader/reader_screen.dart lib/features/library/library_screen.dart
git commit -m "fix: remove extra S from unit label in reading plan banners"
```

---

## Task 2: Fix Arrow Nav First-Click Bug

**Files:**
- Modify: `lib/features/reader/reader_screen.dart` (line ~589)

The `_navBtn` uses `GestureDetector` with default `HitTestBehavior.deferToChild`. The child is a `SizedBox` containing an `Icon` — the `Icon` doesn't fill the full 48×48 `SizedBox`, so tapping empty space within the box misses the hit target on first interaction after the screen settles. `HitTestBehavior.opaque` makes the entire 48×48 area tappable.

- [ ] **Step 1: Update _navBtn**

Find (around line 589):
```dart
Widget _navBtn({required IconData icon, required Color color, VoidCallback? onTap}) =>
    GestureDetector(
      onTap: onTap,
      child: SizedBox(width: 48, height: 48, child: Icon(icon, size: 17, color: color)),
    );
```

Replace with:
```dart
Widget _navBtn({required IconData icon, required Color color, VoidCallback? onTap}) =>
    GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(width: 48, height: 48, child: Icon(icon, size: 17, color: color)),
    );
```

- [ ] **Step 2: Verify**

Run the app. Open any scripture. On first open, tap the right arrow immediately — it should navigate to the next chapter/page without needing a second tap.

- [ ] **Step 3: Commit**

```bash
git add lib/features/reader/reader_screen.dart
git commit -m "fix: use HitTestBehavior.opaque on reader nav arrows to fix first-tap miss"
```

---

## Task 3: Scroll to Top on Page Navigation

**Files:**
- Modify: `lib/features/reader/reader_screen.dart`

The `ListView.separated` for verses has no `ScrollController`, so navigating to the next chapter via `_goTo` keeps the scroll position at the bottom. Fix: add a controller and `jumpTo(0)` after new content renders.

- [ ] **Step 1: Add ScrollController field**

In `_ReaderScreenState`, add the field after the existing fields (around line 49):
```dart
final _scrollCtrl = ScrollController();
```

- [ ] **Step 2: Pass controller to ListView**

Find the `ListView.separated` (around line 436):
```dart
: ListView.separated(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
    itemCount: _displayVerses.length,
```

Change to:
```dart
: ListView.separated(
    controller: _scrollCtrl,
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
    itemCount: _displayVerses.length,
```

- [ ] **Step 3: Scroll to top in _goTo**

In `_goTo`, find:
```dart
if (mounted) setState(() => _loading = false);
```

Replace with:
```dart
if (mounted) {
  setState(() => _loading = false);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(0);
  });
}
```

`addPostFrameCallback` is required because `jumpTo` must fire after the new `ListView` renders.

- [ ] **Step 4: Dispose the controller**

In `dispose()`, add before `super.dispose()`:
```dart
_scrollCtrl.dispose();
```

- [ ] **Step 5: Verify**

Open a scripture with many verses (e.g., Surah 2 Al-Baqarah). Scroll to the middle, then tap the right arrow. The new chapter/page should render from the very top.

- [ ] **Step 6: Commit**

```bash
git add lib/features/reader/reader_screen.dart
git commit -m "fix: scroll reader to top when navigating to next/prev page"
```

---

## Task 4: Build QuranPageMapper Utility

**Files:**
- Create: `lib/core/models/quran_page_mapper.dart`

The Quran has 6236 verses across 114 surahs. One reading-plan "page" = 8 consecutive ayaats = 780 total pages (ceil(6236/8)). This class maps between page number (1–780) and surah number (1–114).

Surah verse counts verified to sum to 6236:
```
Surah  1–10:  7, 286, 200, 176, 120, 165, 206, 75, 129, 109
Surah 11–20:  123, 111,  43,  52,  99, 128, 111, 110,  98, 135
Surah 21–30:  112,  78, 118,  64,  77, 227,  93,  88,  69,  60
Surah 31–40:   34,  30,  73,  54,  45,  83, 182,  88,  75,  85
Surah 41–50:   54,  53,  89,  59,  37,  35,  38,  29,  18,  45
Surah 51–60:   60,  49,  62,  55,  78,  96,  29,  22,  24,  13
Surah 61–70:   14,  11,  11,  18,  12,  12,  30,  52,  52,  44
Surah 71–80:   28,  28,  20,  56,  40,  31,  50,  40,  46,  42
Surah 81–90:   29,  19,  36,  25,  22,  17,  19,  26,  30,  20
Surah 91–100:  15,  21,  11,   8,   8,  19,   5,   8,   8,  11
Surah 101–114: 11,   8,   3,   9,   5,   4,   7,   3,   6,   3, 5, 4, 5, 6
```

- [ ] **Step 1: Create the file**

Create `lib/core/models/quran_page_mapper.dart`:
```dart
class QuranPageMapper {
  QuranPageMapper._();

  static const int versesPerPage = 8;
  static const int totalPages = 780; // ceil(6236 / 8)

  static const List<int> _verseCounts = [
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109,
    123, 111, 43, 52, 99, 128, 111, 110, 98, 135,
    112, 78, 118, 64, 77, 227, 93, 88, 69, 60,
    34, 30, 73, 54, 45, 83, 182, 88, 75, 85,
    54, 53, 89, 59, 37, 35, 38, 29, 18, 45,
    60, 49, 62, 55, 78, 96, 29, 22, 24, 13,
    14, 11, 11, 18, 12, 12, 30, 52, 52, 44,
    28, 28, 20, 56, 40, 31, 50, 40, 46, 42,
    29, 19, 36, 25, 22, 17, 19, 26, 30, 20,
    15, 21, 11, 8, 8, 19, 5, 8, 8, 11,
    11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6,
  ];

  // _cumulative[i] = total verses before surah (i+1). Length = 115.
  static final List<int> _cumulative = () {
    final c = <int>[0];
    for (final v in _verseCounts) {
      c.add(c.last + v);
    }
    return List.unmodifiable(c);
  }();

  /// Returns the 1-based surah number that contains the first verse of [page].
  /// [page] is 1-based (1–780).
  static int pageToSurah(int page) {
    final globalVerse = ((page - 1) * versesPerPage) + 1;
    int lo = 0, hi = _verseCounts.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) ~/ 2;
      if (_cumulative[mid + 1] < globalVerse) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo + 1;
  }

  /// Returns the 1-based page number on which [surah] (1-based) begins.
  static int surahToPage(int surah) {
    final globalVerseStart = _cumulative[surah - 1] + 1;
    return (globalVerseStart - 1) ~/ versesPerPage + 1;
  }
}
```

- [ ] **Step 2: Verify logic with spot checks**

Run: `dart analyze lib/core/models/quran_page_mapper.dart`
Expected: no issues.

Manual spot checks:
- `pageToSurah(1)` → 1 (Al-Fatiha, ayaats 1–7 are page 1)
- `pageToSurah(2)` → 2 (page 2 starts at global ayaat 9 = Al-Baqarah ayaat 2)
- `surahToPage(1)` → 1
- `surahToPage(2)` → 1 (Al-Baqarah starts at global verse 8, which falls on page 1)
- `surahToPage(3)` → 37 (Al-Imran starts at global verse 294; (293÷8)+1 = 37)

- [ ] **Step 3: Commit**

```bash
git add lib/core/models/quran_page_mapper.dart
git commit -m "feat: add QuranPageMapper for 8-ayaat page to surah conversion"
```

---

## Task 5: Update Quran Reading Plan to 780 Pages + Fix End Card Comparison

**Files:**
- Modify: `lib/core/models/reading_plan.dart`
- Modify: `lib/features/reader/reader_screen.dart`

Change `TextReadingMeta._counts['quran']` from 604 to 780. Fix the reader's end-card trigger which compares `_currentChapter` (surah 1–114) directly against `plan.todayEndUnit` (now a page 1–780) — they must be on the same scale.

- [ ] **Step 1: Update Quran count in reading_plan.dart**

In `TextReadingMeta._counts`, find:
```dart
'quran': 604,
```
Change to:
```dart
'quran': 780,
```

The `unitLabel` is already `'pages'` — no change needed.

- [ ] **Step 2: Add import for QuranPageMapper in reader_screen.dart**

At the top of `lib/features/reader/reader_screen.dart`, with the other model imports, add:
```dart
import '../../core/models/quran_page_mapper.dart';
```

- [ ] **Step 3: Add _effectiveUnitForPlan getter**

In `_ReaderScreenState`, add this getter after `_onlyOriginal` (around line 87):
```dart
int get _effectiveUnitForPlan {
  if (_meta?.type == ScriptureTextType.quran) {
    return QuranPageMapper.surahToPage(_currentChapter);
  }
  return _currentChapter;
}
```

- [ ] **Step 4: Update end card trigger**

Find (around line 311):
```dart
final showEndCard = plan != null &&
    !plan.todayDone &&
    !_dismissedEndCard &&
    _currentChapter >= plan.todayEndUnit;
```

Replace with:
```dart
final showEndCard = plan != null &&
    !plan.todayDone &&
    !_dismissedEndCard &&
    _effectiveUnitForPlan >= plan.todayEndUnit;
```

- [ ] **Step 5: Run analyze**

Run: `dart analyze lib/`
Expected: zero errors.

- [ ] **Step 6: Manual test**

Create a new Quran reading plan (or delete and recreate existing). Set to 1 page/day so `todayEndUnit = 1`. Open the Quran reader from library. You should already be on surah 1 (Al-Fatiha), which is page 1, so the end card should appear. Navigate to surah 2 — still on page 1 for surah 2, so the card stays if you haven't marked done.

- [ ] **Step 7: Commit**

```bash
git add lib/core/models/reading_plan.dart lib/features/reader/reader_screen.dart
git commit -m "feat: change Quran reading plan unit to 780 pages of 8 ayaats; fix end card surah comparison"
```

---

## Task 6: Add lastReadUnit Bookmark to ReadingPlan Model + Provider

**Files:**
- Modify: `lib/core/models/reading_plan.dart`
- Modify: `lib/providers/reading_plan_provider.dart`

`lastReadUnit` is a nullable int. For Quran it stores the surah number (1–114); for all other texts it stores the chapter/page/ang (whatever `_currentChapter` is). Display conversion happens at the presentation layer.

- [ ] **Step 1: Add field to ReadingPlan constructor**

In `reading_plan.dart`, add `this.lastReadUnit` to the constructor parameter list (after `catchUpMode`):
```dart
ReadingPlan({
  required this.id,
  required this.textId,
  required this.textTitle,
  required this.religionId,
  required this.totalUnits,
  required this.unitLabel,
  required this.minutesPerUnit,
  this.durationDays,
  required this.unitsPerDay,
  required this.reminderHour,
  required this.reminderMinute,
  required this.reminderEnabled,
  required this.startDate,
  required this.completedDates,
  required this.streakFreezes,
  required this.catchUpMode,
  this.lastReadUnit,   // ← add this
});
```

Add field declaration after `catchUpMode`:
```dart
final bool catchUpMode;
final int? lastReadUnit;
```

- [ ] **Step 2: Update copyWith**

Find the `copyWith` method. Add `lastReadUnit` parameter and assignment:
```dart
ReadingPlan copyWith({
  int? durationDays,
  bool clearDuration = false,
  int? unitsPerDay,
  int? reminderHour,
  int? reminderMinute,
  bool? reminderEnabled,
  Set<String>? completedDates,
  bool? streakFreezes,
  bool? catchUpMode,
  int? lastReadUnit,          // ← add
  bool clearLastRead = false, // ← add
}) {
  return ReadingPlan(
    id: id,
    textId: textId,
    textTitle: textTitle,
    religionId: religionId,
    totalUnits: totalUnits,
    unitLabel: unitLabel,
    minutesPerUnit: minutesPerUnit,
    durationDays: clearDuration ? null : (durationDays ?? this.durationDays),
    unitsPerDay: unitsPerDay ?? this.unitsPerDay,
    reminderHour: reminderHour ?? this.reminderHour,
    reminderMinute: reminderMinute ?? this.reminderMinute,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    startDate: startDate,
    completedDates: completedDates ?? this.completedDates,
    streakFreezes: streakFreezes ?? this.streakFreezes,
    catchUpMode: catchUpMode ?? this.catchUpMode,
    lastReadUnit: clearLastRead ? null : (lastReadUnit ?? this.lastReadUnit), // ← add
  );
}
```

- [ ] **Step 3: Update toJson**

In `toJson()`, add:
```dart
'lastReadUnit': lastReadUnit,
```

- [ ] **Step 4: Update fromJson**

In `ReadingPlan.fromJson`, add:
```dart
lastReadUnit: json['lastReadUnit'] as int?,
```

- [ ] **Step 5: Add updateLastRead to provider**

In `reading_plan_provider.dart`, add to `ReadingPlanNotifier`:
```dart
Future<void> updateLastRead(String planId, int unit) async {
  await _save(state.plans
      .map((p) => p.id == planId ? p.copyWith(lastReadUnit: unit) : p)
      .toList());
}
```

- [ ] **Step 6: Run analyze**

Run: `dart analyze lib/`
Expected: zero errors.

- [ ] **Step 7: Commit**

```bash
git add lib/core/models/reading_plan.dart lib/providers/reading_plan_provider.dart
git commit -m "feat: add lastReadUnit bookmark field to ReadingPlan and updateLastRead to provider"
```

---

## Task 7: Track lastReadUnit in Reader Screen

**Files:**
- Modify: `lib/features/reader/reader_screen.dart`

When an active reading plan exists for the open book, save `_currentChapter` as `lastReadUnit` on every page navigation and when the reader is closed.

- [ ] **Step 1: Save on navigation in _goTo**

In `_goTo`, after:
```dart
await ref.read(scripturePositionProvider.notifier).savePosition(widget.textId, num, 1);
```

Add:
```dart
final plan = ref.read(readingPlanProvider).planForText(widget.textId);
if (plan != null) {
  await ref.read(readingPlanProvider.notifier).updateLastRead(plan.id, num);
}
```

- [ ] **Step 2: Save on reader exit in dispose**

Find the existing `dispose()`:
```dart
@override
void dispose() {
  _searchCtrl.dispose();
  _scrollCtrl.dispose();
  super.dispose();
}
```

Replace with:
```dart
@override
void dispose() {
  final plan = ref.read(readingPlanProvider).planForText(widget.textId);
  if (plan != null && !_loading) {
    ref.read(readingPlanProvider.notifier).updateLastRead(plan.id, _currentChapter);
  }
  _searchCtrl.dispose();
  _scrollCtrl.dispose();
  super.dispose();
}
```

The `!_loading` guard prevents saving `_currentChapter = 1` (its initial value) if the reader was still loading when dismissed.

- [ ] **Step 3: Run analyze**

Run: `dart analyze lib/`
Expected: zero errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/reader/reader_screen.dart
git commit -m "feat: save lastReadUnit to reading plan on navigation and reader exit"
```

---

## Task 8: Show lastReadUnit on Reading Plan Cards

**Files:**
- Modify: `lib/features/reading_plans/reading_plans_screen.dart`

Show `LAST READ: PAGE X` on plan cards when `lastReadUnit != null`. For Quran, convert the stored surah number to a page via `QuranPageMapper.surahToPage`.

- [ ] **Step 1: Add import**

At the top of `reading_plans_screen.dart`:
```dart
import '../../core/models/quran_page_mapper.dart';
```

- [ ] **Step 2: Add _lastReadLabel helper to _PlanCard**

Add this method inside `_PlanCard`:
```dart
String _lastReadLabel(ReadingPlan plan) {
  final unit = plan.lastReadUnit!;
  final displayUnit = plan.textId == 'quran'
      ? QuranPageMapper.surahToPage(unit)
      : unit;
  return 'LAST READ: ${plan.unitLabel.toUpperCase()} $displayUnit';
}
```

- [ ] **Step 3: Render the label under the stats row**

In `_PlanCard.build`, find the last `Row` (the one with "X% READ" and "X LEFT"). Add below it:
```dart
if (plan.lastReadUnit != null) ...[
  const SizedBox(height: 4),
  Text(
    _lastReadLabel(plan),
    style: GoogleFonts.jetBrainsMono(
        color: muted, fontSize: 8, letterSpacing: 0.5),
  ),
],
```

- [ ] **Step 4: Run analyze**

Run: `dart analyze lib/`
Expected: zero errors.

- [ ] **Step 5: Verify**

Open the app. Read a few pages of a book that has a reading plan. Go back. Open the Reading Plans screen. The card should show e.g. `LAST READ: PAGE 3` under the progress row.

- [ ] **Step 6: Commit**

```bash
git add lib/features/reading_plans/reading_plans_screen.dart
git commit -m "feat: show last-read unit on reading plan cards"
```

---

## Task 9: "Continue Plan / Browse" Popup in Library Screen

**Files:**
- Modify: `lib/features/library/library_screen.dart`

When tapping a book that has an active reading plan, show a bottom sheet instead of immediately opening the reader. Two options:
- **Continue Plan** — opens reader at `todayStartUnit` (converted to surah for Quran)
- **Browse** — opens reader freely (no `initialChapter` extra)

- [ ] **Step 1: Add import for QuranPageMapper**

At the top of `library_screen.dart`:
```dart
import '../../core/models/quran_page_mapper.dart';
```

- [ ] **Step 2: Add _showReadOrPlanSheet helper**

Add this top-level function at the bottom of `library_screen.dart` (before any private widget classes). It is a function not a method so it can be called from both `_TextListTile.onTap` and `_PlanHeroCard.onTap`:

```dart
void _showReadOrPlanSheet(
  BuildContext context,
  String textId,
  ReadingPlan plan,
  Color accent,
  Color fg,
  Color muted,
  Color bg,
  Color line,
  Color surface,
) {
  final int readerChapter = textId == 'quran'
      ? QuranPageMapper.pageToSurah(plan.todayStartUnit)
      : plan.todayStartUnit;

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'OPEN AS',
            style: GoogleFonts.jetBrainsMono(
                color: muted, fontSize: 9, letterSpacing: 1.5),
          ),
          const SizedBox(height: 4),
          Text(
            plan.textTitle,
            style: GoogleFonts.cormorantGaramond(
              color: fg, fontSize: 22,
              fontWeight: FontWeight.w500, fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.of(ctx).pop();
              context.push('/read/$textId', extra: {'chapter': readerChapter});
            },
            child: Container(
              width: double.infinity, height: 56,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Continue Plan',
                      style: GoogleFonts.inter(
                          color: Colors.white, fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Day ${plan.dayNumber} · ${plan.unitLabel} ${plan.todayStartUnit}–${plan.todayEndUnit}',
                      style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Navigator.of(ctx).pop();
              context.push('/read/$textId');
            },
            child: Container(
              width: double.infinity, height: 50,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: line),
              ),
              child: Center(
                child: Text(
                  'Browse',
                  style: GoogleFonts.inter(
                      color: fg, fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 3: Update first _TextListTile onTap (filtered view, ~line 221)**

Find:
```dart
onTap: () => context.push('/read/${text.id}'),
plan: planState.planForText(text.id),
```

Replace (note: `bg`, `line`, `surface` are local variables already defined in the enclosing `build` method):
```dart
onTap: () {
  final plan = planState.planForText(text.id);
  if (plan != null) {
    _showReadOrPlanSheet(
        context, text.id, plan, accent, fg, muted, bg, line, surface);
  } else {
    context.push('/read/${text.id}');
  }
},
plan: planState.planForText(text.id),
```

- [ ] **Step 4: Update second _TextListTile onTap (other texts list, ~line 289)**

Find:
```dart
onTap: () => context.push('/read/${text.id}'),
plan: planState.planForText(text.id),
```

Replace:
```dart
onTap: () {
  final plan = planState.planForText(text.id);
  if (plan != null) {
    _showReadOrPlanSheet(
        context, text.id, plan, accent, fg, muted, bg, line, surface);
  } else {
    context.push('/read/${text.id}');
  }
},
plan: planState.planForText(text.id),
```

- [ ] **Step 5: Update _PlanHeroCard to accept bg/line/surface and use the popup**

`_PlanHeroCard` is a `StatelessWidget` without `bg`, `line`, `surface`. Add them to its constructor:

Find the class declaration:
```dart
class _PlanHeroCard extends StatelessWidget {
  const _PlanHeroCard({
    required this.plan,
    required this.text,
    required this.religion,
    required this.accent,
    required this.fg,
    required this.muted,
  });

  final ReadingPlan plan;
  final SacredTextModel text;
  final ReligionModel religion;
  final Color accent, fg, muted;
```

Replace with:
```dart
class _PlanHeroCard extends StatelessWidget {
  const _PlanHeroCard({
    required this.plan,
    required this.text,
    required this.religion,
    required this.accent,
    required this.fg,
    required this.muted,
    required this.bg,
    required this.line,
    required this.surface,
  });

  final ReadingPlan plan;
  final SacredTextModel text;
  final ReligionModel religion;
  final Color accent, fg, muted, bg, line, surface;
```

In `_PlanHeroCard.build`, find:
```dart
onTap: () => context.push(
  '/read/${text.id}',
  extra: {'chapter': plan.todayStartUnit},
),
```

Replace with:
```dart
onTap: () => _showReadOrPlanSheet(
  context, text.id, plan, accent, fg, muted, bg, line, surface,
),
```

Update the instantiation site (~line 241):
```dart
return _PlanHeroCard(
  plan: plan,
  text: primaryText,
  religion: activeReligion,
  accent: accent,
  fg: fg,
  muted: muted,
  bg: bg,
  line: line,
  surface: surface,
);
```

- [ ] **Step 6: Run analyze**

Run: `dart analyze lib/`
Expected: zero errors.

- [ ] **Step 7: Verify**

Run the app. Open Library. Tap a book with an active reading plan:
- A bottom sheet appears with "Continue Plan" (colored, shows day + range) and "Browse" (outlined).
- "Continue Plan" opens the reader at today's unit.
- "Browse" opens the reader freely.

Tap a book without a reading plan — reader opens directly, no popup.

- [ ] **Step 8: Commit**

```bash
git add lib/features/library/library_screen.dart
git commit -m "feat: show Continue Plan / Browse sheet when tapping book with active reading plan"
```

---

## Self-Review

### Spec Coverage

| Requirement | Task |
|---|---|
| Quran divided into 8-ayaat pages (780 total) | Tasks 4, 5 |
| Reading plan page count correct for Quran | Task 5 (604 → 780) |
| Book-click popup: Continue Plan / Browse | Task 9 |
| Arrow nav first-click bug | Task 2 |
| "Pagess" typo removed | Task 1 |
| Scroll to top on page navigation | Task 3 |
| Bookmark / last-read unit on plan card | Tasks 6, 7, 8 |

All 7 requirements covered. ✓

### Placeholder Scan

No TBDs, no vague steps, no "implement later". Every step has exact file paths and complete code snippets.

### Type Consistency

- `QuranPageMapper.pageToSurah(int) → int` — created Task 4, used Tasks 5 and 9 ✓
- `QuranPageMapper.surahToPage(int) → int` — created Task 4, used Tasks 5 and 8 ✓
- `ReadingPlan.lastReadUnit` (nullable int) — added Task 6, written Task 7, read Task 8 ✓
- `ReadingPlan.copyWith(lastReadUnit: int?)` — signature defined Task 6, called Task 6 ✓
- `ReadingPlanNotifier.updateLastRead(String planId, int unit)` — defined Task 6, called Task 7 ✓
- `_PlanHeroCard(bg: Color, line: Color, surface: Color)` — added Task 9 step 5, instantiated Task 9 step 5 ✓
