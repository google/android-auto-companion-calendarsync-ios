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

public import EventKit
public import Foundation

// MARK: - EKEvent conformance to CalendarEvent
extension EKEvent: CalendarEvent {
  private enum RecurrenceType: String {
    // LINT.IfChange
    case single = "S"
    case recurring = "R"
    case detached = "X"
    // LINT.ThenChange(//depot/google3/third_party/java_src/android_libs/connecteddevice/java/com/google/android/connecteddevice/calendarsync/android/EventContentDelegate.java)
  }

  public var eventID: String {
    // Here we are using hashValue to convert iPhone UUID to long type to be compatible with
    // Android calendar event ID, which is in long type. However, since the UUID is 128 bits and the
    // long type is 64 bits, there is a risk of collisions. Since we are only syncing a few days
    // rather than the whole calendar, the possibility of collision is very low. We may need to
    // think of other ways if the possibility becomes higher.
    let hashValue = self.eventIdentifier.hashValue
    let recurrenceCode: RecurrenceType
    let startTime: Date
    if hasRecurrenceRules {
      recurrenceCode = .recurring
      startTime = occurrenceDate
    } else if isDetached {
      recurrenceCode = .detached
      startTime = startDate
    } else {
      // Start time is unused in the event ID for a single event so just assign distant past.
      startTime = .distantPast
      recurrenceCode = .single
    }

    if case .single = recurrenceCode {
      return "\(recurrenceCode.rawValue):\(hashValue)"
    } else {
      return
        "\(recurrenceCode.rawValue):\(hashValue):\(Int64(startTime.timeIntervalSince1970 * 1000))"
    }
  }

  /// EventStatus corresponding to the event's EKEventStatus.
  public var eventStatus: EventStatus {
    EventStatus(status)
  }
}

// MARK: - EventStatus from EKEventStatus
extension EventStatus {
  public init(_ status: EKEventStatus) {
    switch status {
    case .none:
      self = .none
    case .confirmed:
      self = .confirmed
    case .tentative:
      self = .tentative
    case .canceled:
      self = .canceled
    @unknown default:
      self = .none
    }
  }
}

// MARK: - EKCalendar conformance to AndroidAutoCalendarSync.Calendar
extension EKCalendar: AndroidAutoCalendarSync.Calendar {}

// MARK: - EKCalendarItem conformance to CalendarItem
extension EKCalendarItem: CalendarItem {}

// MARK: - EKParticipant conformance to Participant
extension EKParticipant: Participant {
  public var status: ParticipantStatus {
    ParticipantStatus(participantStatus)
  }

  public var type: ParticipantType {
    ParticipantType(participantType, role: participantRole)
  }
}

// MARK: - ParticipantStatus from EKParticipantStatus
extension ParticipantStatus {
  public init(_ status: EKParticipantStatus) {
    switch status {
    case .accepted:
      self = .accepted
    case .declined:
      self = .declined
    case .pending:
      self = .invited
    case .tentative:
      self = .tentative
    case .unknown:
      self = .none
    case .delegated, .completed, .inProcess:
      self = .unspecified
    @unknown default:
      self = .unspecified
    }
  }
}

// MARK: - ParticipantType from EKParticipantType and EKParticipantRole
extension ParticipantType {
  public init(_ type: EKParticipantType, role: EKParticipantRole) {
    switch role {
    case .optional:
      self = .optional
    case .required, .chair:
      self = .required
    case .unknown, .nonParticipant:
      switch type {
      case .resource, .room:
        self = .resource
      default:
        self = .none
      }
    @unknown default:
      self = .unspecified
    }
  }
}

// MARK: - EKEventStore conformance to EventStore
extension EKEventStore: EventStore {
  enum EKEventStoreError: Error {
    /// User did not grant permission to use calendar.
    case notAuthorized
  }

  /// True if calendar access permission are granted, otherwise false.
  static public var isAuthorized: Bool {
    let authorizationStatus = authorizationStatus(for: .event)
    return authorizationStatus == .authorized
  }

  public var observingEventName: NSNotification.Name {
    NSNotification.Name.EKEventStoreChanged
  }

  /// Retrieves all calendars.
  ///
  /// Checks the `EKAuthorizationStatus` before calendars are retriieved and throws an error if
  /// calendar access is not granted.
  ///
  /// - Throws: `EKEventStoreError` if permission to access calendar data is not given.
  public func calendars() throws -> [EKCalendar] {
    guard Self.isAuthorized else { throw EKEventStoreError.notAuthorized }
    return calendars(for: .event)
  }

  /// Retrieves all calandars for the given identifiers.
  ///
  /// Checks the `EKAuthorizationStatus` before calendars are retriieved and throws an error if
  /// calendar access is not granted.
  ///
  /// - Throws: `EKEventStoreError` if permission to access calendar data is not given.
  public func calendars(for calendarIdentifiers: some Collection<String>) throws -> [EKCalendar] {
    return try calendars().filter { calendarIdentifiers.contains($0.calendarIdentifier) }
  }

  /// Retrieves all events for the provided calendars that are within the provided date range.
  ///
  /// Checks the `EKAuthorizationStatus` before events are retrieved and throws an error if
  /// calendar access is not granted.
  ///
  /// - Parameters:
  ///   - calendars: List of `EKCalendar` of which events should be sent.
  ///   - startDate: The start date of the range of events fetched.
  ///   - endDate: The end date of the range of events fetched.
  /// - Returns: A list of matching `CalendarEvent` objects.
  /// - Throws: `CalendarSyncClientError` if permission to access calendar data is not given.
  public func events(
    for calendars: [EKCalendar],
    withStart startDate: Date,
    end endDate: Date
  ) throws -> [EKEvent] {
    let authorizationStatus = Self.authorizationStatus(for: .event)
    guard authorizationStatus == .authorized else {
      throw CalendarSyncClientError.notAuthorized
    }

    let predicate = predicateForEvents(
      withStart: startDate, end: endDate, calendars: calendars)
    return events(matching: predicate)
  }
}
