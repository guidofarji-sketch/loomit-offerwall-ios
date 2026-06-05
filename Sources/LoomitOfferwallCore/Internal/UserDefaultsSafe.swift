//
//  UserDefaultsSafe.swift
//  LoomitOfferwallCore
//
//  Thread-safe wrapper for UserDefaults.
//  UserDefaults internally uses CFPrefsSearchListSource which is not thread-safe.
//  This wrapper uses a serial DispatchQueue to guarantee all operations happen sequentially.
//

import Foundation

/// Thread-safe wrapper for UserDefaults.
/// All read/write operations are serialized on a dedicated queue.
public final class UserDefaultsSafe {

    private let defaults: UserDefaults
    private let queue = DispatchQueue(label: "com.loomit.offerwall.userdefaults", qos: .userInitiated)

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - String

    public func string(forKey key: String) -> String? {
        queue.sync { defaults.string(forKey: key) }
    }

    public func set(_ value: String?, forKey key: String) {
        queue.sync { defaults.set(value, forKey: key) }
    }

    // MARK: - Data

    public func data(forKey key: String) -> Data? {
        queue.sync { defaults.data(forKey: key) }
    }

    public func set(_ value: Data?, forKey key: String) {
        queue.sync { defaults.set(value, forKey: key) }
    }

    // MARK: - Dictionary

    public func dictionary(forKey key: String) -> [String: Any]? {
        queue.sync { defaults.dictionary(forKey: key) }
    }

    // MARK: - Remove

    public func removeObject(forKey key: String) {
        queue.sync { defaults.removeObject(forKey: key) }
    }
}
