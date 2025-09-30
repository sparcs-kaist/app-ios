//
//  SearchSection.swift
//  soap
//
//  Created by 하정우 on 9/29/25.
//

import SwiftUI

struct SearchSection<Content: View>: View {
  let title: String
  
  @Binding var searchScope: SearchScope
  let targetScope: SearchScope
  
  @ViewBuilder let content: () -> Content
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Text(title)
          .font(.title2)
          .fontWeight(.bold)
        Button {
          searchScope = targetScope
        } label: {
          Image(systemName: "chevron.right")
            .font(.caption)
            .labelStyle(.iconOnly)
            .foregroundStyle(.primary)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.circle)
        .tint(Color.systemBackground)
        .foregroundStyle(.secondary)
        Spacer()
      }
      LazyVStack(alignment: .leading, spacing: 0) {
        content()
      }
      .background(Color.systemBackground)
      .clipShape(.rect(cornerRadius: 28.0))
    }
    .padding(.horizontal)
  }
}

#Preview {
  let rooms: [TaxiRoom] = []
  let course: [Course] = Course.mockList
  
  ZStack {
    Color.secondarySystemBackground.ignoresSafeArea()
    
    ScrollView {
      SearchSection(title: "Rides", searchScope: .constant(.all), targetScope: .taxi) {
        SearchContent(results: Array(TaxiRoom.mockList[..<3])) {
          TaxiRoomCell(room: $0)
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
