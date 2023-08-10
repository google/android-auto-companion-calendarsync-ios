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
import Foundation

/// A mock calendar event.
struct MockCalendarEvent: CalendarEvent {
  var eventID: String
  var startDate: Date!
  var endDate: Date!
  var isAllDay: Bool
  var organizer: MockParticipant?
  var eventStatus: EventStatus
  var calendar: MockCalendar!

  var title: String!
  var location: String?
  var creationDate: Date?
  var lastModifiedDate: Date?
  var timeZone: TimeZone?
  var notes: String?
  var attendees: [MockParticipant]?

  init(
    eventID: String, startDate: Date, endDate: Date, isAllDay: Bool = false,
    organizer: MockParticipant? = nil, status: EventStatus = .none, calendar: MockCalendar,
    title: String!, location: String? = nil, creationDate: Date? = nil,
    lastModifiedDate: Date? = nil, timeZone: TimeZone? = nil, notes: String? = nil,
    attendees: [MockParticipant]? = nil
  ) {
    self.eventID = eventID
    self.startDate = startDate
    self.endDate = endDate
    self.isAllDay = isAllDay
    self.organizer = organizer
    self.eventStatus = status
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
