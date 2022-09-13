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

@_implementationOnly import AndroidAutoCalendarExporter
import AndroidAutoConnectedDeviceManager
@_implementationOnly import AndroidAutoEventKit
@_implementationOnly import AndroidAutoEventKitProtocol
import EventKit
import os.log
@_implementationOnly import AndroidAutoCalendarSyncProtos

/// Client for the calendar sync companion feature.
///
/// Calling the `sync` method will observe a secure channel from the `ConnectedCarManager` and send
/// the events for the provided calendar(s) that are within a given timeframe over to the specified
/// car.
///
/// Sample usage:
///
/// ```
/// let calendarSyncClient = CalendarSyncClient(
///   eventStore: EKEventStore(),
///   connectedCarManager: connectionManager
/// )
///
/// let ekCalendars = eventStore.calendars(for: .event).filter { ... }
/// let startDate = Date()
/// let endDate =
///   Calendar.current.date(byAdding: DateComponents(day: daysToSync), to: startDate)!
///
/// calendarSyncClient.sync(
///   calendars: ekCalendars, forCarId: carId, withStart: startDate, end: endDate)
/// ```
///
/// Calling the `unsync` method will cause the removal of the provided calendar identifiers from
/// the specified car.
///
/// Sample usage of `unsync`:
///
/// ```
/// let calendarIdentifiers = ekCalendars.map { $0.calendarIdentifier }
/// calendarSyncClient.unsync(calendarIdentifiers: calendarIdentifiers, forCarId: carId)
/// ```
///
/// If `nil` is provided as car identifier for `sync` or `unsync` the client will use all cars that
/// have a secure channel established rather than just a single specific car.
public final class CalendarSyncClient: FeatureManager, CalendarSyncClientProtocol {

  /// `Error` thrown by CalendarSyncClient to communicate failures back to the client.
  public enum CalendarSyncClientError: Error {
    /// User did not grant permission to use calendar.
    case notAuthorized
  }

  private static let log = OSLog(
    subsystem: "com.google.ios.aae.calendarsync",
    category: "CalendarSyncClient"
  )

  private static let featureUUID = UUID(uuidString: "5a1a16fd-1ebd-4dbe-bfa7-37e40de0fd80")!

  private let eventStore: EKEventStore

  /// Map of cars to the data that should be synced for them.
  ///
  /// These calendars are stored so that when a car disconnects and reconnects, the data would be
  /// resynced. Note that each car is mapped to a list of data to sync as each calendar to be
  /// synced can have a unique start/end time.
  private var dataToSync: [Car: [SyncData]] = [:]

  public override var featureID: UUID {
    return Self.featureUUID
  }

  @available(*, unavailable)
  public override init(connectedCarManager: ConnectedCarManager) {
    fatalError("Use `init(eventStore:connectedCarManager:)` instead.")
  }

  /// Initializes the CalendarSyncClient.
  ///
  /// - Parameters:
  ///   - eventStore: The store for fetching user's calendar data.
  ///   - connectedCarManager: The manager of cars connecting to the current device.
  public init(eventStore: EKEventStore, connectedCarManager: ConnectedCarManager) {
    self.eventStore = eventStore
    super.init(connectedCarManager: connectedCarManager)
  }

