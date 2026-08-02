# Bookedex (BookShelf App)

## What This Is
Flutter/Dart mobile app (Android-first, iOS in Phase 2). Users capture book covers via photo, screenshot, or manual entry into a unified visual library. A mood quiz then rediscovers books from their own library — solving the "saved-list paradox." Not a social app. Not a Goodreads clone.

**App name:** Bookedex
**Package ID:** `com.bookedex.app`

## Where the code lives
**Working copy: `C:\dev\Book-Shelf-Project`.** Moved off OneDrive in Aug 2026 — OneDrive was syncing 3.2 GB (2.9 GB of it disposable `build/` output) against 2.7 MB of real git history, paths were already 369 chars against Windows' 260 limit, and OneDrive syncing `.git/` risks index corruption. Git is the sync mechanism; OneDrive added risk and nothing else.

A stale copy may still exist at `C:\Users\bodek\OneDrive\Documents\Bookshelf App\Book-Shelf-Project` pending deletion. **Check you are in `C:\dev` before editing** — edits have landed in the wrong copy before. Note Windows' shell "Documents" is redirected into OneDrive, so `C:\Users\bodek\Documents` is a *different*, non-synced folder from the one Explorer shows.

## Team
- **Bode** (me): sole developer
- **Richie**: product, UX/UI design, marketing
- **Margot**: target user, beta tester, user voice

