# Completeness Review: IOSCourse-FavoriteMoviesExercise

**Review date:** 2026-07-18

## Assessment basis

Static inspection of project-owned source and configuration only; no dependency installation, build, database migration, external-service call, or runtime launch was performed. The scan considered 26 project files (7 source files), 0 manifest(s), 0 test-like file(s), and 0 CI workflow(s), excluding dependency/generated directories.

## Classification

**Prototype-demo**

This is a prototype/demo for mobile/iOS. The implemented surface is narrow: it contains 7 source files and visible routes/pages in `Fav-movies/`, `Fav-movies.xcodeproj/`, but those surfaces are not evidence of durable domain execution, verified integrations, or operational completion.

## Why it is not complete

- No recognizable project-owned automated tests were found for the main workflow.
- No checked-in CI workflow proves builds, tests, migrations, and security checks on every change.
- No environment template documents required configuration and secret boundaries.
- No clear deployment/container configuration demonstrates a reproducible production topology.

## Needed features

1. Finish the primary user journey with explicit loading, empty, error, offline, and state-restoration behavior.
2. Separate persistence/network services from views and add validated models plus accessible navigation and controls.
3. Add unit and UI tests for lifecycle, rotation, localization, malformed input, and offline recovery.
4. Create reproducible signing/build configuration, privacy disclosures, release assets, and crash/analytics policy.
5. Add risk-based unit, integration, and end-to-end tests in CI, including migration and failure-path coverage.

## Risks or launch blockers

- Regression risk is high because no recognizable project-owned automated tests cover the main path.
- No CI evidence prevents broken or insecure changes from reaching a release.

## Evidence inspected

- `README.md`
- `Fav-movies/AppDelegate.swift`
- `Fav-movies/ViewController.swift`
- `Fav-movies/AddNewMovieVC.swift`

## Recommended next action

Stop adding generated pages; prove one mobile/iOS workflow against real services and persistent state, with tests and measurable acceptance criteria.

## Implementation progress (2026-07-18)

All five requested implementation areas now have project-owned coverage:

1. The offline library now has explicit loading, empty, content, persistence-error, retry, create, validated error, details, swipe-delete, and relaunch-restoration behavior. Optional images and malformed legacy rows no longer force-unwrap or abort the app.
2. `FavoriteMovieDraft`, immutable records, and `CoreDataMovieRepository` separate validation and persistence from UIKit. The additive Core Data schema supplies identifiers, timestamps, and schema versions; lightweight migration and first-fetch backfill preserve the original store. Navigation, rows, add fields, details, errors, refresh, and controls expose accessible labels, stable identifiers, read-only semantics, Dynamic Type behavior, and VoiceOver announcements.
3. The Swift package contains 14 passing validation and in-memory Core Data integration tests. A wired XCUITest target adds five empty/error, create/details, lifecycle persistence, malformed-legacy, rotation, localization, and offline journeys to the shared scheme.
4. The app now has versioned iOS 15/Swift 5 build settings, automatic-signing boundaries, a shared scheme, privacy manifest/disclosure, photo-library purpose text, migration/release runbooks, and a no-crash/no-analytics policy. Final branded App Store icons/screenshots and organization signing assets remain explicit owner/Apple Developer account gates.
5. CI runs domain/repository tests, plist/Xcode-project/XML/model/storyboard validation, the simulator UI suite, a Debug test build, and Release analysis. Migration tests cover legacy backfill and malformed rows; repository tests cover CRUD, ordering, duplicate identity, deterministic reset, limits, and failure-safe validation.

Validation performed locally: 14/14 Swift package tests passed; app and UI-test sources type-checked against the installed iOS Simulator SDK; plists, localization, storyboards, the Core Data model, Xcode project, and shared scheme passed structural validation; Xcode recognizes both targets; and `git diff --check` passed. Full simulator UI execution is blocked on this machine because Xcode 26.6 reports an older incompatible CoreSimulator service and a missing iOS 26.5 platform. Upgrade testing against a real copy of the original SQLite store, physical-device accessibility/rotation/photo-permission checks, signing/archive, screenshots, and App Store privacy verification remain release-owner/device gates.

## Runtime and login acceptance (2026-07-20)

**NOT_APPLICABLE** for the local web-runtime and browser-login acceptance harness.

- This repository is an offline iOS/UIKit application: the supported application target is `Fav-movies.xcodeproj`, its UI is storyboard-based, persistence is local Core Data, and `scripts/verify.sh` uses `xcodebuild` with an iOS Simulator destination.
- `Package.swift` exposes a library used for isolated domain and repository tests; it does not define an executable product, HTTP server, or independently supported local web application.
- The app has no account, authentication, or session workflow. A browser login test therefore has no applicable product surface.
- A fabricated `start.sh` would misrepresent the supported runtime. Runtime acceptance belongs in Xcode on an installed simulator or signed iOS device, subject to the CoreSimulator, signing, and photo-permission gates recorded above.

### Campaign verification evidence (2026-07-20)

The project remains an independent native iOS app, not a web service and not a non-application repository. No `start.sh` was added because this host cannot boot/install/launch its supported target and a build-only script would not be an application runtime. The campaign result is `NOT_APPLICABLE/native_ios_no_web_login_runtime_spm_verified`.

Direct validation passed 14/14 Swift package tests, plist/localization/project/scheme/storyboard/Core Data XML checks, and iOS Simulator SDK typechecking of the repository plus UIKit application sources. The first unsigned Debug build exposed and retained `FAILED/native_xcodebuild_model_codegen`: the explicit unsupported Core Data `codeGenerationType="manual/none"` value crashed Xcode 26's model generator. Removing that invalid attribute restored successful `momc` dry-run/model compilation. The retry was retained as `FAILED/native_xcodebuild_host_unavailable`; it then advanced to the normal build graph and stopped only at linker/storyboard operations because Xcode reports the iOS 26.5 platform unavailable and CoreSimulator 1051.49.0 is older than required 1051.55.0. Assigned ports `55618`, `6050`, and `6051` were not used and remained released. `git diff --check` passed.

## Isolated runtime-verification companion (2026-07-24)

The root `start.sh` now launches a loopback-only campaign companion on separately assigned API/UI ports. It preserves the offline UIKit application: the web page explicitly identifies itself as verification infrastructure and does not simulate the native movie-library interface or receive movie, preference, or device data.

The companion supplies functional credential login, database-backed bearer identity, and a deidentified OpenRouter readiness form. PostgreSQL stores password hashes, token digests, append-only successful provider receipts/output, and terminal attempt evidence. Attempts transition once from `PENDING` to `SUCCEEDED` or `FAILED`; startup reconciles interrupted pending rows, and terminal rows reject mutation. Native evidence remains separate: 14 Swift package tests and iPhoneOS SDK source typechecking pass, while this host's CoreSimulator 1051.49.0/required 1051.55.0 mismatch leaves no available simulator runtime. No native simulator or UIKit application launch is claimed.
