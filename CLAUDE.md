# Bookedex (BookShelf App)

## What This Is
Flutter/Dart mobile app (Android-first, iOS in Phase 2). Users capture book covers via photo, screenshot, or manual entry into a unified visual library. A mood quiz then rediscovers books from their own library — solving the "saved-list paradox." Not a social app. Not a Goodreads clone.

**App name:** Bookedex
**Package ID:** `com.bookedex.app`

## Team
- **Bode** (me): sole developer
- **Richie**: product, UX/UI design, marketing
- **Margot**: target user, beta tester, user voice

## Tech Stack
| Layer | Choice |
|---|---|
| Frontend | Flutter / Dart |
| Backend | Firebase (Firestore, Auth) — Cloud Storage not needed until Phase 2 |
| Book Recognition | Google ML Kit on-device OCR → text → Google Books API |
| Book Data | Google Books API (primary), Open Library (fallback) |
| State Management | Riverpod |
| Notifications | In-app prompts only (NO push notifications in MVP) |
| Monetization | Google Play Billing (Pro tier), affiliate links (Phase 3) |

## MVP Scope (Phase 1) — Build This, Nothing Else
**Capture:**
- Camera → ML Kit OCR → Google Books API → approval screen
- Photo library batch import (individual confirm + "approve all" button) — includes screenshots (TikTok, Instagram, etc.), not just camera photos
- **Screenshot support is core functionality of the app — not an "MVP feature" and not phase-gated.** The founding idea is "pictures of books on your camera roll go in one place," and camera rolls are full of screenshots. It is never deferred, descoped, or treated as optional — a capture pipeline that can't handle screenshots is incomplete.
- Manual title/author entry fallback when recognition fails

**Library:**
- Visual grid dashboard of saved covers
- Book detail sidebar: buy links, summary, rating, genre, tags, shelves
- Basic manual shelves and tags
- Auto-sort by title, author, date added, genre

**Surfacing:**
- "What should I read?" quiz: 2-3 questions → ONE book from the user's library
- In-app housekeeping prompts on app open ("Do you still want this?" / "Did you read it?")

## NOT in MVP — Do Not Build Yet
- AI auto-tagging (Phase 2)
- Series awareness (Phase 2)
- External recommendations (Phase 3)
- Goodreads/StoryGraph import (Phase 3)
- Social sharing or friend features (Phase 3)
- iOS support (Phase 2)

## Critical UX Rules
- **No push notifications in MVP.** Margot turns off push notifications on almost every app. In-app prompts only, triggered on open.
- **Mood quiz surfaces ONE book, not a list.** The whole point is solving choice paralysis.
- **Quiz has only 2-3 questions.** Margot said "only 2 options."
- **Approval screen uncertainty threshold:** two paths only:
  1. High confidence (≥80%) → auto-add, user never sees it
  2. Low confidence (<80%) → show submitted photo + best guess side by side → Yes = added, No = manual entry
  - Edge case: if Google Books returns no results at all, skip straight to manual entry (no best guess to show)
- **Free tier:** up to 100 books, 3 shelves. **Pro ($2.99/mo or $19.99/yr):** unlimited books, shelves, mood filters, auto-cat, CSV export, themes.

