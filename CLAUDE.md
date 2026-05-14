# Divine Dialogue — Claude Code Guide

## Project

Flutter app: AI spiritual companion. Users ask questions about faith; AI answers with direct scripture citations from sacred texts (Quran, Hadith, Bible, Bhagavad Gita, Guru Granth Sahib, etc.).

Working directory: `codes/divine_dialogue/`
GitHub: `https://github.com/ronit450/divine_dialogue_app`
Data (texts): `../../data/` relative to Flutter project root

---

## Stack

| Layer | Choice |
|---|---|
| UI | Flutter 3.x |
| State | Riverpod (`StateNotifierProvider`) |
| Routing | GoRouter (`StatefulShellRoute`) |
| Backend | Firebase Auth + Cloud Firestore |
| AI | Anthropic Claude via Firebase Cloud Functions proxy |
| Local storage | SharedPreferences (flags) + Firestore (user data) |

---

## Architecture

Feature-first folder layout:

```
lib/
  core/
    models/
      scripture.dart        # ScriptureVerse, ScriptureChapter, ScriptureTextMeta, ScriptureTextType enum
    router/                 # app_router.dart — GoRouter + redirect logic
    theme/                  # AppColors, AppTheme
  data/
    texts_repository.dart      # loads assets/data/texts_catalog.json
    scripture_repository.dart  # loads all scripture assets (chunked + direct)
    user_repository.dart       # Firestore CRUD for users/{uid}
    chat_repository.dart       # in-memory chat (Sprint 3: Firestore)
  features/
    splash/
    onboarding/             # intro (3 slides), religion select, text select
    auth/                   # sign_in_screen.dart
    profile_setup/          # name + age collection after first sign-in
    home/
    chat/
    library/                # library_screen.dart — religion-filtered text cards (no chips, shows selected religion only)
    reader/
      reader_screen.dart    # scripture reader with per-type verse cards
      toc_sheet.dart        # showTocSheet (chapter list) + showPagedTocSheet (numeric jump)
    history/
    profile/                # "Self" tab — settings + tradition switcher
  providers/
    religion_provider.dart  # signInDone, onboardingDone, selectedReligion, selectedText
    auth_provider.dart      # Firebase Auth (Google, Apple, email, guest)
    user_provider.dart      # UserModel from Firestore
    chat_provider.dart      # session, messages, isTyping
    theme_provider.dart     # ThemeMode (light default)
  shared/
    widgets/
      religion_glyph.dart   # inline SVG glyphs via SvgPicture.string()
      glass_card.dart       # legacy glassmorphism — DO NOT use on new screens
```

---

## Router Logic

Three-stage redirect in `app_router.dart`:

```
!isLoaded       → null (wait for prefs to load)
!signInDone     → /onboarding  (allow: /onboarding/*, /sign-in)
!onboardingDone → /onboarding/religion  (allow: /onboarding/religion, /onboarding/text, /profile-setup, /sign-in)
both done       → /home  (redirect any pre-auth path)
```

Shell tabs: `/home`, `/chat`, `/library`, `/profile`
Outside shell (push on top): `/history`, `/profile-setup`, `/sign-in`, `/onboarding/*`, `/splash`

---

## Theme & Colors

**Always use the `isDark` pattern. Never use legacy dark aliases.**

```dart
final isDark   = Theme.of(context).brightness == Brightness.dark;
final bg       = isDark ? AppColors.nightBg      : AppColors.boneBg;
final fg       = isDark ? AppColors.nightFg      : AppColors.boneFg;
final muted    = isDark ? AppColors.nightMuted   : AppColors.boneMuted;
final line     = isDark ? AppColors.nightLine    : AppColors.boneLine;
final surface  = isDark ? AppColors.nightSurface : Colors.white;
```

**DO NOT USE** these legacy aliases — they are dark-only and will break light mode:
`AppColors.bg`, `AppColors.surface`, `AppColors.textPrimary`, `AppColors.textSecondary`,
`AppColors.textMuted`, `AppColors.userBubble`, `AppColors.aiBubble`

**DO NOT USE** `GlassCard` on new screens — replace with plain `Container` + `BoxDecoration`.

