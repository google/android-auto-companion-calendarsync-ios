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

import AndroidAutoCalendarSyncMocks
import AndroidAutoConnectedDeviceManagerMocks
import EventKit
import UIKit
import XCTest
import AndroidAutoCalendarSyncProtos

@testable import AndroidAutoCalendarSync

class CalendarSyncClientTest: XCTestCase {
  private let referenceDate =
    Calendar.current.date(from: DateComponents(year: 1990, month: 11, day: 11))!

  private let otherReferenceDate =
    Calendar.current.date(from: DateComponents(year: 1990, month: 11, day: 12))!

  private var eventStore: MockEventStore!
  private var defaultCalendar: EKCalendar!
  private var otherCalendar: EKCalendar!

  override func setUp() {
    super.setUp()
    continueAfterFailure = false

    eventStore = MockEventStore()

    // Pre-fill event store
    let defaultCalendarId = "ID_DEF"
    eventStore.addCalendar(
      title: "Default Calendar", identifier: defaultCalendarId, cgColor: UIColor.yellow.cgColor)
    defaultCalendar = eventStore.calendar(withIdentifier: defaultCalendarId)

    for i in 0..<10 {
      eventStore.addEvent(
        for: defaultCalendar,
        title: "Event \(i)",
        startTimestamp: startTimestamp(hour: i, referenceDate: referenceDate),
        endTimestamp: endTimestamp(hour: i, referenceDate: referenceDate),
        location: "Space 42",
        notes: "Bring nothing!")
    }

    // Pre-fill event store
    let otherCalendarId = "ID_DEF"
    eventStore.addCalendar(
      title: "Other Calendar", identifier: otherCalendarId, cgColor: UIColor.green.cgColor)
    otherCalendar = eventStore.calendar(withIdentifier: otherCalendarId)

    for i in 0..<10 {
      eventStore.addEvent(
        for: otherCalendar,
        title: "Event \(i)",
        startTimestamp: startTimestamp(hour: i, referenceDate: otherReferenceDate),
        endTimestamp: endTimestamp(hour: i, referenceDate: otherReferenceDate),
        location: "Space 42",
        notes: "Bring nothing!")
    }
  }

  func testSendWithoutCalendarPermission() {
    MockEventStore.eventsAuthorizationStatus = .denied

    let mockChannel = SecuredCarChannelMock()
    let mockConnectedCarManager = ConnectedCarManagerMock()
    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)

    let calendarSyncClient = CalendarSyncClient(
      eventStore: eventStore, connectedCarManager: mockConnectedCarManager)

    calendarSyncClient.sync(
      calendars: [defaultCalendar],
      withStart: referenceDate,
      end: Calendar.current.date(byAdding: DateComponents(day: 1), to: referenceDate)!)

