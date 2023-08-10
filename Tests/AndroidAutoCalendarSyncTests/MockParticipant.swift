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

import AndroidAutoCalendarSync

/// A mock participant.
struct MockParticipant: Participant {
  var isCurrentUser: Bool
  var name: String?
  var status: ParticipantStatus
  var type: ParticipantType

  init(
    isCurrentUser: Bool = false,
    name: String? = nil,
    status: ParticipantStatus = .accepted,
    type: ParticipantType = .required
  ) {
    self.isCurrentUser = isCurrentUser
    self.name = name
    self.status = status
    self.type = type
  }
}
