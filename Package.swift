// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Arbitrary",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Arbitrary",
            targets: ["Arbitrary"]
        ),
        .executable(
            name: "ArbitraryClient",
            targets: ["ArbitraryClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "ArbitraryMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ],
        ),

        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(name: "Arbitrary", dependencies: ["ArbitraryMacros"]),

        // A client of the library, which is able to use the macro in its own code.
        .executableTarget(name: "ArbitraryClient", dependencies: ["Arbitrary"]),

    ]
)
