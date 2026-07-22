# TODO

## Auth status (as of this session)

**Working:** logged-in browsing. Login now completes and content renders on device.
The chain that had to be fixed: (1) reddift now sends the User-Agent on OAuth token
requests (`org.quantumbadger.redreader/1.25.2`); (2) the login web view now presents
correctly (deferred one run-loop turn after `resetStack`). Credentials are RedReader's
(matching Android/JRAW).

**Broken / next up — require login (decision: option #2):** guest/not-logged-in
browsing does NOT work, because modern Reddit 403s all unauthenticated API access and
reddift has no userless (`installed_client`) token. We chose to **require login** rather
than add a userless token. Still to implement:
- In `AccountController.initialize()` and the launch path (`AppDelegate`), when
  `!isLoggedIn`, do NOT create the anonymous `Session()` or kick off content loads;
  instead route to the login flow (`doAddAccount` / `challengeWithScopes`) as a
  non-dismissable onboarding step.
- Remove/gate the GUEST fallbacks (e.g. `didRequestGuestAccount`, logout → GUEST) so the
  app never lands in the broken anonymous state.
- The background `forbidden(...)` HTML noise at launch is the doomed guest requests; it
  goes away once guest sessions are eliminated.
- Library note: no maintained Swift Reddit API lib exists to replace reddift; stay on the
  vendored copy and patch as needed (Android parity comes from JRAW, Java-only).

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

## Missing bundled font — googleicon.ttf

At launch the console logs:
`FontParser could not open filePath …/Slide for Reddit.app/googleicon.ttf: [2: No such file or directory]`
and `GSFont: file doesn't exist … googleicon.ttf`.

The app references a `googleicon.ttf` font that isn't present in the app bundle
(not copied as a resource / not in the target's Copy Bundle Resources, or the file is
missing from the repo). Non-fatal, but any UI relying on that icon font won't render.
To fix: locate where `googleicon` is registered/used (Info.plist `UIAppFonts`, or a
`UIFont(name: "googleicon", …)` / icon-font helper), then either add the missing
`googleicon.ttf` to the repo + Copy Bundle Resources, or migrate those glyphs to the
SF Symbols the app already uses elsewhere.
