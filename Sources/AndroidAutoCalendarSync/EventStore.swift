// Copyright 2023 Google LLC
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

/// The protocol of an eventStore.
public protocol EventStore {
  associatedtype Event: CalendarEvent
  associatedtype Calendar: AndroidAutoCalendarSync.Calendar

  /// Indicates whether the user has authorized access to the store for the current process.
  static var isAuthorized: Bool { get }

  /// Convenience to get the authorization status from the instance.
  var isAuthorized: Bool { get }

  /// Notification name to observe for store changes.
  var observingEventName: NSNotification.Name { get }

  /// The calendars associated with the specified identifiers.
  ///
  /// - Parameter calendarIdentifiers: The identifiers for the calendars to fetch.
  /// - Returns: The corresponding calendars.
  /// - Throws: An error if authorization to this store is not granted.
  func calendars(for calendarIdentifiers: some Collection<String>) throws -> [Calendar]

  func events(
    for calendars: [Calendar],
    withStart startDate: Date,
    end endDate: Date
  ) throws -> [Event]
}

extension EventStore {
  public var isAuthorized: Bool { Self.isAuthorized }
}
