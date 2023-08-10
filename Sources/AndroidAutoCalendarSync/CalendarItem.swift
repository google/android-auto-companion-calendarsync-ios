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

// The protocol of a calendar item.
public protocol CalendarItem {
  associatedtype ItemCalendar: AndroidAutoCalendarSync.Calendar
  associatedtype ItemParticipant: Participant

  /// The calendar for the calendar item.
  var calendar: ItemCalendar! { get }

  /// The title for the calendar item.
  var title: String! { get }

  /// The location associated with the calendar item.
  var location: String? { get }

  /// The date that this calendar item iwas created.
  var creationDate: Date? { get }

  /// The date that the calendar item was last modified.
  var lastModifiedDate: Date? { get }

  /// The time zone for the calendar item.
  var timeZone: TimeZone? { get }

  /// The notes associated with the calendar item.
  var notes: String? { get }

  /// The attendees associated with the calendar item.
  var attendees: [ItemParticipant]? { get }
}
