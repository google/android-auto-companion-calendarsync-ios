// swift-tools-version:5.8

// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import PackageDescription

let package = Package(
  name: "AndroidAutoCalendarSync",
  platforms: [
    .iOS(.v15)
  ],
  products: [
    .library(
      name: "AndroidAutoCalendarSync",
      targets: ["AndroidAutoCalendarSync"])
  ],
  dependencies: [
    .package(url: "https://github.com/google/android-auto-companion-ios.git", from: "3.1.0"),
    .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.20.0"),
  ],
  targets: [
    .target(
      name: "AndroidAutoCalendarSync",
      dependencies: [
        "AndroidAutoCalendarSyncProtos",
        .product(name: "AndroidAutoConnectedDeviceManager", package: "android-auto-companion-ios"),
        .product(name: "AndroidAutoLogger", package: "android-auto-companion-ios"),
      ]),
    .target(
      name: "AndroidAutoCalendarSyncProtos",
      dependencies: [.product(name: "SwiftProtobuf", package: "swift-protobuf")],
      plugins: [.plugin(name: "ProtoSourceGenerator", package: "android-auto-companion-ios")]
    ),
    .testTarget(
      name: "AndroidAutoCalendarSyncTests",
      dependencies: [
        "AndroidAutoCalendarSync",
        .product(
          name: "AndroidAutoConnectedDeviceManagerMocks",
          package: "android-auto-companion-ios"
        ),
        .product(name: "AndroidAutoLogger", package: "android-auto-companion-ios"),
      ]),
  ]
)
