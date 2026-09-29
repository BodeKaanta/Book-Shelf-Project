# Bookedex (BookShelf App)

## What This Is
Flutter/Dart mobile app (Android-first; **iOS pulled forward from Phase 2 to unblock the beta** — see "iOS + Beta Distribution"). Users capture book covers via photo, screenshot, or manual entry into a unified visual library. A mood quiz then rediscovers books from their own library — solving the "saved-list paradox." Not a social app. Not a Goodreads clone.

**App name:** Bookedex
**Package ID:** `com.bookedex.app`

## Where the code lives
**Working copy: `C:\dev\Book-Shelf-Project`.** Moved off OneDrive in Aug 2026 — OneDrive was syncing 3.2 GB (2.9 GB of it disposable `build/` output) against 2.7 MB of real git history, paths were already 369 chars against Windows' 260 limit, and OneDrive syncing `.git/` risks index corruption. Git is the sync mechanism; OneDrive added risk and nothing else.

A stale copy may still exist at `C:\Users\bodek\OneDrive\Documents\Bookshelf App\Book-Shelf-Project` pending deletion. **Check you are in `C:\dev` before editing** — edits have landed in the wrong copy before. Note Windows' shell "Documents" is redirected into OneDrive, so `C:\Users\bodek\Documents` is a *different*, non-synced folder from the one Explorer shows.

**Second working copy on a Mac: `/Users/suvikaanta/dev/Book-Shelf-Project`** — Bode's sister's MacBook, added Sep 2026 to build iOS. It is a normal clone; git is the only thing that moves work between the two machines. The four files git will never carry have to be hand-copied — on the Mac only `.env` is actually needed (see "iOS + Beta Distribution").

## Team
- **Bode** (me): sole developer
- **Richie**: product, UX/UI design, marketing
- **Margot**: target user, beta tester, user voice

