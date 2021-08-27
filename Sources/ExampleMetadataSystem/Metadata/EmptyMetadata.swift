//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import MetadataSystem

public extension ExampleMetadataNamespace {
    /// Name definition for the ``EmptyExampleMetadata``.
    typealias Empty = EmptyExampleMetadata
}

public struct EmptyExampleMetadata: EmptyMetadata, ExampleMetadataDefinition {
    public init() {}
}
