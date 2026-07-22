# Slide for Reddit — Modernization & CocoaPods Removal Plan

> Status: **Plan only** — no code changes yet. Branch of record: `feature/eb-build`.
> Decisions locked with the maintainer (2026-07-22):
> - **Minimum iOS: 15.0** (unifies the current 12.0/13.2/14.0 mix).
> - **Dependency strategy: replace forks with native/maintained libraries where possible**; vendor into the repo only what has no alternative (primarily `reddift`).
> - **Package manager: Swift Package Manager only.** CocoaPods removed entirely.

---

## 1. Current State

Large UIKit Reddit client, ~239 Swift files, **8 first-party targets**:

- `Slide for Reddit` (main app)
- `Slide for RedditTests`, `Slide for RedditUITests`
- `Slide Widgets`
- `Slide for Apple Watch`, `Slide for Apple Watch Extension`
- `Favorite SubredditsExtension`
- `Open in Slide` (action extension)
- `Slide Screenshot Automation`

### Dependencies are half-migrated (hybrid CocoaPods + SPM)

**Already on SPM** (in `.xcworkspace/.../Package.resolved`):
SDWebImage 5.9.1, swift-badge (BadgeSwift) 8.0.2, BiometricAuthentication 3.1.2, Embassy 4.1.1, Starscream 3.1.1, Anchorage 4.5.0, Then 2.7.0, Proton 0.5.0.

**Still on CocoaPods** (`Podfile`, `Pods/`, `.xcworkspace` references `Pods.xcodeproj`):
reddift, Alamofire 4.9.1, SwiftyJSON (ccrama `hotfix-xcode12` branch), DTCoreText 1.6.26, MaterialComponents 119.5.0, SDCAlertView 12.0.5, RLBAlertsPickers (ccrama fork), OpalImagePicker 3.0.0, MKColorPicker (ccrama fork), SubtleVolume 1.1.0, SwiftLinkPreview 3.0.1, TGPControls 5.1.0, YoutubePlayer-in-WKWebView 0.3.5, LicensesViewController 0.7.0, MTColorDistance 0.0.3, SwiftEntryKit (ccrama fork), MiniKeychain (transitive), HTMLSpecialCharacters (transitive), SwiftLint 0.42.0; plus MDFInternationalization / MotionAnimator / MotionInterchange / QuickLayout as transitive deps.

### Inconsistencies left by the `feature/eb-build` "get it compiling" hack

- **Deployment target split**: `12.0` (6 configs), `13.2` (2), `14.0` (4).
- **Swift version split**: `5.0` (16 configs), **`4.2` (2 configs)** — RLBAlertsPickers & SwiftLinkPreview, forced by the Podfile `post_install`.
- **Stale/branch-locked deps**: Alamofire pinned `~> 4.3` (4.x is EOL, current 5.x); SwiftyJSON on a personal hotfix branch; Starscream 3.1.1; MaterialComponents 119.5.0 (Google archived MDC-iOS).
- **Personal forks with no upstream releases**: reddift, MKColorPicker, SwiftEntryKit, SwiftyJSON, RLBAlertsPickers (Alerts-Pickers).

### Usage weighting (drives effort)

| Dependency | Import sites |
|---|---:|
| reddift | 102 |
| SDCAlertView | 29 |
| RLBAlertsPickers | 24 |
| MaterialComponents | 10 |
| Alamofire | 9 |
| SwiftyJSON | 6 |
| MKColorPicker | 6 |
| DTCoreText | 6 |
| LicensesViewController | 4 |
| SwiftLinkPreview / SwiftEntryKit / SubtleVolume | 2 each |
| TGPControls / OpalImagePicker / MTColorDistance | 1 each |
| YoutubePlayer-in-WKWebView / MiniKeychain / HTMLSpecialCharacters | 0 (unused/transitive) |

`YTPlayerView.h/.m` is vendored at the repo root (Objective-C).

---

## 2. Target State

- **No CocoaPods**: no `Podfile`, `Podfile.lock`, `Pods/`; `.xcworkspace` no longer references `Pods.xcodeproj` (flatten to the `.xcodeproj`, or drop the workspace — SPM does not require one).
- **All deps via SPM, vendored source, or native APIs.**
- **Single deployment target: iOS 15.0** on every target.
- **Single Swift version: 5.0** (kill the 4.2 configs).
- SwiftLint via SPM build-tool plugin (or Mint), not a pod.
- Clean build settings (xcconfig-driven where practical), modern warning defaults, updated `README` / `bootstrap.sh` / `.gitignore` / CI.

