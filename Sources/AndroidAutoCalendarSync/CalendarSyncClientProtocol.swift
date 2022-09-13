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

/// The protocol for the `CalendarSyncClient`.
public protocol CalendarSyncClientProtocol {
  /// Synchronizes calendar events for the provided calendars that are in the given time frame over
  /// to the specified car.
  ///
  /// If `carId` is `nil`, calendar events will be syncrhonized to all cars the client has a
  /// `SecureCarChannel` established with or establishing a `SecureCarChannel` to.
  ///
  /// - Parameters:
  ///   - calendars: List of `EKCalendar` of which events should be sent.
  ///   - carId: The identifier of the car.
  ///   - startDate: The start date of the range of events fetched.
  ///   - endDate: The end date of the range of events fetched.
  func sync(
    calendars: [EKCalendar], forCarId carId: String?, withStart startDate: Date, end endDate: Date)

  /// Un-synchronizes calendars with the provided identifiers from the specified car.
  ///
  /// If `carId` is `nil`, calendar will be un-syncrhonized from all cars the client has a
  /// `SecureCarChannel` established with.
  ///
  /// `EKCalendar` provides a unique identifier through the `calendarIdentifier` instance property,
  /// which should be used here.
  ///
  /// - Parameters:
  ///   - calendarIdentifiers: A list of unique calendar identifiers.
  ///   - carId: The identifier of the car.
  func unsync(calendarIdentifiers: [String], forCarId carId: String?)
}
