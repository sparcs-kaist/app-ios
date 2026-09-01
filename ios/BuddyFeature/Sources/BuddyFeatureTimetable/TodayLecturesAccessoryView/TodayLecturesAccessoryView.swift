//
//  TodayLecturesAccessoryView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 09/03/2026.
//

import Foundation
import SwiftUI
import BuddyDomain

public struct TodayLecturesAccessoryView: View {
  @Bindable var viewModel: TodayLecturesAccessoryViewModel
  let context: TimelineViewDefaultContext

  @Environment(\.tabViewBottomAccessoryPlacement) private var placement

  public init(
    context: TimelineViewDefaultContext,
    viewModel: TodayLecturesAccessoryViewModel
  ) {
    self.context = context
    self.viewModel = viewModel
  }

  public var body: some View {
    accessoryContent
      .padding(.horizontal)
      .contentShape(.capsule)
  }

  @ViewBuilder
  private var accessoryContent: some View {
    if viewModel.isLoading {
      TodayLectureCard(context: context, item: LectureItem.mock)
        .redacted(reason: .placeholder)
    } else if let nextLecture = viewModel.nextLecture {
      TodayLectureCard(context: context, item: nextLecture)
    } else if let timetable = viewModel.timetable, let semester = viewModel.selectedSemester {
      semesterCard(timetable: timetable, semester: semester)
    } else {
      placeholder(title: "Unknown", subtitle: "Failed to load timetable. Try again later.")
    }
  }

  private func semesterCard(timetable: Timetable, semester: Semester) -> some View {
    HStack(alignment: .center) {
      Circle()
        .fill(Color.accentColor)
        .frame(width: 12, height: 12)

      Text(placement == .expanded ? semester.description : String(semester.year).suffix(2) + semester.semesterType.shortCode)
        .font(.headline)

      Spacer()

      HStack(alignment: .bottom, spacing: 4) {
        Text("\(timetable.credits)")
          .font(.callout)
        Text(placement == .expanded ? "Credits" : "CR")
          .textCase(.uppercase)
          .font(.caption2)

        Spacer()
          .frame(width: placement == .expanded ? 4 : 0)

        Text("\(timetable.creditAUs)")
          .font(.callout)
        Text("AU")
          .textCase(.uppercase)
          .font(.caption2)
      }
      .fontDesign(.rounded)
    }
  }

  private func placeholder(title: String, subtitle: String) -> some View {
    HStack {
      Circle()
        .fill(Color.accentColor)
        .frame(width: 12, height: 12)
        .animation(.spring, value: context.date)

      VStack(alignment: .leading) {
        Text(title)
          .font(.headline)
          .lineLimit(1)
          .animation(.spring, value: context.date)
          .contentTransition(.numericText())

        Text(subtitle)
          .font(.footnote)
          .foregroundStyle(.secondary)
          .animation(.spring, value: context.date)
          .contentTransition(.numericText())
      }

      Spacer()
    }
  }
}

