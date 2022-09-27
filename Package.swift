// swift-tools-version:5.7

//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2021 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import PackageDescription


let package = Package(
    name: "MetadataSystem",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .library(name: "ApodiniContext", targets: ["ApodiniContext"]),
        .library(name: "MetadataSystem", targets: ["MetadataSystem"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/norio-nomura/XCTAssertCrash.git", from: "0.2.0"),
        .package(url: "https://github.com/omochi/FineJSON.git", from: "1.14.0")
    ],
    targets: [
        .target(
            name: "ApodiniContext",
            dependencies: [
                .product(name: "OrderedCollections", package: "swift-collections")
            ]
        ),
        .target(
            name: "MetadataSystem",
            dependencies: [
                .target(name: "ApodiniContext")
            ]
        ),
        .target(
            name: "ExampleMetadataSystem",
            dependencies: [
                .target(name: "MetadataSystem")
            ]
        ),
        .target(
            name: "XCTMetadataSystem",
            dependencies: [
                .product(name: "XCTAssertCrash", package: "XCTAssertCrash", condition: .when(platforms: [.macOS]))
            ]
        ),
        .testTarget(
            name: "ApodiniContextTests",
            dependencies: [
                .target(name: "XCTMetadataSystem"),
                .target(name: "ApodiniContext"),
                .product(name: "FineJSON", package: "FineJSON")
            ]
        ),
        .testTarget(
            name: "MetadataSystemTests",
            dependencies: [
                .target(name: "XCTMetadataSystem"),
                .target(name: "MetadataSystem"),
                .target(name: "ExampleMetadataSystem")
            ]
        )
    ]
)
