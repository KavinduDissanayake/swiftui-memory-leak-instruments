// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftUIMemoryLeakInstruments",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "SwiftUIMemoryLeakInstruments",
            targets: ["SwiftUIMemoryLeakInstruments"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftUIMemoryLeakInstruments",
            path: "Sources"
        ),
        .testTarget(
            name: "SwiftUIMemoryLeakInstrumentsTests",
            dependencies: ["SwiftUIMemoryLeakInstruments"],
            path: "Tests"
        ),
    ]
)
