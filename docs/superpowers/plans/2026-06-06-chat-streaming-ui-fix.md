# Chat Streaming UI Fix + Enhancement Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix three bugs that prevent the Thinking / Searching / preamble states from ever rendering during chat, and enhance the loading experience to feel like Claude's progressive reveal (thinking → searching → streaming answer).

**Architecture:** Three bug fixes in the state layer (`chat_provider.dart`, `divine_api.dart`) restore correct event routing; one visual enhancement in `chat_screen.dart` adds a shimmer pulse to the status pill and a subtle "generating" row while the answer streams. No new files — all changes are surgical edits to existing code.

**Tech Stack:** Flutter 3.x, Riverpod `StateNotifierProvider`, SSE via `http.Client`, `MarkdownBody` (flutter_markdown), `GoogleFonts.inter`

---

## Root-Cause Bugs (understand before touching code)

### Bug 1 — Preamble text routes to answer buffer
`divine_api.dart:138` defaults `phase = 'answer'` when the field is absent.
Backend may send `text_delta` events without a `phase` field, so preamble text lands in `answerBuffer` → `streamingText`.
`hasAnswer = streamingText.isNotEmpty = true` even though no real answer has appeared.
`showLoadingDots = isStreaming && !hasPreamble && !hasToolCall && !hasAnswer = false` → `_ThinkingIndicator` never renders.
`_AnswerBody` renders with invisible Markdown content (newlines/whitespace) + blinking cursor `|`.

### Bug 2 — Status event trigger too narrow
`chat_provider.dart:243`: `flipTool = msg.startsWith('Searching') && !state.hasToolCall`
If backend says "Retrieving passages from Quran…" or anything that doesn't start with "Searching", `hasToolCall` is never set, `_ToolCallBlock` never renders.

### Bug 3 — Thinking state renders zero frames
`isTyping = true` is set, then the SSE `await for` loop starts in the same async function.
If backend responds fast (< 1 frame ≈ 16 ms), Riverpod batches state updates and the user never sees the bouncing-dots bubble.

---

## File Map

| File | Change |
|---|---|
| `lib/data/divine_api.dart` | Task 1: change missing `phase` default from `'answer'` to `'unknown'` |
| `lib/providers/chat_provider.dart` | Task 2: fix status trigger; Task 3: add 300 ms pre-stream delay; Task 4: fix preamble routing fallback |
| `lib/features/chat/chat_screen.dart` | Task 5: enhance `_ToolCallBlock` with shimmer; add "Generating…" row during answer stream |

---

### Task 1: Fix phase defaulting in divine_api.dart

**Context:** `_parseEvent` defaults `phase` to `'answer'` when the field is absent. Change it to `'unknown'` so the provider layer can decide routing based on current streaming state rather than blindly treating all unknown chunks as answer text.

**Files:**
- Modify: `lib/data/divine_api.dart:138`

- [ ] **Step 1: Change phase default**

Open `lib/data/divine_api.dart`. Find:
```dart
case 'text_delta':
  final text = j['text'] as String? ?? '';
  final phase = j['phase'] as String? ?? 'answer';
  return text.isNotEmpty ? ApiStreamChunk(text, phase: phase) : null;
```
Replace with:
```dart
case 'text_delta':
  final text = j['text'] as String? ?? '';
  final phase = j['phase'] as String? ?? 'unknown';
  return text.isNotEmpty ? ApiStreamChunk(text, phase: phase) : null;
```

- [ ] **Step 2: Verify no other callers depend on the 'answer' default**

```bash
grep -rn "phase.*answer" lib/
```
Expected: only `chat_provider.dart` checks `event.phase == 'preamble'` — no files expect a specific default value.

- [ ] **Step 3: Run analyzer**

