# TODO

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