Religion accent colors:
- Islam → `AppColors.islamGreen` `#1F5D4C`
- Hinduism → `AppColors.hinduOrange` `#A8521B`
- Sikhism → `AppColors.sikhNavy` `#1E4D6B`
- Christianity → `AppColors.christianPurple` `#5D4A8A`

---

## Typography

| Use | Font | Style |
|---|---|---|
| Display / screen titles | `GoogleFonts.cormorantGaramond` | italic, w500 |
| Body / buttons / paragraphs | `GoogleFonts.inter` | regular/w500/w600 |
| Labels / chips / mono | `GoogleFonts.jetBrainsMono` | w500, letterSpacing 1.5 |

`GoogleFonts.geist` does NOT exist in the package — never use it.

---

## Key Conventions

```dart
// Deprecated — do not use
color.withOpacity(x)   // use: color.withValues(alpha: x)
color.value            // use: color.toARGB32()

// Lint
(_, __)   // use: (_, _)  — unnecessary_underscores

// Nullable trailing widget in Row
trailing ?? const SizedBox.shrink()
```

### State management rules
- `selectReligion()` is **sync** — no prefs write, prevents router rebuild cascade on card tap
- Router watches only `(isLoaded, signInDone, onboardingDone)` via `.select(...)` — prevents rebuild on every state change
- `completeSignIn()` sets `signInDone=true` synchronously then persists async
- `completeOnboarding()` persists religion + text + `onboarding_done` flag

### Firebase rules
- All Firestore writes go through `UserRepository.instance` — never write directly from widgets
- Guest users: `signInDone=true`, no Firestore profile, skip profile setup
- SHA-1 fingerprint must be registered in Firebase Console for Google Sign-In on Android

---

## Firestore Schema

```
users/{uid}
  firstName, lastName, age, religionId, selectedTextIds[],
  createdAt (Timestamp), lastActiveAt (Timestamp), tier ('free'), photoUrl?

users/{uid}/conversations/{convId}
  title, religionId, textId, createdAt, updatedAt, messageCount

users/{uid}/conversations/{convId}/messages/{msgId}
  text, isUser, citations[], timestamp

users/{uid}/savedVerses/{verseId}
  textId, reference, text, savedAt
```

Security rules: `firestore.rules` at project root — `request.auth.uid == userId` enforced.

---

## Reader Feature

### Scripture texts & asset layout

All scripture assets live in `assets/data/scripture/`. Two loading strategies:

**Direct load** (small files, all chapters in memory):
| Text ID | Asset file | Loader |
|---|---|---|
| `quran` | `scripture/quran.json` | `_loadQuran()` |
| `bhagavad_gita` | `scripture/gita.json` | `_loadGita()` |
| `bible_nrsv` | `scripture/bible.json` | `_loadBible()` |

**Chunked load** (large files, loaded on-demand per page/chapter):
| Text ID | Asset dir | Chunk size | Loader method |
|---|---|---|---|
| `guru_granth_sahib` | `scripture/ggs/` | 100 angs | `loadGgsAng(int)` |
| `dasam_granth` | `scripture/dasam/` | 100 pages | `loadDasamPage(int)` |
| `bhai_gurdas_vaaran` | `scripture/bgv/` | 10 vaars | `loadBgvVaar(int)` |
| `valmiki_ramayana` | `scripture/valmiki_ramayana/` | 50 sargas | `loadRamayanaSarga(int)` |
| `bukhari` | `scripture/bukhari/` | 10 chapters | `loadHadithChapter(textId, int)` |
| `muslim` | `scripture/muslim/` | 10 chapters | `loadHadithChapter(textId, int)` |
| `abu_dawud` | `scripture/abu_dawud/` | 10 chapters | `loadHadithChapter(textId, int)` |
| `tirmidhi` | `scripture/tirmidhi/` | 10 chapters | `loadHadithChapter(textId, int)` |
| `nasai` | `scripture/nasai/` | 10 chapters | `loadHadithChapter(textId, int)` |
| `ibn_majah` | `scripture/ibn_majah/` | 10 chapters | `loadHadithChapter(textId, int)` |

Chunked files named `{prefix}_{idx}.json` (idx zero-padded to 3 digits, e.g. `ggs_000.json`).

### ScriptureTextType enum

```dart
enum ScriptureTextType { quran, bible, gita, ggs, dasam, bgv, hadith, ramayana }
```

`hasTransliteration` → true for: `quran, ggs, dasam, bgv, gita, ramayana`

