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

import XCTest
@_implementationOnly import AndroidAutoCalendarSyncProtos

@testable import AndroidAutoCalendarSync

class CalendarEventProtoTest: XCTestCase {
  let mockCalendar = MockCalendar(title: "My Calendar", calendarIdentifier: "id")
  let date1 = Date(timeIntervalSince1970: 1.0)
  let date2 = Date(timeIntervalSince1970: 42.0)
  let timeZone = TimeZone(identifier: "Europe/Berlin")!

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
  }

  func testProtoFromCalendarItem() {
    let creationDate = Date(timeIntervalSince1970: 1.0)
    let lastModifiedDate = Date(timeIntervalSince1970: 42.0)
    let timeZone = TimeZone(identifier: "Europe/Berlin")!

    var calendarItem = MockCalendarItem(calendar: mockCalendar, title: "Test Event Title")

    var expectedProto = CalendarEventProto()
    expectedProto.title = "Test Event Title"
    XCTAssertEqual(expectedProto, CalendarEventProto(item: calendarItem))

    calendarItem = MockCalendarItem(
      calendar: mockCalendar,
      title: "The crazy ones",
      location: "far far away",
      creationDate: creationDate,
      lastModifiedDate: lastModifiedDate,
      timeZone: timeZone,
      notes: "It's really a crazy one.",
      attendees: nil)

    expectedProto = CalendarEventProto()
    expectedProto.title = "The crazy ones"
    expectedProto.location = "far far away"
    expectedProto.timeZone = TimeZoneProto(timeZone)
    expectedProto.description_p = "It's really a crazy one."

    XCTAssertEqual(expectedProto, CalendarEventProto(item: calendarItem))
  }

  func testProtoFromEvent() {
    let event = MockCalendarEvent(
      eventID: "id",
      startDate: date1,
      endDate: date2,
      isAllDay: true,
      status: .confirmed,
      calendar: mockCalendar,
      title: "event",
      timeZone: timeZone
    )

    var expectedProto = CalendarEventProto()
    expectedProto.key = "id"
    expectedProto.title = "event"
    expectedProto.beginTime = TimestampProto(event.startDate)
    expectedProto.endTime = TimestampProto(event.endDate)
    expectedProto.timeZone = TimeZoneProto(timeZone)
    expectedProto.isAllDay = event.isAllDay
    expectedProto.status = CalendarEventProto.Status(event.eventStatus)

    XCTAssertEqual(expectedProto, CalendarEventProto(event))
  }

  func testProtoFromCalendarItemWithParticipants() {
    let participantA = MockParticipant(name: "Person A")
    let participantB = MockParticipant(name: "Person B")

    let calendarItem = MockCalendarItem(
      calendar: mockCalendar,
      title: "Yet another event",
      location: nil,
      creationDate: nil,
      lastModifiedDate: nil,
      timeZone: nil,
      notes: nil,
      attendees: [participantA, participantB])

    var expectedProto = CalendarEventProto()
    expectedProto.title = "Yet another event"
    expectedProto.attendees = AttendeeProto.makeAttendees([participantA, participantB])

    XCTAssertEqual(expectedProto, CalendarEventProto(item: calendarItem))
  }
}
