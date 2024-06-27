// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "AEPTestUtils",
    platforms: [.iOS(.v12), .tvos(.v12)],
    products: [
        .library(name: "AEPTestUtils", targets: ["AEPTestUtils"]),
    ],
    dependencies: [
        .package(path: "../../../.."), // This points to the root-level AEPCore package
    ],
    targets: [
        .target(
            name: "AEPTestUtils",
            dependencies: [
                .product(name: "AEPCore", package: "AEPCore"),
                .product(name: "AEPServices", package: "AEPCore")
            ],
            path: ".",
            sources: [
                "../../../AEPServices/Mocks/PublicTestUtils",
                "../../../AEPCore/Mocks/PublicTestUtils"
            ],
            swiftSettings: [
                .define("BUILD_LIBRARY_FOR_DISTRIBUTION", .when(configuration: .release))
            ],
            linkerSettings: [
                .linkedFramework("XCTest")
            ]
        )
    ]
)
