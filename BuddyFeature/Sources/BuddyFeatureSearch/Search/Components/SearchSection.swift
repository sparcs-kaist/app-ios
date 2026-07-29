//
//  SearchSection.swift
//  soap
//
//  Created by 하정우 on 9/29/25.
//

import SwiftUI
import BuddyDomain
import BuddyFeatureShared

struct SearchSection<Content: View>: View {
  let title: String
  
  @Binding var searchScope: SearchScope
  let targetScope: SearchScope
  
  @ViewBuilder let content: () -> Content

  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Text(title)
          .font(.title2)
          .fontWeight(.bold)

        if searchScope != targetScope {
          Button {
            searchScope = targetScope
          } label: {
            Image(systemName: "chevron.right")
              .font(.caption)
              .labelStyle(.iconOnly)
              .foregroundStyle(.primary)
          }
          .buttonBorderShape(.circle)
          .padding(8)
          .background(colorScheme == .light ? .white : .clear, in: .circle)
          .glassEffect(colorScheme == .light ? .identity : .regular, in: .circle)
          .tint(Color.secondarySystemGroupedBackground)
          .foregroundStyle(.secondary)
        }

        Spacer()
      }

      LazyVStack(alignment: .leading, spacing: 0) {
        content()
      }
      #if os(macOS)
      // AppKit gives NavigationLink the bordered push-button look by default, which
      // paints an opaque capsule behind every row. The container surface is dropped
      // as well so the rows sit straight on the pane's gradient rather than on a
      // second, differently tinted panel. `.contentShape` is required alongside it:
      // without a button background AppKit has nothing to hit-test, so rows stop
      // responding to clicks entirely.
      .contentShape(.rect)
      .buttonStyle(.plain)
      #else
      .background(
        colorScheme == .light ? Color.secondarySystemGroupedBackground : .clear,
        in: .rect(cornerRadius: 28)
      )
      .glassEffect(colorScheme == .light ? .identity : .regular, in: .rect(cornerRadius: 28))
      #endif
    }
    .padding(.horizontal)
  }
}

//#Preview {
//  let course: [CourseSummary] = CourseSummary.mockList
//
//  ZStack {
//    Color.secondarySystemBackground.ignoresSafeArea()
//    
//    ScrollView {
//      SearchSection(title: "Rides", searchScope: .constant(.all), targetScope: .taxi) {
//        SearchContent(results: Array(TaxiRoom.mockList[..<3])) {
//          TaxiRoomCell(room: $0, withOutBackground: true)
//        }
//      }
//      
//      SearchSection(title: "Courses", searchScope: .constant(.all), targetScope: .courses) {
//        SearchContent<CourseSummary, CourseCell>(results: course) {
//          CourseCell(course: $0)
//        }
//      }
//    }
//  }
//}
