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

internal import XCTest
private import AndroidAutoCalendarSyncProtos

@testable private import AndroidAutoCalendarSync

class AttendeeProtoTest: XCTestCase {
  override func setUp() {
    super.setUp()
    continueAfterFailure = false
  }

  func testProtoFromParticipant() {
    var expectedProto = AttendeeProto()
    expectedProto.name = "Clark Kent"
    expectedProto.status = .declined
    expectedProto.type = .required

    let participant = MockParticipant(
      isCurrentUser: true,
      name: "Clark Kent",
      status: .declined,
      type: .required
    )

    XCTAssertEqual(expectedProto, AttendeeProto(participant))
  }

  func testConvertFromStatus() {
    XCTAssertEqual(.accepted, AttendeeProto.Status(.accepted))
    XCTAssertEqual(.declined, AttendeeProto.Status(.declined))
    XCTAssertEqual(.tentative, AttendeeProto.Status(.tentative))
    XCTAssertEqual(.invited, AttendeeProto.Status(.invited))
    XCTAssertEqual(.noneStatus, AttendeeProto.Status(.none))
    XCTAssertEqual(.unspecifiedStatus, AttendeeProto.Status(.unspecified))
  }

  func testConvertFromType() {
    XCTAssertEqual(.required, AttendeeProto.TypeEnum(.required))
    XCTAssertEqual(.optional, AttendeeProto.TypeEnum(.optional))
    XCTAssertEqual(.resource, AttendeeProto.TypeEnum(.resource))
    XCTAssertEqual(.noneType, AttendeeProto.TypeEnum(.none))
  }
}
