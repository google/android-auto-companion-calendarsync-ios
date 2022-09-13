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

import AndroidAutoEventKitProtocol
import EventKit
import Foundation

/// A mock calendar event.
public struct MockCalendarEvent: CalendarEvent {
  public var eventIdentifier: String!
  public var startDate: Date!
  public var endDate: Date!
  public var isAllDay: Bool
  public var organizer: Participant?
  public var status: EKEventStatus

  public var calendar: ProtocolCalendar!
  public var title: String!
  public var location: String?
  public var creationDate: Date?
  public var lastModifiedDate: Date?
  public var timeZone: TimeZone?
  public var notes: String?
  public var attendees: [Participant]?

  public init(
    eventIdentifier: String!, startDate: Date!, endDate: Date!, isAllDay: Bool = false,
    organizer: Participant? = nil, status: EKEventStatus = .none, calendar: ProtocolCalendar!,
    title: String!, location: String? = nil, creationDate: Date? = nil,
    lastModifiedDate: Date? = nil, timeZone: TimeZone? = nil, notes: String? = nil,
    attendees: [Participant]? = nil
  ) {
    self.eventIdentifier = eventIdentifier
    self.startDate = startDate
    self.endDate = endDate
    self.isAllDay = isAllDay
    self.organizer = organizer
    self.status = status

    self.calendar = calendar
    self.title = title
    self.location = location
    self.creationDate = creationDate
    self.lastModifiedDate = lastModifiedDate
    self.timeZone = timeZone
    self.notes = notes
    self.attendees = attendees
  }
}
