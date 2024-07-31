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

internal import AndroidAutoCalendarSync
internal import AndroidAutoUtils
internal import Foundation

/// A mock key-value store.
class MockKeyValueStore: PropertyListStore {
  private var storage: [String: Any] = [:]

  func clear() {
    storage = [:]
  }

  /// Access and set primitive convertible values by key in the store.
  subscript<T>(key: String) -> T? where T: PropertyListConvertible {
    get {
      guard let primitive = storage[key] as? T.Primitive else { return nil }
      do {
        return try T.init(primitive: primitive)
      } catch {
        print("Error instantiating \(T.self) from \(primitive): \(error.localizedDescription)")
        return nil
      }
    }

    set {
      storage[key] = newValue?.makePropertyListPrimitive()
    }
  }

  func removeValue(forKey key: String) {
    storage[key] = nil
  }
}
