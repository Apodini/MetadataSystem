//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import ApodiniContext

struct StringOptionalContextKey: OptionalContextKey {
    typealias Value = [String]
}

struct StringContextKey: ContextKey {
    typealias Value = [String]
    static var defaultValue = ["default-value"]
}

struct IntContextKey: ContextKey {
    typealias Value = Int
    static var defaultValue = 0
}
