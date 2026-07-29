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
3. ✅ Accuracy test: initial pass 9/12 clean photos (75%); after the recognition work (#46/#52/#55/#60) a harder **real-world phone re-test** (bookstore photos: angled, busy shelves, promo bands) landed at **~10/21 (~48%)**. See "Recognition Status" — the ~48% is the honest ceiling for hard photos; the approval flow (step 6) is what makes imperfect recognition usable, so we stopped tuning and moved on.
4. ✅ Firestore persistence layer
5. ✅ Visual dashboard — Home screen (Netflix-style rows) + Library screen (3-column grid, genre filter chips) + bottom nav (Home, Search, Capture, Import, Discover) + hamburger drawer (Full Library, Settings)
6. ✅ Approval/confirmation screen (with uncertainty threshold) — confidence routing (#41/#42), Tinder swipe review card (#43), manual search (#44), Import-tab wiring + summary popup (#45). Details in section below.
6a. ✅ Camera capture (#67) — Capture tab takes a single photo (`ImageSource.camera`) → the same `importImages` routing → auto-add (snackbar + Undo), open the approval card, or "already in library".

**Import resolution strategy (perf):** batch import downscales at pick time (`maxWidth/maxHeight: 2000`) so ML Kit isn't chewing 12MP photos per book — a per-book hiccup on a busy import reads as jank (matters for the influencer demo) and even blocked tab-switching at full res. Camera capture stays **full resolution** on purpose: it's a single image, so the OCR cost is a one-time wait, not a repeating hiccup, and full res gives the best recognition (e.g. thin/vertical cover text like *Authority*, which fails when downscaled). The proper fix to remove the residual batch hiccup entirely is background processing (#66) — OCR can't be moved off the main isolate with this plugin.

**Import writes + dedup:** confident auto-adds are collected during the loop and written in **one `WriteBatch` after the loop** (not per book) — avoids N Firestore writes + N Home rebuilds mid-import. Duplicate detection matches on **title + author** (not just `googleBooksId`), so two captures of the same book that resolve to different Google Books editions don't both get added. Duplicates on the swipe/manual-search path show an "already in your library" snackbar; the import summary shows an "N already in your library" line.
7. Book detail sidebar ← **NEXT**
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
- **Google Books API key is REQUIRED** — keyless calls return HTTP 429 (Google attributes them to a shared anonymous quota pool that is permanently exhausted; learned the hard way in #48/#50). The key lives in `bookshelf_app/.env` (gitignored) and is injected at build time, not bundled: run with `flutter run --dart-define-from-file=.env`, read in code via `String.fromEnvironment('GOOGLE_BOOKS_API_KEY')`. Debug builds assert the key is present in `main()`.
- **Honest threat model:** any key shipped in a client app is extractable — dart-define is obfuscation, not protection. The real security control is console-side: in Google Cloud Console, restrict the key to the Books API only and cap its daily quota. Books API is free with no billing attached, so a leaked key can only waste quota — no money or data at risk.
- The Firebase keys in `firebase_options.dart` / `google-services.json` are identifiers, not secrets — safe to commit. Data access is enforced by Firestore security rules, not by hiding these keys.
- **Before public launch:** enable Firebase App Check, and add Android package name + SHA-1 restrictions to the Firebase API keys AND the Books API key in Google Cloud Console.
- Never commit secrets to git. If a real secret is ever needed (paid API, etc.), it belongs behind a Cloud Function — never in the app.

## Recognition Status (as of Jul 2026)
Pipeline: ML Kit OCR (bundled on-device model) → query builder → Google Books API → fuzzy rerank → confidence score. Recognition is driven by the Import flow; the POC dev screen was removed in #45.

**Accuracy:** initial clean-photo pass 9/12 (75%). After the recognition work below, a harder **real-world phone re-test** (bookstore photos: angled, busy shelves, promo/movie bands) landed at **~10/21 (~48%)** — a harder set than the POC, not a regression. This ~48% is the practical ceiling; the approval flow (step 6) is what makes imperfect recognition usable.

**Key constraint — OCR can't be improved app-side:** ML Kit's text model is BUNDLED (`com.google.mlkit:text-recognition:16.0.1`), identical across plugin versions and devices — NOT served via Play Services. Bumping the plugin (tried & closed in #56) doesn't change it. The physical device (arm64) reads worse than the emulator (x86_64) on the same model, so **always validate recognition on the physical device — the emulator flatters results.**

**Recognition work shipped:**
- #46 — screenshot-aware filtering: detect screenshot by portrait aspect ratio ≥1.85; zone downweighting + text-size weighting (screenshot-only, to protect clean-photo scoring); social-UI line filtering
- #52 — fuzzy title matching: rerank candidates by normalized-Levenshtein similarity of title+author to the OCR (title 60% / author 40%); reorders only above a 0.6 threshold
- #55 — query-builder junk filtering (taglines like "A NOVEL", publishers, review attributions, bestseller bands), letter-collapse ("NoTEB O O K"→"NoTEBOOK"), leading-operator stripping, and match-aware relaxation (retry with leading words when nothing matches the OCR)
- #60 — drop edition/series ("10th Anniversary Edition", "Book 2 of the…") and film/TV adaptation banners
- ⛔ Reverted: size-weighting for ALL photos (#58) regressed accuracy 10→7 — size doesn't reliably track the title on real covers. Size weighting stays screenshot-only.

**Genuinely-hard cases → manual fallback (step 6), not more tuning:** destroyed OCR (e.g. "ANDY WEIR"→"WET R"), heavily stylized/embossed title fonts, common titles with no author captured.

**Query builder logic** (`lib/services/books_api_service.dart`):
- Filters (drop lines that are never search terms): length 4–40 chars, pure numbers, timestamps, OCR garbage (>25% suspicious mixed-case words), promotional/bestseller/adaptation banners, generic taglines, publisher names, review attributions (leading dash — also a Google negation operator), edition/series metadata; social-UI lines on screenshots.
- Scoring: `:` lines 0.85; ALL CAPS high (titles); title-case multi-word 0.65 (author names); long lines penalized. Screenshots additionally apply zone + size multipliers.
- `_applyOcrCorrections` (word-initial V→Y) + `_collapseSpacedLetters`; query = top 3 scoring lines joined (max 120 chars).
- After fetch: fuzzy rerank (#52) + match-aware relaxation; `searchBooks` also returns a 0–1 confidence (#41).

**Earlier bug fixes (#2, #3):** compound surnames (McCann, O'Brien…) no longer flagged as garbage (segment-split in `_isSuspiciousWord`); removed the `.take(12)` scan window (scoring is the guard).

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

## Approval Screen Design Notes (Step 6 — Done)
Tinder-style swipe review card, only shown for books the system is uncertain about. Built in `screens/approval_screen.dart` (+ `manual_search_screen.dart`, `import_screen.dart`), driven by `providers/import_provider.dart`.

**Confidence threshold — 75% (provisional):**
- ≥75% → auto-save silently
- <75% OR no confident match → approval queue

**Confidence scoring (implemented, `BooksApiService._confidence`):** `0.7 × topMatch + 0.3 × margin`, where topMatch is the #52 fuzzy similarity of the best result to the OCR and margin is how clearly it beats the runner-up (ambiguous common titles score lower). This *superseded* the original "gap between query scores" idea.

**Calibration:** still a homemade heuristic. 21-photo phone set showed correct matches 62–90%, incorrect 0–70% — usable but weak separation, so 75% is provisional; **recalibrate on Margot's real photos**. Undo safety net exists in the notifier (`undoAutoAdd`, `deleteBook`); batch import surfaces a summary popup instead of per-book toasts.

**Import flow (#45):** Import tab → `ImportScreen` "Choose Photos" → `pickMultiImage` → `importImages` routing (progress loader "Recognizing X of N…") → summary popup ("N added · M to review", "Review"/"Later") → approval queue.

**Swipe / buttons (#43):** left = Incorrect (skip), right = Correct (save top guess), up = Manual Search. Buttons and swipes share one path. Card follows the finger with a tilt + fading ✓/✗/🔍 stamp, flies out on commit, springs back below threshold. Card is a keyed `_ReviewCard` owning its own drag offset (so advancing the queue disposes it cleanly — no snap-back flash). "See other matches" (`AnimatedSize`) reveals other candidates; tapping one approves it. A subtle "N to review" counter shows in the app bar. Perf: drag uses a `ValueNotifier` + `ValueListenableBuilder` (only the card rebuilds per frame — smooth in profile mode; debug is expectedly janky).

**No-OCR state:** "We couldn't read this one", Correct disabled — user searches (swipe up) or skips (swipe left).

**Manual search (#44):** swipe-up/button → `ManualSearchScreen` (auto-focused field, 350ms debounce, live results with covers via `BooksApiService.searchByText`, request-id guard). Picking a result approves it and advances; cancelling leaves the card.

**Step 6 issues — all merged:** #41 confidence score · #42 routing · #43 swipe card · #44 manual search · #45 Import wiring + summary popup (+ deleted `poc_screen.dart`).

**Follow-ups filed as issues:**
- **#66 (Option B import UX)** — process in the background, drop the user on their Library (auto-adds stream in live), show an in-app "N ready to review" prompt when done. Better for large camera-roll imports than the blocking loader, and the real fix for the residual per-book OCR hiccup (OCR can't be moved off the main isolate with this plugin).
- **#68 (step 6b — cascading card stack)** — show the next queued cards staggered behind the current review card (Pokémon TCG Pocket-style); shows queue depth AND pre-renders the next card's image to kill the between-card pause. Also tracks a small import-transition flash (Import start screen shows for a frame before the loader).

**Ideas not yet created:**
- Edition-picker / custom cover — let the user choose among a book's Google Books editions so the cover matches their physical copy (no storage needed); true custom-photo covers need Cloud Storage = Phase 2.
- `inauthor:`-constrained retrieval — only worth it if beta shows common-title ambiguity is a recurring pain.
- Full "delight" import loading animation/game — Phase 2 polish.

## Key Files
```
bookshelf_app/lib/
├── main.dart                        — Firebase init, dotenv, anonymous auth, ProviderScope → MainScaffold
├── core/constants.dart              — googleBooksBaseUrl, autoAddConfidenceThreshold (0.75)
├── models/book.dart                 — Book model, fromGoogleBooksJson, fromFirestore, toFirestore (id, googleBooksId, dateAdded, genre, pageCount)
├── models/pending_book.dart         — PendingBook: one queued review card (imagePath, candidates, confidence; topGuess/otherMatches/hasResults)
├── services/book_recognition_service.dart  — ML Kit OCR → OcrResult (per-line text + bounding box + imageHeight + isScreenshot)
├── services/books_api_service.dart  — query builder, fuzzy rerank, confidence, searchByText (free-text for manual search)
├── services/book_repository.dart    — BookRepository: addBook (returns doc id, null if dup), addBooks (one WriteBatch for import), deleteBook, watchBooks. Dedup = same googleBooksId OR same title+author (catches different Google Books editions)
├── providers/recognition_provider.dart     — bookRepositoryProvider (+ RecognitionNotifier, now unused — kept in case the camera flow ever wants a single-photo notifier)
├── providers/import_provider.dart   — ImportNotifier: importImages routing (collects confident matches → one batched addBooks after the loop), approval queue, autoAdded list, undoAutoAdd/approveTop/rejectTop, addedCount/alreadyInLibrary/reviewCount/progress
├── providers/books_provider.dart    — booksStreamProvider: StreamProvider<List<Book>> wrapping watchBooks()
├── screens/main_scaffold.dart       — 5-tab NavigationBar shell (Home, Search, Capture, Import, Discover) + IndexedStack
├── screens/home_screen.dart         — Home screen: Netflix-style rows (Your Library + genre rows) + hamburger drawer
├── screens/library_screen.dart      — Library screen: 3-column grid, genre filter chips, alphabetical sort
├── screens/capture_screen.dart      — Capture tab: Take Photo (camera) → single-photo routing → auto-add (snackbar+Undo) / review / duplicate
├── screens/import_screen.dart       — Import tab: Choose Photos → routing (progress) → summary popup → review queue
├── screens/approval_screen.dart     — Tinder swipe review card (keyed _ReviewCard: drag/animations, see-other-matches, no-OCR/complete states)
├── screens/manual_search_screen.dart — debounced live Google Books search, returns the picked Book
└── screens/placeholder_screen.dart  — Reusable placeholder for the Search and Discover tabs (Home/Capture/Import are real)
```

## Roadmap
| Phase | Timeline | Goal |
|---|---|---|
| MVP Build | May–Jul 2026 | Camera capture, visual library, mood quiz, in-app prompts |
| Beta | Aug–Sep 2026 | 20-50 users, mood tagging, iterate on UX |
| Launch v1.0 | Oct 2026 | Google Play, free + Pro tiers live — complete the pre-launch security steps in "API Keys & Secrets" first (App Check + key restrictions) |
| Phase 2 | Q1 2027 | iOS, AI auto-tagging, social sharing |
