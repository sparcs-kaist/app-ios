//
//  CourseView.swift
//  soap
//
//  Created by 하정우 on 9/30/25.
//

import SwiftUI

struct CourseView: View {
  @State private var viewModel: CourseViewModel
  @State private var course: Course
  
  init(course: Course, viewModel: CourseViewModel = .init()) {
    self.viewModel = viewModel
    self.course = course
  }
  
  var body: some View {
    ScrollView {
      switch viewModel.state {
      case .loading:
        courseSummary
          .redacted(reason: .placeholder)
      case .loaded:
        courseSummary
        courseReview
      case .error(let message):
        ContentUnavailableView("Error", systemImage: "wifi.exclamationmark", description: Text(message))
      }
    }
    .padding()
    .task {
      await viewModel.fetchReviews(courseId: course.id)
    }
  }
  
  private var courseSummary: some View {
    Group {
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
      VStack (alignment: .leading){
        LectureDetailRow(title: "Code", description: course.code)
        LectureDetailRow(title: "Type", description: course.type.localized())
        LectureDetailRow(title: "Department", description: course.department.name.localized())
        
        if course.summary != "" {
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
    .padding(.bottom)
  }
  
  private var courseReview: some View {
    VStack {
      HStack {
        Text("Reviews")
          .font(.title3)
          .fontWeight(.bold)
        Spacer()
      }
      
      Spacer()
        .frame(height: 16)
      
      LazyVStack(spacing: 16) {
        ForEach($viewModel.reviews) { review in
          ReviewCell(review: review, title: course.title.localized(), code: course.code)
            .environment(viewModel)
        }
      }
    }
  }
  
  func lectureSummaryRowWrapper(title: String, description: String) -> some View {
    LectureSummaryRow(title: title, description: description)
      .frame(width: 75)
  }
}

#Preview {
  CourseView(course: .mock)
}
