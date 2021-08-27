//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTest
import XCTMetadataSystem
@testable import ApodiniContext

class ContextKeyTests: XCTestCase {
    func testContextKeys() {
        let context = Context()
        XCTAssertEqual(context.get(valueFor: StringOptionalContextKey.self), nil)
        XCTAssertEqual(context.get(valueFor: StringContextKey.self), ["default-value"])
    }

    func testContextNode() {
        let nodeA = ContextNode()

        // Node A
        // working set 1
        nodeA.markContextWorkSetBegin()
        nodeA.addContext(StringContextKey.self, value: ["1"], scope: .current)
        nodeA.addContext(StringContextKey.self, value: ["2"], scope: .environment)
        
        nodeA.addContext(IntContextKey.self, value: 1, scope: .environment)
        nodeA.addContext(IntContextKey.self, value: 2, scope: .current)
        
        // working set 2
        nodeA.markContextWorkSetBegin(isModifier: true)
        nodeA.addContext(StringContextKey.self, value: ["4"], scope: .environment)
        nodeA.addContext(StringContextKey.self, value: ["5"], scope: .current)
        // working set 3
        nodeA.markContextWorkSetBegin(isModifier: true)
        nodeA.addContext(StringContextKey.self, value: ["3"], scope: .environment)

        // Node B
        let nodeB = nodeA.newContextNode()
        nodeB.addContext(StringContextKey.self, value: ["6"], scope: .current)
        nodeB.markContextWorkSetBegin()
        nodeB.addContext(StringContextKey.self, value: ["7"], scope: .current)

        XCTAssertEqual(nodeB.peekValue(for: StringOptionalContextKey.self), nil)
        XCTAssertEqual(nodeB.peekValue(for: StringContextKey.self), ["2", "3", "4", "6", "7"])
        XCTAssertEqual(nodeB.peekValue(for: IntContextKey.self), 1)

        let contextB = nodeB.export()
        let contextA = nodeA.export()

        XCTAssertEqual(contextA.get(valueFor: StringContextKey.self), ["1", "2", "3", "4", "5"])
        XCTAssertEqual(contextB.get(valueFor: StringContextKey.self), ["2", "3", "4", "6", "7"])

        XCTAssertEqual(contextA.get(valueFor: IntContextKey.self), 2)
        XCTAssertEqual(contextB.get(valueFor: IntContextKey.self), 1)
    }

    func testNeverContextKey() {
        XCTAssertRuntimeFailure(Never.defaultValue)
    }

    func testIllegalContextKey() {
        struct ContextKeyWithOptionalString: ContextKey {
            typealias Value = String?
            static var defaultValue: String? = "asdf"
        }

        let node = ContextNode()
        XCTAssertRuntimeFailure(node.addContext(ContextKeyWithOptionalString.self, value: "heyho", scope: .current))
    }

    func testContextKeyCopying() {
        let context = Context([ObjectIdentifier(String.self): "asdf"])
        let copied = Context(copying: context)

        XCTAssertEqual(context.description, copied.description)
    }
}