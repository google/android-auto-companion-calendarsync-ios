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

internal import AndroidAutoConnectedDeviceManager
public import Foundation

/// The protocol for the `CalendarSyncClient`.
public protocol CalendarSyncClient {
  /// Synchronizes calendar events for the provided calendars starting from now over the client's
  /// sync duration.
  ///
  /// - Parameters:
  ///   - calendars: Identifiers of the calendars to sync.
  ///   - carID: The identifier of the car.
  func sync(calendars: some Collection<String>, withCar carID: String) throws

  /// Synchronizes calendar events for the provided calendars over the client's sync duration.
  ///
  /// - Parameters:
  ///   - calendars: Identifiers of the calendars to sync.
  ///   - carID: The identifier of the car.
  ///   - start: The time beginning which events are synched.
  func sync(calendars: some Collection<String>, withCar carID: String, from start: Date) throws

  /// Un-synchronizes calendars with the provided identifiers with the specified car.
  ///
  /// - Parameters:
  ///   - calendars: Filter of the calendars to unsync.
  ///   - carID: The identifier of the car.
  func unsync(calendars: some Collection<String>, withCar carID: String) throws
}

extension CalendarSyncClient {
  /// Implementation synching events starting from now.
  public func sync(calendars: some Collection<String>, withCar carID: String) throws {
    try sync(calendars: calendars, withCar: carID, from: Date())
  }
}

/// Period over which to filter calendar events to sync.
public enum CalendarSyncDuration {
  /// Number of days to sync.
  case days(Int)

  func makeTimeRange(from start: Date = Date()) throws -> Range<Date> {
    switch self {
    case .days(let numberOfDays):
      guard
        let end = Foundation.Calendar.current.date(
          byAdding: DateComponents(day: numberOfDays),
          to: start
        )
      else {
        throw Error.malformedEndDate
      }
      guard end > start else { throw Error.invalidRange }
      return start..<end
    }
  }
}

extension CalendarSyncDuration {
  public enum Error: Swift.Error {
    /// The constructed end date for the sync range is malformed.
    case malformedEndDate

    /// End date must be strictly greater than start date.
    case invalidRange
  }
}