```bash
cd /home/ronit/Ronit-Personal/Personal/divine-dialogue/codes/divine_dialogue
dart analyze lib/data/divine_api.dart
```
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/data/divine_api.dart
git commit -m "fix: use unknown sentinel for missing phase in text_delta events"
```

---

### Task 2: Fix status event trigger in chat_provider.dart

**Context:** `flipTool = msg.startsWith('Searching')` is too narrow. ANY non-empty status event should trigger the tool-call pill. Also, the first status event should immediately set `isTyping: false` so the bubble transitions from "thinking dots" → "searching pill" without waiting for the first preamble chunk.

**Files:**
- Modify: `lib/providers/chat_provider.dart` — inside `sendMessage()`, the `ApiStreamStatus` handler (~line 241)

- [ ] **Step 1: Locate and replace the ApiStreamStatus handler**

Inside `sendMessage()`, find the block starting with `if (event is ApiStreamStatus) {` and replace the entire block:

Old:
```dart
        if (event is ApiStreamStatus) {
          final msg = event.message;
          final flipTool = msg.startsWith('Searching') && !state.hasToolCall;
          // Keep preamble visible for >=500 ms before the tool-call block
          // appears. No-op when the server already streams at natural pace.
          if (flipTool && preambleFirstAt != null) {
            final elapsed = DateTime.now().difference(preambleFirstAt).inMilliseconds;
            if (elapsed < 500) {
              await Future<void>.delayed(Duration(milliseconds: 500 - elapsed));
            }
          }
          state = state.copyWith(
            statusMessage: msg,
            hasToolCall: flipTool ? true : null,
          );
          if (flipTool) toolCallAt = DateTime.now();
        }
```

New:
```dart
        if (event is ApiStreamStatus) {
          final msg = event.message;
          final flipTool = msg.isNotEmpty && !state.hasToolCall;
          if (flipTool && preambleFirstAt != null) {
            final elapsed = DateTime.now().difference(preambleFirstAt).inMilliseconds;
            if (elapsed < 500) {
              await Future<void>.delayed(Duration(milliseconds: 500 - elapsed));
            }
          }
          state = state.copyWith(
            isTyping: false,
            statusMessage: msg,
            hasToolCall: flipTool ? true : null,
          );
          if (flipTool) toolCallAt = DateTime.now();
        }
```

- [ ] **Step 2: Run analyzer**

```bash
dart analyze lib/providers/chat_provider.dart
```
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/providers/chat_provider.dart
git commit -m "fix: trigger tool-call pill on any non-empty status event"
```

---

### Task 3: Add pre-stream delay to guarantee ThinkingIndicator renders

**Context:** `isTyping = true` is set, then the SSE loop starts immediately. Fast backends can respond before Flutter schedules a build. A 300 ms `Future.delayed` yields to the event loop, guaranteeing the "Thinking…" bubble renders before the first SSE event is processed.

**Files:**
- Modify: `lib/providers/chat_provider.dart` — inside `sendMessage()`, between the initial state set and the `try {` block

- [ ] **Step 1: Find the insertion point**

In `sendMessage()`, find this exact sequence:
```dart
    state = state.copyWith(
      session: withUser,
      isTyping: true,
      streamingPreamble: '',
      streamingText: '',
      hasToolCall: false,
      statusMessage: '',
      streamingPassages: const [],
      error: null,
      clearPendingVerse: true,
    );
    // Fire save concurrently — don't block stream start
    unawaited(ChatRepository.instance.saveSession(withUser));
    _ref.read(historyProvider.notifier).load();

    try {
```

- [ ] **Step 2: Insert the delay**

Add one line between `_ref.read(historyProvider.notifier).load();` and `try {`:

```dart
    state = state.copyWith(
      session: withUser,
      isTyping: true,
      streamingPreamble: '',
      streamingText: '',
      hasToolCall: false,
      statusMessage: '',
      streamingPassages: const [],
      error: null,
      clearPendingVerse: true,
    );
    // Fire save concurrently — don't block stream start
    unawaited(ChatRepository.instance.saveSession(withUser));
    _ref.read(historyProvider.notifier).load();

    // Yield to event loop so Flutter renders the ThinkingIndicator bubble
    // before the SSE loop begins. Without this, fast backends respond before
    // a frame is scheduled and the thinking state never appears.
    await Future.delayed(const Duration(milliseconds: 300));

    try {
```

- [ ] **Step 3: Run analyzer**

```bash
dart analyze lib/providers/chat_provider.dart
```
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/providers/chat_provider.dart
git commit -m "fix: yield 300ms to event loop before SSE loop so ThinkingIndicator renders"
```

---

### Task 4: Fix preamble routing fallback in chat_provider.dart

**Context:** After Task 1, chunks with missing `phase` arrive as `'unknown'`. The current handler only routes `phase == 'preamble'` to `preambleBuffer`; `'unknown'` chunks go to `answerBuffer`. Fix: if phase is not `'answer'` AND the answer hasn't started, treat the chunk as preamble.

**Files:**
- Modify: `lib/providers/chat_provider.dart` — inside the `ApiStreamChunk` handler within `sendMessage()`

- [ ] **Step 1: Find the ApiStreamChunk handler**

Inside `sendMessage()`, find:
```dart
        } else if (event is ApiStreamChunk) {
          if (event.phase == 'preamble') {
            preambleFirstAt ??= DateTime.now();
            preambleBuffer.write(event.text);
            state = state.copyWith(
              isTyping: false,
              streamingPreamble: preambleBuffer.toString(),
            );
          } else {
            // Keep the tool-call spinner visible for >=500 ms before answer
            // text begins streaming in.
            if (!answerStarted) {
              answerStarted = true;
              if (state.hasToolCall && toolCallAt != null) {
                final elapsed = DateTime.now().difference(toolCallAt).inMilliseconds;
                if (elapsed < 500) {
                  await Future<void>.delayed(Duration(milliseconds: 500 - elapsed));
                }
              }
            }
            answerBuffer.write(event.text);
            final now = DateTime.now();
            if (now.difference(lastRender).inMilliseconds >= 50) {
              lastRender = now;
              state = state.copyWith(
                isTyping: false,
                streamingText: answerBuffer.toString(),
              );
            } else if (state.isTyping) {
              state = state.copyWith(isTyping: false);
            }
          }
        }
