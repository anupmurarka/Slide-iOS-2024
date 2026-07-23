# TODO

## Multi-account fixes (in progress — needs device retest)

Symptoms with 2+ accounts: (a) "Add a new account" reused the current account's Reddit
cookies and re-authorized the same user; (b) after a new login, content/subs didn't
switch; (c) the new account wasn't listed in the switcher. Implemented:
- **(a)** `WebsiteViewController` now uses an ephemeral `.nonPersistent()`
  `WKWebsiteDataStore` when `isLoginFlow` (set in `AccountController.challengeWithScopes`),
  so the OAuth page never reuses an existing `reddit_session` cookie → always a fresh
  login. Replaces the old, ineffective `HTTPCookieStorage.shared` wipe (WK uses its own
  store).
- **(c)** The OAuth-success callback now also calls `LocalKeystore.save` (writes
  `SAVED_TOKENS`) alongside the keychain save, so `AccountController.names` includes the
  new account immediately and `initialize()` reads the fresh valid token via the migrated
  branch.
- **(b)** Gated the "Subscribe to r/slide_ios?" onboarding modal in
  `MainViewController.complete` to first-account-only, so adding a 2nd+ account runs
  straight through `finalizeSetup → hardReset` without racing an extra alert against the
  stack rebuild.
- **Could not verify on simulator:** the OAuth web view does not present after
  `resetStack` on this simulator (a present-after-reset quirk; it presents fine on
  device). So (a)/(b)/(c) are code-complete and compile, but **need a device retest**.
  If (b) persists on device, capture the runtime log around login → `syncColors` →
  `complete` → `finalizeSetup` → `hardReset`.

## Auth status (as of this session)

**Working:** logged-in browsing. Login now completes and content renders on device.
The chain that had to be fixed: (1) reddift now sends the User-Agent on OAuth token
requests (`org.quantumbadger.redreader/1.25.2`); (2) the login web view now presents
correctly (deferred one run-loop turn after `resetStack`). Credentials are RedReader's
(matching Android/JRAW).

