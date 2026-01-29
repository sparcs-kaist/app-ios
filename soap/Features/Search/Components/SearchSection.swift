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
      .background(
        colorScheme == .light ? Color.secondarySystemGroupedBackground : .clear,
        in: .rect(cornerRadius: 28)
      )
      .glassEffect(colorScheme == .light ? .identity : .regular, in: .rect(cornerRadius: 28))
    }
    .padding(.horizontal)
  }
}

#Preview {
  let course: [Course] = Course.mockList
  
  ZStack {
    Color.secondarySystemBackground.ignoresSafeArea()
    
    ScrollView {
      SearchSection(title: "Rides", searchScope: .constant(.all), targetScope: .taxi) {
        SearchContent(results: Array(TaxiRoom.mockList[..<3])) {
          TaxiRoomCell(room: $0, withOutBackground: true)
        }
      }
      
      SearchSection(title: "Courses", searchScope: .constant(.all), targetScope: .courses) {
        SearchContent<Course, CourseCell>(results: course) {
          CourseCell(course: $0)
        }
      }
    }
  }
}