### Paged vs chapter-based texts

**Chapter-based** (all chapters loaded upfront, TOC list sheet):
- `quran`, `bhagavad_gita`, `bible_nrsv`
- Uses `showTocSheet(chapters: [...])` — scrollable chapter list with search

**Paged** (on-demand load, numeric jump sheet):
- `guru_granth_sahib`, `dasam_granth`, `bhai_gurdas_vaaran`, `valmiki_ramayana`, all hadith
- Uses `showPagedTocSheet(meta: ScriptureTextMeta)` — text input + quick-jump chips
- `_isPagedType` getter in reader_screen controls which flow is used

### Reader screen state

```dart
bool _showTranslation = true;
bool _showTranslit = true;
```

Reading options exposed via `Icons.tune_rounded` → `showModalBottomSheet` with `StatefulBuilder`.
Transliteration toggle only shown when `_meta?.hasTransliteration == true`.

### Verse card dispatch

```dart
ScriptureTextType.quran    => _quranCard()   // Arabic RTL + transliteration + translation
ScriptureTextType.ggs      => _sikhCard()    // Gurmukhi + Roman + translation
ScriptureTextType.dasam    => _sikhCard()
ScriptureTextType.bgv      => _sikhCard()
ScriptureTextType.gita     => _gitaCard()    // Sanskrit + transliteration + word meanings + translation
ScriptureTextType.bible    => _bibleCard()   // translation only
ScriptureTextType.hadith   => _hadithCard()  // chapter header + Arabic + translation + narrator/grade
ScriptureTextType.ramayana => _gitaCard()    // same layout as gita
```

### Hadith verse encoding

`ScriptureVerse.wordMeanings` stores `'$narrator\n$grade'` — parsed in `_hadithCard()`.

### Bottom navigation bar (reader)

Three buttons: `←` prev / `format_list_bulleted` TOC / `→` next.
TOC button is center, always visible regardless of scripture type.

### TOC sheet overflow fix

`_PagedTocSheet` uses `SingleChildScrollView` + `maxHeight` constraint instead of fixed height.
Keyboard inset handled via `SizedBox(height: MediaQuery.of(context).viewInsets.bottom)` at column bottom.

### Library screen

`ConsumerWidget` (not stateful). Shows only selected religion's texts — no filter chips.
Active religion = `selectedReligion ?? religions.first`.

### Data source files

Raw data lives at `../../data/jsons/` (relative to project root, i.e. two levels up from `codes/divine_dialogue/`):
- `islam/quran-complete.json` — flat list with `{number_of_surah, name, name_translations, verses[{number, text, translation_en, transliteration}]}`
- `islam/bukhari.json` etc — hadith collections
- `hindu/bhagavad-gita-complete.json` — `{verses:[{id, chapter, verse, sanskrit, transliteration, word_meanings, english}]}`
- `hindu/valmiki-ramayana-complete.json` — ramayana source

When replacing a scripture asset, write a Python conversion script to transform raw → app format, then output directly to `assets/data/scripture/`.

---

## Sprint Status

| Sprint | Focus | Status |
|---|---|---|
| 0 | Firestore foundation (UserModel, UserRepository, rules) | ✅ Done |
| 1 | User identity (UserProvider, ProfileSetupScreen, routing) | ✅ Done |
| 2 | Home screen redesign (greeting, input card, topics, verse) | ✅ Done |
| 2.5 | Reader feature (all 10 texts, chunked loading, TOC, reading options) | ✅ Done |
| 3 | Claude AI integration (Cloud Functions proxy, streaming, citations) | 🔜 Next |
| 4 | Library & text explorer (deep links, search across texts) | ⬜ Planned |
| 5 | Conversation history & persistence | ⬜ Planned |
| 6 | Daily engagement (verse of day, streaks, push notifications) | ⬜ Planned |
| 7 | Cross-tradition comparison | ⬜ Planned |
| 8 | Voice input & share cards | ⬜ Planned |
| 9 | Monetisation (freemium, RevenueCat) | ⬜ Planned |
| 10 | Polish & App Store launch | ⬜ Planned |

See `SPRINTS.md` for full feature breakdown.

---

## Running

```bash
flutter pub get
flutter run          # hot reload: r  |  full restart: R
dart analyze         # must be clean before every commit
```
