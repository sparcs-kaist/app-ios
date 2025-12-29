//
//  AppIntent.swift
//  BuddyiOSWidget
//
//  Created by Soongyu Kwon on 25/12/2025.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource { "Configuration" }
  static var description: IntentDescription { "This is an example widget." }

//  @Parameter(title: "Mirror Timetable", default: true)
//  var mirrorTimetable: Bool
//
//  @Parameter(title: "Semester", default: "2026")
//  var semester: String
//
//  static var parameterSummary: some ParameterSummary {
//    When(\.$mirrorTimetable, .equalTo, false) {
//      Summary {
//        \.$mirrorTimetable
//        \.$semester
//      }
//    } otherwise: {
//      Summary {
//        \.$mirrorTimetable
//      }
//    }
//  }
}