## Tech Stack
| Layer | Choice |
|---|---|
| Frontend | Flutter / Dart |
| Backend | Firebase (Firestore, Auth) — Cloud Storage not needed until Phase 2 |
| Book Recognition | Google ML Kit on-device OCR → text → Google Books search |
| Book Data | **Google Books** (primary; recovered in #81). **Open Library** stays live as a fallback, used only on transport failure — timeout/429/5xx |
| State Management | Riverpod |
| Notifications | In-app prompts only (NO push notifications in MVP) |
| Monetization | **Premium — a one-time purchase (~$15, TBC with Richie)** unlocking unlimited books and Richie's themes. Not a subscription: this is a shelf, and people resent renting one. Affiliate links deferred past beta |

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
- **Search your own library** (#100) — added Sep 2026 at Richie's request; it was missing from this list. Distinct from `manual_search_screen.dart`, which searches Google Books to *add* a book. See "Bottom nav — what each tab is for" under Dashboard Design Notes.

**Surfacing:**
- "What should I read?" quiz: 2-3 questions → ONE book from the user's library
- In-app housekeeping prompts on app open ("Do you still want this?" / "Did you read it?")

## NOT in MVP — Do Not Build Yet
- AI auto-tagging — **moved to "Potential ideas" (Sep 2026)**, no longer a scheduled Phase 2 item
- Series awareness (Phase 2)
- External recommendations (Phase 3)
- Goodreads/StoryGraph import (Phase 3)
- Social sharing or friend features (Phase 3)
- iOS-specific *feature* work beyond what shipping a beta build needs (Phase 2). The iOS **build and distribution** path moved up — see "iOS + Beta Distribution". Nothing else from Phase 2 came with it.

## Potential Ideas — Might Never Build
Distinct from "NOT in MVP", which is deferred but intended. These may never happen, and that is fine. Promote one only if beta users actually ask for it.

- **AI auto-tagging** — an LLM assigning mood tags at ingest. Moved here Sep 2026. **The token cost is not the problem**: at roughly 600 input / 20 output tokens per book, Claude Haiku 4.5 runs about **$0.0007 a book** — ~7¢ for a 100-book library, and one $15 Premium purchase would cover ~21,000 books. The barrier is **infrastructure**: an LLM key cannot ship in a client app (unlike the Books key, it spends real money), so this needs a Cloud Function and Firebase on the **Blaze** plan with a billing account. **The genre already pulled from Google Books is good enough for now** — free, instant, no backend. Revisit only if beta testers say tagging is missing.

## Critical UX Rules
- **No push notifications in MVP.** Margot turns off push notifications on almost every app. In-app prompts only, triggered on open.
- **Mood quiz surfaces ONE book, not a list.** The whole point is solving choice paralysis.
- **Quiz has only 2-3 questions.** Margot said "only 2 options."
- **Approval screen uncertainty threshold:** two paths only:
  1. High confidence (≥80%) → auto-add, user never sees it
  2. Low confidence (<80%) → show submitted photo + best guess side by side → Yes = added, No = manual entry
  - Edge case: if Google Books returns no results at all, skip straight to manual entry (no best guess to show)
- **Monetization — one-time "Premium" unlock, not a subscription (Sep 2026).**
  - **Free:** up to **100 books** — a *placeholder*. The beta deliberately has **no limit at all**, and testers will be asked how many books feels fair before paying. Set the real number from that data, not from a guess.
  - **Premium (~$15 one-time, TBC):** unlimited books + themes. Apple and Google take 15–30%.
  - **Free forever:** tags, filtering, genre, search, sort, auto-add — everything that makes the app work. Users should never be annoyed by something simple being missing.
  - **Themes are the real incentive**, not storage. Cosmetics sell the way game skins do, and they give Richie a lane after launch. Storage alone only earns from power users — if most people never reach the free limit, nobody pays.
  - **Undecided:** shelves (the concept needs revisiting post-beta — possibly 3 free then Premium, but decide after seeing how many books people actually store) and CSV export (non-essential, Premium when it exists).
  - **⚠️ #99 blocks monetization.** Store purchases restore via the Play/Apple account, but the **library does not** — anonymous auth mints a new UID on reinstall. A paying customer would get their unlock back and find an empty shelf. Real accounts are mandatory before charging.

## Build Order — Follow This Sequence
1. ✅ Flutter project + Firebase connected + running on physical Android device
2. ✅ **Proof of concept only:** photo → ML Kit OCR → Google Books API → display result (no DB, no UI polish)
3. ✅ Accuracy test: initial pass 9/12 clean photos (75%); after the recognition work (#46/#52/#55/#60) a harder **real-world phone re-test** (bookstore photos: angled, busy shelves, promo bands) landed at **~10/21 (~48%)**. See "Recognition Status" — the ~48% is the honest ceiling for hard photos; the approval flow (step 6) is what makes imperfect recognition usable, so we stopped tuning and moved on.
4. ✅ Firestore persistence layer
5. ✅ Visual dashboard — Home screen (Netflix-style rows) + Library screen (3-column grid, genre filter chips) + bottom nav (Home, Search, Capture, Import, Discover) + hamburger drawer (Full Library, Settings). **The sort control was never wired (#101)** — the screen is done, that button is not.
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
Always run these two commands at the start of a session to orient yourself before doing anything:
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
- If AI features ever land, they need a **Cloud Function** — an LLM key cannot ship in a mobile client, and that means moving Firebase to the **Blaze** plan with a billing account. That infrastructure, not the token cost, is the real barrier (see "Potential ideas").
- Cloud Storage not used in MVP — book cover art is stored as Google Books API URLs in Firestore, no file storage needed. (Screenshot import doesn't change this: screenshots are matched to a Google Books result and only the cover URL is stored.) Revisit in Phase 2 only if we ever need to keep the user's original photo as a fallback cover.

## API Keys & Secrets
- **The Google Books API key is REQUIRED again (#81).** Keyless calls return HTTP 429 — Google attributes them to a shared anonymous quota pool that is permanently exhausted (learned the hard way in #48/#50, re-confirmed in #75). The key lives in `bookshelf_app/.env` (gitignored) and is injected at build time, not bundled: run with `flutter run --dart-define-from-file=.env`, read in code via `String.fromEnvironment('GOOGLE_BOOKS_API_KEY')`. `main()`'s assert is restored, so a **debug** build without the flag fails loudly at startup.
- The Open Library fallback is keyless, so it keeps working without the flag — which means a keyless build degrades to the fallback rather than failing outright. Do not rely on that.
- **Honest threat model:** any key shipped in a client app is extractable — dart-define is obfuscation, not protection. The real security control is console-side: in Google Cloud Console, restrict the key to the Books API only and cap its daily quota. Books API is free with no billing attached, so a leaked key can only waste quota — no money or data at risk.
- The Firebase keys in `firebase_options.dart` / `google-services.json` are identifiers, not secrets — safe to commit. Data access is enforced by Firestore security rules, not by hiding these keys.
- **Before public launch:** enable Firebase App Check, and add Android package name + SHA-1 restrictions to the Firebase API keys AND the Books API key in Google Cloud Console.
- Never commit secrets to git. If a real secret is ever needed (paid API, etc.), it belongs behind a Cloud Function — never in the app.

## Release Builds (Android)
```
flutter build appbundle --dart-define-from-file=.env
```
The dart-define is **mandatory again (#81)** — Google Books is primary and needs the key. The trap: `main()`'s assert is **stripped in release**, so a keyless release build fails *silently*. Since #81 it fails quietly in a new way — every lookup 429s and falls through to the Open Library fallback, so recognition still half-works and the missing key is even harder to spot. Always verify the flag was passed.

**Signing:** upload keystore at `C:\Users\bodek\keys\bookedex-upload-keystore.jks` (alias `upload`, RSA 2048, valid to Dec 2053), deliberately **outside the repo**. `android/key.properties` holds the path + passwords; it and `*.jks` / `*.keystore` are gitignored. `build.gradle.kts` falls back to debug signing when `key.properties` is absent, so a fresh clone still configures and `flutter run` works — meaning **a machine without those files silently produces a debug-signed bundle that Play will reject.** Verify with `keytool -printcert -jarfile <aab>`; it must show `CN=Bode Kaanta`, not `CN=Android Debug`.

**Four files git will never carry** — copy them by hand when moving machines: `.env` (in `bookshelf_app/`), `android/key.properties`, the `.jks` upload keystore, and the App Store Connect API `.p8`. The keystore and the `.p8` both live in `C:\Users\bodek\keys\`, next to `appstore-connect-api.txt`, which holds the Issuer ID and Key ID that pair with the `.p8`. **Apple lets you download the `.p8` exactly once** — lose it and the only fix is revoking the key and generating a new one. Unlike the Firebase keys, it is a real secret: it can upload builds as Bookedex. Note a Mac build session only needs `.env`; the `.p8` is for Codemagic, which signs via the API key rather than an Apple ID login.

**R8:** `android/app/proguard-rules.pro` carries `-dontwarn` for ML Kit's chinese/devanagari/japanese/korean recognizer packages. The plugin's `initialize()` references the options class for every script, but we only bundle the Latin model, and R8 treats the absent ones as fatal missing references. **Release-only failure — it cannot reproduce in debug**, so always build the bundle before assuming a change is shippable. R8 also strips unused code, so a release build needs its own smoke test on a device.

**Icon:** source art `assets/icon/bookedex_icon.png`; regenerate with `dart run flutter_launcher_icons` after changing it (config in `pubspec.yaml`). Adaptive background `#EA3442` sampled from the art, 18% foreground inset so the launcher mask doesn't clip the B.

**Play requirements already met:** `targetSdk`/`compileSdk` 36, `minSdk` 24, `applicationId` `com.bookedex.app`, label "Bookedex". The **store-listing** icon must be exactly 512×512 — the source art is 513×513 and will be rejected until resized.

## iOS + Beta Distribution (Aug–Sep 2026)
**Why iOS moved up.** Every beta tester who agreed to test is an iOS user; Bode and Richie are both Android. There is literally nobody to hand an Android beta to, so the iOS build path came forward from Phase 2. Nothing else from Phase 2 came with it.

**Apple Developer Program — $99/yr, enrolled as Individual.** Organization enrollment needs a D-U-N-S number and a legal entity, which don't exist. Consequences of Individual:
- The account is bound to Bode's verified legal identity, so the name must be **Bode Kaanta** exactly as on the government ID. This becomes the public **App Store seller name** at launch (invisible on TestFlight). Individual → Organization is possible later but is a support-request migration, not a toggle.
- Account Holder is the personal Apple ID `bodekaanta@gmail.com` (chosen because the phone number was already attached). Fine and normal. The Apple ID email can be **renamed** to a project address later without losing certificates or apps — that is not the same as transferring ownership, which an Individual account can't simply do.
- `bookedexapp@gmail.com` should be added as an App Store Connect **user** (project-branded notifications) and used as the **public support email** on the listing. Richie gets his own App Store Connect user — never share the Account Holder password. Account Holder is exactly one person.

**TestFlight is the beta channel — it is NOT the App Store.** No public listing, no ranking, no full App Store review. This distinction caused confusion; it is worth restating.
- **Internal testing:** ≤100 testers, each must be a user on the App Store Connect team. No review, live minutes after the build finishes processing.
- **External testing:** the shareable public link. Requires **Beta App Review** (24–48h on the first build of a version), a **privacy policy URL**, and App Privacy answers — anonymous auth + Firestore counts as data collection.
- **The public link is created once and never changes.** New builds flow to the same URL and tester group; testers re-click nothing. You do not pay the review wait per push.
- Later builds at the same version usually skip full review (minutes to hours). A new version number or a new permission can trigger another.
- **Every upload needs a higher build number** — the `+N` in `pubspec.yaml`'s `version:`. Reusing one is rejected outright. Builds expire **90 days** after upload.
- Testers get a TestFlight notification; whether it self-installs depends on a per-app toggle the *tester* controls.

**Sideloading was considered and rejected.** Free-provisioning and AltStore/SideStore give **7-day** certificates and require each tester to cable their phone to a computer weekly plus enable Developer Mode. Enterprise certificates ($299/yr) are employees-only and Apple revokes them for outside distribution. There is no "tap a link, install an .ipa" on iOS. Firebase App Distribution supports iOS but is only a delivery pipe — it still needs a paid Ad Hoc profile, so it routes around nothing.

**There is no Mac in the project.** Flutter cannot build iOS on Windows, and a macOS VM on non-Apple hardware violates Apple's license. Available: Bode's sister's MacBook (sometimes), Richie's MacBook (no toolchain installed — Xcode alone is a ~7–10GB download, so it must be installed *before* any session).
- **Codemagic** (free tier ~500 macOS min/month) can build and upload to TestFlight with **no Mac at all**, signing via an App Store Connect API key generated on the web. This is the intended routine path.
- The real cost of Mac-free is **debugging**: no hot reload, no breakpoints, no easy device logs — only TestFlight crash reports. Borrow a Mac when something needs actual investigation.
- **On-device test target: Bode's iPad 9th gen, iPadOS 18.1.1** — clears the 15.5 floor and is arm64, so ML Kit behaves like real hardware. Its camera is worse than the testers' iPhones, so treat any OCR figure from it as a floor, not a measurement. The phone-shaped UI will look stretched on a tablet; cosmetic, ignore.

**⚠️ The dart-define trap is worse on iOS.** Build with:
```
flutter build ipa --dart-define-from-file=.env
```
**Never Xcode's Archive button** — it does not pass the dart-define, and `main()`'s assert is stripped in release, so the build fails *silently*: every Google Books lookup 429s and quietly falls through to the Open Library fallback. You would ship a beta with degraded recognition and no error explaining why. `.env` is gitignored, so it must be **hand-carried to any Mac** — add it to the "files git will never carry" list above.

**iOS config, filled in by #85 / PR #86.** `ios/` was untouched Flutter template output pointing at nothing.
- Bundle ID `com.bookedex.app` (was `com.example.bookshelfApp`) across all configs in `ios/Runner.xcodeproj/project.pbxproj`.
- `IPHONEOS_DEPLOYMENT_TARGET` **15.5** — the floor for ML Kit's current iOS SDK. `pod install` may demand higher; one-line fix.
- `ios/Runner/Info.plist` carries `NSCameraUsageDescription` + `NSPhotoLibraryUsageDescription`. **iOS terminates the process without these**, so Capture and Import crashed instantly. App Review also rejects vague strings, so they name what the data is used for.
- `ios/Podfile` is hand-written and pins `platform :ios, '15.5'`; Flutter's auto-generated one defaults below ML Kit's minimum. If `pod install` rejects it, deleting it and letting Flutter regenerate + editing the platform line is the fallback.
- Icons: `remove_alpha_ios: true` + `background_color_ios: "#EA3442"` (matching the Android adaptive background — without the colour it defaults to **white**). **The App Store rejects icons carrying an alpha channel.** Verify with the PNG colour-type byte at offset 25: must be `2` (RGB), not `6` (RGBA).
- **Firebase keys iOS apps by bundle ID and cannot rename one**, so changing the bundle ID orphaned the old registration and a new iOS app had to be created: `1:374852436729:ios:f7fc3301d9fc0912dcd828`. Regenerate with `flutterfire configure --platforms=android,ios` — pass **both** platforms, because it rewrites the whole of `firebase_options.dart` and an iOS-only run can disturb the Android block. Run it **on the task branch**: flutterfire reads the bundle ID from the Xcode project, so running it on `main` (where the old ID still lives) silently registers the wrong app. That happened once.
- Deliberately left stale: the `macos` block in `firebase_options.dart` (flutterfire only regenerates platforms you ask for; macOS isn't a build target) and `google-services.json` (flutterfire wants to add an iOS OAuth client entry — and deleting a Firebase *app* does not delete its underlying OAuth *client*, so the entry describes an app that no longer exists. Android ignores iOS clients).

**Before external TestFlight:** privacy policy URL live, App Privacy answers filled, and **"Bookedex" reserved in App Store Connect** — app names are first-come across the entire App Store.

### iOS build status (Sep 2026) — it runs

**The first successful iOS build happened Sep 3 2026**, clearing the verification gate PR #86 left open. A release build installs and launches standalone on Bode's iPad (9th gen, iPadOS 18.1.1), camera capture works, and Google Books recognition resolves books. The App Store Connect app record exists and "Bookedex" is reserved.

**"In iOS 14+ debug mode Flutter apps can only be launched from Flutter tooling…" is normal, not a bug.** Debug Flutter runs Dart through a JIT, which needs the `get-task-allow` entitlement and a debugger attached at launch; Apple closed the loophole that let such apps self-launch. So a debug build installs fine, runs fine under `flutter run`, and shows that screen the moment you tap its icon. **This cost a session to diagnose — it is not a repo-path or Xcode problem.** For untethered use build release or profile:
```
flutter run --release --dart-define-from-file=.env -d <device-id>
```

**Xcode must be signed in for distribution export.** `flutter build ipa` archives fine but fails at the export step with `No Accounts` / `No signing certificate "iOS Distribution" found` when Xcode has no Apple ID. Device builds keep working throughout, because an `Apple Development` certificate is already in the keychain — **distribution** certificates are fetched from Apple on demand and need an account. Fix in Xcode → Settings → Accounts → **+**. Check with `security find-identity -v -p codesigning`; zero "Apple Distribution" lines means it will fail. Xcode Organizer (`open build/ios/archive/Runner.xcarchive`) is the more reliable route since it can create the certificate interactively.

**The iOS dependency setup is a hybrid, and both lockfiles matter.** ML Kit is the *only* thing left on CocoaPods (`google_mlkit_commons` and `google_mlkit_text_recognition` are the sole `DEPENDENCIES` entries in `Podfile.lock`) because they are the only plugins without Swift Package Manager support. Everything Firebase resolves through **SPM**. So `ios/**/swiftpm/Package.resolved` is a real lockfile, not Xcode noise, and is committed for the same reason `Podfile.lock` is: a clean clone could otherwise resolve different Firebase versions than the build you tested. That matters most for Codemagic, which builds from a fresh clone every time.

**ML Kit ships no arm64 simulator slices** (`GoogleMLKit`, `MLImage`, `MLKitCommon`, `MLKitVision`). The Simulator isn't merely "fussy" as previously assumed — the architecture is absent. iOS recognition can only be tested on physical hardware. The build also warns that the ML Kit plugins' lack of SPM support "will become an error in a future version of Flutter" — a forced migration eventually.

**Never construct a `TextRecognizer` per photo (#120).** A 19-photo import crashed the instant Add was pressed; four photos were fine. `EXC_CRASH`/`SIGABRT` with `NSInvalidArgumentException` — `-[… synchronize]: unrecognized selector` — thrown inside `-[MLKAnalyticsLogger synchronizeUserDefaults]` while *constructing* a recognizer. Unrecognized selector on what should be `NSUserDefaults` is a freed object whose address was reused. `extractTextFromImage` built and closed one per image, so N photos meant N construct/teardown cycles against ML Kit's shared analytics logger. One lazily-created recognizer now lives for the life of the service. It is also faster: constructing one **loads the OCR model**, so the model was being reloaded per photo.

The first theory was memory — `image_picker` on iOS genuinely does decode every selected photo at **full resolution before** applying `maxWidth`/`maxHeight`, so 19 at once is a real spike, and `maxWidth: 2000` does nothing to prevent it. That theory was still wrong: a memory termination reports `EXC_RESOURCE`, not `SIGABRT` with an ObjC exception. **Read the exception type before theorising.**

**`ITSAppUsesNonExemptEncryption = false`** is in `Info.plist`. Without it App Store Connect asks the export-compliance question on *every* build before it can be distributed. `false` is accurate: only standard HTTPS/TLS to Google Books and Firebase, which Apple exempts.

**Which machine can cut a release:**

| Release | Where |
|---|---|
| Android (Play AAB) | Windows, as always |
| iOS (TestFlight / App Store) | **Mac only** — or Codemagic |

Windows cannot build iOS at all: Xcode and codesigning are macOS-only, and a macOS VM on non-Apple hardware violates Apple's licence. **Codemagic is the only genuine Mac-free path** and is what removes the dependency on a borrowed laptop.

**The privacy policy is live, and it lives in a second repo.** App Store Connect will not accept a file — it must be reachable without a login. **GitHub Pages requires a *public* repo on the free plan and `Book-Shelf-Project` is private**, so the public pages live in **`BodeKaanta/bookedex-site`** instead: public, no app code, and deliberately **no licence**, so the text stays all-rights-reserved and readable rather than reusable.

| Page | URL | Used as |
|---|---|---|
| Privacy policy | `https://bodekaanta.github.io/bookedex-site/privacy/` | App Store Connect **Privacy Policy URL** |
| Landing / support | `https://bodekaanta.github.io/bookedex-site/` | App Store Connect **Support URL** (also required, easy to forget) |

The policy describes **current** behaviour on purpose, including two unflattering facts that stay until they stop being true: photos never leave the device but the **text recognised from them does** (sent to Google Books as a search query), and libraries are tied to an installation rather than an account (#99), so a deletion request cannot be matched to a user. **Change the policy in the same PR that changes what the app collects** — Apple's App Privacy questionnaire and Google Play's Data Safety form are both checked against it, and they drift apart the moment this is treated as follow-up work.

**App Privacy questionnaire answers** (derived from `Book.toFirestore`, so they match the code rather than the marketing): collect data = **yes**; *Identifiers → User ID* (the anonymous UID) and *User Content → Other User Content* (the saved library), both **linked**, both **App Functionality**, neither used for tracking. **Do not declare Photos** — Apple excludes data processed only on-device, and declaring them would contradict the policy. **Do not declare Diagnostics** — there is no crash reporting yet; that changes the day Crashlytics lands.

**A handoff document for Richie** covers the App Store Connect work that needs no code: `C:\dev\bookedex-storefront-handoff.md` (plus an `.html` twin). It is a **static copy** — sending it again is the only way to update his. Two items in it are Bode's alone because they are legal acts in his name: accepting the Apple Developer Program License Agreement (at **developer.apple.com/account**, not App Store Connect) and setting EU trader status.

### Beta status — 28 Sep 2026

**Build `1.0.0 (4)` is uploaded and processed in App Store Connect.** TestFlight → Builds shows it Complete. That is the first binary this project has ever sent to Apple, and it ends the Mac-only part of the beta.

**"Built" is not "uploaded", and conflating them wasted a session.** A local `flutter build ipa` is a build; transmitting the binary is a separate step. Builds 1 and 3 were both produced locally and never sent — 3 was archived and then found to crash (#120), so it must never be uploaded.

`version:` is **`1.0.0+4`** (bumped in #122). Apple rejects a reused build number outright, so bump the `+N` again after every upload — including after a build that was only ever archived locally.

**Accepted:** the Apple Developer Program License Agreement (27 Sep). **Still empty as of 27 Sep: App Information and App Privacy** — both are gates on external TestFlight, not optional polish.

Remaining gates on the **external** (public-link) TestFlight track:

| Gate | Where | Needs |
|---|---|---|
| ~~Upload a build~~ | Mac | ✅ **Done 28 Sep — `1.0.0 (4)`.** Every remaining gate is App Store Connect web work and can be finished from Windows |
| App Information URLs + category | App Store Connect | Nothing; both URLs are live above |
| App Privacy questionnaire | App Store Connect | Nothing; answers are recorded above |
| Age rating questionnaire | App Store Connect | Nothing |
| TestFlight Test Information | App Store Connect | Nothing to write it; a build to act on it |
| External tester group → Beta App Review | App Store Connect | An uploaded, processed build |

Internal testing needs neither the review nor the policy — only a build and testers who are App Store Connect users.

**Tester notes must carry the #99 warning**: the library is device-local, so deleting the app may lose it. Without that, reinstall data-loss gets reported as a bug and contaminates the recognition feedback the beta exists to collect.

### Mac session runbook — uploading a build

**Read this before touching the Mac.** The session happens on a borrowed MacBook (`/Users/suvikaanta/dev/Book-Shelf-Project`) under time pressure. Target: build uploaded and processed **before** the release meeting, so the meeting is one button and not a debugging session.

**Carry with you.** `.env` into `bookshelf_app/` — it is gitignored, so a fresh clone will not have it, and without it every Google Books lookup 429s into the Open Library fallback. The `.p8` is **not** needed: it is for Codemagic, and Xcode signs via an Apple ID login instead.

**Do first, before anything else.** Sign Xcode in: **Xcode → Settings → Accounts → +**. Verify with:
```
security find-identity -v -p codesigning
```
**⚠️ Do not use that command to decide whether signing will work — it is misleading.** It printed `Apple Distribution: 0` before the sign-in *and after it*, including immediately after an export that succeeded. The certificate Xcode uses is **Cloud Managed Apple Distribution**, fetched on demand at export time and never written to the local keychain, so `find-identity` cannot see it. Verified 28 Sep: zero local distribution identities, `DistributionSummary.plist` showing `Cloud Managed Apple Distribution` on all 14 components, upload successful.

**What actually matters is whether an Apple ID is signed in** (Xcode → Settings → Accounts). Before the sign-in, `flutter build ipa` archives and then fails at export with `No Accounts` / `No signing certificate "iOS Distribution" found`. After it, the same command exports cleanly with no other change. Device builds keep working throughout — an `Apple Development` certificate really is in the keychain — so nothing warns you until the last step.

**Xcode Settings is in the macOS menu bar, not the Welcome window** (**⌘,**, or Xcode → Settings from the bar beside the  logo). The Welcome window offers only "create / clone / open", which reads like there is no Settings at all.

**Then, in order:**
```
git pull
cd bookshelf_app
flutter pub get
cd ios && pod install && cd ..
flutter build ipa --dart-define-from-file=.env
```
First `pod install` on a clean machine downloads the Firebase and ML Kit pods with no cache — **budget 10–25 minutes** and start it early.

**⚠️ Never Xcode's Archive button.** It does not pass the dart-define, and `main()`'s assert is stripped in release, so the build fails *silently*: recognition still half-works via the fallback and nothing explains why. Always the `flutter build ipa` line above.

**Upload** through Xcode Organizer rather than the CLI — it can create a missing distribution certificate interactively:
```
open build/ios/archive/Runner.xcarchive
```
Distribute App → App Store Connect → Upload. Then watch **App Store Connect → TestFlight → Builds**; processing takes 5–30 minutes and Apple emails when it finishes. Export compliance should **not** be asked, because `ITSAppUsesNonExemptEncryption` is already in `Info.plist`.

**Known failure modes — recognise these rather than re-diagnosing them:**

| Symptom | Cause | Fix |
|---|---|---|
| `No signing certificate "iOS Distribution" found` at export | Xcode not signed in | Settings → Accounts → **+** (⌘, — the menu bar, not the Welcome window) |
| `Upload Symbols Failed — no dSYM` for `FirebaseFirestoreInternal`, `absl`, `grpc`, `grpcpp`, `openssl_grpc` | Firebase ships these prebuilt through SPM with symbols stripped | **Ignore.** Benign and expected; does not block processing, TestFlight or review |
| Recognition degrades to Open Library in the shipped build | dart-define missing — Archive button used | Rebuild with `flutter build ipa --dart-define-from-file=.env` |
| `pod install` rejects platform 15.5 | ML Kit demanding higher | Raise it in `ios/Podfile` **and** `IPHONEOS_DEPLOYMENT_TARGET` together — they must match |
| "can only be launched from Flutter tooling" on the device | Normal for debug: the JIT needs a debugger attached | `flutter run --release --dart-define-from-file=.env -d <id>` |
| Build number rejected as already used | `version:` not bumped | Bump the `+N` in `pubspec.yaml` |
| Simulator build fails to link ML Kit | No arm64 simulator slices exist | Physical device only — this is not fixable |

**Distribute App is not the beta review, and three similarly-named buttons do three different things:**

| Button | Where | What it does |
|---|---|---|
| **Distribute App** | Xcode Organizer | Uploads the binary. No review, nothing public, no clock started |
| **Submit for Beta App Review** | App Store Connect → TestFlight → External group | 24–48h review; unlocks the public tester link |
| ⚠️ **Submit for Review** | App Store Connect → **Distribution** tab | A real **App Store launch** submission. Not this. |

Internal testing needs none of them beyond the upload — it goes live minutes after processing.

**Submitting (the meeting itself):** TestFlight → create an **External** group → add the build → **Submit for Beta App Review**. 24–48h on the first build of a version. Do **not** use "Submit for Review" on the Distribution tab — that is a real App Store submission. The public link is created once and never changes, so later builds need no new link and usually no new review.

**What this beta knowingly ships with**, so nobody treats these as surprises:
- **#99** — the library is device-local. The tester notes must say so.
- **#93** — an unreproduced iOS crash. Shipping to TestFlight is *progress* on it, not a risk being hidden: TestFlight uploads dSYMs, so any recurrence arrives symbolicated, which is exactly what #93 is blocked on.
- **iPad** — `TARGETED_DEVICE_FAMILY` is still `"1,2"`. Irrelevant to TestFlight, which needs no screenshots. Decide before the store listing, because keeping it forces a second screenshot set and puts the stretched tablet layout in front of App Review.

## Recognition Status (as of Sep 2026)
Pipeline: ML Kit OCR (bundled on-device model) → query builder → **Google Books search** (Open Library on transport failure) → fuzzy rerank → confidence score. Recognition is driven by the Import flow; the POC dev screen was removed in #45.

### Data source: Google Books primary, Open Library fallback (#81, Aug 2026)
**Google Books broke, then recovered.** In #75 it stopped returning mainstream commercial books — `isbn:9780593135204` (Project Hail Mary) and `isbn:9780553418026` (The Martian) both returned `totalItems: 0`, and `q=harry potter` returned academic commentary with no Rowling. Ruled out at the time: an invalid key (a bad key returns HTTP 400; ours returned 200 with valid JSON), URL formatting, and quota. We switched to Open Library rather than delete the Google path. By #81 all three symptoms were gone. **The cause was never identified — assume it can recur.**

**Open Library stays live as the fallback**, not commented out. `_fetchBooks` tries Google Books and falls back only on **transport failure — timeout, 429, or 5xx**. Deliberately *not* on other 4xx, and *not* on an empty result set:
- An empty result is a real answer ("no such book"). Falling back on it would double request volume on exactly the photos that already fail.
- A 400/403 means we asked wrongly or the key is bad. Quietly rerouting every request would hide that indefinitely.
- **This fallback would not have caught #75.** Google Books returned HTTP 200 with valid JSON throughout; only the corpus was useless. Detecting that needs a known-answer probe (does `isbn:9780593135204` still return Project Hail Mary?). Not built — the manual switch remains the real safety net.

**Why Google Books wins here:** 16/20 recognised versus Open Library's 13/20 on the same photos. Popularity ranking recovers queries literal matching cannot — `PROUEOT HAIL` → Project Hail Mary, `SRUEL PRUNCE HOLLI` → The Cruel Prince, both previously written off as destroyed OCR. It also returns `description` inline (Open Library's `search.json` does not, which would have cost step 7 a second `/works/{key}.json` fetch per book).

**Covers — the other reason.** Open Library carries sparse duplicate *work* records whose titles are the **plainest**, so they won the #52 fuzzy rerank and lost the cover art. Castle and Invisible Cities both resolved to records with one edition and no image anywhere (`/b/olid/{key}-L.jpg` 404s too). Not fixable app-side: making the rerank prefer covered candidates selects *Creepy Castle* by a different John S. Goodall — a wrong book instead of a cover-less one. On Google Books every book in the 20-photo set has a cover.

**Cover URL — do not use `imageLinks.thumbnail` verbatim.** It is only **128px** wide: narrower than a library grid tile (~325px on a 1080×2400 device) and blurrier than the Open Library covers it replaced. `Book.googleCoverUrl` appends `&fife=w600` for a 600×900 rendition of the same image — server-side resolution selection, no crop and no magnification, despite what the `zoom`/`fife` naming suggests — and strips `&edge=curl`, which paints a fake page-curl over the artwork. 600px leaves headroom for the step-7 detail sidebar: `coverUrl` is frozen per book in Firestore at add time, so going smaller means a migration later. `library_screen` decodes at `cacheWidth: 400` so 600px sources don't hold ~2MB each and thrash the 100MB image cache.

**Two behavioural differences between the APIs:**
- Open Library returns `docs: []` on a miss where Google Books omits `items` entirely. Both must map to "no results", or the retry paths are silently skipped.
- **Open Library's Solr matches literally; Google Books ranks by popularity and tolerates junk.** `q=HAIL` returns Project Hail Mary #1, but `q=HAIL AUTHOR OF` returns *Hail and farewell*. Junk tokens poison an Open Library query rather than merely diluting it — Google's ranking was silently rescuing weak line selection, which is what #78 fixed properly. Sorting cannot substitute: `sort=editions`/`readinglog`/`rating` flood results with Macbeth and King Lear by edition count.

**Open Library stalls under burst load.** 20 rapid requests timed out 20/20 in testing, and a 20-photo import is exactly that pattern. A stalled request is currently recorded as a book we couldn't read — tracked in #82.

**Known issue, now caught by the approval flow.** Blake Crouch's *Pines* (a Wikipedia screenshot listing the whole trilogy) still matches *Wayward*, the next book in the series. On Open Library it scored **100%** and auto-added wrongly at any threshold. On Google Books it scores **70%**, so it lands in the review queue with the correct *Pines* visible under "See other matches" — the intended behaviour. Note this is a side effect of the confidence bug below, not a fix; whoever repairs the scorer must confirm Pines stays below threshold.

**Field mapping — Google Books:** `volumeInfo.title`, `authors[0]`, `imageLinks.thumbnail` → `Book.googleCoverUrl`, `description`, `categories[0]` → genre, `pageCount`. `googleBooksId` holds a real Google Books volume id again. Existing Firestore docs still hold Open Library work keys from the #75 era; dedup is title+author so both coexist, and old docs keep their old `coverUrl`.

**Field mapping — Open Library** (fallback path only): `title`, `author_name[0]`, `cover_i` → `covers.openlibrary.org/b/id/{id}-M.jpg`, `number_of_pages_median`, `subject[0]` (title-cased) → genre. No description. Subjects are noisy (LOTR's first subject is "The Lord of the Rings"; The False Prince's is "Impersonation"). `-M` caps at 180px; `-L` gives ~331×500 if that path ever matters visually.

**`language:eng` does not work on Open Library** — tested and rejected. It searches *works*, which aggregate editions, so a work with any English edition matches while still displaying its original-language title. One Piece still returns 尾田栄一郎 with the filter on, and it costs ~20% of candidates.

### Accuracy — Margot's 20-photo set
**The test set is Margot's own collection**, measured on the physical device. Every number here comes from real target-user photos, which is why the failures are treated as an honest ceiling rather than something to tune away.

| Stage | Recognised |
|---|---|
| Open Library + pre-#78 query builder | 7/20 |
| Open Library + #78 query builder | 13/20 |
| **Google Books + #78 query builder (#81)** | **16/20** |

Earlier figures, different sets: initial clean-photo pass 9/12; a harder real-world re-test on 21 bookstore photos (angled, busy shelves, promo bands) landed ~10/21.

**The 4 still failing, and why none is a query-builder problem:**
- *Pines* — see above; wrong but correctly routed to review.
- *House of Government* — a bookstore **shelf** photo: 50 OCR lines from ~4 different books. A fundamentally different problem from a single cover.
- *I Cheerfully Refuse* — `AVELL Cheerf Retuse`. Destroyed OCR.
- *Monk & Robot omnibus* — matches book 1 (*A Psalm for the Wild-Built*) because the query picked up a blurb's trailing title reference (`-SARAH GAILEY on` / `A Psalm for the Wild-Built`). #78 strips quote bodies but not a blurb's cited title.

**Key constraint — OCR can't be improved app-side:** ML Kit's text model is BUNDLED (`com.google.mlkit:text-recognition:16.0.1`), identical across plugin versions and devices — NOT served via Play Services. Bumping the plugin (tried & closed in #56) doesn't change it. The physical device (arm64) reads worse than the emulator (x86_64) on the same model, so **always validate recognition on the physical device — the emulator flatters results.**

**The figures above are Android-derived.** iOS has now been measured separately — see "iOS recognition" below. ML Kit ships a *different* SDK build on iOS and the two do **not** behave the same, so never assume an Android number transfers. The iOS Simulator is not a substitute for a device: ML Kit ships no arm64 simulator slices at all.

### iOS recognition — measured Sep 2026, and the transposition bug (#94)

**iOS lands at 14/19 correct** on Margot's set imported on the iPad, against Android's 16/20. Comparable overall, but a *different* failure set.

**The bug that was hiding it: ML Kit on iOS returns transposed bounding boxes.** iOS reports text frames in the photo's **unrotated buffer**, so any photo carrying EXIF rotation arrives with every box's axes swapped — a 37-character line of cover text measuring 69 wide by 458 tall. `_isRotated` then reads it as a neighbouring book's spine (the #78 rule) and drops it, so almost every line of a rotated cover was discarded and the query built from scraps. **10 of 19 photos were affected.**

| | Before | After |
|---|---|---|
| Returned a book | 12/19 | **19/19** |
| Auto-added (≥0.75) | 2 | **6** |
| Correct | ~7 | **14/19** |

Queries went `sci` → `INVISIBLE CITIES ITALO CALVINO`, `THE` → `CASTLE JOHN GOODALL`, `THE HOUSE OF` → `THE HOUSE OF A SAGA OF THE RUSSIAN`, and `onumental. A gigantic fable of genuine truths.` → `OverstOry Richard Powers`.

**Fixed in `book_recognition_service.dart`, not the query builder** — at the boundary where ML Kit data enters, so `_isRotated`, the reading-order sort and the size/zone weighting all keep working on the geometry they were tuned for and `books_api_service.dart` needed no change. Detection samples lines of **six or more characters** (horizontal text of four or more is always wider than it is tall, so six is a safe floor) and swaps the axes when the majority come back taller than wide.

**⚠️ This is an iOS SDK behaviour, and the gate is now iOS-only (#105).** Android's ML Kit applies the rotation itself, so its boxes are already correct and must never be touched. The gate used to run on both, and on a photo carrying several neighbouring **spines** the majority vote went the wrong way: Invisible Cities transposed a good Android photo, `_isRotated` then discarded its cover text as spine, and it scored **0.00 where it had scored 0.70**. `extractTextFromImage` now gates on `Platform.isIOS`.

**The heuristic itself is still wrong — #107, iOS only.** Five spines outvote three lines of cover text. Harmless on Android now; still live on iOS, and unverifiable from Windows because there are **no iOS OCR fixtures** and an iOS build needs the Mac. Capture iOS fixtures first, then fix. Weighting the vote by box area is the likely answer (titles are the largest text, spines are thin); deciding from EXIF/image dimensions rather than text geometry would be better still, since transposition is a property of the image, not of the words in it.

**The gate now has a real two-sided test (#105).** It previously had none: it was recorded here that `test/fixtures/ocr_fixtures.dart` is its regression test, which was false — those fixtures hold this step's **output**, and every other test feeds them straight into `books_api_service`, so `_transposeBoxes` never executed. That false confidence is exactly how #105 survived. `test/book_recognition_service_test.dart` now asserts both directions by calling the decision directly: no real photo is transposed on Android, and axis-swapped copies of those same fixtures still are on iOS. It also pins the #107 limitation with an assertion that should **invert** when that is fixed.

**`_transposeBoxes` is a reflection, not a true rotation.** It reliably corrects the aspect ratio, which is what `_isRotated` keys on, but reading order may come out bottom-to-top on some photos. Per #78 order matters for a title split over several lines. Not observed to bite yet; suspect it first if a multi-line title scrambles while single-line titles work.

**Surprise win: House of Government now resolves on iOS though it never has on Android.** It is the shelf photo with ~50 OCR lines from four books. Once cover text stops being misread as spine text, `_isRotated` finally does the job it was written for — separating the photographed book from its neighbours.

**Two iOS-only failures remain, both on non-transposed photos and unrelated to the fix:**
- *Project Hail Mary* → query `HAIL SPECULATIVE SP` → *NASA SP.*
- *The Notebook* → `NOTEBOOK Nicholas Sparks . WILL NOT LET YOU GO. HIS NOVEL SHINES.` — blurb text diluting a query that already holds the right title and author

Both exist because **iOS ML Kit segments lines differently than Android**, which defeats junk filters tuned on Android's segmentation — the same root reason `NATIONAL BESTSELLER` arrived as `NATIONAL BESTSELL E R` and slipped past the bestseller-band filter. This is the #55/#78 domain and wants its own issue.

The other three failures (*I Cheerfully Refuse* destroyed OCR, the *Monk & Robot* omnibus, *Pines*→*Wayward*) are the **same documented Android failures** — iOS converged on the same known limitations.

**Capturing iOS OCR for diagnosis:** run a debug build over the cable (`flutter run --dart-define-from-file=.env -d <id>`), import the photos, and read the `[REC]` records. `recognition_log.dart` is `kDebugMode`-gated and is the only logging in `lib/`, so it compiles out of release automatically — nothing to disable before shipping.

**Recognition work shipped:**
- #46 — screenshot-aware filtering: detect screenshot by portrait aspect ratio ≥1.85; zone downweighting + text-size weighting (screenshot-only, to protect clean-photo scoring); social-UI line filtering
- #52 — fuzzy title matching: rerank candidates by normalized-Levenshtein similarity of title+author to the OCR (title 60% / author 40%); reorders only above a 0.6 threshold
- #55 — query-builder junk filtering (taglines like "A NOVEL", publishers, review attributions, bestseller bands), letter-collapse ("NoTEB O O K"→"NoTEBOOK"), leading-operator stripping, and match-aware relaxation (retry with leading words when nothing matches the OCR)
- #60 — drop edition/series ("10th Anniversary Edition", "Book 2 of the…") and film/TV adaptation banners
- #78 — **rework of line selection and filtering; 7/20 → 13/20.** Details in "Query builder logic" below. The two findings worth remembering: lines are joined in **reading order**, not score order (a title split over four lines is only a title in the order it was printed), and a bounding box **taller than it is wide** is rotated text — a neighbouring book's spine on a shelf photo, which is what `EMILY EMILY EMILY` and Authority's `"VERY, VERY SCARY !"-WIRED` actually were.
- #81 — data source back to Google Books; 13/20 → 16/20.
- ⛔ Reverted: size-weighting for ALL photos (#58) regressed accuracy 10→7 — size doesn't reliably track the title on real covers. Size weighting stays screenshot-only.

**Recognition is testable without a device.** `test/fixtures/ocr_fixtures.dart` holds all 20 photos' OCR captured verbatim from the physical device (line text + bounding boxes + screenshot flag), and `test/books_api_service_test.dart` asserts query construction against it. The query builder is a pure function, so a change can be checked in seconds instead of a full device run. Regenerate fixtures from the debug-only `[REC]` logging in `core/recognition_log.dart` — capture losslessly with `adb logcat -v brief > file` rather than reading the terminal, since logcat's ring buffer rolls mid-import.

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

**Bottom nav — what each tab is for.** Never specified when the five tabs were built, and both Search and Discover shipped as `PlaceholderScreen`. Settled Sep 2026:
- **Search = the user's own library** (#100) — *not* a book-adding flow. Adding already has three doors (Capture, Import, and the manual search inside the approval card) and does not need a fourth.
- **Discover = finding books the user does not own.** Phase 3's external recommendations land here.

The library-search screen opens from **both** the Search tab and a new search icon in the Library AppBar. The tab is one tap from anywhere; the Library screen is 2–3 taps deep (Home → drawer → Full Library, or the "See all" on the Your Library row), so neither entry point alone covers both "find a book from anywhere" and "search while I am browsing". One widget, two doors.

**⚠️ The Library sort icon does nothing (#101).** `Icons.sort` — the three-lines icon top-right — has an empty `onPressed`, so it reads as a dead control, and the grid hardcodes alphabetical-by-title. This is unfinished **step-5** work, not new scope: "Auto-sort by title, author, date added, genre" was always in MVP Library scope. `author` and `genre` are nullable, so nulls need a consistent home (trailing) or the grid looks randomly shuffled for books without an author.

**Implementation notes:**
- Data is already in Firestore (`watchBooks()` stream is ready) — this step is mostly UI
- Each cover tile shows the `coverUrl` from the Book model (Google Books thumbnail URL)
- **The genre chip was dropped from the grid (#104).** It used to overlay the cover, standing in for the moods Richie's design shows. Title and author under the cover replaced it: Google's `categories` are usually just "Fiction", so the chip read the same on nearly every tile, the filter chips above already cover genre, and step 7's detail view shows it properly. When moods arrive (step 8) they can return as a chip, designed then.
- "Capture" bottom nav tab → entry point into capture flow (camera)
- "Import" bottom nav tab → entry point into batch photo import → feeds approval screen (step 6)

## Approval Screen Design Notes (Step 6 — Done)
Tinder-style swipe review card, only shown for books the system is uncertain about. Built in `screens/approval_screen.dart` (+ `manual_search_screen.dart`, `import_screen.dart`), driven by `providers/import_provider.dart`.

**Confidence threshold — 75%, re-confirmed on Google Books (#81):**
- ≥75% → auto-save silently
- <75% OR no confident match → approval queue

**Confidence scoring (`BooksApiService._confidence`):** `0.7 × topMatch + 0.3 × margin`, where topMatch is the #52 fuzzy similarity of the best result to the OCR and margin is how clearly it beats the runner-up. This *superseded* the original "gap between query scores" idea.

**The margin term was broken on Google Books — fixed in #83.** Margin was measured against the runner-up whatever it was, and Google Books returns *several editions of the same book* (`Overstory Richard PoWers` returns The Overstory three times). Margin collapsed to 0 and confidence was capped at `0.7 × topMatch` ≈ 0.70 — five correct books landed on exactly 0.70 for this reason. The fix collapses duplicate editions **after the rerank** (`_dedupeEditions`), so the runner-up becomes a genuinely different book and the margin means what it claims; `_confidence` itself needed no change. The same collapse is applied on **all three surfaces** the duplicates reached: the confidence margin, "See other matches" on the review card, and the manual search picker (#109) — one `_dedupeEditions`, so they cannot diverge. "Same book" lives in `Book.identityKey` — shared with `BookRepository`'s duplicate check so the two cannot drift — and strips both subtitles and **edition parentheticals**, because `_coreTitle` already ignores "(Movie Tie-In)" when scoring and identity has to agree.

**Calibration — done on real target-user photos, three times.** The 20-photo set **is Margot's own collection**. After #83: **7 of 16 correct matches auto-add, none wrong** (was 4 before the dedup). Correct 0.51–0.87, incorrect 0.43–0.74. **0.75 remains the lowest threshold that excludes the wrong Monk & Robot match at 0.74**, so it stays. For reference, #78 on Open Library measured a clean 0.65 split; the distribution is a property of the data source, so re-measure after any source change. Undo safety net exists in the notifier (`undoAutoAdd`, `deleteBook`); batch import surfaces a summary popup instead of per-book toasts.

**Confidence is calibrated offline — no device run needed.** `test/fixtures/candidate_fixtures.dart` holds real Google Books candidate lists for the queries the builder produces from the OCR fixtures, and `rankCandidates` exposes the whole post-fetch half of `searchBooks` as a pure function. Validated: **19 of 20 device confidences matched the offline prediction exactly**, the lone exception being #105. Regenerate with the `[REC]` logging — `query`, `top` and `also` lines give queries, scores and the full candidate list.

**Import flow (#45):** Import tab → `ImportScreen` "Choose Photos" → `pickMultiImage` → `importImages` routing (progress loader "Recognizing X of N…") → summary popup ("N added · M to review", "Review"/"Later") → approval queue.

**Swipe / buttons (#43):** left = Incorrect (skip), right = Correct (save top guess), up = Manual Search. Buttons and swipes share one path. Card follows the finger with a tilt + fading ✓/✗/🔍 stamp, flies out on commit, springs back below threshold. Card is a keyed `_ReviewCard` owning its own drag offset (so advancing the queue disposes it cleanly — no snap-back flash). "See other matches" (`AnimatedSize`) reveals other candidates; tapping one approves it. A subtle "N to review" counter shows in the app bar. Perf: drag uses a `ValueNotifier` + `ValueListenableBuilder` (only the card rebuilds per frame — smooth in profile mode; debug is expectedly janky).

**Cascading card stack (#68, step 6b):** the next two queue items render staggered behind the current card, each translated down `_stackStep` (12) and scaled `_stackScaleStep` (0.04) about `Alignment.bottomCenter` — bottom-edge scaling pins the peek to exactly 12px per depth without measuring the card. Back cards are mounted **in full** (not photo-only): that pre-decodes the photo *and* the `Image.network` cover thumbnail, so promotion never pops content in. All cards share `cacheWidth: 1080` — a different decode width would mean a different image-cache key and the pre-decode would buy nothing.
The deck animates forward off the existing fly-out `AnimationController` (gated by `_committing`, so spring-back and manual search don't promote), reaching depth 0 — identity transform — before the queue advances, so the swap is invisible. **Bottom reserve is constant (`12 × _maxBackCards`), not scaled to queue depth:** otherwise the top card's own bounds change as the queue shrinks and every advance snaps. Costs ~24px of dead space under the last card; worth it for a card that never reflows. Stack is `Clip.none` so the committed card flies clear and shadows aren't cut off.

**No-OCR state:** "We couldn't read this one", Correct disabled — user searches (swipe up) or skips (swipe left).

**Manual search (#44):** swipe-up/button → `ManualSearchScreen` (auto-focused field, 350ms debounce, live results with covers via `BooksApiService.searchByText`, request-id guard). Picking a result approves it and advances; cancelling leaves the card. Results are deduped by edition (#109): a picker offers a book once, since you choose a book rather than an edition — edition choice is the step-7 "Change cover" flow. Measured 7–9 of 10 results survive, so the list stays useful without over-fetching.

**Step 6 issues — all merged:** #41 confidence score · #42 routing · #43 swipe card · #44 manual search · #45 Import wiring + summary popup (+ deleted `poc_screen.dart`) · #68 cascading card stack + picker-return flash.

**Follow-ups filed as issues:**
- **#93 (iOS: crash on the first "Use Photo" after capture)** — **read #120 first: it may share a root.** #120 was the same `MLKAnalyticsLogger`/`NSUserDefaults` path, crashing while *constructing* a recognizer; #93 was a single construction against uninitialised first-run state. Plausible, unproven. Note TestFlight now has the dSYMs, so a recurrence arrives symbolicated — which is what #93 was always blocked on. — killed the app once on the first camera capture after a fresh install, never reproduced. Ruled out: the Flutter tooling detaching, and a missing usage-description string (both are present, and that class kills the process *every* time). Leading theory is memory pressure — "Use Photo" is peak memory (full-res capture + JPEG encode + ML Kit's first model load) on a 3GB iPad. **Do not "fix" it by downscaling capture**: that reverses the deliberate full-resolution decision that protects thin/vertical cover text. If it was a memory kill there is no `Runner` crash report to find — iOS records those as system-wide `JetsamEvent-*.ips`. Blocked on crash visibility: `devicectl sysdiagnose` fails and nothing syncs to the Mac, which is why TestFlight (dSYMs upload, so reports arrive symbolicated) and Firebase Crashlytics matter.
- **#66 (Option B import UX)** — process in the background, drop the user on their Library (auto-adds stream in live), show an in-app "N ready to review" prompt when done. Better for large camera-roll imports than the blocking loader, and the real fix for the residual per-book OCR hiccup (OCR can't be moved off the main isolate with this plugin).
- ✅ **#87 (delete `linux/`, `macos/`, `windows/`) — done.** Seven generated plugin-registrant files used to show as modified after **every** `flutter pub get` (including the implicit ones inside `dart run flutter_launcher_icons` and `flutterfire configure`) with **zero content change**: Flutter writes LF, Windows Git checks out CRLF. It made a clean `main` read as dirty (`main*` in VS Code) and cost real diagnosis time. **Deleting the folders was necessary but not sufficient** — `flutter pub get` still regenerates the registrant stubs into those paths (an empty `windows/`, three files under `linux/flutter/`, `macos/Flutter/`), so they came straight back as *untracked* noise instead of modified noise. The fix is both halves: the tracked scaffolding is deleted **and** `/linux/`, `/macos/`, `/windows/` are gitignored. Desktop is not a build target — Android + iOS only — so if it were ever wanted, `flutter create --platforms=windows .` regenerates it.
- **#100 (search your own library)** — requested by Richie; there is currently no way to find a book you already own. One screen, opened from the bottom-nav Search tab *and* a search icon in the Library AppBar. Filters `booksStreamProvider` **in memory** rather than querying Firestore: Firestore has no substring search (server-side would mean a third-party index like Algolia), the free tier caps at 100 books, and in-memory also works offline at no read cost. `_GridTile` is private to `library_screen.dart` and should be extracted so search results match the grid instead of drifting from it.
- **#101 (wire up the Library sort control)** — see the warning under Dashboard Design Notes. Small, and already specified by MVP scope.

**Ideas not yet created:**
- **Change cover** — specified in full under "Book Detail Design Notes (Step 7)" below; it is part of step 7, not a loose idea.
- `inauthor:`-constrained retrieval — only worth it if beta shows common-title ambiguity is a recurring pain.
- Full "delight" import loading animation/game — Phase 2 polish.

## Book Detail Design Notes (Step 7 — Next)
Richie's Figma prototype: tap a cover anywhere in the library → a sheet slides over it, the library staying visible and dimmed behind.

**Layout, top to bottom:** cover art full-bleed at the top, **X to close top-right and a 3-dot menu opposite it**; genre chip; title; author; a two-column stat row **YEAR | PAGES**; synopsis paragraph; **MOODS** chips; **BUY THIS BOOK** — one row per retailer (Amazon "Paperback · Kindle", Audible "Audiobook") with a chevron each.

**Build for beta: title, author, year, pages, synopsis, genre.** Everything else is layout-only or later:
- **Moods do not exist yet.** Moods are *user-created tags* a person applies to a book in their own library — that is step 8's "basic manual shelves and tags", and the same vocabulary the mood quiz (step 9) and Richie's filter chips draw on. Until then the detail view shows **genre only**. When moods arrive they sit next to the genre chip and must be **visually distinguished — a different colour** — because one is publisher metadata and the other is the user's own word for the book.
- **Buy links: build the placement, not the affiliate wiring.** Affiliate links are Phase 3 per the monetization table. The rows should sit and look as the mockup shows so the eventual swap is cosmetic.

**Nothing is tappable yet.** Cover tiles have no `onTap` in `library_screen.dart` or the `home_screen` rows — there is currently no way to open anything from a cover. Step 7 has to wire that, and #100 (library search) needs the same destination for its results.

**What Google Books actually returns**, measured across 12 books from Margot's set via the search endpoint the app already calls. The single-volume endpoint (`/volumes/{id}`) adds only `printedPageCount` and `dimensions` — **there is no reason to make a second request.**

| Availability | Fields |
|---|---|
| **12/12** | `title`, `authors[]`, `description`, `pageCount`, `categories[]`, `imageLinks`, `publishedDate`, `publisher`, `industryIdentifiers` (ISBN), `language`, `printType`, `maturityRating`, `previewLink`/`infoLink`, `accessInfo.webReaderLink` |
| **9/12** | `subtitle` — often marketing fluff ("A Novel"), occasionally real |
| **6/12** | `saleInfo.buyLink` (Google Play), `listPrice`, `retailPrice` — e.g. list $18 / retail $9 |
| **2/12** | `averageRating`, `ratingsCount` |

Ignore as plumbing: `contentVersion`, `readingModes`, `panelizationSummary`, `allowAnonLogging`, `quoteSharingAllowed`.

**Already stored, no work needed:** title, author, **description (the synopsis)**, pageCount, categories → genre, imageLinks → coverUrl. The synopsis is the one Figma element that is already fully in the database.

**⚠️ Google Books ratings are unusable — 2/12, and the single-volume endpoint does not help.** So MVP scope's "rating" in the sidebar is **the user's own rating** of a book they have read, which is a new Firestore field. The scope line was ambiguous; this settles it.

**Buy links — what is actually possible:**
- **Amazon: constructible from ISBN-10** (`amazon.com/dp/{ISBN_10}`), present 8/9. The one miss is a movie tie-in whose ISBN-13 starts `979`; those have no ISBN-10 equivalent **by design**, not a data gap. Fall back to a search URL on the ISBN-13.
- **Google Play: free when present** via `saleInfo.buyLink`, but only 6/12.
- **Audible: nothing.** Google Books returns no audiobook data at all, so the mockup's "Audible / Audiobook" row could only ever be a search link unless another source is added.

The Figma's clean Amazon-and-Audible pair is therefore aspirational, and "Paperback · Kindle" as distinct formats is not something Google tells us either.

**Affiliate links are deliberately deferred past beta.** The *link* is trivial; the *programme* is not. Amazon Associates needs an application, a disclosure notice, and — verify current terms — historically a few qualifying sales within ~180 days of approval or the account is closed. A 20-tester beta is unlikely to clear that bar, so applying early risks burning the application. Build the row, point it at a plain untagged link, and swap in a tagged URL once there is real traffic. Link to the **physical** book's page: linking out to buy physical goods is standard, while external purchase flows for *digital* content stray into Apple's review rules.

**Store ISBN alongside `publishedDate`.** The detail view reads Firestore, not the API, so anything unstored means a fresh request per open. `publisher` (12/12) and `previewLink` (12/12, "Read a sample") are cheap adds worth considering in the same pass.

**Three gaps between the mockup and the data we actually store:**
- **`publishedDate` is not on `Book` at all.** Google Books returns `volumeInfo.publishedDate` but `fromGoogleBooksJson` drops it, so "YEAR" needs a new field and a Firestore mapping. The format varies — `2018-04-03`, `2018-04`, `2018` — so take the leading four digits rather than parsing a date.
- **Google's `categories` are far coarser than the mockup.** The Overstory returns `['Fiction']`, not the "Literary Fiction" the Figma shows. Others give `['Young Adult Fiction']`, `['Electronic books']`, or nothing. The genre chip will often read a bland "Fiction" or be absent — design for both.
- **Year and pages describe the matched *edition*, not the work.** Project Hail Mary's movie tie-in reports 2025 where the original is 2021; The Overstory returns 420 pages where the mockup shows 512. A 2018 novel can legitimately display a 2025 year. Same edition ambiguity as #83 and change-cover.

**Change cover (Bode's design).** The 3-dot menu on the cover — opposite the X — opens options including **Change cover**, which shows the other editions of that book so the user can pick the one matching their physical copy. **Deliberately not part of import**: whatever cover recognition picks is fine at add time, and we advertise that it can be changed afterwards. That is why import can dedupe duplicate editions freely (#83) — editions are re-queried by title+author on demand, never carried through the review queue or stored. `coverUrl` is a single Firestore field, so applying a choice is one overwrite. True custom-photo covers are different: they need Cloud Storage = Phase 2.

## Key Files
```
bookshelf_app/lib/
├── main.dart                        — Firebase init, dotenv, anonymous auth, ProviderScope → MainScaffold
├── core/constants.dart              — googleBooksBaseUrl, openLibraryBaseUrl/UserAgent, bookLookupTimeout, autoAddConfidenceThreshold (0.75)
├── core/recognition_log.dart        — debug-only [REC] dump: OCR lines + boxes, query, top match, and why a lookup missed. Source of test/fixtures
├── models/book.dart                 — Book model, fromGoogleBooksJson + googleCoverUrl (600px, no page-curl), fromOpenLibraryJson, fromFirestore, toFirestore
├── widgets/book_grid_tile.dart       — BookGridTile: one book in a 3-column grid (cover, title, author). Shared so library search (#100) renders identically; `gridAspectRatio` lives here beside the layout it describes
├── models/pending_book.dart
├── services/book_recognition_service.dart  — ML Kit OCR → OcrResult. Holds ONE lazily-created TextRecognizer for the service's life — one per photo crashed iOS (#120) (per-line text + bounding box + imageHeight + isScreenshot). Normalizes iOS's transposed boxes here (#94) so the query builder sees Android geometry
├── services/books_api_service.dart  — query builder, fuzzy rerank, confidence, searchByText. _fetchBooks = Google Books, falling back to Open Library only on timeout/429/5xx
├── services/book_repository.dart    — BookRepository: addBook (returns doc id, null if dup), addBooks (one WriteBatch for import), deleteBook, watchBooks. Dedup = same googleBooksId OR same title+author (catches different Google Books editions)
├── providers/recognition_provider.dart     — bookRepositoryProvider (+ RecognitionNotifier, now unused — kept in case the camera flow ever wants a single-photo notifier)
├── providers/import_provider.dart   — ImportNotifier: importImages routing (collects confident matches → one batched addBooks after the loop), approval queue, autoAdded list, undoAutoAdd/approveTop/rejectTop, addedCount/alreadyInLibrary/reviewCount/progress
├── providers/books_provider.dart    — booksStreamProvider: StreamProvider<List<Book>> wrapping watchBooks()
├── screens/main_scaffold.dart       — 5-tab NavigationBar shell (Home, Search, Capture, Import, Discover) + IndexedStack
├── screens/home_screen.dart         — Home screen: Netflix-style rows (Your Library + genre rows) + hamburger drawer
├── screens/library_screen.dart      — Library screen: 3-column grid of BookGridTile, genre filter chips, alphabetical sort. Sort control still unwired (#101)
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
| Beta | Aug–Sep 2026 | 20-50 users, mood tagging, iterate on UX. **Delivered via iOS TestFlight** — every tester who agreed is an iOS user, so the iOS build path moved up from Phase 2. See "iOS + Beta Distribution" |
| Launch v1.0 | Oct 2026 | Google Play, free + **Premium one-time unlock** live — complete the pre-launch security steps in "API Keys & Secrets" first (App Check + key restrictions), and **#99 (real accounts) is a hard prerequisite**: charging for storage while the library can vanish on reinstall is a refund waiting to happen |
| Phase 2 | Q1 2027 | iOS *feature* parity + polish (the build path landed early for beta), themes, social sharing. AI auto-tagging is no longer scheduled here — see "Potential Ideas" |
