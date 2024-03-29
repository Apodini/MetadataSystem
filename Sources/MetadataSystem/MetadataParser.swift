//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import ApodiniContext

/// An instance of this protocol is used to visit a ``AnyMetadata`` tree.
public protocol MetadataParser {
    /// Adds a new context value to the current context of the ``MetadataParser``.
    ///
    /// Call this function every time you need to register a new context value for a `ContextKey` that need to be available
    /// for all subsequent `Handlers` registered in the current `Component` subtree of the Apodini DSL.
    /// - Parameters:
    ///   - contextKey: The key of the context value
    ///   - value: The value that is associated to the `ContextKey`
    ///   - scope: The scope of the context value as defined by the `Scope` enum
    func addContext<C: OptionalContextKey>(_ contextKey: C.Type, value: C.Value, scope: Scope)

    /// Called to visit a ``MetadataDefinition``.
    func visit<Definition: MetadataDefinition>(definition: Definition)

    /// Called to visit an ``AnyMetadataBlock``.
    func visit<Block: AnyMetadataBlock>(block: Block)

    /// Called to visit a ``RestrictedMetadataBlock``.
    func visit<Block: RestrictedMetadataBlock>(restrictedBlock: Block)

    /// Called to visit an ``EmptyMetadata``.
    func visit<Empty: EmptyMetadata>(empty: Empty)

    /// Called to visit an ``AnyMetadataArray``.
    func visit<Array: AnyMetadataArray>(array: Array)

    /// Called to visit a ``WrappedMetadataDefinition``.
    func visit<Wrapped: WrappedMetadataDefinition>(wrapped: Wrapped)
}

public extension MetadataParser {
    /// The default implementation calls ``addContent(contextKey:value:scope:)``
    /// to add the value for the corresponding key to the `ContextNode`.
    func visit<Definition: MetadataDefinition>(definition: Definition) {
        self.addContext(Definition.Key.self, value: definition.value, scope: Definition.scope)
    }

    /// The default implementation visits the content of the ``AnyMetadataBlock``.
    func visit<Block: AnyMetadataBlock>(block: Block) {
        block.typeErasedContent.collectMetadata(self)
    }

    /// The default implementation forwards the call to ``visit(block:)`.
    func visit<Block: RestrictedMetadataBlock>(restrictedBlock: Block) {
        visit(block: restrictedBlock)
    }

    /// The default implementation is empty.
    func visit<Empty: EmptyMetadata>(empty: Empty) {}

    /// The default implementation visits every entry in the ``AnyMetadataArray``.
    func visit<Array: AnyMetadataArray>(array: Array) {
        for element in array.array {
            (element as! AnyMetadata).collectMetadata(self) // swiftlint:disable:this force_cast
        }
    }

    /// THe default implementation visits the wrapped metadata of the ``WrappedMetadataDefinition``.
    func visit<Wrapped: WrappedMetadataDefinition>(wrapped: Wrapped) {
        wrapped.metadata.collectMetadata(self)
    }
}


extension MetadataParser {
    // swiftlint:disable:next identifier_name
    func _visit<Definition: MetadataDefinition>(definition: Definition) {
        if let emptyBlock = definition as? any EmptyMetadata {
            emptyBlock._accept(parser: self)
        } else {
            self.visit(definition: definition)
        }
    }

    // swiftlint:disable:next identifier_name
    func _visit<Block: AnyMetadataBlock>(block: Block) {
        if let restrictedBlock = block as? any RestrictedMetadataBlock {
            restrictedBlock._accept(parser: self)
        } else {
            self.visit(block: block)
        }
    }
}


public struct StandardMetadataParser: MetadataParser {
    let context = ContextNode()

    public init() {}

    public func addContext<C: OptionalContextKey>(_ contextKey: C.Type, value: C.Value, scope: Scope) {
        context.addContext(contextKey, value: value, scope: scope)
    }

    public func exportContext() -> Context {
        context.export()
    }
}


extension RestrictedMetadataBlock {
    fileprivate func _accept(parser: MetadataParser) {
        parser.visit(restrictedBlock: self)
    }
}


extension EmptyMetadata {
    fileprivate func _accept(parser: MetadataParser) {
        parser.visit(empty: self)
    }
}
