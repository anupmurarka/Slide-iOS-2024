//
//  ModAction.swift
//  reddift
//
//  Created by Carlos Crane on 11/17/20.
//

import Foundation

/**
ModAction object.
*/
public struct ModAction: Thing {
    public var name: String
    
    /// identifier of Thing like 15bfi0.
    public let id: String
    /// type of Thing, like t3.
    public static let kind = "modaction"
    
    public let targetBody: String
    public let createdUtc: Double
    public let subreddit: String
    public let targetTitle: String
    public let targetPermalink: String
    public let details: String
    public let action: String
    public let targetAuthor: String
    public let targetFullname: String
    public let mod: String
    
    public init(id: String) {
        self.id = id
        self.name = "\(ModAction.kind)_\(self.id)"
        self.targetBody = ""
        self.createdUtc = 0
        self.subreddit = ""
        self.targetTitle = ""
        self.targetPermalink = ""
        self.details = ""
        self.action = ""
        self.targetAuthor = ""
        self.targetFullname = ""
        self.mod = ""
    }
    
    /**
    Parse more object.
    
    - parameter data: Dictionary, must be generated parsing "more".
    - returns: More object as Thing.
    */
    public init(json data: JSONDictionary) {
        id = data["id"] as? String ?? ""
        name = data["mod_id36"] as? String ?? ""
        targetBody = data["target_body"] as? String ?? ""
        createdUtc = data["created_utc"] as? Double ?? 0
        subreddit = data["subreddit"] as? String ?? ""
        targetTitle = data["target_title"] as? String ?? ""
        targetPermalink = data["target_permalink"] as? String ?? ""
        details = data["details"] as? String ?? ""
        action = data["action"] as? String ?? ""
        targetAuthor = data["target_author"] as? String ?? ""
        targetFullname = data["target_fullname"] as? String ?? ""
        mod = data["mod"] as? String ?? ""
    }
    
    public var isEmpty: Bool {
        get {
            return id == "_"
        }
    }
}
