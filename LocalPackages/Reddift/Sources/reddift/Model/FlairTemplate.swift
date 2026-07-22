//
//  FlairTemplate.swift
//  reddift-iOS
//
//  Created by Carlos Crane on 5/19/18.
//  Copyright © 2018 sonson. All rights reserved.
//
import Foundation

/**
 FlairTemplate object
 */
public struct FlairTemplate: Thing {
    /// identifier of Thing like 15bfi0.
    public let id: String
    public let name: String
    public static let kind = ""
    
    public init(id: String){
        self.id = id
        name = ""
        cssClass = ""
        editable = false
        text = ""
    }
    
    public let cssClass: String
    
    /// Flair data
    public let editable: Bool
    public let text: String
    
    public init(json: JSONDictionary) {
        id = json["flair_template_id"] as? String ?? ""
        cssClass = json["flair_css_class"] as? String ?? ""
        editable = json["flair_text_editable"] as? Bool ?? false
        text = json["flair_text"] as? String ?? ""
        name = cssClass
    }
}
