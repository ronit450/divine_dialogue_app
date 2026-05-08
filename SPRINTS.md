# Divine Dialogue — Sprint Plan

## Vision

Private AI spiritual companion. Users ask questions about their faith; app answers from the actual sacred texts with direct citations. Judgment-free, always available, deeply sourced.

**Unique edge**: Unlike Google or ChatGPT, every answer cites the exact verse, hadith number, chapter — so the user can go read it themselves. The AI is a guide into the texts, not a replacement for them.

---

## Sprint 0 — Firestore Foundation ✅

**Goal**: Durable data layer before any feature needs it.

| File | What |
|---|---|
| `lib/core/models/user_model.dart` | UserModel with Firestore serialization |
| `lib/data/user_repository.dart` | Singleton: createUser, getUser, updateUser, userStream |
| `firestore.rules` | Auth-scoped security rules (uid-locked) |

---

## Sprint 1 — User Identity ✅

**Goal**: Know who the user is from day one.

| Feature | Detail |
|---|---|
| Profile setup screen | Collect first name, last name, age after Google/Apple sign-in |
| UserProvider | Load/create/update UserModel from Firestore |
| Routing fix | `/sign-in` added to onboarding allowlist so profile-setup always fires |
| Guest mode | Skip profile setup, go straight to religion selection |

---

## Sprint 2 — Home Screen Redesign ✅

**Goal**: Personalized, beautiful home that makes the user want to open the app daily.

| Feature | Detail |
|---|---|
| Greeting | "Hello, [firstName]." — Cormorant italic, pulls from UserProvider |
| Input card | Rounded card with placeholder + Ask button — primary entry point |
| Topic chips | 6 starter topics (Prayer, Forgiveness, Afterlife, etc.) |
| Conversation history | Last 2 conversations with glyph circle + title |
| Daily verse card | Verse of the day with "Ask about this →" link |

---

## Sprint 3 — Claude AI Integration 🔜 NEXT

**Goal**: Make the chat actually work. Core product value unlocked here.

| Feature | Detail |
|---|---|
| Firebase Cloud Functions proxy | Node.js function calls Anthropic API — hides key from client |
| Model selection | `claude-haiku-4-5` for speed/cost, `claude-sonnet-4-6` for depth |
| System prompt engineering | Per-religion prompt: "You are a guide to [text]. Cite every answer with [format]." |
| Streaming responses | Server-sent events → Flutter `StreamBuilder` for live typing feel |
| Citation extraction | Parse `[Surah 2:286]`, `[Bukhari 1:1]` from response into tappable chips |
| Conversation persistence | Save messages to `users/{uid}/conversations/{convId}/messages` |
| Session title generation | Auto-generate title from first user message |
| Error handling | Graceful fallback if AI call fails; show toast, allow retry |

**Implementation order**:
1. Cloud Function: `POST /chat` → Anthropic API → stream back
2. `ChatRepository.sendMessage()` calls function, streams tokens
3. `ChatProvider` accumulates stream into message state
4. Citations parsed and rendered as tappable chips in bubble
5. Conversation saved to Firestore on session end

---

## Sprint 4 — Library & Text Explorer

**Goal**: Let users browse and read the sacred texts directly. Turns the app from a chatbot into a study tool.

| Feature | Detail |
|---|---|
| Library screen redesign | Browse by religion → text → chapter → verse |
| Text reader | Clean verse-by-verse reader, paginated |
| Full-text search | Query across all texts for the selected religion |
| Verse detail page | Verse + transliteration + translation options |
| **"Ask about this" ⭐** | From any verse, one tap → opens chat pre-loaded with that verse as context |
| Bookmark verse | Save to `savedVerses` collection; shows in home |
| Reading progress | Track last-read position per text |

> **"Ask about this"** is the highest-priority feature in the entire roadmap (see priority matrix below).
> The user reads a verse, doesn't understand it, taps — and now they're in a conversation about exactly that verse with full context injected. No other app has this flow.

---

## Sprint 5 — Conversation History & Persistence

**Goal**: Make conversations feel permanent and valuable, not disposable.

| Feature | Detail |
|---|---|
| History screen | Full list of past conversations, sorted by recency |
| Conversation card | Title, religion glyph, date, message count, excerpt |
| Continue conversation | Tap any item → resume where you left off (load messages from Firestore) |
| Search conversations | Keyword search across all past messages |
| Delete conversation | Swipe to delete with undo snackbar |
| Export conversation | Share as plain text or PDF |

---

## Sprint 6 — Daily Engagement

**Goal**: Build a daily habit. Users who return every day become lifelong subscribers.

