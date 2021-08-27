// swift-tools-version:5.5

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
        .macOS(.v12)
    ],
    products: [
        .library(name: "ApodiniContext", targets: ["ApodiniContext"]),
        .library(name: "MetadataSystem", targets: ["MetadataSystem"])
    ],
    dependencies: [
        .package(url: "https://github.com/nerdsupremacist/AssociatedTypeRequirementsKit.git", .upToNextMinor(from: "0.3.2")),

        .package(url: "https://github.com/norio-nomura/XCTAssertCrash.git", from: "0.2.0")
    ],
    targets: [
        .target(
            name: "ApodiniContext"
        ),

        .target(
            name: "MetadataSystem",
            dependencies: [
                .target(name: "ApodiniContext"),
                .product(name: "AssociatedTypeRequirementsKit", package: "AssociatedTypeRequirementsKit")
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
                .target(name: "ApodiniContext")
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
