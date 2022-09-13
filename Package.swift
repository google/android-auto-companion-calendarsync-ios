// swift-tools-version:5.3

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
    .iOS(.v13)
  ],
  products: [
    .library(
      name: "AndroidAutoCalendarSync",
      targets: ["AndroidAutoCalendarSync"]),
  ],
  dependencies: [
    .package(
      name: "AndroidAutoCompanion",
      url: "https://github.com/google/android-auto-companion-ios.git",
      from: "2.0.0"),
    .package(
      name: "SwiftProtobuf",
      url: "https://github.com/apple/swift-protobuf.git",
      from: "1.18.0"),
  ],
  targets: [
    .target(
      name: "AndroidAutoEventKitProtocol",
      dependencies: []),
    .target(
      name: "AndroidAutoEventKitProtocolMocks",
      dependencies: ["AndroidAutoEventKitProtocol"]),
    .target(
      name: "AndroidAutoEventKit",
      dependencies: ["AndroidAutoEventKitProtocol"]),
    .target(
      name: "AndroidAutoCalendarSyncProtos",
      dependencies: ["SwiftProtobuf"]),
    .target(
      name: "AndroidAutoCalendarExporter",
      dependencies: [
        "AndroidAutoEventKitProtocol",
        "AndroidAutoCalendarSyncProtos",
      ]),
    .target(
      name: "AndroidAutoCalendarSync",
      dependencies: [
        "AndroidAutoCalendarExporter",
        "AndroidAutoCalendarSyncProtos",
        "AndroidAutoEventKit",
        "AndroidAutoEventKitProtocol",
        .product(name: "AndroidAutoConnectedDeviceManager", package: "AndroidAutoCompanion"),
      ]),
    .target(
      name: "AndroidAutoCalendarSyncMocks",
      dependencies: []),
    .testTarget(
      name: "AndroidAutoCalendarExporterTests",
      dependencies: [
        "AndroidAutoCalendarExporter",
        "AndroidAutoEventKitProtocolMocks",
      ]),
    .testTarget(
      name: "AndroidAutoCalendarSyncTests",
      dependencies: [
        "AndroidAutoCalendarSync",
        "AndroidAutoCalendarSyncMocks",
        .product(name: "AndroidAutoConnectedDeviceManagerMocks", package: "AndroidAutoCompanion"),
      ]),
  ]
)
