//
//  CourseView.swift
//  soap
//
//  Created by 하정우 on 9/30/25.
//

import SwiftUI

struct CourseView: View {
  @State private var viewModel: CourseViewModel
  let course: Course
  
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
      case .loaded(let reviews):
        courseSummary
        courseReview(reviews: reviews)
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
  
  private func courseReview(reviews: [CourseReview]) -> some View {
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
        ForEach(reviews) { review in
          reviewCell(review: review)
        }
      }
    }
  }
  
  private func reviewCell(review: CourseReview) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Group {
          if let professor = review.professor, !professor.localized().isEmpty {
            Text(professor.localized())
          } else {
            Text("Unknown")
          }
        }
        .font(.headline)
        
        Text(String(review.year).suffix(2) + review.semester.shortCode)
          .foregroundStyle(.secondary)
          .fontDesign(.rounded)
          .fontWeight(.semibold)
        
        Spacer()
        
        Menu {
          Button("Translate", systemImage: "translate") { }
          Button("Summarise", systemImage: "text.append") { }
          Divider()
          Button("Report", systemImage: "exclamationmark.triangle.fill") { }
        } label: {
          Label("More", systemImage: "ellipsis")
            .padding(8)
            .contentShape(.rect)
        }
        .labelStyle(.iconOnly)
      }
      
      Text(review.content)
        .truncationMode(.head)
      
      HStack(alignment: .bottom) {
        HStack(spacing: 4) {
          Text("Grade")
            .foregroundStyle(.tertiary)
            .fontWeight(.medium)
            .textCase(.uppercase)
          
          Text(review.gradeLetter)
            .foregroundStyle(.secondary)
            .fontDesign(.rounded)
            .fontWeight(.semibold)
        }
        .font(.footnote)
        
        HStack(spacing: 4) {
          Text("Load")
            .foregroundStyle(.tertiary)
            .fontWeight(.medium)
            .textCase(.uppercase)
          
          Text(review.loadLetter)
            .foregroundStyle(.secondary)
            .fontDesign(.rounded)
            .fontWeight(.semibold)
        }
        .font(.footnote)
        
        HStack(spacing: 4) {
          Text("Speech")
            .foregroundStyle(.tertiary)
            .fontWeight(.medium)
            .textCase(.uppercase)
          
          Text(review.speechLetter)
            .foregroundStyle(.secondary)
            .fontDesign(.rounded)
            .fontWeight(.semibold)
        }
        .font(.footnote)
        
        Spacer()
        
        Button(action: { }, label: {
          HStack {
            Text("\(review.like)")
            Image(systemName: review.isLiked ? "arrowshape.up.fill" : "arrowshape.up")
          }
        })
        .tint(.primary)
      }
    }
    .padding()
    .background(.white)
    .clipShape(.rect(cornerRadius: 26))
    .shadow(color: .black.opacity(0.1), radius: 8)
  }
  
  func lectureSummaryRowWrapper(title: String, description: String) -> some View {
    LectureSummaryRow(title: title, description: description)
      .frame(width: 75)
  }
}

#Preview {
  CourseView(course: .mock)
}
