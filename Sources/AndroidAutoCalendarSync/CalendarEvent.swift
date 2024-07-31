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

public import Foundation

/// The protocol of a calendar event.
public protocol CalendarEvent: CalendarItem {
  /// A unique identifier for the event.
  var eventID: String { get }

  /// The start date of the event.
  var startDate: Date! { get }

  /// The end date of the event.
  var endDate: Date! { get }

  /// A Boolean value that indicates whether the event is an all-day event.
  var isAllDay: Bool { get }

  /// The organizer associated with the event.
  var organizer: ItemParticipant? { get }

  /// The status of the event.
  var eventStatus: EventStatus { get }
}