  /// Synchronizes calendar events for the provided calendars that are in the given time frame over
  /// to the specified car.
  ///
  /// If `carId` is `nil` calendar events will be synchronized to all cars the client has a
  /// `SecureCarChannel` established with or establishing a `SecureCarChannel` to.
  ///
  /// - Parameters:
  ///   - calendars: List of `EKCalendar` of which events should be sent.
  ///   - carId: The identifier of the car or `nil` to sync all all connected cars.
  ///   - startDate: The start date of the range of events fetched.
  ///   - endDate: The end date of the range of events fetched.
  public func sync(
    calendars: [EKCalendar], forCarId carId: String?, withStart startDate: Date,
    end endDate: Date
  ) {
    guard calendars.count > 0 else {
      os_log("No calendars provided", log: CalendarSyncClient.log, type: .error)
      return
    }

    guard startDate < endDate else {
      os_log("startDate is after endDate", log: CalendarSyncClient.log, type: .error)
      return
    }

    // Either sync the car specified or all connected cars.
    let carsToSync = carId != nil ? [Car(id: carId!, name: nil)] : securedCars

    for car in carsToSync {
      let syncData = SyncData(calendars: calendars, startDate: startDate, endDate: endDate)

      // Save the calendar data so that a sync occurs if the car reconnects.
      if let existingSyncData = dataToSync[car] {
        dataToSync[car] = mergeSyncData(syncData, into: existingSyncData)
      } else {
        dataToSync[car] = [syncData]
      }

      do {
        try send(calendars: calendars, withStart: startDate, end: endDate, to: car)
      } catch {
        os_log(
          "Encountered error syncing calendars to car %@: %@",
          log: Self.log,
          car.name ?? car.id,
          error.localizedDescription)
      }
    }
  }

  /// Merges the given `syncData` into the given list of `SyncData`s.
  ///
  /// The `syncData` is either merged into one of the `SyncData`s in the list if it has the
  /// same start/end time as one of them, or it is appended to the end of list if it does not.
  ///
  /// - Returns: A  list containing the merging of the given `syncData`.
  private func mergeSyncData(_ syncData: SyncData, into syncDatas: [SyncData]) -> [SyncData] {
    for existingSyncData in syncDatas {
      if existingSyncData.hasSameTimeInterval(as: syncData) {
        existingSyncData.mergeCalendars(from: syncData)
        return syncDatas
      }
    }

    // Returning a new list since `syncDatas` is a `let` constant due to it being an argument.
    return syncDatas + [syncData]
  }

  /// Un-synchronizes calendars with the provided identifiers from the specified car.
  ///
  /// If `carId` is `nil`, calendar will be un-synchronized from all cars the client has a
  /// `SecureCarChannel` established with.
  ///
  /// `EKCalendar` provides a unique identifier through the `calendarIdentifier` instance property,
  /// which should be used here.
  ///
  /// - Parameters:
  ///   - calendarIdentifiers: A list of unique calendar identifiers.
  ///   - carId: The identifier of the car or `nil` to unsync calendars from all connected cars.
  public func unsync(calendarIdentifiers: [String], forCarId carId: String?) {
    guard calendarIdentifiers.count > 0 else {
      os_log("No calendar identifiers provided", log: CalendarSyncClient.log, type: .error)
      return
    }

    // Send as little as possible information to the IHU. To unsync only the unique identifiers of
    // the calendars are required.
    var calendarsProto = Aae_Calendarsync_Calendars()
    calendarsProto.calendar.append(
      contentsOf: calendarIdentifiers.map { (element) -> Aae_Calendarsync_Calendar in
        var calendar = Aae_Calendarsync_Calendar()
        calendar.uuid = element
        return calendar
      })

    // Only unsynchronize connected cars. Without a connection there can't be synchronized
    // calendars. On disconnect, calendars are automatically deleted on the IHU.
    let carsToUnsync = carId != nil ? [Car(id: carId!, name: nil)] : securedCars

    for car in carsToUnsync {
      // Remove matching calendars so they will not be synced later.
      dataToSync[car] = dataToSync[car]?.filter { syncData in
        syncData.removeAllCalendars(withIdentifiers: calendarIdentifiers)
        // Completely remove the `SyncData` object if there are no more calendars to sync.
        return !syncData.calendars.isEmpty
      }

      guard isCarSecurelyConnected(car) else {
        os_log(
          "Request to unsync calendars from unconnected car %@. Ignoring.",
          log: Self.log,
          car.name ?? car.id)
        continue
      }

      do {
        let data = try calendarsProto.serializedData()
        try sendMessage(data, to: car)
      } catch {
        os_log(
          "Failed to unsync calendars. Error: %@", log: CalendarSyncClient.log, type: .error,
          "\(error)")
      }
    }
  }

