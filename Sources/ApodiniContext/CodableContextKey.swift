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

    static func anyEncode(value: Any) throws -> String
}

/// An ``OptionalContextKey`` which value is able to be encoded and decoded.
public protocol CodableContextKey: AnyCodableContextKey, OptionalContextKey where Value: Codable {
    static func decode(from base64String: String) throws -> Value
}

private let encoder = JSONEncoder()
private let decoder = JSONDecoder()

extension CodableContextKey {
    public static var identifier: String {
        "\(Self.self)"
    }

    public static func anyEncode(value: Any) throws -> String {
        guard let value = value as? Self.Value else {
            fatalError("CodableContextKey.anyEncode(value:) received illegal value type \(type(of: value)) instead of \(Value.self)")
        }

        return try encoder
            .encode(value)
            .base64EncodedString()
    }

    public static func decode(from base64String: String) throws -> Value {
        guard let data = Data(base64Encoded: base64String) else {
            fatalError("Failed to unwrap bas64 encoded data string: \(base64String)")
        }

        return try decoder.decode(Value.self, from: data)
    }
}
