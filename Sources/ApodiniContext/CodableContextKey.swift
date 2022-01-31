//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2022 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// Type erased ``CodableContextKey``.
public protocol AnyCodableContextKey: AnyContextKey {
    static var identifier: String { get }

    static func anyEncode(value: Any) throws -> Data
}

/// An ``OptionalContextKey`` which value is able to be encoded and decoded.
public protocol CodableContextKey: AnyCodableContextKey, OptionalContextKey where Value: Codable {
    static func decode(from data: Data) throws -> Value
}

// Data, by default, is encoded as base64
private let encoder = JSONEncoder()
private let decoder = JSONDecoder()

extension CodableContextKey {
    public static var identifier: String {
        "\(Self.self)"
    }

    public static func anyEncode(value: Any) throws -> Data {
        guard let value = value as? Self.Value else {
            fatalError("CodableContextKey.anyEncode(value:) received illegal value type \(type(of: value)) instead of \(Value.self)")
        }

        return try encoder.encode(value)
    }

    public static func decode(from data: Data) throws -> Value {
        try decoder.decode(Value.self, from: data)
    }
}
