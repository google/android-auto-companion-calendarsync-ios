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
import XCTest

@testable import AndroidAutoCalendarSync

let store = MockKeyValueStore()

class CarCalendarSettingsTest: XCTestCase {
  private let carID = "someTestCarID"
  private var settings = CarCalendarSettings(store)

  override func setUp() {
    store.clear()
  }

  func testIsCalendarSyncEnabled_NonExistingCar_ReturnsFalse() {
    XCTAssertFalse(settings[carID].isEnabled)
  }

  func testIsCalendarSyncEnabled_ReturnsTrue() {
    let calendarConfig = CalendarConfig(isEnabled: true)
    settings[carID] = calendarConfig

    XCTAssertTrue(settings[carID].isEnabled)
    XCTAssertFalse(settings["unknownCarID"].isEnabled)
  }

  func testCalendarIDsForNonExistingCarReturnsEmptyList() {
    settings.remove(carID)
    let calendarIDs = settings[carID].calendarIDs
    XCTAssertTrue(calendarIDs.isEmpty)
  }

  func testStoreCalendarIDs() {
    let expectedCalendarIDs: Set = ["calendarA", "calendarB"]
    let config = CalendarConfig(calendarIDs: expectedCalendarIDs)
    settings[carID] = config

    let calendarIDs = settings[carID].calendarIDs

    XCTAssertEqual(calendarIDs, expectedCalendarIDs)
    XCTAssertTrue(settings["unknownCarID"].calendarIDs.isEmpty)
  }

  func testRemove() {
    var config = CalendarConfig(isEnabled: true)
    config.calendarIDs = ["calendarZ", "calendarY"]
    XCTAssertNotNil(settings[carID])

    settings.remove(carID)
    XCTAssertFalse(settings[carID].isEnabled)
    XCTAssertTrue(settings[carID].calendarIDs.isEmpty)
  }

  func testSettingsByCar() {
    let car = Car(id: "test", name: "Test")
    let calendarIDs: Set = ["test1", "test2"]
    let config = CalendarConfig(isEnabled: true, calendarIDs: calendarIDs)

    settings[car] = config

    XCTAssertTrue(settings[car].isEnabled)
    XCTAssertFalse(settings[car].calendarIDs.isEmpty)
    XCTAssertEqual(settings[car].calendarIDs, calendarIDs)

    settings.remove(car)

    XCTAssertFalse(settings[car].isEnabled)
    XCTAssertTrue(settings[car].calendarIDs.isEmpty)
  }
}