  // MARK: - Event methods

  public override func onSecureChannelEstablished(for car: Car) {
    guard let syncDatas = dataToSync[car] else {
      os_log(
        "Car %@ connected, but no stored calendar sync for that car. Ignoring.",
        log: Self.log,
        type: .debug,
        car.name ?? car.id)
      return
    }

    os_log(
      "Secure channel established for car %@. Syncing stored calendar data.",
      log: Self.log,
      car.name ?? car.id)

    do {
      for syncData in syncDatas {
        try send(
          calendars: syncData.calendars,
          withStart: syncData.startDate,
          end: syncData.endDate,
          to: car)
      }
    } catch {
      os_log(
        "Encountered an error sending message to car %@: %@",
        log: Self.log,
        type: .error,
        car.name ?? car.id,
        error.localizedDescription)
    }
  }

  public override func onCarDisassociated(_ car: Car) {
    dataToSync[car] = nil
  }

  /// Sends calendar events for the provided calendars that are in the given time frame over the
  /// provided channel.
  private func send(
    calendars: [EKCalendar],
    withStart startDate: Date,
    end endDate: Date,
    to car: Car
  ) throws {
    guard isCarSecurelyConnected(car) else {
      os_log(
        "Request to sync to car %@, but not currently connected. Will sync when it is.",
        log: CalendarSyncClient.log,
        car.name ?? car.id)
      return
    }

    let eventsList = try eventStore.events(for: calendars, withStart: startDate, end: endDate)
    guard eventsList.count > 0 else {
      os_log("No events to send", log: CalendarSyncClient.log, type: .debug)
      return
    }

    let protoEvents = EventsExporter.proto(from: eventsList)
    let data = try protoEvents.serializedData()

    try sendMessage(data, to: car)
  }
}

extension EKEventStore {
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
  fileprivate func events(for calendars: [EKCalendar], withStart startDate: Date, end endDate: Date)
    throws
    -> [CalendarEvent]
  {
    let authorizationStatus = Self.authorizationStatus(for: .event)
    guard authorizationStatus == .authorized else {
      throw CalendarSyncClient.CalendarSyncClientError.notAuthorized
    }

    let predicate = predicateForEvents(
      withStart: startDate, end: endDate, calendars: calendars)
    return events(matching: predicate).map { EKEventWrapper(event: $0) }
  }
}

/// Encapsulates all the data required to sync a list of calendars to a car.
// Note: using a class instead of `struct` to make mutating functions easier to manage when
// syncing and unsyncing calendar data. If concurrency becomes an issue, might need to switch
// this to a struct.
private class SyncData {
  private(set) var calendars: [EKCalendar]
  let startDate: Date
  let endDate: Date

  init(calendars: [EKCalendar], startDate: Date, endDate: Date) {
    self.calendars = calendars
    self.startDate = startDate
    self.endDate = endDate
  }

  /// Returns `true` if this `SyncData` has the same start and end date as the specified
  /// `syncData`.
  func hasSameTimeInterval(as syncData: SyncData) -> Bool {
    return startDate == syncData.startDate && endDate == syncData.endDate
  }

  /// Takes the calendars from the given `syncData` and merges them with the calendars in this
  /// `SyncData`.
  ///
  /// Any duplicate entries will be consolidated. The ordering of the calendars is not preserved
  /// after this merge.
  func mergeCalendars(from syncData: SyncData) {
    // Using a `Set` to remove any possible duplicates.
    calendars = Array(Set(calendars + syncData.calendars))
  }

  /// Removes any calendars whose identifier is contained within the list of identifiers.
  func removeAllCalendars(withIdentifiers identifiers: [String]) {
    // The lists of calendars are usually small (< 10), so this `contains` should be
    // negligible. If the calendar list grows, using a Set should be considered.
    calendars.removeAll(where: { identifiers.contains($0.calendarIdentifier) })
  }
}
