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
import UIKit

public typealias ProtocolCalendar = AndroidAutoEventKitProtocol.Calendar

/// A mock calendar.
public struct MockCalendar: ProtocolCalendar {
  public var title: String
  public var calendarIdentifier: String
  public var cgColor: CGColor!

  public init(title: String, calendarIdentifier: String, cgColor: CGColor!) {
    self.title = title
    self.calendarIdentifier = calendarIdentifier
    self.cgColor = cgColor
  }

  public init(title: String, calendarIdentifier: String) {
    self.init(title: title, calendarIdentifier: calendarIdentifier, cgColor: UIColor.blue.cgColor)
  }
}
