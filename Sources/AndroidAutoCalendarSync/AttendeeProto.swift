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

import AndroidAutoLogger
@_implementationOnly import AndroidAutoCalendarSyncProtos

typealias AttendeeProto = Aae_Calendarsync_Attendee

extension AttendeeProto {
  private static var log: Logger { Logger(for: AttendeeProto.self) }

  init(_ participant: Participant) {
    self.init()

    if let name = participant.name {
      self.name = name
    }

    status = Status(participant.status)
    type = TypeEnum(participant.type)
  }

  static func makeAttendees(_ participants: [Participant]) -> [Self] {
    participants.map { Self.init($0) }
  }
}

extension AttendeeProto.Status {
  init(_ status: ParticipantStatus) {
    switch status {
    case .unspecified:
      self = .unspecifiedStatus
    case .none:
      self = .noneStatus
    case .accepted:
      self = .accepted
    case .declined:
      self = .declined
    case .invited:
      self = .invited
    case .tentative:
      self = .tentative
    }
  }
}

extension AttendeeProto.TypeEnum {
  init(_ type: ParticipantType) {
    switch type {
    case .unspecified:
      self = .unspecifiedType
    case .none:
      self = .noneType
    case .optional:
      self = .optional
    case .required:
      self = .required
    case .resource:
      self = .resource
    }
  }
}
