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

import Foundation
@_implementationOnly import AndroidAutoCalendarSyncProtos

typealias CalendarEventProto = Aae_Calendarsync_Event

extension CalendarEventProto {
  init(item: some CalendarItem) {
    self.init()

    title = item.title

    if let location = item.location {
      self.location = location
    }

    if let timeZone = item.timeZone {
      self.timeZone = TimeZoneProto(timeZone)
    }

    if let notes = item.notes {
      self.description_p = notes
    }

    if let participants = item.attendees {
      self.attendees = AttendeeProto.makeAttendees(participants)
    }
  }

  init(_ event: some CalendarEvent) {
    self.init(item: event)

    key = event.eventID

    if event.timeZone != nil {
      beginTime = TimestampProto(event.startDate)
      endTime = TimestampProto(event.endDate)
    } else {
      // When timeZone is nil, startDate and endDate are floating according to local time,
      // so make it a UTC time here.
      let localTimeZone = TimeZone.current
      var timeInterval = TimeInterval(localTimeZone.secondsFromGMT(for: event.startDate))
      let startDate = event.startDate.addingTimeInterval(timeInterval)
      beginTime = TimestampProto(startDate)

      if event.isAllDay {
        // For all day events, iOS has a default end time as 23:59:59, which does not fit Android's
        // calendar schema (hour, minute and second must all be zero). So round up 1 second to fit.
        timeInterval =
          TimeInterval(localTimeZone.secondsFromGMT(for: event.endDate)) + TimeInterval(1)
      } else {
        timeInterval = TimeInterval(localTimeZone.secondsFromGMT(for: event.endDate))
      }
      let endDate = event.endDate.addingTimeInterval(timeInterval)
      endTime = TimestampProto(endDate)
    }

    isAllDay = event.isAllDay

    if let organizer = event.organizer?.name {
      self.organizer = organizer
    }

    status = Aae_Calendarsync_Event.Status(event.eventStatus)
  }
}

extension CalendarEventProto.Status {
  init(_ status: EventStatus) {
    switch status {
    case .confirmed:
      self = .confirmed
    case .tentative:
      self = .tentative
    case .canceled:
      self = .canceled
    case .none:
      // Ignore for now.
      fallthrough
    @unknown default:
      self = .unspecifiedStatus
    }
  }
}
