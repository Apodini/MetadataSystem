//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

/// Some instance which can be used to retrieve values of a ``OptionalContextKey`` or a ``ContextKey``.
public protocol ContextKeyRetrievable {
    /// Retrieves the value for a given `ContextKey`.
    /// - Parameter contextKey: The `ContextKey` to retrieve the value for.
    /// - Returns: Returns the stored value or the `ContextKey.defaultValue` if it does not exist on the given `Context`.
    func get<C: ContextKey>(valueFor contextKey: C.Type) -> C.Value

    /// Retrieves the value for a given `OptionalContextKey`.
    /// - Parameter contextKey: The `OptionalContextKey` to retrieve the value for.
    /// - Returns: Returns the stored value or `nil` if it does not exist on the given `Context`.
    func get<C: OptionalContextKey>(valueFor contextKey: C.Type) -> C.Value?
}
