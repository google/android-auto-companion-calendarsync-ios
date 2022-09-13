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

/// A wrapper around a 'EKEvent' that will make it conform to 'Event'.
public struct EKEventWrapper: CalendarEvent {
  let event: EKEvent

  public init(event: EKEvent) {
    self.event = event
  }

  public var eventIdentifier: String! {
    return event.eventIdentifier
  }

  public var startDate: Date! {
    return event.startDate
  }

  public var endDate: Date! {
    return event.endDate
  }

  public var isAllDay: Bool {
    return event.isAllDay
  }

  public var organizer: Participant? {
    guard let organizer = event.organizer else {
      return nil
    }
    return EKParticipantWrapper(participant: organizer)
  }

  public var status: EKEventStatus {
    return event.status
  }

  public var calendar: Calendar! {
    return EKCalendarWrapper(calendar: event.calendar)
  }

  public var title: String! {
    return event.title
  }

  public var location: String? {
    return event.location
  }

  public var creationDate: Date? {
    return event.creationDate
  }

  public var lastModifiedDate: Date? {
    return event.lastModifiedDate
  }

  public var timeZone: TimeZone? {
    return event.timeZone
  }

  public var notes: String? {
    return event.notes
  }

  public var attendees: [Participant]? {
    return event.attendees?.map { EKParticipantWrapper(participant: $0) }
  }
}
