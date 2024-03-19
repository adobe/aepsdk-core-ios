// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
let package = Package(
    name: "TestProject",
    defaultLocalization: "en-US",
    platforms: [
        .iOS(.v12), .tvOS(.v12)
    ],
    products: [
        .library(
            name: "TestProject",
            targets: ["TestProject"]
        )
    ],
    dependencies: [
        .package(name: "AEPCore", path: "../"),
    ],
    targets: [
        .target(
            name: "TestProject",
            dependencies: [
                .product(name: "AEPCore", package: "AEPCore"),
                .product(name: "AEPIdentity", package: "AEPCore"),
                .product(name: "AEPLifecycle", package: "AEPCore"),
                .product(name: "AEPServices", package: "AEPCore"),
                .product(name: "AEPSignal", package: "AEPCore"),
            ])
    ]
)

