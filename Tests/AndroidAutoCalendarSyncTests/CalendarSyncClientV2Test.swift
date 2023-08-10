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

import AndroidAutoConnectedDeviceManagerMocks
import Foundation
import UIKit
import XCTest
@_implementationOnly import AndroidAutoCalendarSyncProtos

@testable import AndroidAutoCalendarSync

@MainActor class CalendarSyncClientV2Test: XCTestCase {
  private let referenceDate =
    Foundation.Calendar.current.date(from: DateComponents(year: 1990, month: 11, day: 11))!

  private let otherReferenceDate =
    Foundation.Calendar.current.date(from: DateComponents(year: 1990, month: 11, day: 12))!

  private let nowReferenceDate = Date()

  private var mockSettingsStore: MockKeyValueStore!
  private var settings: CarCalendarSettings<MockKeyValueStore>!
  private var eventStore: MockEventStore!
  private var testClient: CalendarSyncClientV2<MockEventStore, MockKeyValueStore>!
  private var mockConnectedCarManager: ConnectedCarManagerMock!

  private var defaultCalendar: MockCalendar!
  private var otherCalendar: MockCalendar!
  private var nowCalendar: MockCalendar!

  override func setUp() {
    super.setUp()
    continueAfterFailure = false

    eventStore = MockEventStore()
    mockSettingsStore = MockKeyValueStore()
    settings = CarCalendarSettings(mockSettingsStore)
    mockConnectedCarManager = ConnectedCarManagerMock()

    testClient = CalendarSyncClientV2(
      eventStore: eventStore,
      settings: settings,
      connectedCarManager: mockConnectedCarManager,
      syncDuration: .days(1)
    )

    populateCalendars()
  }

  override func tearDown() {
    testClient = nil
    mockConnectedCarManager = nil
    settings = nil
    mockSettingsStore = nil
    eventStore = nil
    MockEventStore.isAuthorized = false

    super.tearDown()
  }

  func testSendWithoutCalendarPermission() {
    MockEventStore.isAuthorized = false

    let mockChannel = SecuredCarChannelMock(id: "TestCar", name: nil)
    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)

    XCTAssertThrowsError(
      try testClient.sync(
        calendars: [self.defaultCalendar.calendarIdentifier],
        withCar: "TestCar",
        from: self.referenceDate
      )
    )

