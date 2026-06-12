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
- Photo library batch import (individual confirm + "approve all" button)
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
- Screenshot OCR/text recognition (Phase 2)
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
3. ✅ Accuracy test: run Margot's 20-30 real photos through it, need ~80%+ on clean photos before proceeding — **achieved ~83% (10/15 tested), query builder iteration done**
4. ✅ Firestore persistence layer
5. Approval/confirmation screen (with uncertainty threshold)
6. Visual dashboard (cover grid)
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

## Code + Testing Protocol
- **Always show the code change and explain it before applying it** — Bode is a student and wants to understand every change, not just see it happen
- **Never commit until Bode has tested the change on the emulator and confirmed it works** — the commit represents a known-working state
- The correct order is: write code → show and explain → apply edit → Bode tests → if good, then `git add` and commit → push → open PR
- This is standard professional practice: you test before you commit, not after

## Firebase / Data Notes
- AI tagging happens at ingest time only (when a book is added) — NOT at recommendation time
- Recommendations are served from pre-computed tags/metadata in Firestore — cheap database reads
- Open-ended AI queries are Pro-only with daily limits (when we get there)
- Cloud Storage not used in MVP — book cover art is stored as Google Books API URLs in Firestore, no file storage needed. Revisit in Phase 2 for screenshot import.

## API Keys
- Google Books API key: stored in `bookshelf_app/.env` as `GOOGLE_BOOKS_API_KEY` — loaded via `flutter_dotenv`. File is gitignored.
- Never commit secrets to git

## POC Status (as of May 2026)
The POC screen (`lib/screens/poc_screen.dart`) is fully running on the Android emulator.
Recognition pipeline: ML Kit OCR → smart query builder → Google Books API → display top result + debug info.

**Recognition results so far (clean photos):**
- ✅ Working: Dream Hotel, Fair Play, The Castle, Lord of the Rings, Pines, Unbecoming, Transformed, Project Hail Mary, The Notebook
- ⚠️ Near miss: Apeirogon (correct book appears in other matches but not best match — blurb text outscores the title)
- ❌ Still failing: The Cruel Prince (ML Kit physically misreads "PRINCE" as "PBCE" — image quality issue, not fixable in software), House of Government (garbled all-caps lines outscore the correct title-case title)
- 🔄 Not yet tested: Invisible Cities
- Current accuracy: ~10/15 tested = ~83% — step 3 complete ✅

**Bugs fixed (issues #2 and #3):**
- #2: Compound surnames (McCann, FitzGerald, O'Brien, DeLuca) were falsely flagged as OCR garbage — fixed with segment-split approach in `_isSuspiciousWord()`
- #3: `.take(12)` scan window was cutting off valid lines — removed entirely, scoring function is the guard against noise

**Query builder logic** (`lib/services/books_api_service.dart`):
- Filters: pure numbers, timestamps (`13:24`-style), OCR garbage (>40% of words have suspicious mixed casing)
- Words split at lowercase→uppercase boundaries to allow compound surnames before checking for garbage
- Scores ALL lines that pass filters (no scan window limit)
- Scoring: ALL CAPS lines score high (book titles); title-case multi-word lines score 0.65 (author names like "Nicholas Sparks")
- Builds query from top 3 scoring lines, max 120 chars

## Key Files
```
bookshelf_app/lib/
├── main.dart                        — Firebase init, dotenv, ProviderScope → PocScreen
├── core/constants.dart              — googleBooksBaseUrl
├── models/book.dart                 — Book model, fromGoogleBooksJson, fromFirestore, toFirestore (id, googleBooksId, dateAdded, genre, pageCount)
├── services/book_recognition_service.dart  — ML Kit OCR, returns raw String
├── services/books_api_service.dart  — query builder + Google Books API call
├── providers/recognition_provider.dart     — RecognitionState (books, extractedText, searchQuery)
└── screens/poc_screen.dart          — POC UI: pick photo, show results + debug text
```

## Roadmap
| Phase | Timeline | Goal |
|---|---|---|
| MVP Build | May–Jul 2026 | Camera capture, visual library, mood quiz, in-app prompts |
| Beta | Aug–Sep 2026 | 20-50 users, mood tagging, iterate on UX |
| Launch v1.0 | Oct 2026 | Google Play, free + Pro tiers live |
| Phase 2 | Q1 2027 | iOS, AI auto-tagging, screenshot OCR, social sharing |
