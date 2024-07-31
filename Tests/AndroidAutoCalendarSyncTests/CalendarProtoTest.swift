// Copyright 2023 Google LLC
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

private import Foundation
private import UIKit
internal import XCTest
private import AndroidAutoCalendarSyncProtos

@testable private import AndroidAutoCalendarSync

class CalendarProtoTest: XCTestCase {
  func testProtoFromCalendar() {
    let cgColor = UIColor.clear.cgColor
    let calendar = MockCalendar(
      title: "calendar",
      calendarIdentifier: "id",
      cgColor: cgColor
    )

    var expectedProto = CalendarProto()
    expectedProto.title = "calendar"
    expectedProto.key = "id"
    expectedProto.color = ColorProto(cgColor)

    XCTAssertEqual(expectedProto, CalendarProto(calendar))
  }
}
