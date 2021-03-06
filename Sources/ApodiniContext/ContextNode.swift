//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation

/// A `ContextNode` stores all captured `OptionalContextKey` values within the parsing process of the Syntax Tree.
/// Every parsed Component has a dedicated `ContextNode` instance, potentially inheriting context values from
/// `ContextNode`s of the parent component tree level.
///
/// As Modifiers are parsed in reverse order (the outermost Modifier wraps the innermost Modifiers)
/// and therefore the `ContextNode` needs to adjust for that ordering.
/// Nonetheless, adding multiple values of the same `OptionalContextKey` inside a Modifier must maintain proper ordering.
/// Further, depending on the `OptionalContextKey`, context values should be inherited from the parent `ContextNode`.
///
/// Below are some examples demonstrating the parsing order vs expected ordering of the captured values:
///
/// Modifier Ordering:
/// ```swift
/// Component()
///     .modifier(1) // parsed second
///     .modifier(2) // parsed first
///
/// // result order should be: 1, 2
/// ```
///
/// Inheritance:
/// ```swift
/// Group {
///     Component1() // expected value is: 2
///         .modifier(2)
///     Component2() // expected value is: 1
/// }.modifier(1)
/// ```
///
/// Complex Example with Metadata:
/// ```swift
/// struct TestHandler: Handler {
///     // ...
///     var metadata: Metadata {
///         Example(1)
///         Example(2)
///     }
/// }
///
/// TestHandler()
///     .metadata(Example(3))
///     .metadata {
///         Example(4)
///         Example(5)
///     }
///
/// // expected order is: 1, 2, 3, 4, 5
/// ```
public class ContextNode {
    /// Holds the parent `ContextNode` if it's not the root `ContextNode`.
    public let parentContextNode: ContextNode?

    /// The current working set of `AnyContextEntry`s belonging to the currently parsed `Component`.
    /// Once a `Component` has fully been parsed, entries of the `currentWorkingSet` are stored
    /// inside the `storedEntries` by calling `storeCurrentWorkingSet()`.
    private var currentWorkingSet: [ObjectIdentifier: AnyContextEntry] = [:]
    private var storedEntries: [ObjectIdentifier: AnyContextEntryCollection] = [:]

    /// Defines if we are currently in the process of parsing a Modifier.
    private var parsingModifier = false

    /// Caches the result of `exportEntries()` optimizing multiple executions.
    private var exportedEntries: [ObjectIdentifier: AnyContextEntry]? // swiftlint:disable:this discouraged_optional_collection

    /// Initializes a new ``ContextNode`` optionally referencing a parent ``ContextNode``.
    public init(parent: ContextNode? = nil) {
        parentContextNode = parent
    }

    /// Marks the beginning of a working-set for the ``ContextNode``.
    /// In general, for every parsed Component we create a working set. Working sets are a abstraction
    /// to be able to handle ordering of context values added thorough modifier.
    /// - Parameter isModifier: Defines if the current component is a modifier.
    public func markContextWorkSetBegin(isModifier: Bool = false) {
        storeCurrentWorkingSet()

        parsingModifier = isModifier
    }

    /// Adds a new value to the ``ContextNode``.
    public func addContext<C: OptionalContextKey>(_ contextKey: C.Type = C.self, value: C.Value, scope: Scope) {
        precondition(exportedEntries == nil, "Tried adding additional context values on a ContextNode which was already exported!")

        guard !(C.Value.self is SomeOptional.Type) else {
            fatalError(
                """
                The `Value` type of a `ContextKey` or `OptionalContextKey` must not be a `Optional` type.
                Found \(C.Value.self) as `Value` type for key \(C.self).
                """
            )
        }

        let id = ObjectIdentifier(contextKey)

        if let entry = currentWorkingSet[id] {
            entry.add(value: value, in: scope)
        } else {
            currentWorkingSet[id] = ContextEntry<C>(value: value, scope: scope)
        }
    }

    private func storeCurrentWorkingSet() {
        for (key, value) in currentWorkingSet {
            if let collection = storedEntries[key] {
                collection.add(entry: value, derivedFromModifier: parsingModifier)
            } else {
                storedEntries[key] = value.deriveCollection(entry: value, derivedFromModifier: parsingModifier)
            }
        }

        currentWorkingSet.removeAll()

        parsingModifier = false
    }

    private func exportEntries() -> [ObjectIdentifier: AnyContextEntry] {
        if let exported = exportedEntries {
            return exported
        }

        var entries: [ObjectIdentifier: AnyContextEntry] = [:]

        for (key, collection) in storedEntries {
            entries[key] = collection.joined()
        }

        if let parentEntries = parentContextNode?.exportEntries() {
            for (key, entry) in parentEntries {
                if let existing = entries[key] {
                    entries[key] = entry.join(with: existing, filterForLocalScope: true)
                } else if let filteredEntry = entry.filterLocalValues() {
                    entries[key] = filteredEntry
                }
            }
        }

        exportedEntries = entries

        return entries
    }

    private func peekExportEntry<C: OptionalContextKey>(for contextKey: C.Type = C.self) -> AnyContextEntry? {
        let id = ObjectIdentifier(contextKey)

        var storedEntries = self.storedEntries[id]?.copy()

        for (key, value) in currentWorkingSet where key == id {
            if let storedEntries = storedEntries {
                storedEntries.add(entry: value, derivedFromModifier: parsingModifier)
            } else {
                storedEntries = value.deriveCollection(entry: value, derivedFromModifier: parsingModifier)
            }
        }

        return [
            parentContextNode?.peekExportEntry(for: contextKey)?.filterLocalValues(),
            storedEntries?.joined()
        ]
            .compactMap { $0 }
            .reduceIntoFirst { first, entry in
                first.join(with: entry, filterForLocalScope: false)
            }
    }

    /// Exports the ``ContextNode``, creating a ``Context`` instance which preserves the contents of this node.
    public func export() -> Context {
        storeCurrentWorkingSet()

        let entries = exportEntries()
            .compactMapValues { entry in
                entry.reduce()
            }

        return Context(entries)
    }

    /// Creates new new child ``ContextNode``.
    public func newContextNode() -> ContextNode {
        markContextWorkSetBegin()

        return ContextNode(parent: self)
    }

    /// Peeks a value of the ``ContextNode``. In general value can only be retrieved once
    /// the ``ContextNode`` was exported into a ``Context``. This guarantees that the value is only
    /// retrieved when everything was fully parsed.
    /// `peekValue` doesn't guarantee that. The value might change after the call as parsing continues.
    public func peekValue<C: ContextKey>(for contextKey: C.Type = C.self) -> C.Value {
        peekExportEntry(for: contextKey)?.reduce().value as? C.Value
            ?? C.defaultValue
    }

    /// Peeks a value of the ``ContextNode``. In general value can only be retrieved once
    /// the ``ContextNode`` was exported into a ``Context``. This guarantees that the value is only
    /// retrieved when everything was fully parsed.
    /// `peekValue` doesn't guarantee that. The value might change after the call as parsing continues.
    public func peekValue<C: OptionalContextKey>(for contextKey: C.Type = C.self) -> C.Value? {
        peekExportEntry(for: contextKey)?.reduce().value as? C.Value
    }
}

private protocol SomeOptional {}

extension Optional: SomeOptional {}

private extension Collection {
    /// Reduces the collection using the specified closure, using the first element as the initial value
    func reduceIntoFirst(_ transform: (Element, Element) throws -> Element) rethrows -> Element? {
        guard let first = self.first else {
            return nil
        }
        return try dropFirst().reduce(first, transform)
    }
}
