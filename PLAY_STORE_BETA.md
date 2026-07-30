# Play Store Beta — Handoff / Checklist

Working doc for getting the Bookedex closed beta onto Google Play. Delete once the beta is live.
Durable build knowledge lives in CLAUDE.md → "Release Builds (Android)"; this file is the current state and the remaining steps.

## State as of 30 Jul 2026

Done and verified on Bode's PC:

- Upload keystore generated, release signing wired up. A test bundle built and `keytool -printcert` confirmed `CN=Bode Kaanta, O=Bookedex` (not the debug key).
- R8 failure fixed (`android/app/proguard-rules.pro`) — release builds now complete.
- App icon replaced at all five densities + adaptive icon.
- `targetSdk`/`compileSdk` 36, `minSdk` 24 — Play's recent-API requirement already satisfied.
- Artifact produced: `build/app/outputs/bundle/release/app-release.aab`, 65.2 MB.

**Not yet done:** nobody has run the minified release build on a device. See "Do this first".

## Setting up a second machine

`git pull` gets the code but **three files are not in git and never will be.** Without them the build still succeeds — it just quietly produces a debug-signed, keyless bundle that Play rejects and that fails every book lookup.

| File | Where it goes | Get it from |
|---|---|---|
| `.env` (Books API key) | `bookshelf_app/.env` | Copy from the PC, or regenerate the key in Google Cloud Console |
| `android/key.properties` | `bookshelf_app/android/key.properties` | Copy from the PC |
| `bookedex-upload-keystore.jks` | anywhere outside the repo | Copy from `C:\Users\bodek\keys\` on the PC |

`key.properties` contains an absolute `storeFile` path — **update it to wherever the keystore lives on this machine.** Its format:

```properties
storePassword=<the keystore password>
keyPassword=<same>
keyAlias=upload
storeFile=C:/Users/<you>/keys/bookedex-upload-keystore.jks
```

Forward slashes, even on Windows — backslashes are escape characters in `.properties` files.

Transfer these over USB or an encrypted archive. Do not paste the keystore password into a chat, an issue, or any file that gets committed.

### Verify the machine is set up correctly

```bash
flutter build appbundle --dart-define-from-file=.env
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

Must print `Owner: CN=Bode Kaanta, O=Bookedex, C=US`. If it says `CN=Android Debug`, `key.properties` is missing or its `storeFile` path is wrong — and the build gave no warning about it.

## Do this first: smoke-test the release build

R8 strips unused code and can break things that work perfectly in debug. This has not been checked yet.

```bash
flutter run --release --dart-define-from-file=.env
```

Confirm:

1. The red Bookedex icon appears on the home screen (not the blue Flutter logo).
2. App launches without crashing.
3. **Import one photo and confirm a book is recognized.** This is the important one — it proves the API key reached the release build. `main()` asserts the key is present, but asserts are stripped in release, so a keyless build fails *silently*: every lookup returns HTTP 429 and recognition just never works.
4. Library grid and the swipe review card still render.

If recognition fails here but works in debug, suspect the missing `--dart-define-from-file=.env` before anything else.

## Remaining steps to ship the beta

**Bode:**

- [ ] Smoke-test the release build (above)
- [ ] $25 one-time Google Play developer account fee
- [ ] Create the app in Play Console (`com.bookedex.app`)
- [ ] 2+ phone screenshots — easy now the icon is in. Good candidates: the Library grid, and the swipe review card mid-swipe
- [ ] Upload the AAB to a **closed testing** track, add Margot as a tester
- [ ] Complete the Data Safety form — **it must match the privacy policy**, so get the policy corrected first or review will bounce it
- [ ] Host the privacy policy (GitHub Pages on this repo) and put the URL in Play Console

**Richie:**

- [ ] **Resize the store icon to exactly 512×512.** Current art is 513×513 and Play Console will reject it. (The in-app launcher icon is already handled — it gets resampled from the same art.)
- [ ] Fix the privacy policy. It currently describes an app that doesn't exist:

| Policy claims | Reality |
|---|---|
| Google Cloud Vision API processes covers; images "may be sent" to it | **False.** ML Kit runs a bundled on-device model. No image ever leaves the phone. |
| Firebase Analytics collects usage data | Not a dependency. Not collected. |
| Firebase Crashlytics collects crash reports | Not a dependency. Not collected. |
| Email address collected via Firebase Authentication | Anonymous auth only. No email collected. |
| Firebase "file storage" | Cloud Storage unused. Only Google Books cover URLs are stored. |
| "Delete your account and all associated data at any time from within the app" | **Feature does not exist.** Cut the claim or build it. |

The Cloud Vision line is worth fixing first: reality is a *better* story than the policy tells. "Your photos are processed entirely on your device and never uploaded" belongs in the store description, not disclaimed away.

- [ ] Replace both `[your contact email]` placeholders

## Known non-blockers

- **65 MB AAB** is fine. It bundles all three CPU architectures; Play serves per-device slices, so testers download roughly a third. Play's base-module limit is 150 MB.
- **KGP build warning** about `image_picker_android` applying the Kotlin Gradle Plugin is upstream, harmless today, and will matter only when a future Flutter release enforces built-in Kotlin.
- **Recognition accuracy is ~48%** on hard real-world photos and that is the known ceiling — see CLAUDE.md → "Recognition Status". The approval/swipe flow is what makes it usable. Not a bug to chase before beta.
