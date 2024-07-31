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
public import Foundation

// MARK: - CalendarConfig Core

/// Store of Calendar Sync configuration settings for a particular car.
public struct CalendarConfig {
  /// Indicates whether Calendar Sync is enabled for the car.
  public var isEnabled: Bool = false

  /// The calendar identifiers of the calendars to sync with the car.
  public var calendarIDs: Set<String> = []
}

// MARK: - PropertyListConvertible

extension CalendarConfig: PropertyListConvertible {
  private enum Key {
    static let isEnabled = "isEnabled"
    static let calendarIDs = "calendarIDs"
  }

  /// Construct the build number from an array of `major`, `minor`, `patch`.
  public init(primitive: [String: Any]) throws {
    isEnabled = primitive[Key.isEnabled] as? Bool ?? false
    calendarIDs = Set(primitive[Key.calendarIDs] as? [String] ?? [])
  }

  /// Represent this calendar config as a dictionary.
  public func makePropertyListPrimitive() -> [String: Any] {
    return [
      Key.isEnabled: isEnabled,
      Key.calendarIDs: calendarIDs.makePropertyListPrimitive(),
    ]
  }
}

// MARK: - CalendarConfig Conformance to CustomStringConvertible

extension CalendarConfig: CustomStringConvertible {
  public var description: String {
    "isEnabled: \(isEnabled), calendarIDs: \(calendarIDs)"
  }
}

// MARK: - CarCalendarSettings

/// Store and fetch of data by the associated key.
public struct CarCalendarSettings<Store: PropertyListStore> {
  private var store: Store

  public init(_ store: Store) {
    self.store = store
  }

  public init(_ defaults: UserDefaults) where Store == UserDefaultsPropertyListStore {
    self.init(UserDefaultsPropertyListStore(defaults))
  }

  /// Remove the Calendar Sync settings for the specific car.
  ///
  /// - Parameter carID: The identifier of the car for which to remove the settings.
  public mutating func remove(_ carID: String) {
    let carRootKey = rootKey(car: carID)
    store.removeValue(forKey: carRootKey)
  }

  /// Remove the Calendar Sync settings for the specified car.
  ///
  /// - Parameter car: The car for which to remove the settings.
  public mutating func remove(_ car: Car) {
    remove(car.id)
  }

  /// Get/Set the calendar sync configuration for the specified car.
  ///
  /// - Parameter carID: The identifier of the car for which to get/set the configuration.
  public subscript(carID: String) -> CalendarConfig {
    get {
      let carRootKey = rootKey(car: carID)
      return store[carRootKey, default: CalendarConfig()]
    }

    set {
      let carRootKey = rootKey(car: carID)
      store[carRootKey] = newValue
    }
  }

  /// Get/Set the calendar sync configuration for the specified car.
  ///
  /// - Parameter car: The car for which to get/set the configuration.
  public subscript(car: Car) -> CalendarConfig {
    get { self[car.id] }
    set { self[car.id] = newValue }
  }

  /// Root key for storing a car's settings.
  private func rootKey(car carID: String) -> String {
    "com.google.CalendarSync.\(carID)"
  }
}