    XCTAssert(mockChannel.writtenMessages.isEmpty)
  }

  func testSend() throws {
    MockEventStore.isAuthorized = true

    let mockChannel = SecuredCarChannelMock(id: "TestCar", name: nil)
    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)

    XCTAssertNoThrow(
      try testClient.sync(
        calendars: [self.defaultCalendar.calendarIdentifier],
        withCar: "TestCar",
        from: self.referenceDate
      )
    )

    XCTAssertEqual(mockChannel.writtenMessages.count, 1)
    XCTAssertNoThrow(
      try Aae_Calendarsync_UpdateCalendars(serializedData: mockChannel.writtenMessages.first!))
  }

  func testSend_ToSpecificCar() throws {
    MockEventStore.isAuthorized = true

    let carID = "someCoolCarID"
    let mockChannel = SecuredCarChannelMock(id: carID, name: "Some cool car")
    let mockChannelOtherCar = SecuredCarChannelMock()

    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)
    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannelOtherCar)

    XCTAssertNoThrow(
      try testClient.sync(
        calendars: [self.defaultCalendar.calendarIdentifier],
        withCar: carID,
        from: self.referenceDate
      )
    )

    XCTAssert(mockChannelOtherCar.writtenMessages.isEmpty)
    XCTAssertEqual(mockChannel.writtenMessages.count, 1)
    XCTAssertNoThrow(
      try Aae_Calendarsync_UpdateCalendars(serializedData: mockChannel.writtenMessages.first!))
  }

  func testSend_ToSpecificCar_withTwoDifferentCalendars() throws {
    MockEventStore.isAuthorized = true

    let carID = "someCoolCarID"
    let mockChannel = SecuredCarChannelMock(id: carID, name: "Some cool car")

    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)

    XCTAssertNoThrow(
      try testClient.sync(
        calendars: [self.defaultCalendar.calendarIdentifier],
        withCar: carID,
        from: self.referenceDate
      )
    )

    XCTAssertNoThrow(
      try testClient.sync(
        calendars: [self.otherCalendar.calendarIdentifier],
        withCar: carID,
        from: self.otherReferenceDate
      )
    )

    // Both calendars should be written since their start dates are different.
    XCTAssertEqual(mockChannel.writtenMessages.count, 2)
    XCTAssertNoThrow(
      try Aae_Calendarsync_UpdateCalendars(serializedData: mockChannel.writtenMessages[0]))
    XCTAssertNoThrow(
      try Aae_Calendarsync_UpdateCalendars(serializedData: mockChannel.writtenMessages[1]))
  }

  /// Two calendars are sent (one with no events in range and one with events in range).
  func testSend_ToSpecificCar_twoCalendars_oneWithEventsInRange() throws {
    MockEventStore.isAuthorized = true

    let carID = "someCoolCarID"
    let mockChannel = SecuredCarChannelMock(id: carID, name: "Some cool car")

    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)

    // Send calendar with events in range.
    XCTAssertNoThrow(
      try testClient.sync(
        calendars: [self.defaultCalendar.calendarIdentifier],
        withCar: carID,
        from: self.referenceDate
      )
    )

    // Send calendar with no events in range.
    XCTAssertNoThrow(
      try testClient.sync(
        calendars: [self.otherCalendar.calendarIdentifier],
        withCar: carID,
        from: .distantPast
      )
    )

    // Both calendars should be sent including the empty one.
    XCTAssertEqual(mockChannel.writtenMessages.count, 2)
    XCTAssertNoThrow(
      try Aae_Calendarsync_UpdateCalendars(serializedData: mockChannel.writtenMessages[0]))

    let secondUpdate = try Aae_Calendarsync_UpdateCalendars(
      serializedData: mockChannel.writtenMessages[1])
    XCTAssertEqual(secondUpdate.calendars.count, 1)
    XCTAssertEqual(secondUpdate.calendars[0].key, otherCalendar.calendarIdentifier)
    XCTAssertTrue(secondUpdate.calendars[0].events.isEmpty)
  }

  func testSyncCalendarsOnConnection() throws {
    MockEventStore.isAuthorized = true

    let carID = "Test"
    let mockChannel = SecuredCarChannelMock(id: carID, name: "Test")

    settings[carID].isEnabled = true
    settings[carID].calendarIDs = [
      defaultCalendar.calendarIdentifier,
      nowCalendar.calendarIdentifier,
      otherCalendar.calendarIdentifier,
    ]

    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)

    // One message from the initial connection.
    XCTAssertEqual(mockChannel.writtenMessages.count, 1)

    // The last update is for synching the calendars.
    let sync = try Aae_Calendarsync_UpdateCalendars(
      serializedData: mockChannel.writtenMessages[0])
    XCTAssertEqual(sync.calendars.count, 3)
  }

  func testSend_toSpecificCarBeforeConnection_syncsAfterCarConnects() throws {
    MockEventStore.isAuthorized = true

    let carID = "TestCar"
    let mockChannel = SecuredCarChannelMock(id: carID, name: "Some cool car")

    settings[carID].isEnabled = true
    settings[carID].calendarIDs = [self.nowCalendar.calendarIdentifier]

    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)

    XCTAssertEqual(mockChannel.writtenMessages.count, 1)
    XCTAssertNoThrow(
      try Aae_Calendarsync_UpdateCalendars(serializedData: mockChannel.writtenMessages.first!))
  }

  func testSend_ToSpecificCar_syncsAfterReconnect() throws {
    MockEventStore.isAuthorized = true

    let carID = "TestCar"
    let mockChannel = SecuredCarChannelMock(id: carID, name: "Some cool car")
    let mockChannelOtherCar = SecuredCarChannelMock()

    settings[carID].isEnabled = true
    settings[carID].calendarIDs = [self.nowCalendar.calendarIdentifier]
    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)
    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannelOtherCar)

    XCTAssertNoThrow(
      try testClient.sync(
        calendars: [self.defaultCalendar.calendarIdentifier],
        withCar: carID,
        from: self.referenceDate
      )
    )

    // Trigger a reconnection.
    mockConnectedCarManager.triggerDisconnection(for: mockChannel.car)
    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)

    // Should have three messages: initial connection, manual sync and reconnection.
    XCTAssert(mockChannelOtherCar.writtenMessages.isEmpty)
    XCTAssertEqual(mockChannel.writtenMessages.count, 3)
    XCTAssertNoThrow(
      try Aae_Calendarsync_UpdateCalendars(serializedData: mockChannel.writtenMessages[1]))
  }

  func testSendCalendarWithNoEventsInRange() throws {
    MockEventStore.isAuthorized = true

    let carID = "TestCar"
    let mockChannel = SecuredCarChannelMock(id: carID, name: nil)
    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)

    settings[carID].isEnabled = true
    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)

    XCTAssertNoThrow(
      try testClient.sync(
        calendars: [self.defaultCalendar.calendarIdentifier],
        withCar: carID,
        from: Foundation.Calendar.current.date(
          byAdding: DateComponents(day: 7), to: self.referenceDate)!
      )
    )

    XCTAssertEqual(mockChannel.writtenMessages.count, 1)
  }

  func testSendCalendars_EventsInRangeAndEmptyCalendar() throws {
    MockEventStore.isAuthorized = true

    let carID = "TestCar"
    let mockChannel = SecuredCarChannelMock(id: carID, name: nil)
    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)

    settings[carID].isEnabled = true
    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)

    // Send events starting at reference date. Both calendars should be sent.
    XCTAssertNoThrow(
      try testClient.sync(
        calendars: [
          self.defaultCalendar.calendarIdentifier, self.otherCalendar.calendarIdentifier,
        ],
        withCar: carID,
        from: referenceDate
      )
    )

    XCTAssertEqual(mockChannel.writtenMessages.count, 1)

    let update = try Aae_Calendarsync_UpdateCalendars(
      serializedData: mockChannel.writtenMessages[0])

    // Both calendars should be sent. One has events and the other is empty (no events in range).
    XCTAssertEqual(update.calendars.count, 2)

    // Update calendar ordering is not guaranteed, so we need to put them in a dictionary.
    let updateCalendarsKeyedByID = update.calendars.reduce(into: [:]) { dict, calendar in
      dict[calendar.key] = calendar
    }

    // Default calendar has events in range.
    XCTAssertFalse(
      try XCTUnwrap(updateCalendarsKeyedByID[defaultCalendar.calendarIdentifier]).events.isEmpty
    )

    // Other calendar should be empty as it has not events in range.
    XCTAssertTrue(
      try XCTUnwrap(updateCalendarsKeyedByID[otherCalendar.calendarIdentifier]).events.isEmpty
    )
  }

  func testUnsyncRemovedCalendar() throws {
    MockEventStore.isAuthorized = true

    let carID = "Test"
    let mockChannel = SecuredCarChannelMock(id: carID, name: "Test")

    settings[carID].isEnabled = true
    settings[carID].calendarIDs = [
      defaultCalendar.calendarIdentifier,
      nowCalendar.calendarIdentifier,
      otherCalendar.calendarIdentifier,
    ]

    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)
    eventStore.removeCalendar(self.otherCalendar.calendarIdentifier)

    // Settings should no longer contain the removed calendar ID.
    XCTAssertEqual(settings[carID].calendarIDs.count, 2)
    XCTAssertFalse(settings[carID].calendarIDs.contains(otherCalendar.calendarIdentifier))

    // One message from initial connection, one for update and one for removing the calendar.
    XCTAssertEqual(mockChannel.writtenMessages.count, 3)

    // The last update is for unsynching the removed calendar.
    let unsync = try Aae_Calendarsync_UpdateCalendars(
      serializedData: mockChannel.writtenMessages[2])
    XCTAssertEqual(unsync.calendars.count, 1)
    XCTAssertEqual(unsync.calendars[0].key, self.otherCalendar.calendarIdentifier)
    XCTAssertTrue(unsync.calendars[0].events.isEmpty)
  }

  func testUnsync_ToSpecificCar() throws {
    let carID = "TestCar"
    let mockChannel = SecuredCarChannelMock(id: carID, name: "Car name")
    let mockChannelOtherCar = SecuredCarChannelMock()

    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)
    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannelOtherCar)

    let calId1 = "some identifier"
    let calId2 = "yet another id"

    XCTAssertNoThrow(
      try testClient.unsync(calendars: [calId1, calId2], withCar: carID)
    )

    XCTAssert(mockChannelOtherCar.writtenMessages.isEmpty)
    XCTAssertEqual(mockChannel.writtenMessages.count, 1)

    let expectedCalendarsProto = createCalendarsProto(calendarId1: calId1, calendarId2: calId2)

    let receivedCalendarsProto =
      try Aae_Calendarsync_UpdateCalendars(serializedData: mockChannel.writtenMessages.first!)
    XCTAssertEqual(receivedCalendarsProto, expectedCalendarsProto)
  }

  func testUnsync_ToSpecificCar_doesNotSyncAfterReconnection() throws {
    let carID = "TestCar"
    let mockChannel = SecuredCarChannelMock(id: carID, name: "Car name")

    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)

    let calId1 = "some identifier"
    let calId2 = "yet another id"

    XCTAssertNoThrow(
      try testClient.unsync(calendars: [calId1, calId2], withCar: carID)
    )
    XCTAssertEqual(mockChannel.writtenMessages.count, 1)

    // Trigger reconnection.
    mockConnectedCarManager.triggerDisconnection(for: mockChannel.car)
    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)

    // Count should remain the same because nothing needs to be synced.
    XCTAssertEqual(mockChannel.writtenMessages.count, 1)
  }
}

