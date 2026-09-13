//
//  Cacheable.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/7/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import CoreData
import Foundation

// An object that has a CoreData representable, can save its own state
protocol Cacheable {
    func insertSelf(into context: NSManagedObjectContext, andSave: Bool) -> NSManagedObject?
}

extension NSManagedObjectContext {
    func performAndWaitReturnable<T>(_ block: () throws -> T) rethrows -> T {
        return try _performAndWaitHelper(
            fn: performAndWait, execute: block, rescue: { throw $0 }
        )
    }

    /// Helper function for convincing the type checker that
    /// the rethrows invariant holds for performAndWait.
    ///
    /// Source: https://github.com/apple/swift/blob/bb157a070ec6534e4b534456d208b03adc07704b/stdlib/public/SDK/Dispatch/Queue.swift#L228-L249
    private func _performAndWaitHelper<T>(fn: (@Sendable () -> Void) -> Void, execute work: () throws -> T, rescue: ((Error) throws -> (T))) rethrows -> T {
        // `performAndWait` runs its block synchronously and does not return until it has
        // finished, so these captures cannot actually race — but marking `fn`'s closure
        // `@Sendable` (which is what NSManagedObjectContext requires) makes the compiler
        // treat the mutations as concurrent. `nonisolated(unsafe)` states the invariant.
        nonisolated(unsafe) var result: T?
        nonisolated(unsafe) var error: Error?
        withoutActuallyEscaping(work) { _work in
            fn {
                do {
                    result = try _work()
                } catch let e {
                    error = e
                }
            }
        }
        if let e = error {
            return try rescue(e)
        } else {
            return result!
        }
    }
}