```

- [ ] **Step 2: Replace with phase-fallback routing**

```dart
        } else if (event is ApiStreamChunk) {
          // Treat chunk as preamble when:
          //   (a) explicitly marked preamble, OR
          //   (b) phase is unknown/missing AND answer hasn't started yet
          final isPreamble = event.phase == 'preamble' ||
              (event.phase != 'answer' && !answerStarted);

          if (isPreamble) {
            preambleFirstAt ??= DateTime.now();
            preambleBuffer.write(event.text);
            state = state.copyWith(
              isTyping: false,
              streamingPreamble: preambleBuffer.toString(),
            );
          } else {
            // Keep the tool-call spinner visible for >=500 ms before answer
            // text begins streaming in.
            if (!answerStarted) {
              answerStarted = true;
              if (state.hasToolCall && toolCallAt != null) {
                final elapsed = DateTime.now().difference(toolCallAt).inMilliseconds;
                if (elapsed < 500) {
                  await Future<void>.delayed(Duration(milliseconds: 500 - elapsed));
                }
              }
            }
            answerBuffer.write(event.text);
            final now = DateTime.now();
            if (now.difference(lastRender).inMilliseconds >= 50) {
              lastRender = now;
              state = state.copyWith(
                isTyping: false,
                streamingText: answerBuffer.toString(),
              );
            } else if (state.isTyping) {
              state = state.copyWith(isTyping: false);
            }
          }
        }
```

- [ ] **Step 3: Run analyzer**

```bash
dart analyze lib/providers/chat_provider.dart
```
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/providers/chat_provider.dart
git commit -m "fix: route unknown-phase chunks to preamble buffer before answer starts"
```

---

### Task 5: Enhance _ToolCallBlock with shimmer pulse + add Generating row

**Context:** The current status pill has a static background. Convert `_ToolCallBlock` from `StatelessWidget` to `StatefulWidget` and add a gentle pulsing background animation while running. Also add a subtle "Generating…" row below the answer body while it streams in, giving the user feedback that generation is still active.

**Files:**
- Modify: `lib/features/chat/chat_screen.dart` — `_ToolCallBlock` class (~lines 762–833) and `_AgentBubble.build()` (~lines 667–680)

- [ ] **Step 1: Replace _ToolCallBlock with StatefulWidget version**

Find the entire `class _ToolCallBlock extends StatelessWidget {` definition and replace it with:

