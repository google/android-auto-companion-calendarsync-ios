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
import AndroidAutoCalendarSyncProtos

/// A calendar item exporter to convert a native iOS calendar item into a proto.
enum CalendarItemExporter {

  static func proto(from calendarItem: CalendarItem) -> Aae_Calendarsync_Event {
    var eventProto = Aae_Calendarsync_Event()

    eventProto.title = calendarItem.title

    if let location = calendarItem.location {
      eventProto.location = location
    }

    if let creationDate = calendarItem.creationDate {
      eventProto.creationDate = CommonExporter.proto(from: creationDate)
    }

    if let lastModifiedDate = calendarItem.lastModifiedDate {
      eventProto.lastModifiedDate = CommonExporter.proto(from: lastModifiedDate)
    }

    if let timeZone = calendarItem.timeZone {
      eventProto.timeZone = CommonExporter.proto(from: timeZone)
    }

    if let notes = calendarItem.notes {
      eventProto.description_p = notes
    }

    if let attendees = calendarItem.attendees {
      eventProto.attendee = ParticipantExporter.proto(from: attendees)
    }

    return eventProto
  }
}
