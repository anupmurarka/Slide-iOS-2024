//
//  Slide_for_RedditTests.swift
//  Slide for RedditTests
//
//  Created by Carlos Crane on 12/22/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

@testable import Slide_for_Reddit
import UIKit
import XCTest

class Slide_for_RedditTests: XCTestCase {

    private let suiteName = "Slide_for_RedditTests.ColorUtil"

    override func tearDown() {
        UserDefaults().removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    /// `colorForKey` was migrated off the deprecated `NSKeyedUnarchiver.unarchiveObject(with:)`.
    /// Existing users' theme colours were written by the pre-iOS-12
    /// `archivedData(withRootObject:)`, which produces a *non*-secure-coding archive, so
    /// this asserts the replacement still decodes that older format rather than silently
    /// returning nil and resetting everyone's custom theme.
    func testColorForKeyDecodesLegacyNonSecureArchive() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        let original = UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0)

        // Byte-for-byte what `NSKeyedArchiver.archivedData(withRootObject:)` produced.
        let archiver = NSKeyedArchiver(requiringSecureCoding: false)
        archiver.encode(original, forKey: NSKeyedArchiveRootObjectKey)
        archiver.finishEncoding()
        defaults.set(archiver.encodedData, forKey: "legacycolor")

        let decoded = try XCTUnwrap(defaults.colorForKey(key: "legacycolor"),
                                    "legacy non-secure colour archive failed to decode")

        var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        original.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        decoded.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        XCTAssertEqual(r1, r2, accuracy: 0.001)
        XCTAssertEqual(g1, g2, accuracy: 0.001)
        XCTAssertEqual(b1, b2, accuracy: 0.001)
        XCTAssertEqual(a1, a2, accuracy: 0.001)
    }

    /// Round-trips through the new writer as well, so a colour saved after the migration
    /// reads back correctly.
    func testSetColorRoundTrips() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        let original = UIColor(red: 0.9, green: 0.1, blue: 0.35, alpha: 0.8)

        defaults.setColor(color: original, forKey: "roundtrip")
        let decoded = try XCTUnwrap(defaults.colorForKey(key: "roundtrip"))

        var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        original.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        decoded.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        XCTAssertEqual(r1, r2, accuracy: 0.001)
        XCTAssertEqual(g1, g2, accuracy: 0.001)
        XCTAssertEqual(b1, b2, accuracy: 0.001)
        XCTAssertEqual(a1, a2, accuracy: 0.001)
    }

    /// Nothing stored for the key must stay nil rather than throwing.
    func testColorForKeyReturnsNilForMissingKey() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        XCTAssertNil(defaults.colorForKey(key: "nothing-here"))
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
