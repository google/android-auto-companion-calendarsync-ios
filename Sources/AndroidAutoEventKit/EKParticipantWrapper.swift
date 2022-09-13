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

/// A wrapper around 'EKParticipant' that will make it conform to 'Participant'.
struct EKParticipantWrapper: Participant {
  let participant: EKParticipant

  init(participant: EKParticipant) {
    self.participant = participant
  }

  var isCurrentUser: Bool {
    return participant.isCurrentUser
  }

  var name: String? {
    return participant.name
  }

  var participantRole: EKParticipantRole {
    return participant.participantRole
  }

  var participantStatus: EKParticipantStatus {
    return participant.participantStatus
  }

  var participantType: EKParticipantType {
    return participant.participantType
  }
}
