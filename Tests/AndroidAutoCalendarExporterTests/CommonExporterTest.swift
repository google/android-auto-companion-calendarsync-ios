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

import XCTest
import AndroidAutoCalendarSyncProtos

@testable import AndroidAutoCalendarExporter

class CommonExporterTest: XCTestCase {

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
  }

  func testProtoFromDate() {
    let secondsPerDay: Int64 = 24 * 60 * 60

    let dateJan2 = createDateComponents(day: 2, month: 1, year: 1970).date!
    XCTAssertEqual(secondsPerDay, CommonExporter.proto(from: dateJan2).seconds)

    let dateJan3 = createDateComponents(day: 3, month: 1, year: 1970).date!
    XCTAssertEqual(2 * secondsPerDay, CommonExporter.proto(from: dateJan3).seconds)
  }

  func testProtoFromTimeZone() {
    let timeZoneBerlin = TimeZone(identifier: "Europe/Berlin")!

    var expectedProto = Aae_Calendarsync_TimeZone()
    expectedProto.name = timeZoneBerlin.identifier
    expectedProto.secondsFromGmt = Int64(timeZoneBerlin.secondsFromGMT())

    XCTAssertEqual(expectedProto, CommonExporter.proto(from: timeZoneBerlin))
  }

  func testProtoFromCGColor() {
    XCTAssertEqual(255 << 24, CommonExporter.proto(from: UIColor.black.cgColor).argb)
    XCTAssertEqual(255 << 24 | 255, CommonExporter.proto(from: UIColor.blue.cgColor).argb)
    XCTAssertEqual(255 << 24 | 255 << 8, CommonExporter.proto(from: UIColor.green.cgColor).argb)
    XCTAssertEqual(255 << 24 | 255 << 16, CommonExporter.proto(from: UIColor.red.cgColor).argb)

    let color = UIColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 0.5).cgColor
    let expectedArgb =
      Int32(0.5 * 255) << 24 | Int32(0.1 * 255) << 16 | Int32(0.2 * 255) << 8
      | Int32(0.3 * 255)
    XCTAssertEqual(expectedArgb, CommonExporter.proto(from: color).argb)
  }

  private func createDateComponents(day: Int, month: Int, year: Int) -> DateComponents {
    var dateComponents = DateComponents()
    dateComponents.calendar = Calendar.current
    dateComponents.timeZone = TimeZone(identifier: "Etc/GMT")
    dateComponents.day = day
    dateComponents.month = month
    dateComponents.year = year
    return dateComponents
  }
}
