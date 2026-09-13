//
//  UIColor+Extensions.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 8/9/18, though he may not wish to take credit for this.
//  Copyright Jon. I spent too long on this. MIT License.
//

import Foundation

/*
 ██████╗  █████╗ ███╗   ██╗ ██████╗ ███████╗██████╗     ███████╗ ██████╗ ███╗   ██╗███████╗
 ██╔══██╗██╔══██╗████╗  ██║██╔════╝ ██╔════╝██╔══██╗    ╚══███╔╝██╔═══██╗████╗  ██║██╔════╝
 ██║  ██║███████║██╔██╗ ██║██║  ███╗█████╗  ██████╔╝      ███╔╝ ██║   ██║██╔██╗ ██║█████╗
 ██║  ██║██╔══██║██║╚██╗██║██║   ██║██╔══╝  ██╔══██╗     ███╔╝  ██║   ██║██║╚██╗██║██╔══╝
 ██████╔╝██║  ██║██║ ╚████║╚██████╔╝███████╗██║  ██║    ███████╗╚██████╔╝██║ ╚████║███████╗
 ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝    ╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝
 */

public extension UIColor {

    private struct StaticVars {
        static let randomColorBlock: @convention(block) (AnyObject?) -> CGColor = { (_: AnyObject?) -> (CGColor) in
            return CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [
                CGFloat.random(in: 0...1), // R
                CGFloat.random(in: 0...1), // G
                CGFloat.random(in: 0...1), // B
                1.0, // A
                ])!
        }
    }
    
    func hsbaComponents() -> (hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat) {
        var h: CGFloat = 0.0
        var s: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 0.0
        
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return (hue: h, saturation: s, brightness: b, alpha: a)
    }

    private static let rzl_swizzleImplementation: Void = {

        var classCount = objc_getClassList(nil, 0)
        var allClasses = UnsafeMutablePointer<AnyClass?>.allocate(capacity: Int(classCount))
        var autoreleasingAllClasses = AutoreleasingUnsafeMutablePointer<AnyClass>(allClasses)
        classCount = objc_getClassList(autoreleasingAllClasses, classCount)

        var modifiedClassCount = 0

        for i in 0 ..< classCount {
            if let currentClass: AnyClass = allClasses[Int(i)] {
                let _super: AnyClass? = class_getSuperclass(currentClass)
                let _supersuper: AnyClass? = class_getSuperclass(_super)
                if currentClass == UIColor.self || _super == UIColor.self || _supersuper == UIColor.self {
                    if let originalMethod = class_getInstanceMethod(currentClass.self, #selector(getter: cgColor)) {
//                        slideLog(String(describing: currentClass), currentClass)
                        method_setImplementation(originalMethod, imp_implementationWithBlock(unsafeBitCast(StaticVars.randomColorBlock, to: AnyObject.self)))
                        modifiedClassCount += 1
                    }
                }
            }
        }

        slideLog("Swizzled UIColor class derivatives: \(modifiedClassCount)")

    }()

    /**
     Swaps all UIColor.cgColor getter calls for a function block that returns a random color. This has the
     effect of randomizing all UIColors every time their getter is called.
     */
    static func 💀() {
        _ = self.rzl_swizzleImplementation
    }
    
    var redValue: CGFloat {
        if cgColor.components != nil && cgColor.components!.count >= 1 {
            return cgColor.components! [0]
        }
        return 0
    }
    
    var greenValue: CGFloat {
        if cgColor.components != nil && cgColor.components!.count >= 2 {
            return cgColor.components! [1]
        }
        return 0
    }
    
    var blueValue: CGFloat {
        if cgColor.components != nil && cgColor.components!.count >= 3 {
            return cgColor.components! [2]
        }
        return 0
    }
    
    var alphaValue: CGFloat {
        if cgColor.components != nil && cgColor.components!.count >= 4 {
            return cgColor.components! [3]
        }
        return 0
    }
}
