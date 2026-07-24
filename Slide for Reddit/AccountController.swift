//
//  AccountController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/7/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import reddift
import SafariServices

class AccountController {
    @objc static func didSaveToken(_ notification: Notification) {
        AccountController.reload()
    }

    static func reload() {
        AccountController.names.removeAll(keepingCapacity: false)
        AccountController.names += LocalKeystore.savedNames
        slideLog(AccountController.names)
    }

    static func switchAccount(name: String) {
        changed = true
        ActionStates.upVotedFullnames.removeAll()
        ActionStates.downVotedFullnames.removeAll()
        ActionStates.savedFullnames.removeAll()
        ActionStates.unvotedFullnames.removeAll()
        ActionStates.unSavedFullnames.removeAll()
        
        UserDefaults.standard.set(name, forKey: "name")
        UserDefaults.standard.synchronize()
        initialize()
    }

    static var isLoggedIn = false
    static var isGold = false
    static var changed = false
    static var modSubs: [String] = []

    static var current: Account?

    static func delete(name: String) {
        do {
            try LocalKeystore.removeToken(of: name)
            try OAuth2TokenRepository.removeToken(of: name)

            if let index = names.firstIndex(of: name) {
                names.remove(at: index)
            }
            // Clear the current-account selection if we just deleted it, so the app
            // routes to login instead of re-selecting a now-tokenless account.
            if UserDefaults.standard.string(forKey: "name") == name {
                UserDefaults.standard.removeObject(forKey: "name")
            }
            UserDefaults.standard.synchronize()

        } catch {
            slideLog(error)
        }
    }

    static var currentName = ""

    /// Removes all persisted state for a stale/corrupt account so the app stops
    /// re-selecting a login that can no longer authenticate.
    static func purgeAccount(_ name: String) {
        do { try LocalKeystore.removeToken(of: name) } catch { slideLog(error) }
        do { try OAuth2TokenRepository.removeToken(of: name) } catch { slideLog(error) }
        names.removeAll { $0 == name }
        UserDefaults.standard.removeObject(forKey: "AUTH+\(name)")
        if UserDefaults.standard.string(forKey: "name") == name {
            UserDefaults.standard.removeObject(forKey: "name")
        }
        UserDefaults.standard.synchronize()
    }

    /// Reddit no longer serves unauthenticated API access, so there is no guest/anonymous
    /// browsing. When there is no valid logged-in account we clear auth state and ask the
    /// UI to present the login flow. A tokenless `Session()` is still assigned to preserve
    /// the non-nil `session` invariant callers rely on; content is gated on `isLoggedIn`.
    static func requireLogin() {
        AccountController.isLoggedIn = false
        AccountController.isGold = false
        AccountController.current = nil
        AccountController.currentName = ""
        (UIApplication.shared.delegate as! AppDelegate).session = Session()
        NotificationCenter.default.post(name: .onRequireLogin, object: nil)
    }

    static func initialize() {
        names.removeAll(keepingCapacity: false)
        names += LocalKeystore.savedNames

        names = names.unique()

        NotificationCenter.default.addObserver(self, selector: #selector(AccountController.didSaveToken(_:)), name: OAuth2TokenRepositoryDidSaveTokenName, object: nil)
        let storedName = UserDefaults.standard.string(forKey: "name")
        if let name = storedName, name != "GUEST", !name.isEmpty {
            slideLog("Name is \(name)")
            do {
                let token: OAuth2Token
                if !isMigrated(name) {
                    token = try OAuth2TokenRepository.token(of: name)
                    try LocalKeystore.save(token: token, of: name)
                } else {
                    token = try LocalKeystore.token(of: name)
                }

                // A legacy/corrupt record (e.g. migrated from the old Slide app) parses
                // without throwing but yields an empty access token. Treat that as a
                // failed login rather than sending an empty bearer token.
                if token.accessToken.isEmpty {
                    throw NSError(domain: "AccountController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Stored token for \(name) is missing an access token"])
                }

                AccountController.isLoggedIn = true
                AccountController.currentName = name

                let session = Session(token: token)
                (UIApplication.shared.delegate as! AppDelegate).session = session
                try session.getUserProfile(name, completion: { (result) in
                    switch result {
                    case .failure(let error):
                        slideLog(error)
                    case .success(let account):
                        AccountController.current = account
                        NotificationCenter.default.post(name: .onAccountChanged, object: nil, userInfo: [
                            "Account": account,
                            ])
                        if AccountController.currentName == name {
                            AccountController.isGold = account.isGold
                        }
                    }
                })
                UserDefaults.standard.set(name, forKey: "name")
                UserDefaults.standard.synchronize()
            } catch {
                slideLog("Token load failed for \(name): \(error)")
                // Drop the stale/corrupt account so we don't keep re-selecting it, then
                // require a fresh login.
                purgeAccount(name)
                requireLogin()
            }
        } else {
            requireLogin()
        }
        NotificationCenter.default.post(name: OAuth2TokenRepositoryDidSaveTokenName, object: nil, userInfo: nil)
    }

    public static var names: [String] = []

    static func addAccount(context: UIViewController, register: Bool) {
        try! AccountController.challengeWithAllScopes(context, register: register)
    }

    public static var canShowNSFW: Bool {
        return AccountController.isLoggedIn && SettingValues.nsfwEnabled
    }
    
