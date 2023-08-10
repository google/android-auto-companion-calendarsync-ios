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

import Foundation
import UIKit
import XCTest
@_implementationOnly import AndroidAutoCalendarSyncProtos

@testable import AndroidAutoCalendarSync

class UpdateCalendarsProtoTest: XCTestCase {
  let date1 = Date(timeIntervalSince1970: 1.0)
  let date2 = Date(timeIntervalSince1970: 42.0)
  let mockCalendar = MockCalendar(title: "My Calendar", calendarIdentifier: "id1")
  let timeZone = TimeZone(identifier: "Europe/Berlin")!

  func testProtoFromEvents() {
    let date3 = Date(timeIntervalSince1970: 5.0)
    let date4 = Date(timeIntervalSince1970: 50.0)
    let event1 = MockCalendarEvent(
      eventID: "id",
      startDate: date1,
      endDate: date2,
      isAllDay: true,
      status: .confirmed,
      calendar: mockCalendar,
      title: "event1",
      timeZone: timeZone
    )

    let event2 = MockCalendarEvent(
      eventID: "id",
      startDate: date3,
      endDate: date4,
      isAllDay: true,
      status: .confirmed,
      calendar: mockCalendar,
      title: "event",
      timeZone: timeZone
    )

    let events = [event1, event2]

    var expectedProto = UpdateCalendarsProto()
    var calendarProto = CalendarProto(mockCalendar)
    calendarProto.events.append(CalendarEventProto(event1))
    calendarProto.events.append(CalendarEventProto(event2))
    calendarProto.range.from = TimestampProto(date1)
    calendarProto.range.to = TimestampProto(date4)

    expectedProto.calendars.append(calendarProto)
    expectedProto.type = UpdateCalendarsProto.TypeEnum.receive
    expectedProto.version = 1
    XCTAssertEqual(expectedProto, UpdateCalendarsProto(events: events, in: [mockCalendar]))
  }
}
