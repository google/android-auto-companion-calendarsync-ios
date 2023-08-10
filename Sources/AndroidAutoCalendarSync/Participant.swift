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

/// The protocol of a participant.
public protocol Participant {
  /// A Boolean value indication whether this participant represents the owner of this account.
  var isCurrentUser: Bool { get }

  /// The participant's name.
  var name: String? { get }

  /// The status of the participant in the event.
  var status: ParticipantStatus { get }

  /// The participant's type including role in the event.
  var type: ParticipantType { get }
}

/// Participant status aligned with the corresponding calendar proto status.
public enum ParticipantStatus: Int {
  case unspecified
  case none
  case accepted
  case declined
  case invited
  case tentative
}

/// Participant type including role aligned with the corresponding calendar proto type.
public enum ParticipantType: Int {
  case unspecified
  case none
  case optional
  case required
  case resource
}
