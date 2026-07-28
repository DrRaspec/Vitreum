// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "vitreum",
  platforms: [
    .iOS("13.0")
  ],
  products: [
    .library(name: "vitreum", targets: ["vitreum"])
  ],
  dependencies: [
    .package(name: "FlutterFramework", path: "../FlutterFramework")
  ],
  targets: [
    .target(
      name: "vitreum",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework")
      ]
    )
  ]
)
