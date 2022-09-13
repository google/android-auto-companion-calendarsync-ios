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

import EventKit

/// The protocol of a participant.
public protocol Participant {
  /// A Boolean value indication whether this participant represents the owner of this account.
  var isCurrentUser: Bool { get }

  /// The participant's name.
  var name: String? { get }

  /// The participant's role in the event.
  var participantRole: EKParticipantRole { get }

  /// The participant's attendence status.
  var participantStatus: EKParticipantStatus { get }

  /// The participant's type.
  var participantType: EKParticipantType { get }
}