```dart
class _ToolCallBlock extends StatefulWidget {
  const _ToolCallBlock({
    required this.isRunning,
    required this.passageCount,
    required this.statusMessage,
    required this.accent,
    required this.isDark,
    required this.muted,
    required this.line,
  });

  final bool isRunning;
  final int passageCount;
  final String statusMessage;
  final Color accent;
  final bool isDark;
  final Color muted;
  final Color line;

  @override
  State<_ToolCallBlock> createState() => _ToolCallBlockState();
}

class _ToolCallBlockState extends State<_ToolCallBlock>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _alpha;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _alpha = Tween<double>(begin: 0.04, end: 0.14)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doneColor = const Color(0xFF2E9D5C);
    final blockBg = (widget.isDark ? AppColors.nightBg : AppColors.boneBg)
        .withValues(alpha: widget.isDark ? 0.6 : 1.0);
    final borderColor = widget.isRunning
        ? widget.accent.withValues(alpha: 0.35)
        : doneColor.withValues(alpha: 0.6);
    final fgColor = widget.isRunning ? widget.muted : doneColor;

    final label = widget.isRunning
        ? (widget.statusMessage.isNotEmpty ? widget.statusMessage : 'Searching…')
        : 'Found ${widget.passageCount} passage${widget.passageCount == 1 ? '' : 's'}';

    return AnimatedBuilder(
      animation: _alpha,
      builder: (_, child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: widget.isRunning
              ? widget.accent.withValues(alpha: _alpha.value)
              : blockBg,
          border: Border.all(color: borderColor, width: 0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isRunning)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(widget.accent),
              ),
            )
          else
            Icon(Icons.check_rounded, size: 14, color: doneColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: fgColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Add "Generating…" row in _AgentBubble**

In `_AgentBubble.build()`, inside the Column's `children` list, find:

```dart
                      // Initial loading state — visible before any preamble arrives
                      if (showLoadingDots) _ThinkingIndicator(accent: accent, muted: muted),
```

Add the "Generating…" row immediately BEFORE that line (so it appears after `_AnswerBody` which is above it in the Column order):

```dart
                      // Subtle "Generating…" row while answer is actively streaming
                      if (isStreaming && hasAnswer) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    muted.withValues(alpha: 0.5)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Generating…',
                              style: GoogleFonts.inter(
                                color: muted.withValues(alpha: 0.5),
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Initial loading state — visible before any preamble arrives
                      if (showLoadingDots) _ThinkingIndicator(accent: accent, muted: muted),
```

- [ ] **Step 3: Run analyzer**

```bash
dart analyze lib/features/chat/chat_screen.dart
```
Expected: `No issues found!`

- [ ] **Step 4: Visual test**

Run: `flutter run`
Send "What is the day of judgment?"
Expected sequence:
1. ~300ms: bouncing dots + "Thinking…"
2. Status pill appears with pulsing accent background + backend's status text
3. Preamble text (italic, muted) appears above the pill
4. Pill changes to "✓ Found N passages" (static, no pulse)
5. Answer streams in below; "Generating…" row visible with small spinner
6. "Generating…" disappears when stream completes; "N References ▸" chip appears

- [ ] **Step 5: Commit**

```bash
git add lib/features/chat/chat_screen.dart
git commit -m "feat: pulse animation on status pill + generating row during answer stream"
```

---

## Self-Review

### 1. Spec coverage

| Requirement | Task |
|---|---|
| Thinking indicator must show (bouncing dots) | Task 3 (300ms delay before SSE) |
| Status pill shows for any backend status message | Task 2 (robust `msg.isNotEmpty` trigger) |
| Preamble text shows italic/muted above pill | Task 1 + Task 4 (phase routing fix) |
| Status pill pulses while searching | Task 5 |
| "Generating…" feedback while answer streams | Task 5 |
| No UI theme/color scheme changes | All tasks use existing AppColors pattern ✓ |

### 2. Placeholder scan

No TBDs, no "add appropriate X" patterns. All code blocks are complete and runnable. ✓

### 3. Type consistency

- `isPreamble` — local `bool` in Task 4, used only within that handler ✓
- `_ToolCallBlock` constructor signature unchanged between Tasks 2 and 5 — all existing callsites pass same named params ✓
- `_pulse`, `_alpha` — private to `_ToolCallBlockState`, no external references ✓
