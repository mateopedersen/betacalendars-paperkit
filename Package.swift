// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BetaCalendarsPaperKit",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "BetaCalendarsPaperKit", targets: ["BetaCalendarsPaperKit"]),
        .executable(name: "PaperKitExample", targets: ["PaperKitExample"])
    ],
    targets: [
        .target(name: "BetaCalendarsPaperKit"),
        .executableTarget(name: "PaperKitExample", dependencies: ["BetaCalendarsPaperKit"], path: "Examples/ExampleApp"),
        .testTarget(name: "BetaCalendarsPaperKitTests", dependencies: ["BetaCalendarsPaperKit"], resources: [.copy("Fixtures")])
    ],
    swiftLanguageVersions: [.v5]
)