## Build Order — Follow This Sequence
1. ✅ Flutter project + Firebase connected + running on physical Android device
2. ✅ **Proof of concept only:** photo → ML Kit OCR → Google Books API → display result (no DB, no UI polish)
3. ✅ Accuracy test (initial pass): 9 of 12 tested clean photos correct (75%) — query builder iteration done. **Re-run with the full 20–30 photo set after the OCR spatial filtering work (#46) to properly confirm the 80% gate.**
4. ✅ Firestore persistence layer
5. ✅ Visual dashboard — Home screen (Netflix-style rows) + Library screen (3-column grid, genre filter chips) + bottom nav (Home, Search, Capture, Import, Discover) + hamburger drawer (Full Library, Settings)
6. Approval/confirmation screen (with uncertainty threshold) ← **NEXT** — full design spec in section below
7. Book detail sidebar
8. Basic shelves and manual tags
9. Mood quiz → ONE recommendation flow
10. In-app housekeeping prompts

## Code Conventions
- No comments explaining what code does — use clear naming
- No abstractions beyond what the current feature needs
- No error handling for impossible scenarios — validate only at system boundaries (user input, API responses)
- No features, flags, or backwards-compatibility shims beyond current requirements
- Snake_case for Dart files
- Never commit API keys — use environment variables, add .env to .gitignore

## GitHub Workflow
- One issue per feature/bug, one branch per issue
- Branch naming: `task_X` where X is the issue number
- Every PR body must include `Closes #X` — this auto-closes the issue and moves it to Done on the project board when merged. No manual board updates needed.
- Size and assignee are set on the issue when it's created, not on the PR
- `gh` CLI is installed at `C:\Program Files\GitHub CLI\gh.exe` (also in user PATH after terminal restart)

### Creating issues — always follow this checklist:
1. `gh issue create` with `--assignee BodeKaanta` and `--label "Task"`
2. Add to the project board and get the item ID:
   ```
   gh api graphql -f query='mutation { addProjectV2ItemById(input: { projectId: "PVT_kwHOBJc_rc4BW00y", contentId: "<issue-node-id>" }) { item { id } } }'
   ```
3. Set the Size field on the project item (S for small, M for medium, L for large):
   ```
   gh api graphql -f query='mutation { updateProjectV2ItemFieldValue(input: { projectId: "PVT_kwHOBJc_rc4BW00y" itemId: "<item-id>" fieldId: "PVTSSF_lAHOBJc_rc4BW00yzhSGANw" value: { singleSelectOptionId: "<size-id>" } }) { projectV2Item { id } } }'
   ```
   Size option IDs: S = `f784b110`, M = `7515a9f1`, L = `817d0097`
   Project ID: `PVT_kwHOBJc_rc4BW00y`
   Size field ID: `PVTSSF_lAHOBJc_rc4BW00yzhSGANw`

### Updating CLAUDE.md:
- Always edit CLAUDE.md locally as a file and commit it through git — never via the GitHub API directly

## Starting a New Session
Always run these three commands at the start of a session to orient yourself before doing anything:
```
gh pr list --state open
gh issue list --label "Task" --state open
```
Then check the Build Order section to see the current step. The open issues tell you what's already planned; the open PRs tell you what's waiting to be merged. Don't create duplicate issues for work that's already tracked.

## Code + Testing Protocol
- **Always show the code change and explain it before applying it** — Bode is a student and wants to understand every change, not just see it happen
- **Never commit until Bode has tested the change on the emulator and confirmed it works** — the commit represents a known-working state
- The correct order is: write code → show and explain → apply edit → Bode tests → if good, then `git add` and commit → push → open PR
- This is standard professional practice: you test before you commit, not after

## Firebase / Data Notes
- AI tagging happens at ingest time only (when a book is added) — NOT at recommendation time
- Recommendations are served from pre-computed tags/metadata in Firestore — cheap database reads
- Open-ended AI queries are Pro-only with daily limits (when we get there)
- Cloud Storage not used in MVP — book cover art is stored as Google Books API URLs in Firestore, no file storage needed. (Screenshot import doesn't change this: screenshots are matched to a Google Books result and only the cover URL is stored.) Revisit in Phase 2 only if we ever need to keep the user's original photo as a fallback cover.

## API Keys & Secrets
- **Google Books API calls are made WITHOUT an API key** — the volumes endpoint doesn't require one (PR #48 removed the key and `flutter_dotenv`). Never add a key back to the client: anything bundled in the APK (assets, dart-defines, string constants) is extractable by anyone with a build.
- The Firebase keys in `firebase_options.dart` / `google-services.json` are identifiers, not secrets — safe to commit. Data access is enforced by Firestore security rules, not by hiding these keys.
- **Before public launch:** enable Firebase App Check, and add Android package name + SHA-1 restrictions to the Firebase API keys in Google Cloud Console.
- Never commit secrets to git. If a real secret is ever needed (paid API, etc.), it belongs behind a Cloud Function — never in the app.

## POC Status (as of May 2026)
The POC screen (`lib/screens/poc_screen.dart`) is fully running on the Android emulator.
Recognition pipeline: ML Kit OCR → smart query builder → Google Books API → display top result + debug info.

**Recognition results so far (clean photos):**
- ✅ Working: Dream Hotel, Fair Play, The Castle, Lord of the Rings, Pines, Unbecoming, Transformed, Project Hail Mary, The Notebook
- ⚠️ Near miss: Apeirogon (correct book appears in other matches but not best match — blurb text outscores the title)
- ❌ Still failing: The Cruel Prince (ML Kit misreads "PRINCE" as "PBCE" — candidate for fuzzy title matching against API results, see planned issue G), House of Government (garbled all-caps lines outscore the correct title-case title)
- 🔄 Not yet tested: Invisible Cities
- Current accuracy: 9 of 12 tested = 75% (counts from the lists above) — full 20–30 photo re-test planned after #46 lands, before declaring the 80% gate passed

**Bugs fixed (issues #2 and #3):**
- #2: Compound surnames (McCann, FitzGerald, O'Brien, DeLuca) were falsely flagged as OCR garbage — fixed with segment-split approach in `_isSuspiciousWord()`
- #3: `.take(12)` scan window was cutting off valid lines — removed entirely, scoring function is the guard against noise

**Query builder logic** (`lib/services/books_api_service.dart`):
- Filters: pure numbers, timestamps (`13:24`-style), OCR garbage (>25% of words have suspicious mixed casing), promotional lines (LONGLISTED, BESTSELLER, PRIZE, etc.)
- Words split at lowercase→uppercase boundaries to allow compound surnames before checking for garbage
- Scores ALL lines that pass filters (no scan window limit)
- Scoring: lines containing `:` score 0.85 (metadata format); ALL CAPS lines score high (book titles); title-case multi-word lines score 0.65 (author names like "Nicholas Sparks"); lines >25 chars are penalized
- OCR corrections applied first (`_applyOcrCorrections`, e.g. word-initial V before vowel → Y), falls back to the uncorrected query if the corrected one returns nothing
- Builds query from top 3 scoring lines, max 120 chars

## Dashboard Design Notes (Step 5 — Done)
Richie's Figma prototype: https://www.figma.com/make/QjDuOmFO2heo8XJkhrGesw/Design-Bookedex-Library-Screen

**What Richie designed:**
- Header: "Bookedex" title + "Good afternoon, [name]" greeting + user avatar
- Filter bar: sort icon + `+ Tag` button + mood filter chips (All, Cozy, Quick Read, Fiction, Intense, Feel Good, Classic…)
- Grid: 3-column masonry-style grid of book cover photos, each with 1–2 mood tag chips overlaid at bottom-left
- Bottom nav in Richie's design: Search, Capture, Import, Settings, Discover — **superseded**. Final implemented nav is **Home, Search, Capture, Import, Discover**; Settings lives in the hamburger drawer.

**Implementation notes:**
- Data is already in Firestore (`watchBooks()` stream is ready) — this step is mostly UI
- Each cover tile shows the `coverUrl` from the Book model (Google Books thumbnail URL)
- Mood tags on covers come from the `genre` field — for now display genre as the tag
- "Capture" bottom nav tab → entry point into capture flow (camera)
- "Import" bottom nav tab → entry point into batch photo import → feeds approval screen (step 6)

## Approval Screen Design Notes (Step 6 — After Dashboard)
**Concept:** Tinder-style swipe card UI. Only shown for books the system is uncertain about.

**Confidence threshold:**
- ≥80% confidence → auto-save silently, user never sees the card
- <80% confidence OR no OCR results → added to the approval queue

**Confidence scoring approach (not yet implemented):**
Derive a 0.0–1.0 score from the gap between the top result's internal query score and the second result's score. Large gap = high confidence. This requires changes to `BooksApiService` to expose the score alongside results.

**Calibration requirement:** the gap-based score is a homemade heuristic, not a real probability — "80%" on it means nothing until measured. Before trusting silent auto-add, run Margot's photo set through the scorer and check where correct vs. wrong matches actually land, then set the threshold from that data. Safety net for beta: auto-adds show a brief "Added [title]" toast with an Undo button, so silent additions are never invisible.

**Swipe gestures:**
- Swipe right → save the book to library
- Swipe left → skip/discard (book is not saved)
- Swipe up → open manual search overlay (keyboard rises, search bar at top, live results)

**Queue ordering:** Most confident first → least confident last. User gets easy confirms first and only has to type manually for the genuinely hard ones at the end.

**No-OCR state:** When OCR returned no usable text at all, the card shows the photo with "We couldn't read this one" and disables the right swipe — user must either search manually (swipe up) or skip (swipe left).

**Manual search overlay:**
- Triggered by swipe up
- Search bar at top, keyboard opens immediately
- Debounced Google Books API call as user types (Netflix-style live filtering)
- Tapping a result saves that book and advances to the next card

**POC screen note:** `poc_screen.dart` stays alive as a dev tool during step 6 development so books can still be added for testing the dashboard. Remove or repurpose it when step 6 is fully wired in.

**GitHub issues for step 6 (created 2026-06-18):**
- A. #41 — Add confidence score to `BooksApiService` search results (S)
- B. #42 — Confidence-based routing — auto-save ≥80%, queue <80% into approval flow (S)
- C. #43 — Build approval screen — tinder swipe card UI with all 3 states (L)
- D. #44 — Build manual search overlay — debounced live Google Books results (M)
- E. #45 — Wire approval screen into app, replace POC Save Book button (S)
- F. #46 — Screenshot-aware OCR filtering (M). Fixes TikTok screenshots where UI text (top AND bottom) outscores the actual book title. Agreed design:
  1. **Detect screenshots first** — image dimensions exactly match a device screen resolution / ~9:16 aspect ratio, no camera EXIF data. Camera photos skip all of the following, so the clean-photo accuracy results are untouched.
  2. **Zone downweighting** — penalize (don't discard) text in the top ~15% and bottom ~30% of detected screenshots (TikTok nav + caption areas).
  3. **Social-UI text filtering** — drop lines matching social patterns: `@handles`, `#hashtags`, known UI strings ("For You", "Following", "Add comment"), counts like "1.2M".
  4. **Text-size weighting** — use ML Kit bounding box heights: book titles are large display type, captions/usernames are small UI text.
  - Affects `BookRecognitionService` (return structured text + position + size data instead of raw String) and `BooksApiService` (incorporate the new signals into line scoring).
  - **After implementing: re-run the full clean-photo test set** — the scoring function is load-bearing for the accuracy gate.

**Planned but not yet created:**
- G. Fuzzy title matching — rescore Google Books candidates by edit distance between candidate title/author and the OCR lines, so misreads like "PBCE"→"PRINCE" (The Cruel Prince) and garbled lines (House of Government) can still match the right book. (M)

## Key Files
```
bookshelf_app/lib/
├── main.dart                        — Firebase init, dotenv, anonymous auth, ProviderScope → MainScaffold
├── core/constants.dart              — googleBooksBaseUrl
├── models/book.dart                 — Book model, fromGoogleBooksJson, fromFirestore, toFirestore (id, googleBooksId, dateAdded, genre, pageCount)
├── services/book_recognition_service.dart  — ML Kit OCR, returns raw String
├── services/books_api_service.dart  — query builder + Google Books API call
├── services/book_repository.dart    — BookRepository: addBook (with duplicate check), watchBooks, deleteBook
├── providers/recognition_provider.dart     — RecognitionState, bookRepositoryProvider, RecognitionNotifier (recognizeFromImage, saveBook)
├── providers/books_provider.dart    — booksStreamProvider: StreamProvider<List<Book>> wrapping watchBooks()
├── screens/main_scaffold.dart       — 5-tab NavigationBar shell (Home, Search, Capture, Import, Discover) + IndexedStack
├── screens/home_screen.dart         — Home screen: Netflix-style rows (Your Library + genre rows) + hamburger drawer
├── screens/library_screen.dart      — Library screen: 3-column grid, genre filter chips, alphabetical sort
├── screens/placeholder_screen.dart  — Reusable placeholder for Search, Capture, Discover tabs
└── screens/poc_screen.dart          — DEV TOOL: pick photo, show results, save book button — temporary until step 6
```

## Roadmap
| Phase | Timeline | Goal |
|---|---|---|
| MVP Build | May–Jul 2026 | Camera capture, visual library, mood quiz, in-app prompts |
| Beta | Aug–Sep 2026 | 20-50 users, mood tagging, iterate on UX |
| Launch v1.0 | Oct 2026 | Google Play, free + Pro tiers live — complete the pre-launch security steps in "API Keys & Secrets" first (App Check + key restrictions) |
| Phase 2 | Q1 2027 | iOS, AI auto-tagging, social sharing |
