//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import MetadataSystem

public struct RestrictedExampleMetadataBlock<RestrictedContent: AnyExampleMetadata>: ExampleMetadataBlock, RestrictedMetadataBlock {
    public typealias RestrictedContent = RestrictedContent

    public var metadata: AnyExampleMetadata

    public init(@RestrictedMetadataBlockBuilder<Self> metadata: () -> AnyExampleMetadata) {
        self.metadata = metadata()
    }
}