---

## 3. Dependency Disposition (per the "replace forks, vendor only reddift" decision)

| Dependency | Uses | Disposition | Notes |
|---|---:|---|---|
| **reddift** (fork) | 102 | **Vendor** as local SPM package `LocalPackages/Reddift` | No upstream release; core Reddit API. Patch its Alamofire dep to 5.x here. Highest-risk item. |
| **Alamofire** | 9 | **SPM 5.x** | 4→5 breaking API changes. Also resolve reddift's internal Alamofire usage. |
| **SwiftyJSON** | 6 | **SPM, official 5.x** | Drop ccrama branch. |
| **SDCAlertView** | 29 | **SPM** | Recent versions support SPM; verify API parity (high usage). |
| **RLBAlertsPickers** (fork) | 24 | **Replace where possible**; vendor the remainder as `LocalPackages/AlertsPickers` | Much of it (image/photo/location pickers) can move to `PHPickerViewController` / native alerts. Vendor only the irreplaceable pieces. |
| **MaterialComponents** | 10 | **Replace with native** | `ActivityIndicator` → `UIActivityIndicatorView`; `ProgressView` → `UIProgressView`. Eliminates MDF/Motion/QuickLayout transitive tree. |
| **MKColorPicker** (fork) | 6 | **Replace** with `UIColorPickerViewController` (iOS 14+) | Native since iOS 14; viable at the iOS 15 floor. |
| **DTCoreText** | 6 | **SPM** (or vendor) | Recent versions support SPM. |
| **LicensesViewController** | 4 | **SPM** if available, else vendor (small) | |
| **SwiftLinkPreview** | 2 | **SPM, official** | Also removes a 4.2-Swift config. |
| **SwiftEntryKit** (fork) | 2 | **SPM, upstream 2.x** | |
| **SubtleVolume** | 2 | **Vendor** (tiny, unmaintained) | |
| **TGPControls** | 1 | **Vendor** (tiny) | |
| **MTColorDistance** | 1 | **Vendor** (tiny) or inline the color-distance math | |
| **OpalImagePicker** | 1 | **Replace** with `PHPickerViewController` | |
| **YoutubePlayer-in-WKWebView** | 0 | **Remove** | Confirm dead; `YTPlayerView.h/.m` at root already covers YouTube embedding. |
| **MiniKeychain / HTMLSpecialCharacters** | 0 | **Resolve via reddift** | Transitive; re-declare inside vendored reddift package or replace with Keychain Services / native unescaping. |
| **SwiftLint** | tooling | **SPM build-tool plugin** or Mint | Remove from Podfile. |

Net result: `LocalPackages/` will contain roughly `Reddift`, `AlertsPickers` (residual), `SubtleVolume`, `TGPControls`, `MTColorDistance`. Everything else is an SPM remote or gone.

---

## 4. Phased Execution Plan

### Phase 0 — Baseline & safety net  ✅ DONE
- Branched `feature/modernize` off `feature/eb-build`.
- Captured `xcodebuild -showBuildSettings` baseline (scratchpad `baseline-buildsettings-app.txt`).
- **Finding:** the `feature/eb-build` baseline does **not** build via command-line `xcodebuild` — it fails on `'WebSocket' is ambiguous` in `LiveThreadViewController.swift`. Cause: `reddift` (CocoaPods) pulls Starscream transitively **and** Starscream is added via SPM, so two `WebSocket` types are in scope. This is a preview of exactly the duplicate-symbol class of problem the migration resolves. Fixed interim by qualifying `Starscream.WebSocket` (survives into the final state since Starscream stays an SPM dep).

### Phase 1 — Set the floor  ✅ DONE
- Unified **all** first-party configs to `IPHONEOS_DEPLOYMENT_TARGET = 15.0` (12 configs, was 12.0/13.2/14.0) and `SWIFT_VERSION = 5.0` (18 configs, killed the two Swift 4.2 configs on the Apple Watch app).
- Bumped the two watch targets to `WATCHOS_DEPLOYMENT_TARGET = 8.0` (was 4.3, unbuildably ancient — the natural pair for an iOS 15 floor). ⚠️ Confirm this watchOS floor is acceptable.
- Left the `Podfile` `post_install` (forces pods to 12.0 / Swift 4.2) untouched — pods deploy below the app fine and are slated for removal in later phases.
- **Verified:** `Slide for Reddit` scheme (app + widgets + WidgetConfigIntent + extensions) builds clean on iOS 17 simulator; `Slide for Apple Watch` scheme builds clean on watchOS simulator. Both BUILD SUCCEEDED.

