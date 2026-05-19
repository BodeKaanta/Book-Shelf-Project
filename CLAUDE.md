# BookShelf App

## What This Is
Flutter/Dart mobile app (Android-first, iOS in Phase 2). Users capture book covers via photo, screenshot, or manual entry into a unified visual library. A mood quiz then rediscovers books from their own library — solving the "saved-list paradox." Not a social app. Not a Goodreads clone.

## Team
- **Bode** (me): sole developer
- **Richie**: product, UX/UI design, marketing
- **Margot**: target user, beta tester, user voice

## Tech Stack
| Layer | Choice |
|---|---|
| Frontend | Flutter / Dart |
| Backend | Firebase (Firestore, Auth, Cloud Storage) |
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
- **Approval screen uncertainty threshold:** high confidence = quick confirm; low confidence = show submitted photo + app's guess side by side, user says yes/no; unrecognized = manual input required.
- **Free tier:** up to 100 books, 3 shelves. **Pro ($2.99/mo or $19.99/yr):** unlimited books, shelves, mood filters, auto-cat, CSV export, themes.

## Build Order — Follow This Sequence
1. Flutter project + Firebase connected + running on physical Android device
2. **Proof of concept only:** photo → ML Kit OCR → Google Books API → display result (no DB, no UI polish)
3. Accuracy test: run Margot's 20-30 real photos through it, need ~80%+ on clean photos before proceeding
4. Firestore persistence layer
5. Approval/confirmation screen (with uncertainty threshold)
6. Visual dashboard (cover grid)
7. Book detail sidebar
8. Basic shelves and manual tags
9. Mood quiz → ONE recommendation flow
10. In-app housekeeping prompts
11. CSV export

## Code Conventions
- No comments explaining what code does — use clear naming
- No abstractions beyond what the current feature needs
- No error handling for impossible scenarios — validate only at system boundaries (user input, API responses)
- No features, flags, or backwards-compatibility shims beyond current requirements
- Snake_case for Dart files
- Never commit API keys — use environment variables, add .env to .gitignore

## Firebase / Data Notes
- AI tagging happens at ingest time only (when a book is added) — NOT at recommendation time
- Recommendations are served from pre-computed tags/metadata in Firestore — cheap database reads
- Open-ended AI queries are Pro-only with daily limits (when we get there)

## API Keys
- Google Books API key: provided by Richie (do not hardcode)
- Never commit secrets to git

## Roadmap
| Phase | Timeline | Goal |
|---|---|---|
| MVP Build | May–Jul 2026 | Camera capture, visual library, mood quiz, in-app prompts |
| Beta | Aug–Sep 2026 | 20-50 users, mood tagging, iterate on UX |
| Launch v1.0 | Oct 2026 | Google Play, free + Pro tiers live |
| Phase 2 | Q1 2027 | iOS, AI auto-tagging, screenshot OCR, social sharing |
