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

import AndroidAutoLogger
import Foundation
@_implementationOnly import AndroidAutoCalendarSyncProtos

typealias UpdateCalendarsProto = Aae_Calendarsync_UpdateCalendars

extension UpdateCalendarsProto {
  private var log: Logger { Logger(for: UpdateCalendarsProto.self) }

  init(
    events: [some CalendarEvent],
    in calendars: some Collection<some AndroidAutoCalendarSync.Calendar>
  ) {
    self.init()

    version = 1
    type = UpdateCalendarsProto.TypeEnum.receive

    // Include all calendars to sync including those with no events.
    var calendarProtosByID: [String: CalendarProto] = calendars.reduce(into: [:]) {
      protos, calendar in
      protos[calendar.calendarIdentifier] = CalendarProto(calendar)
    }

    log("Generating proto from \(events.count) events.")
    for event in events {
      let eventTitle = event.title ?? "<none>"
      guard let calendar = event.calendar else {
        log.error("Skipping event \(eventTitle) because it isn't associated with a calendar.")
        continue
      }

      log.debug("Exporting event: \(eventTitle) in calendar: \(calendar.title)")

      var calendarProto = calendarProtosByID[calendar.calendarIdentifier] ?? CalendarProto(calendar)
      calendarProto.events.append(CalendarEventProto(event))
      if calendarProto.hasRange {
        let rangeStart = Date(timeIntervalSince1970: Double(calendarProto.range.from.seconds))
        let rangeEnd = Date(timeIntervalSince1970: Double(calendarProto.range.to.seconds))
        if rangeStart > event.startDate {
          calendarProto.range.from = TimestampProto(event.startDate)
        }
        if rangeEnd < event.endDate {
          calendarProto.range.to = TimestampProto(event.endDate)
        }
      } else {
        calendarProto.range.from = TimestampProto(event.startDate)
        calendarProto.range.to = TimestampProto(event.endDate)
      }
      calendarProtosByID[calendar.calendarIdentifier] = calendarProto
    }

    for value in calendarProtosByID.values {
      self.calendars.append(value)
    }
  }
}