## Tech Stack
| Layer | Choice |
|---|---|
| Frontend | Flutter / Dart |
| Backend | Firebase (Firestore, Auth) — Cloud Storage not needed until Phase 2 |
| Book Recognition | Google ML Kit on-device OCR → text → Open Library search |
| Book Data | **Open Library** (primary since #75). Google Books is commented out, not deleted — its corpus stopped returning mainstream titles |
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
6b. ✅ Cascading card stack on the review screen (#68) — next two queued cards staggered behind the current one, mounted in full so the photo *and* cover thumbnail are decoded before promotion; the deck animates forward during the fly-out so the queue advance is invisible. Also fixed the picker-return flash on Import and Capture.
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
- **No API key is currently needed.** Open Library is keyless (#75), so `.env` and the dart-define are optional and `main()`'s key assert is commented out. `.env` is kept for a fast switch back to Google Books.
- **If Google Books is ever re-enabled, its key is REQUIRED** — keyless calls return HTTP 429 (Google attributes them to a shared anonymous quota pool that is permanently exhausted; learned the hard way in #48/#50, and re-confirmed in #75). The key lives in `bookshelf_app/.env` (gitignored) and is injected at build time, not bundled: run with `flutter run --dart-define-from-file=.env`, read in code via `String.fromEnvironment('GOOGLE_BOOKS_API_KEY')`.
- **Honest threat model:** any key shipped in a client app is extractable — dart-define is obfuscation, not protection. The real security control is console-side: in Google Cloud Console, restrict the key to the Books API only and cap its daily quota. Books API is free with no billing attached, so a leaked key can only waste quota — no money or data at risk.
- The Firebase keys in `firebase_options.dart` / `google-services.json` are identifiers, not secrets — safe to commit. Data access is enforced by Firestore security rules, not by hiding these keys.
- **Before public launch:** enable Firebase App Check, and add Android package name + SHA-1 restrictions to the Firebase API keys AND the Books API key in Google Cloud Console.
- Never commit secrets to git. If a real secret is ever needed (paid API, etc.), it belongs behind a Cloud Function — never in the app.

## Release Builds (Android)
```
flutter build appbundle --dart-define-from-file=.env
```
The dart-define is **currently optional** — Open Library needs no key (#75). Keep using it out of habit: it costs nothing, and if Google Books is ever re-enabled it becomes mandatory again. The trap it used to hide is worth remembering: a keyless Google Books build failed *silently*, because `main()`'s assert is stripped in release, so recognition simply never worked with no error at all.

**Signing:** upload keystore at `C:\Users\bodek\keys\bookedex-upload-keystore.jks` (alias `upload`, RSA 2048, valid to Dec 2053), deliberately **outside the repo**. `android/key.properties` holds the path + passwords; it and `*.jks` / `*.keystore` are gitignored. `build.gradle.kts` falls back to debug signing when `key.properties` is absent, so a fresh clone still configures and `flutter run` works — meaning **a machine without those files silently produces a debug-signed bundle that Play will reject.** Verify with `keytool -printcert -jarfile <aab>`; it must show `CN=Bode Kaanta`, not `CN=Android Debug`.

**Three files git will never carry** — copy them by hand when moving machines: `.env`, `android/key.properties`, and the `.jks` keystore.

**R8:** `android/app/proguard-rules.pro` carries `-dontwarn` for ML Kit's chinese/devanagari/japanese/korean recognizer packages. The plugin's `initialize()` references the options class for every script, but we only bundle the Latin model, and R8 treats the absent ones as fatal missing references. **Release-only failure — it cannot reproduce in debug**, so always build the bundle before assuming a change is shippable. R8 also strips unused code, so a release build needs its own smoke test on a device.

**Icon:** source art `assets/icon/bookedex_icon.png`; regenerate with `dart run flutter_launcher_icons` after changing it (config in `pubspec.yaml`). Adaptive background `#EA3442` sampled from the art, 18% foreground inset so the launcher mask doesn't clip the B.

**Play requirements already met:** `targetSdk`/`compileSdk` 36, `minSdk` 24, `applicationId` `com.bookedex.app`, label "Bookedex". The **store-listing** icon must be exactly 512×512 — the source art is 513×513 and will be rejected until resized.

## Recognition Status (as of Aug 2026)
Pipeline: ML Kit OCR (bundled on-device model) → query builder → **Open Library search** → fuzzy rerank → confidence score. Recognition is driven by the Import flow; the POC dev screen was removed in #45.

### Data source switched to Open Library (#75, Aug 2026)
**Google Books stopped returning mainstream commercial books.** `isbn:9780593135204` (Project Hail Mary) and `isbn:9780553418026` (The Martian) both return `totalItems: 0`; `q=harry potter` returns academic commentary and no Rowling; every query returns exactly `totalItems: 300`. Ruled out as causes: an invalid key (a deliberately bad key returns HTTP 400 "API key not valid"; ours returns 200 with valid JSON), URL/protocol formatting (those produce 400s, not parsed volumes), and quota (keyless 429s, keyed requests succeed). `isbn:` is an exact index lookup, so this is not a query-builder problem. Cause unknown and possibly reversible — hence Google Books is commented out rather than deleted.

**Two behavioural differences that matter:**
- **Open Library returns `docs: []` on a miss; Google Books omitted `items` entirely.** Callers distinguish null (try another query) from results, so `_fetchBooks` must map empty → null or the retry paths are silently skipped.
- **Open Library's Solr matches literally; Google Books ranked by popularity and tolerated junk.** `q=HAIL` returns Project Hail Mary #1, but `q=HAIL AUTHOR OF` returns *Hail and farewell* / *The Merchant of Venice* — junk tokens actively poison the query rather than merely diluting it. Google's ranking was silently rescuing weak queries; that mask is now gone, which is what #78 addresses. Sorting cannot substitute: `sort=editions`/`readinglog`/`rating` flood results with Macbeth and King Lear by edition count.

**Confidence separation improved.** On the 20-photo run: correct matches 70–85%, incorrect 19–60% — a clean gap, versus Google's overlapping 62–90 / 0–70. Measured threshold is **0.65**, but it stays at 0.75 until #78 lands so we recalibrate once rather than twice.

**Current state: 7 of 20 recognised** on Margot's set. #78 (query builder) should recover ~6 more; the rest are destroyed OCR that belongs in manual search.

**Accepted known issue — high-confidence wrong match.** Blake Crouch's *Pines* matches "Wayward" (the next book in the series) at **100%**, so it auto-adds wrongly at any threshold. The photo is a Wikipedia screenshot listing the whole trilogy. Deliberately not fixed: a Wikipedia-article screenshot is a rarer shape than BookTok screenshots or real cover photos, and #78's junk filtering may drop the `en.wikipedia.org` chrome incidentally. Revisit only if beta shows it recurring.

**Field mapping:** `title`, `author_name[0]`, `cover_i` → `covers.openlibrary.org/b/id/{id}-M.jpg`, `number_of_pages_median`, `subject[0]` (title-cased) → genre. `search.json` carries **no description** — the book detail sidebar (step 7) will need a second `/works/{key}.json` fetch. `googleBooksId` now holds an Open Library work key; the name is a misnomer kept so existing Firestore docs and title+author dedup keep working. Subjects are noisy (LOTR's first subject is "The Lord of the Rings"; The False Prince's is "Impersonation"), so genre rows will look odd until tuned.

**`language:eng` does not work** — tested and rejected. Open Library searches *works*, which aggregate editions, so a work with any English edition matches while still displaying its original-language title. One Piece still returns 尾田栄一郎 with the filter on, and it costs ~20% of candidates.

**Accuracy:** initial clean-photo pass 9/12 (75%). After the recognition work below, a harder **real-world phone re-test** (bookstore photos: angled, busy shelves, promo/movie bands) landed at **~10/21 (~48%)** — a harder set than the POC, not a regression. This ~48% is the practical ceiling; the approval flow (step 6) is what makes imperfect recognition usable.

**The 21-photo test set is Margot's own collection** — every accuracy and confidence number above comes from real target-user photos, which is why ~48% is treated as the honest ceiling rather than something to tune away.

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

**Calibration — already done on real target-user photos.** The 21-photo phone set **is Margot's own collection**, so 0.75 is calibrated against real target-user data, not synthetic or developer-picked photos. There is no pending "recalibrate on Margot's photos" task. On that set correct matches scored 62–90% and incorrect ones 0–70%: the separation is genuinely weak, and that is a property of the confidence formula itself, not an artifact of an unrepresentative test set — so re-running the same photos won't improve it. 0.75 is the best compromise found. Only two things would move it: a better scorer, or beta data at a much larger N. Undo safety net exists in the notifier (`undoAutoAdd`, `deleteBook`); batch import surfaces a summary popup instead of per-book toasts.

**Import flow (#45):** Import tab → `ImportScreen` "Choose Photos" → `pickMultiImage` → `importImages` routing (progress loader "Recognizing X of N…") → summary popup ("N added · M to review", "Review"/"Later") → approval queue.

**Swipe / buttons (#43):** left = Incorrect (skip), right = Correct (save top guess), up = Manual Search. Buttons and swipes share one path. Card follows the finger with a tilt + fading ✓/✗/🔍 stamp, flies out on commit, springs back below threshold. Card is a keyed `_ReviewCard` owning its own drag offset (so advancing the queue disposes it cleanly — no snap-back flash). "See other matches" (`AnimatedSize`) reveals other candidates; tapping one approves it. A subtle "N to review" counter shows in the app bar. Perf: drag uses a `ValueNotifier` + `ValueListenableBuilder` (only the card rebuilds per frame — smooth in profile mode; debug is expectedly janky).

**Cascading card stack (#68, step 6b):** the next two queue items render staggered behind the current card, each translated down `_stackStep` (12) and scaled `_stackScaleStep` (0.04) about `Alignment.bottomCenter` — bottom-edge scaling pins the peek to exactly 12px per depth without measuring the card. Back cards are mounted **in full** (not photo-only): that pre-decodes the photo *and* the `Image.network` cover thumbnail, so promotion never pops content in. All cards share `cacheWidth: 1080` — a different decode width would mean a different image-cache key and the pre-decode would buy nothing.
The deck animates forward off the existing fly-out `AnimationController` (gated by `_committing`, so spring-back and manual search don't promote), reaching depth 0 — identity transform — before the queue advances, so the swap is invisible. **Bottom reserve is constant (`12 × _maxBackCards`), not scaled to queue depth:** otherwise the top card's own bounds change as the queue shrinks and every advance snaps. Costs ~24px of dead space under the last card; worth it for a card that never reflows. Stack is `Clip.none` so the committed card flies clear and shadows aren't cut off.

**No-OCR state:** "We couldn't read this one", Correct disabled — user searches (swipe up) or skips (swipe left).

**Manual search (#44):** swipe-up/button → `ManualSearchScreen` (auto-focused field, 350ms debounce, live results with covers via `BooksApiService.searchByText`, request-id guard). Picking a result approves it and advances; cancelling leaves the card.

**Step 6 issues — all merged:** #41 confidence score · #42 routing · #43 swipe card · #44 manual search · #45 Import wiring + summary popup (+ deleted `poc_screen.dart`) · #68 cascading card stack + picker-return flash.

**Follow-ups filed as issues:**
- **#66 (Option B import UX)** — process in the background, drop the user on their Library (auto-adds stream in live), show an in-app "N ready to review" prompt when done. Better for large camera-roll imports than the blocking loader, and the real fix for the residual per-book OCR hiccup (OCR can't be moved off the main isolate with this plugin).

**Ideas not yet created:**
- Edition-picker / custom cover — let the user choose among a book's Google Books editions so the cover matches their physical copy (no storage needed); true custom-photo covers need Cloud Storage = Phase 2.
- `inauthor:`-constrained retrieval — only worth it if beta shows common-title ambiguity is a recurring pain.
- Full "delight" import loading animation/game — Phase 2 polish.

## Key Files
```
bookshelf_app/lib/
├── main.dart                        — Firebase init, dotenv, anonymous auth, ProviderScope → MainScaffold
├── core/constants.dart              — openLibraryBaseUrl/UserAgent, bookLookupTimeout, autoAddConfidenceThreshold (0.75)
├── models/book.dart                 — Book model, fromOpenLibraryJson, fromFirestore, toFirestore (id, googleBooksId, dateAdded, genre, pageCount)
├── models/pending_book.dart         — PendingBook: one queued review card (imagePath, candidates, confidence; topGuess/otherMatches/hasResults)
├── services/book_recognition_service.dart  — ML Kit OCR → OcrResult (per-line text + bounding box + imageHeight + isScreenshot)
├── services/books_api_service.dart  — query builder, fuzzy rerank, confidence, searchByText (free-text for manual search). Fetches Open Library; Google Books path commented out below it
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
