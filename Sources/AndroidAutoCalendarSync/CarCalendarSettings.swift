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

import AndroidAutoConnectedDeviceManager
import Foundation

/// Marks types that can be stored in `UserDefaults`.
public protocol KeyValuePrimitive {}

extension Bool: KeyValuePrimitive {}
extension Int: KeyValuePrimitive {}
extension String: KeyValuePrimitive {}
extension Array: KeyValuePrimitive where Element == any KeyValuePrimitive {}
extension Dictionary: KeyValuePrimitive where Key == String, Value == any KeyValuePrimitive {}

/// A compound type that can be converted to and from a primitive.
private protocol KeyValuePrimitiveConvertible {
  associatedtype Primitive: KeyValuePrimitive

  /// The primitive that represents the compound type in storage.
  var primitive: Primitive { get }

  /// Construct the compound type from the primitives.
  ///
  /// Note that we take `Any` here because `UserDefaults` unfortunately uses internal types that
  /// don't conform to `KeyValuePrimitive`.
  init(primitive: Any)
}

/// Provides for primitive storage based on `UserDefaults` and storage for compound types.
public protocol KeyValueStore: AnyObject {
  /// Get the stored object for the specified key.
  func object(forKey: String) -> Any?

  /// Store the object with the specified key.
  func set(_: Any?, forKey: String)
}

// MARK: - KeyValueStore Additions

extension KeyValueStore {
  /// Access and set primitive convertible values by key in the store.
  fileprivate subscript<T: KeyValuePrimitiveConvertible>(key: String) -> T? {
    get {
      guard let rawValue = object(forKey: key) else { return nil }
      return T.init(primitive: rawValue)
    }

    set {
      set(newValue?.primitive, forKey: key)
    }
  }
}

// MARK: - UserDefaults Conformance to KeyValueStore

extension UserDefaults: KeyValueStore {}

// MARK: - CalendarConfig Core

/// Store of Calendar Sync configuration settings for a particular car.
public struct CalendarConfig {
  /// Indicates whether Calendar Sync is enabled for the car.
  public var isEnabled: Bool = false

  /// The calendar identifiers of the calendars to sync with the car.
  public var calendarIDs: Set<String> = []
}

// MARK: - CalendarConfig Conformance to KeyValuePrimitiveConvertible

extension CalendarConfig: KeyValuePrimitiveConvertible {
  private enum Key {
    static let isEnabled = "isEnabled"
    static let calendarIDs = "calendarIDs"
  }

  /// Make a primitive representation of the config which can be stored in the key value store.
  fileprivate var primitive: [String: any KeyValuePrimitive] {
    return [
      Key.isEnabled: isEnabled,
      Key.calendarIDs: Array(calendarIDs) as [any KeyValuePrimitive],
    ]
  }

  /// Build the config from the supplied primitive.
  fileprivate init(primitive: Any) {
    if let settings = primitive as? [String: Any] {
      isEnabled = settings[Key.isEnabled] as? Bool ?? false
      calendarIDs = Set(settings[Key.calendarIDs] as? [String] ?? [])
    }
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
public struct CarCalendarSettings<Store: KeyValueStore> {
  private let store: Store

  public init(_ store: Store) {
    self.store = store
  }

  /// Remove the Calendar Sync settings for the specific car.
  ///
  /// - Parameter carID: The identifier of the car for which to remove the settings.
  public mutating func remove(_ carID: String) {
    let carRootKey = rootKey(car: carID)
    store.set(nil, forKey: carRootKey)
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
      return store[carRootKey] ?? CalendarConfig()
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
