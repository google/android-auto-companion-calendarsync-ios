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
import AndroidAutoLogger
import EventKit
import UIKit
import AndroidAutoCalendarSyncProtos

public typealias ProtocolCalendar = AndroidAutoEventKitProtocol.Calendar

/// An event exporter to convert native iOS events into protos.
public enum EventsExporter {
  private static let log = Logger(for: EventsExporter.self)

  public static func proto(from events: [CalendarEvent]) -> Aae_Calendarsync_Calendars {
    var calendars: [String: Aae_Calendarsync_Calendar] = [:]

    for event in events {
      if let calendar = event.calendar {
        var calendarProto = calendars[calendar.calendarIdentifier] ?? proto(from: calendar)
        calendarProto.event.append(proto(from: event))
        calendars[calendar.calendarIdentifier] = calendarProto
      }
    }
    var calendarsProto = Aae_Calendarsync_Calendars()
    for value in calendars.values {
      calendarsProto.calendar.append(value)
    }
    return calendarsProto
  }

  static func proto(from calendar: ProtocolCalendar) -> Aae_Calendarsync_Calendar {
    var calendarProto = Aae_Calendarsync_Calendar()
    calendarProto.title = calendar.title
    calendarProto.uuid = calendar.calendarIdentifier
    calendarProto.color = CommonExporter.proto(from: calendar.cgColor)
    return calendarProto
  }

  static func proto(from event: CalendarEvent) -> Aae_Calendarsync_Event {
    var eventProto = CalendarItemExporter.proto(from: event)

    if let eventIdentifier = event.eventIdentifier {
      // TODO(b/146420937): Fix that the eventIdentifier is set when using `MockEventStore`.
      eventProto.externalIdentifier = eventIdentifier
    }

    if event.timeZone != nil {
      eventProto.startDate = CommonExporter.proto(from: event.startDate)
      eventProto.endDate = CommonExporter.proto(from: event.endDate)
    } else {
      // When timeZone is nil, startDate and endDate are floating according to local time,
      // so make it a UTC time here.
      let localTimeZone = TimeZone.current
      var timeInterval = TimeInterval(localTimeZone.secondsFromGMT(for: event.startDate))
      let startDate = event.startDate.addingTimeInterval(timeInterval)
      eventProto.startDate = CommonExporter.proto(from: startDate)

      timeInterval = TimeInterval(localTimeZone.secondsFromGMT(for: event.endDate))
      let endDate = event.endDate.addingTimeInterval(timeInterval)
      eventProto.endDate = CommonExporter.proto(from: endDate)
    }

    eventProto.isAllDay = event.isAllDay

    if let organizer = event.organizer?.name {
      eventProto.organizer = organizer
    }

    eventProto.status = convert(from: event.status)

    return eventProto
  }

  static func convert(from status: EKEventStatus) -> Aae_Calendarsync_Event.Status {
    switch status {
    case .confirmed:
      return .confirmed
    case .tentative:
      return .tentative
    case .canceled:
      return .canceled
    case .none:
      // Ignore for now.
      fallthrough
    @unknown default:
      Self.log.error("Unhandled EKEventStatus value \(status.rawValue).")
      return .unspecifiedStatus
    }
  }
}
