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

import EventKit
import UIKit

public class MockEventStore: EKEventStore {
  /// Specifies the `EKAuthorizationStatus` returned` by `authorizationStatus`.
  /// This allows to test without requiring explicit platform Calendar access permission.
  public static var eventsAuthorizationStatus: EKAuthorizationStatus = .authorized

  private var calendarsMap = [String: EKCalendar]()
  private var events = [EKEvent]()

  public func addCalendar(
    title: String,
    identifier: String,
    cgColor: CGColor,
    sourceTitle: String = "Test"
  ) {
    let calendar = EKCalendar(for: .event, eventStore: self)
    calendar.title = title
    calendar.cgColor = cgColor
    calendar.source = MockEKSource(sourceType: .local, title: sourceTitle)
    calendarsMap[identifier] = calendar
  }

  public func addEvent(
    for calendar: EKCalendar,
    title: String,
    startTimestamp: Double,
    endTimestamp: Double,
    allDay: Bool = false,
    location: String? = nil,
    notes: String? = nil
  ) {
    let event = EKEvent(eventStore: self)
    event.calendar = calendar
    event.title = title

    event.startDate = Date(timeIntervalSince1970: startTimestamp)

    if allDay {
      event.endDate = Date(timeIntervalSince1970: endTimestamp - 1)
      event.isAllDay = allDay
    } else {
      event.endDate = Date(timeIntervalSince1970: endTimestamp)
    }

    event.location = location
    event.notes = notes
    events.append(event)
  }

  public override func calendar(withIdentifier: String) -> EKCalendar? {
    return calendarsMap[withIdentifier]
  }

  public override func calendars(for entityType: EKEntityType) -> [EKCalendar] {
    return calendarsMap.values.filter {
      (entityType == .event && $0.allowedEntityTypes == .event)
        || (entityType == .reminder && $0.allowedEntityTypes == .reminder)
    }
  }

  /// - Returns: The `EKAuthorizationStatus` specified by the `eventsAuthorizationStatus` variable.
  public override class func authorizationStatus(for entityType: EKEntityType)
    -> EKAuthorizationStatus
  {
    return eventsAuthorizationStatus
  }

  public override func events(matching predicate: NSPredicate) -> [EKEvent] {
    return events.filter { predicate.evaluate(with: $0) }
  }

  public override func reset() {
    events.removeAll()
    calendarsMap.removeAll()
    Self.eventsAuthorizationStatus = .authorized
  }
}
