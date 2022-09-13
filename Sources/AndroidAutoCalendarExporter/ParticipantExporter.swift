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

import AndroidAutoEventKitProtocol
import EventKit
import os.log
import AndroidAutoCalendarSyncProtos

/// Participant exporter to convert a native iOS participant into a proto.
enum ParticipantExporter {

  static let log = OSLog(
    subsystem: "com.google.ios.aae.calendarsync.exporter",
    category: "ParticipantExporter"
  )

  static func proto(from participants: [Participant]) -> [Aae_Calendarsync_Attendee] {
    return participants.map { proto(from: $0) }
  }

  static func proto(from participant: Participant) -> Aae_Calendarsync_Attendee {
    var attendeeProto = Aae_Calendarsync_Attendee()

    if let name = participant.name {
      attendeeProto.name = name
    }

    attendeeProto.status = convert(from: participant.participantStatus)
    attendeeProto.type = convert(
      from: participant.participantType,
      with: participant.participantRole)
    return attendeeProto
  }

  static func convert(from type: EKParticipantType, with role: EKParticipantRole)
    -> Aae_Calendarsync_Attendee.TypeEnum
  {
    switch role {
    case .optional:
      return .optional
    case .required, .chair:
      return .required
    case .unknown, .nonParticipant:
      if type == .resource || type == .room {
        return .resource
      }
      return .noneType
    @unknown default:
      return .unspecifiedType
    }
  }

  static func convert(from status: EKParticipantStatus) -> Aae_Calendarsync_Attendee.Status {
    switch status {
    case .accepted:
      return .accepted
    case .declined:
      return .declined
    case .pending:
      return .invited
    case .tentative:
      return .tentative
    case .unknown:
      return .noneStatus
    case .delegated, .completed, .inProcess:
      return .unspecifiedStatus
    @unknown default:
      os_log(
        "Unhandled EKParticipantStatus value %d",
        log: ParticipantExporter.log, type: .error, status.rawValue)
      return .unspecifiedStatus
    }
  }
}
