//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTest
import XCTMetadataSystem
import MetadataSystem
import ExampleMetadataSystem

private struct TestIntMetadataContextKey: ContextKey {
    typealias Value = [Int]
    static var defaultValue: [Int] = []
}

private struct OptionalTestIntMetadataContextKey: OptionalContextKey {
    typealias Value = [Int]
}


private extension ExampleMetadataNamespace {
    typealias TestInt = TestIntHandlerMetadata
    typealias OptionalTestInt = OptionalTestIntMetadata
    typealias Ints = RestrictedExampleMetadataBlock<TestInt>
}

private struct OptionalTestIntMetadata: ExampleMetadataDefinition {
    typealias Key = OptionalTestIntMetadataContextKey

    var value: [Int] = []

    init(_ num: Int) {
        self.value = [num]
    }
}

private struct TestIntHandlerMetadata: ExampleMetadataDefinition {
    typealias Key = TestIntMetadataContextKey
    
    var value: [Int]

    init(_ num: Int) {
        self.value = [num]
    }
}

private struct ReusableTestHandlerMetadata: ExampleMetadataBlock {
    var metadata: Metadata {
        TestInt(14)
        Empty()
        Block {
            Empty()
            TestInt(15)
        }
    }
}

private struct TestMetadataExample: ExampleMetadataBlock {
    var state: Bool

    var metadata: Metadata {
        OptionalTestInt(0)

        TestInt(0)

        if state {
            TestInt(1)
        }

        Empty()

        Block {
            TestInt(2)

            if state {
                TestInt(3)
            } else {
                TestInt(4)
            }

            Empty()

            Block {
                Empty()
                TestInt(5)
            }

            TestInt(6)
        }

        Ints {
            if state {
                Ints {
                    TestInt(7)
                }
                TestInt(8)
            }

            if state {
                TestInt(9)
            } else {
                TestInt(10)
            }

            for num in 11...11 {
                TestInt(num)
            }
        }

        for num in 12...13 {
            TestInt(num)
        }

        ReusableTestHandlerMetadata()
    }
}

final class HandlerMetadataTest: XCTestCase {
    static var expectedIntsState: [Int] {
        [0, 1, 2, 3, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15]
    }

    static var expectedInts: [Int] {
        [0, 2, 4, 5, 6, 10, 11, 12, 13, 14, 15]
    }

    func testHandlerMetadataTrue() {
        let parser = StandardMetadataParser()
        TestMetadataExample(state: true)
            .collectMetadata(parser)
        let context = parser.exportContext()

        let capturedInts = context.get(valueFor: TestIntHandlerMetadata.self)
        let expectedInts: [Int] = Self.expectedIntsState
        XCTAssertEqual(capturedInts, expectedInts)
        XCTAssertEqual(context.get(valueFor: OptionalTestIntMetadata.self), [0])
    }

    func testHandlerMetadataFalse() {
        let parser = StandardMetadataParser()
        TestMetadataExample(state: false)
            .collectMetadata(parser)
        let context = parser.exportContext()

        let captured = context.get(valueFor: TestIntHandlerMetadata.self)
        let expected: [Int] = Self.expectedInts
        XCTAssertEqual(captured, expected)
    }

    func testEmptyMetadata() {
        XCTAssertRuntimeFailure(EmptyExampleMetadata().value)
    }
}
