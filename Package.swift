// swift-tools-version: 6.1
//
//  Package.swift
//  UnionTabBar
//
//  Created by Union St on 11/28/25.
//

import PackageDescription

let package = Package(
    name: "union-tab-bar",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "UnionTabBar",
            targets: ["UnionTabBar"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "UnionTabBar",
            dependencies: []
        )
    ]
)

