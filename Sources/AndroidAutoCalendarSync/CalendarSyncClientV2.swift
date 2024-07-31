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
private import AndroidAutoLogger
internal import AndroidAutoUtils
internal import Foundation
internal import AndroidAutoCalendarSyncProtos

/// Client for the calendar sync companion feature.
///
/// This version syncs the calendars upon connection, configuration and when the local calendar
/// events are modified.
final class CalendarSyncClientV2<Store: EventStore, SettingsStore: PropertyListStore>:
  FeatureManager
{
  private static var log: Logger {
    Logger(for: CalendarSyncClientV2.self)
  }

  private let eventStore: Store

  private var settings: CarCalendarSettings<SettingsStore>

  private var observer: NSObjectProtocol?

  /// Duration over which to sync the calendars.
  private let syncDuration: CalendarSyncDuration

  public override var featureID: UUID {
    return CalendarSyncClientConstants.featureUUID
  }

  @available(*, unavailable)
  override init(connectedCarManager: ConnectedCarManager) {
    fatalError("Use `init(eventStore:connectedCarManager:)` instead.")
  }

  /// Initializes the CalendarSyncClientV2.
  ///
  /// - Parameters:
  ///   - eventStore: The store for fetching user's calendar data.
  ///   - settings: The UserDefaults settings that stores the feature status.
  ///   - connectedCarManager: The manager of cars connecting to the current device.
  init(
    eventStore: Store,
    settings: CarCalendarSettings<SettingsStore>,
    connectedCarManager: ConnectedCarManager,
    syncDuration: CalendarSyncDuration
  ) {
    self.eventStore = eventStore
    self.settings = settings
    self.syncDuration = syncDuration

    super.init(connectedCarManager: connectedCarManager)
    Self.log.info("Init a calendar sync client.")

    startMonitoringCalendarUpdatesOnConnectedCars()
  }

  deinit {
    if let observer {
      NotificationCenter.default.removeObserver(observer)
    }
  }

  /// Notify for every calendar event change on the local phone calendar and send the updates to all
  /// the securely connected cars with calendar feature ON.
  func startMonitoringCalendarUpdatesOnConnectedCars() {
    if let observer {
      NotificationCenter.default.removeObserver(observer)
    }

    observer = NotificationCenter.default.addObserver(
      forName: self.eventStore.observingEventName, object: self.eventStore, queue: .main
    ) { [weak self] notification in
      guard let self else { return }

      Self.log.info("Calendar events changed. Synching calendars with cars.")
      for car in self.securedCars {
        self.syncEnabledCalendars(with: car)
        self.unsyncRemovedCalendars(with: car)
      }
    }

    Self.log.info("Start listening to the notification center.")
  }

  // MARK: - Feature Manager Overrides

  /// For a specific re-connected car, check if its calendar feature is on. If it is, send a
  /// one-time sync from the phone to make car calendar events updated.
  public override func onSecureChannelEstablished(for car: Car) {
    Self.log.info("Secure channel established for car: \(car.logName).")
    syncEnabledCalendars(with: car)
    unsyncRemovedCalendars(with: car)
  }

  // MARK: - Private Implementation

  /// For the specified car, syncs with the car the calendars enabled for it.
  private func syncEnabledCalendars(with car: Car) {
    guard settings[car].isEnabled else {
      Self.log("Requested synching calendar events with car: \(car.logName) but sync is disabled.")
      return
    }

    Self.log("Synching calendar events with car: \(car.logName).")
    do {
      try sync(
        calendars: settings[car].calendarIDs,
        withCar: car.id
      )
    } catch {
      Self.log.error("Error synching calendars to car: \(car), \(error.localizedDescription)")
    }
  }

  /// Compares the calendars that exist the event store with the calendars marked for synching and
  /// unsyncs the calendars that no longer exist in the event store.
  private func unsyncRemovedCalendars(with car: Car) {
    guard settings[car].isEnabled else {
      Self.log(
        "Requested to unsync removed calendars with car: \(car.logName) but sync is disabled.")
      return
    }

    let syncCalendarIDs = settings[car].calendarIDs
    do {
      // Calendar IDs for calendars that exist and are marked for synching.
      let validSyncCalendarIDs = try eventStore.calendars(for: syncCalendarIDs).map {
        $0.calendarIdentifier
      }

      // Sync calendar IDs that don't belong to an existing calendar.
      let removedCalendarIDs = syncCalendarIDs.subtracting(validSyncCalendarIDs)
      guard !removedCalendarIDs.isEmpty else { return }

      Self.log("Unsynching with car: \(car.logName) removed calendars: \(removedCalendarIDs).")
      settings[car].calendarIDs.subtract(removedCalendarIDs)
      try unsync(calendars: removedCalendarIDs, withCar: car.id)
    } catch {
      Self.log.error("Error unsynching calendars with car: \(car), \(error.localizedDescription)")
    }
  }

  /// Sends calendar events for the provided calendars that are in the given time frame over the
  /// provided channel.
  private func sendEvents(
    in calendars: [Store.Calendar],
    over timeRange: Range<Date>,
    to car: Car
  ) throws {
    guard isCarSecurelyConnected(car) else {
      Self.log.error(
        """
        Request to sync to car \(car.logName), but not currently connected. Will sync when it is.
        """
      )
      return
    }

    let events = try fetchEvents(in: calendars, over: timeRange)

    Self.log("Send \(events.count) events over \(calendars.count) calendars.")
    let protoEvents = UpdateCalendarsProto(events: events, in: calendars)
    let data = try protoEvents.serializedData()

    try sendMessage(data, to: car)
  }

  private func fetchEvents(
    in calendars: [Store.Calendar],
    over timeRange: Range<Date>
  ) throws -> [some CalendarEvent] {
    try eventStore.events(
      for: calendars,
      withStart: timeRange.lowerBound,
      end: timeRange.upperBound
    )
  }
}

