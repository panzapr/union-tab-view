// swift-tools-version: 6.1
//
//  Package.swift
//  UnionTabView
//
//  Created by Union St on 11/28/25.
//

import PackageDescription

let package = Package(
    name: "union-tab-view",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "UnionTabView",
            targets: ["UnionTabView"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "UnionTabView",
            dependencies: []
        )
    ]
)