// MARK: - Helpers
extension CalendarSyncClientV2Test {
  private func startTimestamp(hour: Int, referenceDate: Date) -> Double {
    let date = Foundation.Calendar.current.date(
      byAdding: DateComponents(hour: hour),
      to: referenceDate)!
    return date.timeIntervalSince1970
  }

  private func endTimestamp(hour: Int, referenceDate: Date, allDay: Bool = false) -> Double {
    let hourInSeconds: Double = 60 * 60
    let duration = allDay ? 24 * hourInSeconds : hourInSeconds
    return startTimestamp(hour: hour, referenceDate: referenceDate) + duration
  }

  private func createCalendarsProto(calendarId1: String, calendarId2: String)
    -> Aae_Calendarsync_UpdateCalendars
  {
    var proto = Aae_Calendarsync_UpdateCalendars()
    var calendarProto1 = Aae_Calendarsync_Calendar()
    calendarProto1.key = calendarId1
    var calendarProto2 = Aae_Calendarsync_Calendar()
    calendarProto2.key = calendarId2
    proto.calendars.append(calendarProto1)
    proto.calendars.append(calendarProto2)

    return proto
  }

  private func populateCalendars() {
    // Pre-fill event store
    let defaultCalendarId = "ID_ABC"
    eventStore.addCalendar(
      title: "Default Calendar", identifier: defaultCalendarId, cgColor: UIColor.yellow.cgColor)
    defaultCalendar = eventStore.calendar(withIdentifier: defaultCalendarId)

    for eventIndex in 0..<10 {
      eventStore.addEvent(
        for: defaultCalendar,
        title: "Event \(eventIndex)",
        startTimestamp: startTimestamp(hour: eventIndex, referenceDate: referenceDate),
        endTimestamp: endTimestamp(hour: eventIndex, referenceDate: referenceDate),
        location: "Space 42",
        notes: "Bring nothing!")
    }

    // Pre-fill event store
    let otherCalendarId = "ID_DEF"
    eventStore.addCalendar(
      title: "Other Calendar", identifier: otherCalendarId, cgColor: UIColor.green.cgColor)
    otherCalendar = eventStore.calendar(withIdentifier: otherCalendarId)

    for eventIndex in 0..<10 {
      eventStore.addEvent(
        for: otherCalendar,
        title: "Event \(eventIndex)",
        startTimestamp: startTimestamp(hour: eventIndex, referenceDate: otherReferenceDate),
        endTimestamp: endTimestamp(hour: eventIndex, referenceDate: otherReferenceDate),
        location: "Space 42",
        notes: "Bring nothing!")
    }

    // Pre-fill event store
    let nowCalendarId = "ID_NOW"
    eventStore.addCalendar(
      title: "Now", identifier: nowCalendarId, cgColor: UIColor.red.cgColor)
    nowCalendar = eventStore.calendar(withIdentifier: nowCalendarId)

    for eventIndex in 0..<10 {
      eventStore.addEvent(
        for: nowCalendar,
        title: "Event \(eventIndex)",
        startTimestamp: startTimestamp(hour: eventIndex, referenceDate: nowReferenceDate),
        endTimestamp: endTimestamp(hour: eventIndex, referenceDate: nowReferenceDate),
        location: "Space 42",
        notes: "Bring nothing!")
    }
  }
}

extension SecuredCarChannelMock {
  convenience init() {
    self.init(id: "carID", name: "mock car")
  }
}
