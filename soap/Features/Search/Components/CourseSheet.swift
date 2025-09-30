//
//  CourseSheet.swift
//  soap
//
//  Created by 하정우 on 9/30/25.
//

import SwiftUI

struct CourseSheet: View {
  @Binding var sheetDetent: PresentationDetent
  let course: Course
  
  var body: some View {
    Group {
      switch sheetDetent {
      case .large:
        largeView
          .padding(.top)
      case .height(200):
        courseSummary
      default:
        EmptyView()
      }
    }
    .padding()
  }
  
  private var courseSummary: some View {
    VStack(spacing: 20) {
      HStack {
        Text(course.title)
          .font(.title3)
          .fontWeight(.bold)
        Spacer()
      }
      VStack(alignment: .center) {
        HStack {
          lectureSummaryRowWrapper(title: "Lec. Hours", description: String(course.numClasses))
          lectureSummaryRowWrapper(title: "Lab Hours", description: String(course.numLabs))
          if course.credit == 0 {
            lectureSummaryRowWrapper(title: "AU", description: String(course.creditAu))
          } else {
            lectureSummaryRowWrapper(title: "Credit", description: String(course.credit))
          }
        }
        Divider()
        HStack {
          lectureSummaryRowWrapper(title: "Grade", description: course.gradeLetter)
          lectureSummaryRowWrapper(title: "Load", description: course.loadLetter)
          lectureSummaryRowWrapper(title: "Speech", description: course.speechLetter)
        }
      }
    }
  }
  
  private var largeView: some View {
    ScrollView {
      courseSummary
      VStack (alignment: .leading){
        LectureDetailRow(title: "Code", description: course.code)
        LectureDetailRow(title: "Type", description: course.type.localized())
        LectureDetailRow(title: "Department", description: course.department.name.localized())
        Text("Summary")
          .foregroundStyle(.secondary)
          .font(.callout)
          .padding(.vertical, 4)
        Text(course.summary)
          .font(.footnote)
          .multilineTextAlignment(.leading)
      }
    }
  }
  
  func lectureSummaryRowWrapper(title: String, description: String) -> some View {
    LectureSummaryRow(title: title, description: description)
      .frame(width: 75)
  }
}

#Preview {
  @Previewable @State var detent: PresentationDetent = .height(200)
  
  Text("")
    .sheet(isPresented: .constant(true), content: {
      CourseSheet(sheetDetent: $detent, course: .mock)
        .presentationDetents([.height(200), .large], selection: $detent)
        .presentationDragIndicator(.visible)
    })
}
