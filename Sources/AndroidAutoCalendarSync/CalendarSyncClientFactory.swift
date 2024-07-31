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

public import AndroidAutoConnectedDeviceManager
public import AndroidAutoUtils
public import EventKit
internal import Foundation

/// Factory for making calendar sync clients.
@MainActor
public enum CalendarSyncClientFactory {
  /// Sync calendars to cars.
  case v2

  /// Make a client with the specified configuration.
  ///
  /// - Parameters:
  ///   - settings: Determines which calendars are enabled for each car.
  ///   - eventStore: The local store of calendar events.
  ///   - connectedCarManager: The manager with the connected cars.
  ///   - syncDuration: The period of calendar events to sync.
  /// - Returns: The created client.
  public func makeClient(
    settings: CarCalendarSettings<UserDefaultsPropertyListStore>,
    eventStore: EKEventStore,
    connectedCarManager connectionManager: ConnectedCarManager,
    syncDuration: CalendarSyncDuration
  ) -> any CalendarSyncClient {
    switch self {
    case .v2:
      return CalendarSyncClientV2(
        eventStore: eventStore,
        settings: settings,
        connectedCarManager: connectionManager,
        syncDuration: syncDuration
      )
    }
  }
}
