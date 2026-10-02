//
//  ExpandSheet.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 01/10/2026.
//

import SwiftUI

extension EnvironmentValues {
  /// Asks the enclosing sheet for full height. Set by lecture search, whose sheet may still
  /// have the short height it used to preview a lecture; `nil` anywhere else.
  @Entry var expandSheet: (@MainActor () -> Void)? = nil

  /// Opens a course page in place of a link that pushes one. Set by the full-screen lecture
  /// search, which keeps every screen it shows, in its stack or its inspector, under its control.
  @Entry var openCourse: (@MainActor (_ id: Int, _ name: String) -> Void)? = nil
}
