//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

private class ContextBox {
    var entries: [ObjectIdentifier: StoredContextValue]

    init(_ entries: [ObjectIdentifier: StoredContextValue]) {
        self.entries = entries
    }
}

struct StoredContextValue {
    let key: AnyContextKey.Type
    let value: Any
}

/// Defines some sort of `Context` for a given representation (like `Endpoint`).
/// A `Context` holds a collection of values for predefined `ContextKey`s or `OptionalContextKey`s.
public struct Context: ContextKeyRetrievable {
    private var boxedEntries: ContextBox
    private var entries: [ObjectIdentifier: StoredContextValue] {
        boxedEntries.entries
    }
    private let decodedEntries: [String: Data]

    init(_ entries: [ObjectIdentifier: StoredContextValue] = [:], _ decodedEntries: [String: Data] = [:]) {
        self.boxedEntries = ContextBox(entries)
        self.decodedEntries = decodedEntries
    }

    /// Create a new empty ``Context``.
    public init() {
        self.init([:])
    }

    /// Creates a new ``Context`` by copying the contents of the provided ``Context``.
    public init(copying context: Context) {
        self.init(context.entries, context.decodedEntries)
    }

    /// Retrieves the value for a given `ContextKey`.
    /// - Parameter contextKey: The `ContextKey` to retrieve the value for.
    /// - Returns: Returns the stored value or the `ContextKey.defaultValue` if it does not exist on the given `Context`.
    public func get<C: ContextKey>(valueFor contextKey: C.Type = C.self) -> C.Value {
        entries[ObjectIdentifier(contextKey)]?.value as? C.Value
            ?? C.defaultValue
    }

    /// Retrieves the value for a given `OptionalContextKey`.
    /// - Parameter contextKey: The `OptionalContextKey` to retrieve the value for.
    /// - Returns: Returns the stored value or `nil` if it does not exist on the given `Context`.
    public func get<C: OptionalContextKey>(valueFor contextKey: C.Type = C.self) -> C.Value? {
        entries[ObjectIdentifier(contextKey)]?.value as? C.Value
    }

    /// Retrieves the value for a given `CodableContextKey`.
    /// - Parameter contextKey: The `OptionalContextKey` to retrieve the value for.
    /// - Returns: Returns the stored value or `nil` if it does not exist on the given `Context`.
    public func get<C: CodableContextKey>(valueFor contextKey: C.Type = C.self) -> C.Value? {
        entries[ObjectIdentifier(contextKey)]?.value as? C.Value
            ?? checkForDecodedEntries(for: contextKey)
    }

    /// Retrieves the value for a given `ContextKey & CodableContextKey`.
    /// - Parameter contextKey: The `ContextKey` to retrieve the value for.
    /// - Returns: Returns the stored value or the `ContextKey.defaultValue` if it does not exist on the given `Context`.
    public func get<C: ContextKey & CodableContextKey>(valueFor contextKey: C.Type = C.self) -> C.Value {
        entries[ObjectIdentifier(contextKey)]?.value as? C.Value
            ?? checkForDecodedEntries(for: contextKey)
            ?? C.defaultValue
    }

    /// This method can be used to unsafely add new entries to a constructed ``Context``.
    /// This method is considered unsafe as it changes the ``Context`` which is normally considered non-mutable.
    /// Try to not used this method!
    ///
    /// Note: This method does NOT reduce multiple values for the same key. You cannot add a value
    /// if there is already a value for the given context key!
    ///
    /// - Parameters:
    ///   - contextKey: The context to add value for.
    ///   - value: The value to add.
    public func unsafeAdd<C: OptionalContextKey>(_ contextKey: C.Type = C.self, value: C.Value) {
        let key = ObjectIdentifier(contextKey)

        precondition(entries[key] == nil, "Cannot overwrite existing ContextKey entry with `unsafeAdd`: \(C.self): \(value)")
        if let codableContextKey = contextKey as? AnyCodableContextKey.Type {
            // we need to prevent this. as Otherwise we would need to handle merging this stuff which get really complex
            precondition(decodedEntries[codableContextKey.identifier] == nil, "Cannot overwrite existing CodableContextKey entry with `unsafeAdd`: \(C.self): \(value)")
        }

        boxedEntries.entries[key] = StoredContextValue(key: contextKey, value: value)
    }

    private func checkForDecodedEntries<Key: CodableContextKey>(for key: Key.Type = Key.self) -> Key.Value? {
        guard let dataValue = decodedEntries[Key.identifier] else {
            return nil
        }

        do {
            return try Key.decode(from: dataValue)
        } catch {
            fatalError("Error occurred when trying to decode `CodableContextKey` `\(Key.self)` with stored value '\(dataValue)': \(error)")
        }
    }
}

extension Context: CustomStringConvertible {
    public var description: String {
        "Context(entries: \(entries))"
    }
}

// MARK: LazyCodable
extension Context: Codable {
    private struct StringContextKey: CodingKey {
        let stringValue: String
        let intValue: Int? = nil

        init(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue: Int) {
            nil
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringContextKey.self)

        self.boxedEntries = ContextBox([:])

        var decodedEntries: [String: Data] = [:]

        for key in container.allKeys {
            decodedEntries[key.stringValue] = try container.decode(Data.self, forKey: key)
        }

        self.decodedEntries = decodedEntries
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringContextKey.self)

        var entries: [String: Data] = [:]

        for storedValue in self.entries.values {
            guard let contextKey = storedValue.key as? AnyCodableContextKey.Type else {
                continue
            }

            entries[contextKey.identifier] = try contextKey.anyEncode(value: storedValue.value)
        }

        entries.merge(self.decodedEntries) { current, new in
            fatalError("Encountered context value conflicts of \(current) and \(new)!")
        }

        for (key, data) in entries {
            try container.encode(data, forKey: StringContextKey(stringValue: key))
        }
    }
}
