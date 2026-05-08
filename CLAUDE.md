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
    models/          # ReligionModel, SacredTextModel, UserModel, ChatMessage
    router/          # app_router.dart — GoRouter + redirect logic
    theme/           # AppColors, AppTheme
  data/
    texts_repository.dart   # loads assets/data/texts_catalog.json
    user_repository.dart    # Firestore CRUD for users/{uid}
    chat_repository.dart    # in-memory chat (Sprint 3: Firestore)
  features/
    splash/
    onboarding/      # intro (3 slides), religion select, text select
    auth/            # sign_in_screen.dart
    profile_setup/   # name + age collection after first sign-in
    home/
    chat/
    library/
    history/
    profile/         # "Self" tab — settings + tradition switcher
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

## Sprint Status

| Sprint | Focus | Status |
|---|---|---|
| 0 | Firestore foundation (UserModel, UserRepository, rules) | ✅ Done |
| 1 | User identity (UserProvider, ProfileSetupScreen, routing) | ✅ Done |
| 2 | Home screen redesign (greeting, input card, topics, verse) | ✅ Done |
| 3 | Claude AI integration (Cloud Functions proxy, streaming, citations) | 🔜 Next |
| 4 | Library & text explorer | ⬜ Planned |
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