| Feature | Detail |
|---|---|
| Verse of the Day algorithm | Personalised by tradition; curated rotation; never repeats within 90 days |
| Daily streak | "Day 7 of dialogue" on home screen; resets if missed |
| Push notifications | Morning verse notification; configurable time; deep-links to verse |
| Seasonal content | Ramadan (daily Quran), Advent (daily Gospel), Diwali (Gita), Gurpurab (Gurbani) |
| Reading plans | "30 Days in the Gita", "Quran in 3 Months", "Psalms in a Week" — structured daily reading |
| Streak recovery | One free skip per week, like Duolingo — prevents streak anxiety |

---

## Sprint 7 — Cross-Tradition Comparison

**Goal**: Unlock the multi-religion positioning. What makes Divine Dialogue fundamentally different from any single-religion app.

| Feature | Detail |
|---|---|
| Compare mode | One question → answers from all 4 traditions side by side |
| Parallel wisdom | Topic cards (Love, Death, Forgiveness, Gratitude) → auto-comparison |
| All Paths mode | Wire the "All Paths" card from onboarding for multi-tradition users |
| Scholar mode | Full citation chain: hadith grade (Sahih/Hasan), chapter lineage, variant readings |
| Tradition insights | "3 traditions agree on this point" summary label |

---

## Sprint 8 — Voice & Share

**Goal**: Native feel for spiritual moments — prayer time, commute, night reflection.

| Feature | Detail |
|---|---|
| Voice input | Speech-to-text for questions — hands-free use during prayer |
| Text-to-speech | AI reads response aloud; useful for commute or visually impaired users |
| Share as image | Beautiful quote card (verse + context + branding) for WhatsApp/Instagram |
| Share conversation excerpt | Pick any AI response → share as styled image |
| Copy verse | One tap copy with citation formatted for WhatsApp (`Quran 2:286 — ...`) |

---

## Sprint 9 — Monetisation

**Goal**: Sustainable business that doesn't punish spiritual seekers.

| Tier | Features | Price |
|---|---|---|
| Free | 10 AI questions/day, 1 reading plan, verse of day | Free |
| Seeker | Unlimited questions, all reading plans, voice input | ~$4.99/mo |
| Scholar | Everything + scholar mode, comparison mode, export | ~$9.99/mo |

| Feature | Detail |
|---|---|
| RevenueCat integration | Cross-platform subscription management (iOS + Android) |
| Paywall screen | Contextual paywall shown when free limit hit |
| 7-day free trial | For Seeker tier |
| Referral | Share app → 7 extra free questions for both parties |

**Rule**: Never paywall verse of day, basic library browsing, or one tradition. Free tier must provide genuine spiritual value.

---

## Sprint 10 — Polish & Launch

**Goal**: App Store ready.

| Area | Tasks |
|---|---|
| Accessibility | Screen reader labels on all custom widgets; font scaling; WCAG AA contrast |
| Performance | Flutter DevTools profiling; eliminate scroll jank; image caching |
| Crash reporting | Firebase Crashlytics + Performance Monitoring |
| App Store assets | Screenshots (6.5", 5.5"), preview video, icon variants |
| Legal | Privacy policy (GDPR + CCPA), terms of service, data deletion flow |
| Submission | iOS TestFlight beta → App Store; Google Play closed testing → production |

---

## Feature Priority Matrix

Ranked by: (user impact × uniqueness) ÷ build effort

| # | Feature | Impact | Uniqueness | Effort | Score |
|---|---|---|---|---|---|
| 1 | **"Ask about this" from Library** | ★★★★★ | ★★★★★ | ★★ | **25** |
| 2 | Streaming AI with citations | ★★★★★ | ★★★★ | ★★★ | **20** |
| 3 | Cross-tradition comparison | ★★★★ | ★★★★★ | ★★★ | **20** |
| 4 | Daily verse + push notifications | ★★★★ | ★★★ | ★★ | **12** |
| 5 | Reading plans | ★★★★ | ★★★ | ★★ | **12** |
| 6 | Voice input | ★★★ | ★★★ | ★★ | **9** |
| 7 | Share as image | ★★★ | ★★★ | ★★ | **9** |
| 8 | Scholar mode | ★★★ | ★★★★ | ★★★ | **9** |
| 9 | Conversation export | ★★ | ★★ | ★ | **4** |

---

## Recommended Build Order

```
Sprint 3  →  Sprint 4 ("Ask about this")  →  Sprint 5  →  Sprint 6  →  Sprint 7
```

After Sprint 3 (AI core), build the Library + "Ask about this" before anything else.
It is the highest-impact feature, most unique in the market, and creates the deepest engagement loop.

---

## Engagement Loop (Target State)

```
Morning notification
  → Verse of Day on home screen
    → "Ask about this" → chat conversation
      → "Read more in the Library" → Library reader
        → Find a verse → "Ask about this" → deeper conversation
          → Save verse to bookmarks
            → Streak maintained
              → Next morning notification
```

This loop compounds: more reading → more questions → deeper understanding → more reading.
Every feature in this roadmap either starts, deepens, or sustains this loop.
