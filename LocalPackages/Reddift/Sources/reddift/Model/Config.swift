//
//  Config.swift
//  reddift
//
//  Created by sonson on 2015/04/13.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

/**
Class to manage parameters of reddift.
This class is used as singleton model.

Values are loaded from `reddift_config.json` in the main bundle:
- `client_id`     — OAuth client ID (installed-app type, no secret)
- `redirect_uri`  — OAuth redirect URI (its scheme must be registered in Info.plist)
- `DeveloperName` — reddit username, used in the default User-Agent
- `user_agent`    — optional; when present, overrides the computed User-Agent verbatim
*/
public struct Config {
	/// Application verison, be updated by Info.plist later.
    let version: String
	/// Bundle identifier, be updated by Info.plist later.
    let bundleIdentifier: String
	/// Developer's reddit user name
    let developerName: String
	/// OAuth redirect URL you register
    public let redirectURI: String
	/// Application ID
    public let clientID: String
    /// Optional explicit User-Agent override from reddift_config.json.
    let userAgentOverride: String

    /**
    Singleton model.
    */
    public static let sharedInstance = Config()

    /**
    Returns User-Agent for API. When `user_agent` is set in reddift_config.json it is
    returned verbatim; otherwise a User-Agent is derived from the app's bundle info.
    */
    public var userAgent: String {
        if !userAgentOverride.isEmpty {
            return userAgentOverride
        }
        return "ios:" + bundleIdentifier + ":v" + version + "(by /u/" + developerName + ")"
    }

    /**
    Returns scheme of redirect URI.
    */
    public var redirectURIScheme: String {
        if let scheme = URL(string: redirectURI)?.scheme {
            return scheme
        } else {
            return ""
        }
    }

    init() {
        version =  Bundle.infoValueInMainBundle(for: "CFBundleShortVersionString") as? String ?? "1.0"
        bundleIdentifier = Bundle.infoValueInMainBundle(for: "CFBundleIdentifier") as? String ?? ""

        var _developerName: String? = nil
        var _redirectURI: String? = nil
        var _clientID: String? = nil
        var _userAgent: String? = nil
		if let path = Bundle.main.path(forResource: "reddift_config", ofType: "json") {
			if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? JSONDictionary {
                        _developerName = json["DeveloperName"] as? String
                        _redirectURI = json["redirect_uri"] as? String
                        _clientID = json["client_id"] as? String
                        _userAgent = json["user_agent"] as? String
                    }
                } catch {

                }
			}
		}

        developerName = _developerName ?? ""
        redirectURI = _redirectURI ?? ""
        clientID = _clientID ?? ""
        userAgentOverride = _userAgent ?? ""
    }
}
