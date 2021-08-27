//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import MetadataSystem

public protocol AnyExampleMetadataBlock: AnyMetadataBlock, AnyExampleMetadata, ExampleMetadataNamespace {}

public protocol ExampleMetadataBlock: AnyExampleMetadataBlock {
    associatedtype Metadata = AnyExampleMetadata

    @ExampleMetadataBuilder
    var metadata: Metadata { get }
}

public extension ExampleMetadataBlock {
    /// Type erased content of the metadata block.
    var typeErasedContent: AnyMetadata {
        self.metadata as! AnyMetadata // swiftlint:disable:this force_cast
    }
}


public extension ExampleMetadataNamespace {
    /// Name definition for the ``StandardExampleMetadataBlock``.
    typealias Block = StandardExampleMetadataBlock
}

public struct StandardExampleMetadataBlock: ExampleMetadataBlock {
    public let metadata: AnyExampleMetadata

    public init(@ExampleMetadataBuilder metadata: () -> AnyExampleMetadata) {
        self.metadata = metadata()
    }
}
