import AndroidAutoEventKitProtocolMocks
import UIKit
import XCTest
import AndroidAutoCalendarSyncProtos

@testable import AndroidAutoCalendarExporter

class CalendarItemExporterTest: XCTestCase {

  let mockCalendar = MockCalendar(title: "My Calendar", calendarIdentifier: "id")

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
  }

  func testProtoFromCalendarItem() {
    let creationDate = Date(timeIntervalSince1970: 1.0)
    let lastModifiedDate = Date(timeIntervalSince1970: 42.0)
    let timeZone = TimeZone(identifier: "Europe/Berlin")!

    var calendarItem = MockCalendarItem(calendar: mockCalendar, title: "Test Event Title")

    var expectedProto = Aae_Calendarsync_Event()
    expectedProto.title = "Test Event Title"
    XCTAssertEqual(expectedProto, CalendarItemExporter.proto(from: calendarItem))

    calendarItem = MockCalendarItem(
      calendar: mockCalendar,
      title: "The crazy ones",
      location: "far far away",
      creationDate: creationDate,
      lastModifiedDate: lastModifiedDate,
      timeZone: timeZone,
      notes: "It's really a crazy one.",
      attendees: nil)

    expectedProto = Aae_Calendarsync_Event()
    expectedProto.title = "The crazy ones"
    expectedProto.location = "far far away"
    expectedProto.creationDate = CommonExporter.proto(from: creationDate)
    expectedProto.lastModifiedDate = CommonExporter.proto(from: lastModifiedDate)
    expectedProto.timeZone = CommonExporter.proto(from: timeZone)
    expectedProto.description_p = "It's really a crazy one."

    XCTAssertEqual(expectedProto, CalendarItemExporter.proto(from: calendarItem))
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

    var expectedProto = Aae_Calendarsync_Event()
    expectedProto.title = "Yet another event"
    expectedProto.attendee = ParticipantExporter.proto(from: [participantA, participantB])

    XCTAssertEqual(expectedProto, CalendarItemExporter.proto(from: calendarItem))
  }
}