### Phase 2 — Vendor reddift (and residual forks)
- Create `LocalPackages/Reddift/` with a `Package.swift`; move reddift source in; retarget its Alamofire dependency to 5.x; re-declare MiniKeychain/HTMLSpecialCharacters needs (native Keychain / native HTML unescape).
- Vendor `SubtleVolume`, `TGPControls`, `MTColorDistance` as local packages.
- Add all local packages to the app/extension/widget/watch targets as needed.

### Phase 3 — Add SPM remotes
- Alamofire 5.x, SwiftyJSON 5.x (official), SDCAlertView, DTCoreText, SwiftLinkPreview, SwiftEntryKit (upstream), LicensesViewController.
- Pin explicit versions; commit `Package.resolved`.

### Phase 4 — Native replacements
- MaterialComponents → `UIActivityIndicatorView` / `UIProgressView` (10 sites).
- MKColorPicker → `UIColorPickerViewController` (6 sites).
- OpalImagePicker + RLBAlertsPickers photo/media flows → `PHPickerViewController` (native).
- Remove YoutubePlayer-in-WKWebView after confirming it's dead.

### Phase 5 — Fix API breakage
- Alamofire 4→5 call-site migration (request/response builders, validation, serialization changes) across the app **and** vendored reddift.
- SDCAlertView / SwiftEntryKit / SwiftyJSON API deltas.
- Reconcile any RLBAlertsPickers call sites not covered by native replacements.

### Phase 6 — Tear out CocoaPods
- Delete `Podfile`, `Podfile.lock`, `Pods/`, `Pods.xcodeproj`.
- Remove `[CP]` build phases (Check Pods Manifest, Copy Pods Resources, Embed Pods Frameworks) from **every** target — including widgets, watch, and extensions.
- Strip `${PODS_ROOT}` / `${PODS_CONFIGURATION_BUILD_DIR}` from `FRAMEWORK_SEARCH_PATHS`, `HEADER_SEARCH_PATHS`, `OTHER_LDFLAGS`, and any pod-generated `.xcconfig` includes.
- Flatten `.xcworkspace` to reference only the project, or delete the workspace.

### Phase 7 — Normalize build settings
- Confirm single deployment target & Swift version everywhere (no 4.2 remnants).
- Introduce shared `.xcconfig` files per configuration for maintainability.
- Enable modern defaults: recommended compiler warnings, dead-code stripping, `ENABLE_USER_SCRIPT_SANDBOXING`, up-to-date `LastUpgradeCheck`.
- Wire SwiftLint as a build-tool plugin; update `.swiftlint.yml` if needed.

### Phase 8 — Verify & document
- Build **all** targets on simulator; run test targets.
- Visual-diff against the Phase 0 baseline screens.
- Update `README.md`, `bootstrap.sh` (drop pod/Mint bootstrap steps), `.gitignore` (drop CocoaPods section), and `.github` CI to remove `pod install`.
- Update `Gemfile`/`fastlane` if they invoke CocoaPods.

---

## 5. Key Risks

1. **reddift ↔ Alamofire coupling** — reddift's networking is built on Alamofire 4. Vendoring reddift lets us patch it to Alamofire 5, but this is the largest single migration surface (102 + 9 call sites plus library internals). This is the critical path.
2. **MaterialComponents removal** — touches 10 files but is the biggest debt reducer (archived library, no SPM, pulls 4 transitive pods). Native replacements are straightforward but need visual verification.
3. **Multi-target pod teardown** — widgets, watch app/extension, and the two app extensions each carry their own pod embed phases and search paths; missing one produces link/embed failures that are easy to misattribute.
4. **RLBAlertsPickers residual** — the "replace where possible" scope for its 24 sites needs case-by-case triage; some custom pickers may still require vendoring.
5. **SDCAlertView SPM parity** — 29 sites; confirm the SPM-published version exposes the same API surface before committing.

---

## 6. Open Items (to confirm during execution)
- Whether reddift's fork can move to Alamofire 5 cleanly, or needs a compatibility shim.
- Which RLBAlertsPickers components have no native equivalent and must be vendored.
- Whether `Slide Screenshot Automation` (uses Embassy) and fastlane snapshot flows still work post-migration.
- CI provider specifics in `.github/` (build steps referencing CocoaPods).