**DONE — require login (decision: option #2):** guest/not-logged-in browsing is removed
because modern Reddit 403s all unauthenticated API access and reddift has no userless
(`installed_client`) token. Implemented:
- `AccountController.initialize()` and `AppDelegate.reloadSession()` now treat a
  missing/legacy token — including a corrupt record that parses to an **empty
  `accessToken`** (the old-Slide-app migration case) — as a failed login: the stale
  account is purged (`purgeAccount`) and `requireLogin()` posts `.onRequireLogin`
  instead of silently creating an anonymous session.
- `SplitMainViewController.viewDidAppear` gates on `isLoggedIn` and presents the login
  flow (`presentLoginIfNeeded` → `doAddAccount`), guarded by a static
  `isPresentingLogin` flag so the stack-rebuild doesn't loop. Verified on simulator: a
  fresh launch shows the Reddit Log In web view, not a guest feed.
- Removed GUEST fallbacks: `didRequestGuestAccount` (protocol + impl) and the "Browse as
  Guest" menu item deleted; logout now switches to another saved account or requires
  login; `AccountController.delete` typo fixed (`"GUEST"` key → `"name"`). The
  `.onAccountChangedToGuest` notification was replaced with `.onRequireLogin`. Widget
  `"Guest"` display fallbacks → `"Sign in"`.
- The background `forbidden(...)` HTML noise at launch (doomed guest requests) should be
  gone now that guest sessions are eliminated.
- Library note: no maintained Swift Reddit API lib exists to replace reddift; stay on the
  vendored copy and patch as needed (Android parity comes from JRAW, Java-only).

**Minor follow-up:** the login web view still has an `X` close button; dismissing it lands
on an empty feed until re-triggered from the sidebar. Consider re-presenting on dismiss
for a strictly non-dismissable gate. Also `WatchSessionManager` still has `?? Session()`
fallbacks (harmless, ungated) if the watch messages while logged out.

## Other issues to triage (new session)
- Autolayout warning: `ExpandedHitButton` width 30 vs `NavigationButtonBar.ItemWrapperView`
  width 36 (unsatisfiable constraint, non-fatal) — recurring in the nav bar.
- App-group prefs warning `group.io.automationworks.redditslide.prefs` "only allowed for
  System Containers" (see iCloud provisioning item below).
- (User mentioned additional issues to tackle next session — capture them here as found.)

## Reddit API credentials — add a runtime override (settings)

**Context.** After Reddit's 2023 API changes, new third-party API registrations
are impractical, so the app currently authenticates using **RedReader's exempted
OAuth app** (client_id `yH0aTnJEt6qUgGn835B4vg`, redirect `redreader://rr_oauth_redir`,
user-agent `org.quantumbadger.redreader/1.25.2`). These live in
[`Slide for Reddit/reddift_config.json`](Slide%20for%20Reddit/reddift_config.json)
and flow through the now-public reddift `Config` (single source of truth).

These are **not secrets** (OAuth "installed app" has no client secret; the client_id
ships in every binary), so committing them is acceptable. The real improvement is to
stop shipping a *borrowed* identity as the only option.

**Task — mirror the Android runtime-override design.** The Android app
(`slide-2025-android`) lets each user supply their own Reddit app credentials at
runtime instead of relying on the bundled default:
- `SettingValues.PREF_REDDIT_CLIENT_ID_OVERRIDE`
- `SettingValues.PREF_REDDIT_REDIRECT_URI_OVERRIDE`
- `SettingValues.PREF_REDDIT_USER_AGENT_OVERRIDE`
- `SettingValues.PREF_REDDIT_ENABLE_OVERRIDES` (opt-in toggle)
- See `Constants.getClientId()/getRedirectUrl()/getUserAgent()` for the fallback logic.

On iOS:
1. Add a Settings screen ("Advanced" / "Reddit API") with fields for client_id,
   redirect_uri, user_agent and an "Use my own Reddit app" toggle, persisted in
   `UserDefaults`/`SettingValues`.
2. Have reddift `Config` (or a thin app-side wrapper) prefer the user override when
   the toggle is on, else fall back to `reddift_config.json`. Config already reads the
   JSON; add the override lookup ahead of it.
3. If the user sets a custom `redirect_uri`, its scheme must be registered in
   `Info.plist` (`CFBundleURLSchemes`) for the OAuth callback to return to the app —
   document this, or restrict overrides to schemes we register.
4. Update the OAuth authorize URL (AccountController) and the WebView redirect match
   (WebsiteViewController) — both already read `Config`, so they inherit the override
   automatically once Config honors it.

**Optional hardening (repo hygiene), not required since these aren't secrets:**
- Untrack `reddift_config.json` (`git rm --cached`), add to `.gitignore`, and commit a
  `reddift_config.example.json` template so real/borrowed values stay out of future commits.
- Or move the values to a git-ignored `Secrets.xcconfig` surfaced via `Info.plist`
  build settings (CI-friendly; pairs with the Phase 7 xcconfig work in MIGRATION.md).

## iCloud / CloudKit provisioning — finish verifying

The stripped entitlements (iCloud/CloudKit, `aps-environment`, `ubiquity-kvstore`,
`user-fonts`, app group) were restored in `Slide for Reddit/Slide for Reddit.entitlements`,
which fixed the launch crash at `AppDelegate.isCloudKitAvailable()` (`CKContainer`
trapped without the `com.apple.developer.icloud-services` entitlement).

Provisioning appeared to work when building to device (akm-iPad8) but is **not fully
tested**. Still to verify:
- iCloud container `iCloud.io.automationworks.redditslide` (and `…-debug`) is created
  and enabled on the App ID, and CloudKit **and** Key-value storage are both on.
- The App Group `group.io.automationworks.redditslide.prefs` is provisioned — the earlier
  "only allowed for System Containers" console warning should be gone.
- Push (`aps-environment`) and Fonts (`user-fonts`) capabilities are actually enabled, or
  trim those two entitlement keys if you don't want them (they force extra signing setup).
- Exercise the iCloud paths end-to-end: Settings → sync/restore (`SettingsBackup`
  syncSettings/restoreSync via `NSUbiquitousKeyValueStore`) and the CloudKit
  save/read in `AppDelegate` (readLater/collections/deleted records) on a real device
  signed into iCloud. Confirm no `CKContainer` trap and that data round-trips.

## Missing bundled font — googleicon.ttf  ✅ RESOLVED

At launch the console logged:
`FontParser could not open filePath …/Slide for Reddit.app/googleicon.ttf: [2: No such file or directory]`
and `GSFont: file doesn't exist … googleicon.ttf`.

Investigation: `googleicon.ttf` was listed in `UIAppFonts` in `Slide for Reddit/Info.plist`
since the initial commit, but the file was never present in the repo and was **not
referenced by any code** — `git grep googleicon` matched only the Info.plist entry (no
`UIFont(name: "googleicon", …)`, no icon-font helper; the font picker uses
`UIFont.familyNames`). It was a dead reference inherited from upstream Slide; nothing ever
rendered with it, so no glyph migration was needed.

Fix: removed the stale `googleicon.ttf` entry from `UIAppFonts`. Silences the launch
warnings with no functional impact. The 11 Roboto faces remain correctly declared/bundled.
