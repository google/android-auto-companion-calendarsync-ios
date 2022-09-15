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

import AndroidAutoEventKitProtocolMocks
import EventKit
import XCTest
import AndroidAutoCalendarSyncProtos

@testable import AndroidAutoCalendarExporter

class ParticipantExporterTest: XCTestCase {

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
  }

  func testProtoFromParticipant() {
    var expectedProto = Aae_Calendarsync_Attendee()
    expectedProto.name = "Clark Kent"
    expectedProto.status = .declined
    expectedProto.type = .required

    let participant = MockParticipant(
      isCurrentUser: true,
      name: "Clark Kent",
      participantRole: .required,
      participantStatus: .declined,
      participantType: .person)

    XCTAssertEqual(expectedProto, ParticipantExporter.proto(from: participant))
  }

  func testConvertFromStatus() {
    XCTAssertEqual(.accepted, ParticipantExporter.convert(from: .accepted))
    XCTAssertEqual(.declined, ParticipantExporter.convert(from: .declined))
    XCTAssertEqual(.tentative, ParticipantExporter.convert(from: .tentative))
    XCTAssertEqual(.invited, ParticipantExporter.convert(from: .pending))
    XCTAssertEqual(.noneStatus, ParticipantExporter.convert(from: .unknown))
    XCTAssertEqual(.unspecifiedStatus, ParticipantExporter.convert(from: .delegated))
    XCTAssertEqual(.unspecifiedStatus, ParticipantExporter.convert(from: .completed))
    XCTAssertEqual(.unspecifiedStatus, ParticipantExporter.convert(from: .inProcess))
  }

  func testConvertFromType() {
    XCTAssertEqual(.required, ParticipantExporter.convert(from: .person, with: .required))
    XCTAssertEqual(.required, ParticipantExporter.convert(from: .resource, with: .chair))

    XCTAssertEqual(.optional, ParticipantExporter.convert(from: .person, with: .optional))
    XCTAssertEqual(.optional, ParticipantExporter.convert(from: .resource, with: .optional))

    XCTAssertEqual(.resource, ParticipantExporter.convert(from: .resource, with: .nonParticipant))
    XCTAssertEqual(.resource, ParticipantExporter.convert(from: .resource, with: .unknown))
    XCTAssertEqual(.resource, ParticipantExporter.convert(from: .room, with: .unknown))

    XCTAssertEqual(.noneType, ParticipantExporter.convert(from: .person, with: .unknown))
    XCTAssertEqual(.noneType, ParticipantExporter.convert(from: .unknown, with: .nonParticipant))
    XCTAssertEqual(.noneType, ParticipantExporter.convert(from: .group, with: .nonParticipant))
    XCTAssertEqual(.noneType, ParticipantExporter.convert(from: .person, with: .nonParticipant))
  }
}
