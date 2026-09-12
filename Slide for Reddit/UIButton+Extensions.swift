//
//  UIButton+Extensions.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 7/6/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit

private let minimumHitArea = CGSize(width: 100, height: 100)
// https://stackoverflow.com/a/50127204/3697225
extension UIButton {
    /// Padding between the button's bounds and its content.
    ///
    /// Wraps `contentEdgeInsets`, deprecated in iOS 15 in favour of
    /// `UIButton.Configuration.contentInsets`. No button in this app sets a
    /// `configuration`, so the property still applies exactly as it always has — the
    /// deprecation is a migration notice, not a behaviour change.
    ///
    /// Call sites funnel through here so the migration in #13 is one function to rewrite
    /// rather than 27 call sites to find. Note the trade: the compiler no longer flags
    /// those call sites, so if a button is ever given a `configuration`, this padding
    /// will be silently ignored on it.
    func setContentPadding(_ insets: UIEdgeInsets) {
        contentEdgeInsets = insets
    }

    func leftImage(image: UIImage, renderMode: UIImage.RenderingMode) {
        self.setImage(image.withRenderingMode(renderMode), for: .normal)
        self.imageEdgeInsets = UIEdgeInsets(top: 0, left: image.size.width / 2, bottom: 0, right: image.size.width / 2)
        self.contentHorizontalAlignment = .left
        self.imageView?.contentMode = .scaleAspectFit
    }

    func rightImage(image: UIImage, renderMode: UIImage.RenderingMode) {
        self.setImage(image.withRenderingMode(renderMode), for: .normal)
        self.imageEdgeInsets = UIEdgeInsets(top: 0, left: image.size.width / 2, bottom: 0, right: 0)
        self.contentHorizontalAlignment = .right
        self.imageView?.contentMode = .scaleAspectFit
    }
    
    convenience init(buttonImage: UIImage?, toolbar: Bool = false) { // TODO accessibility here too
        self.init(type: .custom)
        if toolbar {
            self.setImage(buttonImage?.navIcon(), for: UIControl.State.normal)
            self.frame = CGRect.init(x: 0, y: 0, width: 44, height: 44)
        } else {
            self.setImage(buttonImage?.toolbarIcon(), for: UIControl.State.normal)
            self.frame = CGRect.init(x: 0, y: 0, width: 30, height: 44)
        }
        self.imageView?.contentMode = .center
    }
}
extension UIBarButtonItem {
    func addTargetForAction(target: AnyObject, action: Selector) {
        self.target = target
        self.action = action
    }
}
