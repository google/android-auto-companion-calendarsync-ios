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

/// A wrapper around 'EKCalendarItem' that will make it conform to "CalendarItem".
struct EKCalendarItemWrapper: CalendarItem {
  let calendarItem: EKCalendarItem

  init(calendarItem: EKCalendarItem) {
    self.calendarItem = calendarItem
  }

  var calendar: Calendar! {
    return EKCalendarWrapper(calendar: calendarItem.calendar)
  }

  var title: String! {
    return calendarItem.title
  }

  var location: String? {
    return calendarItem.location
  }

  var creationDate: Date? {
    return calendarItem.creationDate
  }

  var lastModifiedDate: Date? {
    return calendarItem.lastModifiedDate
  }

  var timeZone: TimeZone? {
    return calendarItem.timeZone
  }

  var notes: String? {
    return calendarItem.notes
  }

  var attendees: [Participant]? {
    return calendarItem.attendees?.map { EKParticipantWrapper(participant: $0) }
  }
}
