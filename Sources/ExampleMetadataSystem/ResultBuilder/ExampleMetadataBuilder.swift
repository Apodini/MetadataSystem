//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import MetadataSystem

// swiftlint:disable missing_docs

@resultBuilder
public enum ExampleMetadataBuilder {}

public extension ExampleMetadataBuilder {
    static func buildExpression<Metadata: ExampleMetadataDefinition>(_ expression: Metadata) -> AnyExampleMetadata {
        WrappedExampleMetadataDefinition(expression)
    }

    static func buildExpression<Metadata: ExampleMetadataBlock>(_ expression: Metadata) -> AnyExampleMetadata {
        expression
    }

    static func buildOptional(_ component: AnyExampleMetadata?) -> AnyExampleMetadata {
        component ?? EmptyExampleMetadata()
    }

    static func buildEither(first: AnyExampleMetadata) -> AnyExampleMetadata {
        first
    }

    static func buildEither(second: AnyExampleMetadata) -> AnyExampleMetadata {
        second
    }

    static func buildArray(_ components: [AnyExampleMetadata]) -> AnyExampleMetadata {
        ExampleMetadataArray(components)
    }

    static func buildBlock(_ components: AnyExampleMetadata...) -> AnyExampleMetadata {
        ExampleMetadataArray(components)
    }
}