// MARK: - CalendarSyncClient Conformance

extension CalendarSyncClientV2: CalendarSyncClient {
  // TODO(helenweiyu): consider for real case scenario if a phone should only be actively connected
  // to one car only.

  /// Synchronizes calendar events for the provided calendars that are in the given time frame over
  /// to the specified car.
  ///
  /// - Parameters:
  ///   - calendarIdentifiers: A list of unique calendar identifiers.
  ///   - carID: The identifier of the car with which to sync.
  ///   - start: Time from which to begin filtering events to sync.
  func sync(
    calendars calendarIdentifiers: some Collection<String>,
    withCar carID: String,
    from start: Date
  ) throws {
    guard !calendarIdentifiers.isEmpty else {
      Self.log.error("No calendars provided.")
      return
    }

    let syncTimeRange = try syncDuration.makeTimeRange(from: start)
    Self.log(
      """
      Sync \(calendarIdentifiers.count) calendars with car from: \(syncTimeRange.lowerBound) to \
      \(syncTimeRange.upperBound).
      """
    )

    let calendars = try eventStore.calendars(for: calendarIdentifiers)
    let car = Car(id: carID, name: nil)

    try sendEvents(in: calendars, over: syncTimeRange, to: car)
  }

  /// Un-synchronizes calendars with the provided identifiers from the specified car.
  ///
  /// - Parameters:
  ///   - calendarIdentifiers: A list of unique calendar identifiers.
  ///   - carID: The identifier of the car to unsync calendars.
  func unsync(
    calendars calendarIdentifiers: some Collection<String>,
    withCar carID: String
  ) throws {
    guard !calendarIdentifiers.isEmpty else {
      Self.log.error("No calendar identifiers provided to unsync.")
      return
    }

    // Send as little as possible information to the IHU. To unsync only the unique identifiers of
    // the calendars are required.
    var update = Aae_Calendarsync_UpdateCalendars()
    update.calendars = calendarIdentifiers.reduce(into: []) { calendars, identifier in
      var calendar = Aae_Calendarsync_Calendar()
      calendar.key = identifier
      calendars.append(calendar)
    }

    let car = Car(id: carID, name: nil)

    guard isCarSecurelyConnected(car) else {
      Self.log("Request to unsync calendars from unconnected car \(car.logName). Ignoring.")
      return
    }

    let data = try update.serializedData()
    try sendMessage(data, to: car)
  }
}