    /**
     Open OAuth2 page to try to authorize with all scopes in Safari.app.
     */
    public static func challengeWithAllScopes(_ context: UIViewController, register: Bool) throws {
        do {
            try self.challengeWithScopes(["account", "identity", "edit", "flair", "history", "modconfig", "modflair", "modlog", "modposts", "modwiki", "mysubreddits", "privatemessages", "read", "report", "save", "submit", "subscribe", "vote", "wikiedit", "wikiread"], context, register: register)
        } catch {
            throw error
        }
    }
    
    /**
     Open OAuth2 page to try to authorize with user specified scopes in Safari.app.
     
     - parameter scopes: Scope you want to get authorizing. You can check all scopes at https://www.reddit.com/dev/api/oauth.
     */
    public static func challengeWithScopes(_ scopes: [String], _ context: UIViewController, register: Bool) throws {
        let commaSeparatedScopeString = scopes.joined(separator: ",")
        
        let length = 64
        let mutableData = NSMutableData(length: Int(length))
        if let data = mutableData {
            let a = OpaquePointer(data.mutableBytes)
            let ptr = UnsafeMutablePointer<UInt8>(a)
            _ = SecRandomCopyBytes(kSecRandomDefault, length, ptr)
            OAuth2Authorizer.sharedInstance.state = data.base64EncodedString(options: .endLineWithLineFeed)
            guard let authorizationURL = URL(string: "https://www.reddit.com/api/v1/authorize.compact?client_id=" + Config.sharedInstance.clientID + "&response_type=code&state=" + OAuth2Authorizer.sharedInstance.state + "&redirect_uri=" + Config.sharedInstance.redirectURI + "&duration=permanent&scope=" + commaSeparatedScopeString)
                else { throw ReddiftError.canNotCreateURLRequestForOAuth2Page as NSError }
            let vc: UIViewController
            let web = WebsiteViewController(url: authorizationURL, subreddit: "")
            web.isLoginFlow = true
            web.reloadCallback = {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                    AccountController.addAccount(context: context, register: false)
                }
            }
            web.register = register
            vc = web
            VCPresenter.showVC(viewController: vc, popupIfPossible: false, parentNavigationController: nil, parentViewController: context)
        } else {
            throw ReddiftError.canNotAllocateDataToCreateURLForOAuth2 as NSError
        }
    }

    static func doModOf() {
        DispatchQueue.main.async {
            let session = (UIApplication.shared.delegate as! AppDelegate).session!
            getSubscriptionsFully(session: session) { (subs: [Subreddit]) in
                for sub in subs {
                    modSubs.append(sub.displayName)
                }
            }
        }
    }
    
    public static func formatUsername(input: String, small: Bool) -> String {
        if SettingValues.nameScrubbing && input == AccountController.currentName {
            return "you"
        } else {
            if small {
                return input
            }
            return "u/\(input)"
        }
    }
    
    public static func isMigrated(_ name: String) -> Bool {
        return UserDefaults.standard.data(forKey: "AUTH+\(name)") != nil
    }
    
    public static func formatUsernamePosessive(input: String, small: Bool) -> String {
        if SettingValues.nameScrubbing && input == AccountController.currentName {
            return "Your"
        } else {
            if small {
                return input
            }
            return "u/\(input)'s"
        }
    }

    public static func getSubscriptionsUntilCompletion(session: Session, p: Paginator, tR: [Subreddit], completion: @escaping (_ result: [Subreddit]) -> Void) {
        var toReturn = tR
        var paginator = p
        do {
            try session.getUserRelatedSubreddit(.moderator, paginator: paginator, completion: { (result) -> Void in
                switch result {
                case .failure:
                    slideLog(result.error!.localizedDescription)
                    completion(toReturn)
                case .success(let listing):
                    toReturn += listing.children.compactMap({ $0 as? Subreddit })
                    paginator = listing.paginator
                    if paginator.hasMore() {
                        getSubscriptionsUntilCompletion(session: session, p: paginator, tR: toReturn, completion: completion)
                    } else {
                        for sub in toReturn {
                            Subscriptions.subIcons[sub.displayName.lowercased()] = sub.iconImg == "" ? sub.communityIcon : sub.iconImg
                            if sub.keyColor.hexString().lowercased() != "#ffffff" && sub.keyColor.hexString() != "#000000" {
                                Subscriptions.subColors[sub.displayName.lowercased()] = sub.keyColor
                            }
                        }

                        completion(toReturn)
                    }
                }
            })
        } catch {
            completion(toReturn)
        }

    }

    public static func getSubscriptionsFully(session: Session, completion: @escaping (_ result: [Subreddit]) -> Void) {
        let toReturn: [Subreddit] = []
        let paginator = Paginator()
        getSubscriptionsUntilCompletion(session: session, p: paginator, tR: toReturn, completion: completion)
    }

}
extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: [Iterator.Element: Bool] = [:]
        return self.filter { seen.updateValue(true, forKey: $0) == nil }
    }
}

extension Notification.Name {
    static let onRequireLogin = Notification.Name("on-require-login")
    static let onAccountChanged = Notification.Name("on-account-changed")
    static let onAccountMailCountChanged = Notification.Name("on-account-mail-count-changed")
    static let accountRefreshRequested = Notification.Name("account-refresh-requested")
    static let onThemeChanged = Notification.Name("theme-change-requested")
}
