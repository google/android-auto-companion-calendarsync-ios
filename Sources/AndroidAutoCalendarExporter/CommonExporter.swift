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

import Foundation
import UIKit
import AndroidAutoCalendarSyncProtos

/// An exporter to convert common iOS objects into protos.
enum CommonExporter {

  static func proto(from date: Date) -> Aae_Calendarsync_Timestamp {
    var dateProto = Aae_Calendarsync_Timestamp()
    dateProto.seconds = Int64(date.timeIntervalSince1970)
    return dateProto
  }

  static func proto(from timeZone: TimeZone) -> Aae_Calendarsync_TimeZone {
    var timeZoneProto = Aae_Calendarsync_TimeZone()
    timeZoneProto.name = timeZone.identifier
    timeZoneProto.secondsFromGmt = Int64(timeZone.secondsFromGMT())
    return timeZoneProto
  }

  static func proto(from cgColor: CGColor) -> Aae_Calendarsync_Color {
    let color = UIColor.init(cgColor: cgColor)
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0

    color.getRed(&r, green: &g, blue: &b, alpha: &a)

    let argb: Int32 =
      Int32(a * 255) << 24 | Int32(r * 255) << 16 | Int32(g * 255) << 8 | Int32(
        b * 255) << 0

    var protoColor = Aae_Calendarsync_Color()
    protoColor.argb = argb
    return protoColor
  }

}
