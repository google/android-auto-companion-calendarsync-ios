// Copyright 2022 Google LLC
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

internal import Foundation
internal import UIKit
internal import AndroidAutoCalendarSyncProtos

typealias TimestampProto = Aae_Calendarsync_Timestamp
typealias TimeZoneProto = Aae_Calendarsync_TimeZone
typealias ColorProto = Aae_Calendarsync_Color

extension TimestampProto {
  init(_ date: Date) {
    self.init()

    seconds = Int64(date.timeIntervalSince1970)
  }
}

extension TimeZoneProto {
  init(_ timeZone: TimeZone) {
    self.init()

    name = timeZone.identifier
  }
}

extension ColorProto {
  init(_ color: UIColor) {
    self.init()

    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0

    color.getRed(&r, green: &g, blue: &b, alpha: &a)
    argb = Int32(a * 255) << 24 | Int32(r * 255) << 16 | Int32(g * 255) << 8 | Int32(b * 255) << 0
  }

  init(_ cgColor: CGColor) {
    self.init(UIColor(cgColor: cgColor))
  }
}
