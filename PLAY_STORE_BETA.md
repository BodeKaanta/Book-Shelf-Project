# Play Store Beta — Handoff / Checklist

Working doc for getting the Bookedex closed beta onto Google Play. Delete once the beta is live.
Durable build knowledge lives in CLAUDE.md → "Release Builds (Android)"; this file is the current state and the remaining steps.

## State as of 2 Aug 2026

Done and verified on Bode's PC (working copy is now `C:\dev\Book-Shelf-Project`):

- Upload keystore generated, release signing wired up. `keytool -printcert` on the bundle confirms `CN=Bode Kaanta, O=Bookedex`, not the debug key.
- Release build **runs on device** — it initially hung at "Recognizing… 0 of N" because R8 stripped ML Kit members; fixed with `-keep` rules in `proguard-rules.pro` (#76).
- App icon replaced at all densities + adaptive icon, source art resized to exactly **512×512** for the Play listing (#76).
- `targetSdk`/`compileSdk` 36, `minSdk` 24 — Play's recent-API requirement satisfied.
- Book data switched to **Open Library** (#75) after Google Books stopped returning mainstream titles. No API key needed now, so the dart-define is optional.

**Recognition is 7 of 20** on Margot's photo set. **#78** (query builder) should recover ~6 more and is the highest-value work before shipping — 7/20 will read as broken to a beta tester.

## Keystore backup

| Item | State |
|---|---|
| Keystore password | **Backed up** (password manager) |
| `bookedex-upload-keystore.jks` | **NOT yet backed up** |

File is `C:\Users\bodek\keys\bookedex-upload-keystore.jks`, 2,632 bytes. Copy to two locations and verify with `certutil -hashfile <path> SHA256`:

```
238e6ba69813d62b0582102c210c4a1c6778a53aecf09371d4b4cea21f240a52
```

The `.jks` is itself password-protected, so an unencrypted copy in cloud storage is an acceptable trade — the realistic risk is **losing** it, not theft. **Do not store `key.properties` beside it**: that file holds the password in plaintext and cancels out the keystore's own encryption.

Loss is recoverable but slow: with Play App Signing (accept the default when Play Console offers it) Google holds the app signing key and can reset a lost *upload* key via support over several days. Opting out of Play App Signing is what makes loss unrecoverable.

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
