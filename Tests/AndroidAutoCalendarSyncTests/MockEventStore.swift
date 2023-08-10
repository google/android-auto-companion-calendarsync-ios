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

import AndroidAutoCalendarSync
import UIKit

class MockEventStore {
  /// Calendars keyed by identifier.
  private var calendars: [String: MockCalendar] = [:] {
    didSet {
      NotificationCenter.default.post(name: self.observingEventName, object: self)
    }
  }

  private var events: [MockCalendarEvent] = [] {
    didSet {
      NotificationCenter.default.post(name: self.observingEventName, object: self)
    }
  }

  func addCalendar(title: String, identifier: String, cgColor: CGColor) {
    let calendar = MockCalendar(title: title, calendarIdentifier: identifier, cgColor: cgColor)
    calendars[identifier] = calendar
  }

  func removeCalendar(_ identifier: String) {
    calendars[identifier] = nil
  }

  func addEvent(
    for calendar: MockCalendar,
    title: String,
    startTimestamp: Double,
    endTimestamp: Double,
    isAllDay: Bool = false,
    location: String? = nil,
    notes: String? = nil
  ) {
    let endDate: Date
    if isAllDay {
      endDate = Date(timeIntervalSince1970: endTimestamp - 1)
    } else {
      endDate = Date(timeIntervalSince1970: endTimestamp)
    }

    let event = MockCalendarEvent(
      eventID: UUID().uuidString,
      startDate: Date(timeIntervalSince1970: startTimestamp),
      endDate: endDate,
      isAllDay: isAllDay,
      calendar: calendar,
      title: "title",
      location: location,
      notes: notes
    )

    events.append(event)
  }

  func calendar(withIdentifier identifier: String) -> MockCalendar? {
    return calendars[identifier]
  }
}

extension MockEventStore: EventStore {
  static var isAuthorized: Bool = false

  public var observingEventName: NSNotification.Name {
    Notification.Name("mockEventStoreChanged")
  }

  func events(
    for calendars: [MockCalendar],
    withStart startDate: Date,
    end endDate: Date
  ) throws -> [MockCalendarEvent] {
    guard !calendars.isEmpty else { return [] }

    let requestTimeRange = startDate..<endDate
    let calendarIdentifiers: Set<String> = Set(
      calendars.map {
        $0.calendarIdentifier
      })

    return events.filter {
      guard calendarIdentifiers.contains($0.calendar.calendarIdentifier) else { return false }
      let timeRange = $0.startDate..<$0.endDate
      return timeRange.overlaps(requestTimeRange)
    }
  }

  func calendars(for identifiers: some Collection<String>) throws -> [MockCalendar] {
    guard Self.isAuthorized else { throw CalendarSyncClientError.notAuthorized }
    return identifiers.compactMap { calendars[$0] }
  }
}