    XCTAssert(mockChannel.writtenMessages.isEmpty)
  }

  func testSend() {
    MockEventStore.eventsAuthorizationStatus = .authorized

    let mockChannel = SecuredCarChannelMock()
    let mockConnectedCarManager = ConnectedCarManagerMock()
    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)

    let calendarSyncClient = CalendarSyncClient(
      eventStore: eventStore, connectedCarManager: mockConnectedCarManager)

    calendarSyncClient.sync(
      calendars: [defaultCalendar],
      withStart: referenceDate,
      end: Calendar.current.date(byAdding: DateComponents(day: 1), to: referenceDate)!)

    XCTAssertEqual(mockChannel.writtenMessages.count, 1)
    XCTAssertNoThrow(
      try Aae_Calendarsync_Calendars(serializedData: mockChannel.writtenMessages.first!))
  }

  func testSend_ToSpecificCar() {
    MockEventStore.eventsAuthorizationStatus = .authorized

    let carId = "someCoolCarId"
    let mockChannel = SecuredCarChannelMock(id: carId, name: "Some cool car")
    let mockChannelOtherCar = SecuredCarChannelMock()
    let mockConnectedCarManager = ConnectedCarManagerMock()

    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)
    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannelOtherCar)

    let calendarSyncClient = CalendarSyncClient(
      eventStore: eventStore, connectedCarManager: mockConnectedCarManager)

    calendarSyncClient.sync(
      calendars: [defaultCalendar],
      forCarId: carId,
      withStart: referenceDate,
      end: Calendar.current.date(byAdding: DateComponents(day: 1), to: referenceDate)!)

    XCTAssert(mockChannelOtherCar.writtenMessages.isEmpty)
    XCTAssertEqual(mockChannel.writtenMessages.count, 1)
    XCTAssertNoThrow(
      try Aae_Calendarsync_Calendars(serializedData: mockChannel.writtenMessages.first!))
  }

  func testSend_ToSpecificCar_withTwoDifferentCalendars() {
    MockEventStore.eventsAuthorizationStatus = .authorized

    let carId = "someCoolCarId"
    let mockChannel = SecuredCarChannelMock(id: carId, name: "Some cool car")
    let mockConnectedCarManager = ConnectedCarManagerMock()

    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)

    let calendarSyncClient = CalendarSyncClient(
      eventStore: eventStore, connectedCarManager: mockConnectedCarManager)

    calendarSyncClient.sync(
      calendars: [defaultCalendar],
      forCarId: carId,
      withStart: referenceDate,
      end: Calendar.current.date(byAdding: DateComponents(day: 1), to: referenceDate)!)

    calendarSyncClient.sync(
      calendars: [otherCalendar],
      forCarId: carId,
      withStart: otherReferenceDate,
      end: Calendar.current.date(byAdding: DateComponents(day: 1), to: otherReferenceDate)!)

    // Both calendars should be written since their start dates are different.
    XCTAssertEqual(mockChannel.writtenMessages.count, 2)
    XCTAssertNoThrow(
      try Aae_Calendarsync_Calendars(serializedData: mockChannel.writtenMessages[0]))
    XCTAssertNoThrow(
      try Aae_Calendarsync_Calendars(serializedData: mockChannel.writtenMessages[1]))
  }

  func testSend_ToSpecificCar_combinesCalendarsWithSameTimeInterval() {
    MockEventStore.eventsAuthorizationStatus = .authorized

    let carId = "someCoolCarId"
    let mockChannel = SecuredCarChannelMock(id: carId, name: "Some cool car")
    let mockConnectedCarManager = ConnectedCarManagerMock()

    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)

    let calendarSyncClient = CalendarSyncClient(
      eventStore: eventStore, connectedCarManager: mockConnectedCarManager)

    calendarSyncClient.sync(
      calendars: [defaultCalendar],
      forCarId: carId,
      withStart: referenceDate,
      end: Calendar.current.date(byAdding: DateComponents(day: 1), to: referenceDate)!)

    calendarSyncClient.sync(
      calendars: [otherCalendar],
      forCarId: carId,
      withStart: referenceDate,
      end: Calendar.current.date(byAdding: DateComponents(day: 1), to: referenceDate)!)

    // The two calendars should be combined into one.
    XCTAssertEqual(mockChannel.writtenMessages.count, 1)
    XCTAssertNoThrow(
      try Aae_Calendarsync_Calendars(serializedData: mockChannel.writtenMessages.first!))
  }

  func testSend_toSpecificCarBeforeConnection_syncsAfterCarConnects() {
    MockEventStore.eventsAuthorizationStatus = .authorized

    let carId = "someCoolCarId"
    let mockChannel = SecuredCarChannelMock(id: carId, name: "Some cool car")
    let mockConnectedCarManager = ConnectedCarManagerMock()

    let calendarSyncClient = CalendarSyncClient(
      eventStore: eventStore, connectedCarManager: mockConnectedCarManager)

    calendarSyncClient.sync(
      calendars: [defaultCalendar],
      forCarId: carId,
      withStart: referenceDate,
      end: Calendar.current.date(byAdding: DateComponents(day: 1), to: referenceDate)!)

    // Trigger connection after `sync` is called.
    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)

    XCTAssertEqual(mockChannel.writtenMessages.count, 1)
    XCTAssertNoThrow(
      try Aae_Calendarsync_Calendars(serializedData: mockChannel.writtenMessages.first!))
  }

  func testSend_ToSpecificCar_syncsAfterReconnect() {
    MockEventStore.eventsAuthorizationStatus = .authorized

    let carId = "someCoolCarId"
    let mockChannel = SecuredCarChannelMock(id: carId, name: "Some cool car")
    let mockChannelOtherCar = SecuredCarChannelMock()
    let mockConnectedCarManager = ConnectedCarManagerMock()

    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)
    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannelOtherCar)

    let calendarSyncClient = CalendarSyncClient(
      eventStore: eventStore, connectedCarManager: mockConnectedCarManager)

    calendarSyncClient.sync(
      calendars: [defaultCalendar],
      forCarId: carId,
      withStart: referenceDate,
      end: Calendar.current.date(byAdding: DateComponents(day: 1), to: referenceDate)!)

    // Trigger a reconnection.
    mockConnectedCarManager.triggerDisconnection(for: mockChannel.car)
    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)

    // The calendar should be resynced (hence the count of 2).
    XCTAssert(mockChannelOtherCar.writtenMessages.isEmpty)
    XCTAssertEqual(mockChannel.writtenMessages.count, 2)
    XCTAssertNoThrow(
      try Aae_Calendarsync_Calendars(serializedData: mockChannel.writtenMessages[1]))
  }

  func testSend_ToAnyCar() {
    MockEventStore.eventsAuthorizationStatus = .authorized

    let mockChannel = SecuredCarChannelMock()
    let mockChannel2 = SecuredCarChannelMock(id: "someCoolCarId", name: "Some cool car")
    let mockConnectedCarManager = ConnectedCarManagerMock()

    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)
    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel2)

    let calendarSyncClient = CalendarSyncClient(
      eventStore: eventStore, connectedCarManager: mockConnectedCarManager)

    calendarSyncClient.sync(
      calendars: [defaultCalendar],
      withStart: referenceDate,
      end: Calendar.current.date(byAdding: DateComponents(day: 1), to: referenceDate)!)

    XCTAssertEqual(mockChannel.writtenMessages.count, 1)
    XCTAssertNoThrow(
      try Aae_Calendarsync_Calendars.init(serializedData: mockChannel.writtenMessages.first!))
    XCTAssertEqual(mockChannel2.writtenMessages.count, 1)
    XCTAssertNoThrow(
      try Aae_Calendarsync_Calendars.init(serializedData: mockChannel2.writtenMessages.first!))
  }

  func testSend_ToAnyCar_syncsAfterReconnect() {
    MockEventStore.eventsAuthorizationStatus = .authorized

    let mockChannel = SecuredCarChannelMock()
    let mockChannel2 = SecuredCarChannelMock(id: "someCoolCarId", name: "Some cool car")
    let mockConnectedCarManager = ConnectedCarManagerMock()

    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)
    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel2)

    let calendarSyncClient = CalendarSyncClient(
      eventStore: eventStore, connectedCarManager: mockConnectedCarManager)

    calendarSyncClient.sync(
      calendars: [defaultCalendar],
      withStart: referenceDate,
      end: Calendar.current.date(byAdding: DateComponents(day: 1), to: referenceDate)!)

    // Trigger a reconnection for both cars.
    mockConnectedCarManager.triggerDisconnection(for: mockChannel.car)
    mockConnectedCarManager.triggerDisconnection(for: mockChannel2.car)
    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)
    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel2)

    // Calendars should be resynced (hence the count of 2).
    XCTAssertEqual(mockChannel.writtenMessages.count, 2)
    XCTAssertNoThrow(
      try Aae_Calendarsync_Calendars.init(serializedData: mockChannel.writtenMessages[1]))
    XCTAssertEqual(mockChannel2.writtenMessages.count, 2)
    XCTAssertNoThrow(
      try Aae_Calendarsync_Calendars.init(serializedData: mockChannel2.writtenMessages[1]))
  }

  func testSendNoEvents() {
    MockEventStore.eventsAuthorizationStatus = .authorized

    let mockChannel = SecuredCarChannelMock()
    let mockConnectedCarManager = ConnectedCarManagerMock()
    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)

    let calendarSyncClient = CalendarSyncClient(
      eventStore: eventStore, connectedCarManager: mockConnectedCarManager)

    calendarSyncClient.sync(
      calendars: [defaultCalendar],
      withStart: Calendar.current.date(byAdding: DateComponents(day: 7), to: referenceDate)!,
      end: Calendar.current.date(byAdding: DateComponents(day: 8), to: referenceDate)!)

    XCTAssert(mockChannel.writtenMessages.isEmpty)
  }

  func testUnsync() throws {
    let mockChannel = SecuredCarChannelMock()
    let mockConnectedCarManager = ConnectedCarManagerMock()
    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)

    let calendarSyncClient = CalendarSyncClient(
      eventStore: eventStore, connectedCarManager: mockConnectedCarManager)

    let calId1 = "some identifier"
    let calId2 = "yet another id"

    calendarSyncClient.unsync(calendarIdentifiers: [calId1, calId2])

    XCTAssertEqual(1, mockChannel.writtenMessages.count)

    let expectedCalendarsProto = createCalendarsProto(calendarId1: calId1, calendarId2: calId2)

    let receivedCalendarsProto = try Aae_Calendarsync_Calendars(
      serializedData: mockChannel.writtenMessages.first!)
    XCTAssertEqual(receivedCalendarsProto, expectedCalendarsProto)
  }

  func testUnsync_ToSpecificCar() throws {
    let carId = "someSuperCarId"
    let mockChannel = SecuredCarChannelMock(id: carId, name: "Car name")
    let mockChannelOtherCar = SecuredCarChannelMock()
    let mockConnectedCarManager = ConnectedCarManagerMock()

    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)
    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannelOtherCar)

    let calendarSyncClient = CalendarSyncClient(
      eventStore: eventStore, connectedCarManager: mockConnectedCarManager)

    let calId1 = "some identifier"
    let calId2 = "yet another id"

    calendarSyncClient.unsync(calendarIdentifiers: [calId1, calId2], forCarId: carId)

    XCTAssert(mockChannelOtherCar.writtenMessages.isEmpty)
    XCTAssertEqual(mockChannel.writtenMessages.count, 1)

    let expectedCalendarsProto = createCalendarsProto(calendarId1: calId1, calendarId2: calId2)

    let receivedCalendarsProto = try Aae_Calendarsync_Calendars(
      serializedData: mockChannel.writtenMessages.first!)
    XCTAssertEqual(receivedCalendarsProto, expectedCalendarsProto)
  }

  func testUnsync_ToSpecificCar_doesNotSyncAfterReconnection() throws {
    let carId = "someSuperCarId"
    let mockChannel = SecuredCarChannelMock(id: carId, name: "Car name")
    let mockConnectedCarManager = ConnectedCarManagerMock()

    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)

    let calendarSyncClient = CalendarSyncClient(
      eventStore: eventStore, connectedCarManager: mockConnectedCarManager)

    let calId1 = "some identifier"
    let calId2 = "yet another id"

    calendarSyncClient.unsync(calendarIdentifiers: [calId1, calId2], forCarId: carId)
    XCTAssertEqual(mockChannel.writtenMessages.count, 1)

    // Trigger reconnection.
    mockConnectedCarManager.triggerDisconnection(for: mockChannel.car)
    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)

    // Count should remain the same because nothing needs to be synced.
    XCTAssertEqual(mockChannel.writtenMessages.count, 1)
  }

  func testUnsync_ToAnyCar() throws {
    let carId = "someSuperCarId"
    let mockChannel = SecuredCarChannelMock()
    let mockChannel2 = SecuredCarChannelMock(id: carId, name: "Car name")
    let mockConnectedCarManager = ConnectedCarManagerMock()

    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)
    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel2)

    let calendarSyncClient = CalendarSyncClient(
      eventStore: eventStore, connectedCarManager: mockConnectedCarManager)

    let calId1 = "some identifier"
    let calId2 = "yet another id"

    calendarSyncClient.unsync(calendarIdentifiers: [calId1, calId2])

    XCTAssertEqual(mockChannel.writtenMessages.count, 1)
    XCTAssertEqual(mockChannel2.writtenMessages.count, 1)

    let expectedCalendarsProto = createCalendarsProto(calendarId1: calId1, calendarId2: calId2)

    let receivedCalendarsProto = try Aae_Calendarsync_Calendars(
      serializedData: mockChannel.writtenMessages.first!)
    XCTAssertEqual(receivedCalendarsProto, expectedCalendarsProto)

    let receivedCalendarsProto2 = try Aae_Calendarsync_Calendars(
      serializedData: mockChannel2.writtenMessages.first!)
    XCTAssertEqual(receivedCalendarsProto2, expectedCalendarsProto)
  }

  func testUnsyncWithoutIdentifiers() {
    let mockChannel = SecuredCarChannelMock()
    let mockConnectedCarManager = ConnectedCarManagerMock()
    mockConnectedCarManager.triggerSecureChannelSetUp(with: mockChannel)

    let calendarSyncClient = CalendarSyncClient(
      eventStore: eventStore, connectedCarManager: mockConnectedCarManager)

    calendarSyncClient.unsync(calendarIdentifiers: [])

    XCTAssert(mockChannel.writtenMessages.isEmpty)
  }

  // MARK: - Helpers

  private func startTimestamp(hour: Int, referenceDate: Date) -> Double {
    let date = Calendar.current.date(
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
    -> Aae_Calendarsync_Calendars
  {
    var proto = Aae_Calendarsync_Calendars()
    var calendarProto1 = Aae_Calendarsync_Calendar()
    calendarProto1.uuid = calendarId1
    var calendarProto2 = Aae_Calendarsync_Calendar()
    calendarProto2.uuid = calendarId2
    proto.calendar.append(calendarProto1)
    proto.calendar.append(calendarProto2)

    return proto
  }
}

extension SecuredCarChannelMock {
  convenience init() {
    self.init(id: "carId", name: "mock car")
  }
}

extension CalendarSyncClient {
  func unsync(calendarIdentifiers: [String]) {
    unsync(calendarIdentifiers: calendarIdentifiers, forCarId: nil)
  }

  func sync(calendars: [EKCalendar], withStart startDate: Date, end endDate: Date) {
    sync(calendars: calendars, forCarId: nil, withStart: startDate, end: endDate)
  }
}
