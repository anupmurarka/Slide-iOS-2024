//
//  UIColor+Distance.swift
//  MTColorDistance
//
//  Swift port of the original Objective-C `UIColor+Distance` category by
//  Quenton Jones / Mysterious Trousers (2011). Behaviour is preserved: it
//  converts colors to the CIE-L*a*b* space and returns the palette entry with
//  the smallest CIE94-style color difference. Ported during the CocoaPods
//  removal so the project no longer carries an Objective-C dependency.
//

import UIKit

public extension UIColor {

    /// Returns the color in `palette` that most closely matches the receiver.
    func closestColor(inPalette palette: [UIColor]) -> UIColor? {
        // Grayscale colors (which lack RGBA components) are unsupported, matching
        // the original implementation's `colorToLab` guard returning nil.
        guard let lab1 = colorToLab() else { return nil }

        let kL: CGFloat = 1
        let k1: CGFloat = 0.045
        let k2: CGFloat = 0.015

        var bestDifference = CGFloat.greatestFiniteMagnitude
        var bestColor: UIColor?

        let c1 = sqrt(lab1[1] * lab1[1] + lab1[2] * lab1[2])

        for color in palette {
            guard let lab2 = color.colorToLab() else { continue }
            let c2 = sqrt(lab2[1] * lab2[1] + lab2[2] * lab2[2])

            let deltaL = lab1[0] - lab2[0]
            let deltaC = c1 - c2
            let deltaA = lab1[1] - lab2[1]
            let deltaB = lab1[2] - lab2[2]
            let deltaH = sqrt(max(0, deltaA * deltaA + deltaB * deltaB - deltaC * deltaC))

            let deltaE = sqrt(pow(deltaL / kL, 2)
                              + pow(deltaC / (1 + k1 * c1), 2)
                              + pow(deltaH / (1 + k2 * c1), 2))

            if deltaE < bestDifference {
                bestColor = color
                bestDifference = deltaE
            }
        }

        return bestColor
    }

    private func colorToLab() -> [CGFloat]? {
        guard let components = cgColor.components,
              cgColor.numberOfComponents == 4 else {
            return nil
        }
        let rgb = [components[0], components[1], components[2]]
        return UIColor.xyzToLab(UIColor.rgbToXYZ(rgb))
    }

    private static func rgbToXYZ(_ rgb: [CGFloat]) -> [CGFloat] {
        var newRGB = rgb.map { component -> CGFloat in
            if component > 0.04045 {
                return pow((component + 0.055) / 1.055, 2.4)
            } else {
                return component / 12.92
            }
        }
        newRGB = newRGB.map { $0 * 100.0 }

        let x = (newRGB[0] * 0.4124) + (newRGB[1] * 0.3576) + (newRGB[2] * 0.1805)
        let y = (newRGB[0] * 0.2126) + (newRGB[1] * 0.7152) + (newRGB[2] * 0.0722)
        let z = (newRGB[0] * 0.0193) + (newRGB[1] * 0.1192) + (newRGB[2] * 0.9505)
        return [x, y, z]
    }

    private static func xyzToLab(_ xyz: [CGFloat]) -> [CGFloat] {
        let xRef: CGFloat = 95.047
        let yRef: CGFloat = 100.0
        let zRef: CGFloat = 108.883

        let normalized = [xyz[0] / xRef, xyz[1] / yRef, xyz[2] / zRef].map { component -> CGFloat in
            if component > 0.008856 {
                return pow(component, 1.0 / 3.0)
            } else {
                // The original C used integer division here (`16/116 == 0`), so the
                // added term is 0. Preserved verbatim rather than "corrected" to
                // 16.0/116.0 to keep identical output for dark colors.
                return (7.787 * component) + 0
            }
        }

        let l = (116 * normalized[1]) - 16
        let a = 500 * (normalized[0] - normalized[1])
        let b = 200 * (normalized[1] - normalized[2])
        return [l, a, b]
    }
}
