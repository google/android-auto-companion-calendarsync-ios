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

private import EventKit
private import Foundation
private import UIKit
internal import XCTest

@testable private import AndroidAutoCalendarSync

/// Test EventKit integration with Calendar Sync.
class EventKitTest: XCTestCase {
  private var eventStore: EKEventStore! = nil

  override func setUp() {
    super.setUp()
    continueAfterFailure = false

    eventStore = EKEventStore()
  }

  override func tearDown() {
    eventStore = nil

    super.tearDown()
  }

  func testEventStatusFromEKEventStatus() throws {
    XCTAssertEqual(EventStatus.none, EventStatus(EKEventStatus.none))
    XCTAssertEqual(EventStatus.confirmed, EventStatus(EKEventStatus.confirmed))
    XCTAssertEqual(EventStatus.tentative, EventStatus(EKEventStatus.tentative))
    XCTAssertEqual(EventStatus.canceled, EventStatus(EKEventStatus.canceled))
  }

  func testParticipantStatusFromEKPatricipantStatus() throws {
    XCTAssertEqual(ParticipantStatus.accepted, ParticipantStatus(EKParticipantStatus.accepted))
    XCTAssertEqual(ParticipantStatus.declined, ParticipantStatus(EKParticipantStatus.declined))
    XCTAssertEqual(ParticipantStatus.invited, ParticipantStatus(EKParticipantStatus.pending))
    XCTAssertEqual(ParticipantStatus.tentative, ParticipantStatus(EKParticipantStatus.tentative))
    XCTAssertEqual(ParticipantStatus.none, ParticipantStatus(EKParticipantStatus.unknown))
    XCTAssertEqual(ParticipantStatus.unspecified, ParticipantStatus(EKParticipantStatus.delegated))
    XCTAssertEqual(ParticipantStatus.unspecified, ParticipantStatus(EKParticipantStatus.completed))
    XCTAssertEqual(ParticipantStatus.unspecified, ParticipantStatus(EKParticipantStatus.inProcess))
  }

  func testParticipantTypeFromEKPatricipantTypeAndRole() throws {
    XCTAssertEqual(
      ParticipantType.optional,
      ParticipantType(EKParticipantType.person, role: EKParticipantRole.optional)
    )
    XCTAssertEqual(
      ParticipantType.required,
      ParticipantType(EKParticipantType.person, role: EKParticipantRole.required)
    )
    XCTAssertEqual(
      ParticipantType.required,
      ParticipantType(EKParticipantType.person, role: EKParticipantRole.chair)
    )
    XCTAssertEqual(
      ParticipantType.resource,
      ParticipantType(EKParticipantType.resource, role: EKParticipantRole.unknown)
    )
    XCTAssertEqual(
      ParticipantType.resource,
      ParticipantType(EKParticipantType.room, role: EKParticipantRole.unknown)
    )
    XCTAssertEqual(
      ParticipantType.resource,
      ParticipantType(EKParticipantType.resource, role: EKParticipantRole.nonParticipant)
    )
    XCTAssertEqual(
      ParticipantType.resource,
      ParticipantType(EKParticipantType.room, role: EKParticipantRole.nonParticipant)
    )
    XCTAssertEqual(
      ParticipantType.none,
      ParticipantType(EKParticipantType.group, role: EKParticipantRole.unknown)
    )
    XCTAssertEqual(
      ParticipantType.none,
      ParticipantType(EKParticipantType.group, role: EKParticipantRole.nonParticipant)
    )
  }
}
