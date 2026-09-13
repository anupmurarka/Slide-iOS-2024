//
//  UIApplication+Extensions.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 7/6/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Foundation

extension UIApplication {

    var statusBarView: UIView? {
        return statusBarUIView
    }

    /// The window scene the user is currently interacting with, falling back to any
    /// connected window scene so callers during launch or backgrounding still get one.
    var currentWindowScene: UIWindowScene? {
        let windowScenes = connectedScenes.compactMap { $0 as? UIWindowScene }
        return windowScenes.first { $0.activationState == .foregroundActive } ?? windowScenes.first
    }

    /// The interface orientation of the scene the user is currently interacting with.
    ///
    /// Replaces `statusBarOrientation`, deprecated in iOS 13: it reports a single
    /// app-wide orientation, which is not meaningful once several scenes can be on
    /// screen in different orientations on iPad and Mac. Falls back to `.unknown`,
    /// which is what `statusBarOrientation` itself returned with no windows — so
    /// comparisons behave as they did before.
    var currentInterfaceOrientation: UIInterfaceOrientation {
        currentWindowScene?.interfaceOrientation ?? .unknown
    }

    /// The key window of the scene the user is currently interacting with.
    ///
    /// Replaces `UIApplication.keyWindow`, deprecated in iOS 13 because it returns a key
    /// window across *all* connected scenes — the wrong answer for an app that supports
    /// multiple windows on iPad and Mac, where it can hand back a window belonging to a
    /// different, possibly backgrounded, scene.
    var currentKeyWindow: UIWindow? {
        if let scene = currentWindowScene, let window = scene.keyWindow ?? scene.windows.first {
            return window
        }
        // Fall back across every connected scene. Several callers force-unwrap this, so it
        // must not return nil in any case where the deprecated `keyWindow` would have
        // found a window.
        let windowScenes = connectedScenes.compactMap { $0 as? UIWindowScene }
        return windowScenes.compactMap { $0.keyWindow }.first ?? windowScenes.flatMap { $0.windows }.first
    }
    
    public func isMac() -> Bool {
        if #available(iOS 14.0, *) {
            return ProcessInfo.processInfo.isiOSAppOnMac || ProcessInfo.processInfo.isMacCatalystApp
        } else if #available(iOS 13.0, *) {
            return ProcessInfo.processInfo.isMacCatalystApp
        } else {
           return false
        }
    }
    
}
extension UIApplication {
    public var isSplitOrSlideOver: Bool {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return false
        }
        if #available(iOS 13, *) {
            guard let window = currentKeyWindow else { return false }
            return !(window.frame.width == window.screen.bounds.width)
        }
        guard let w = self.delegate?.window, let window = w else {
            return false
        }
        return !window.frame.equalTo(window.screen.bounds)
    }
    
    public var isSlideOver: Bool {
        guard let w = self.delegate?.window, let window = w else {
            return false
        }
        return window.frame.size.height != window.screen.bounds.size.height
    }
}
