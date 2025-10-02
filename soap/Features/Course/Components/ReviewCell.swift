//
//  ReviewCell.swift
//  soap
//
//  Created by 하정우 on 10/1/25.
//

import SwiftUI

@preconcurrency
import Translation

struct ReviewCell: View {
  @Binding var review: LectureReview
  @Environment(CourseViewModel.self) private var viewModel: CourseViewModel
  @Environment(\.openURL) private var openURL
  @State private var summarisedContent: String? = nil
  @State private var isTranslating: Bool = false
  @State private var translatedContent: String? = nil
  @State private var configuration: TranslationSession.Configuration?
  let title: String
  let code: String
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Group {
          if let professor = review.lecture.professors.first, !professor.name.localized().isEmpty {
            Text(professor.name.localized())
          } else {
            Text("Unknown")
          }
        }
        .font(.headline)
        
        Text(String(review.lecture.year).suffix(2) + review.lecture.semester.shortCode)
          .foregroundStyle(.secondary)
          .fontDesign(.rounded)
          .fontWeight(.semibold)
        
        Spacer()
        
        Menu {
          Button("Translate", systemImage: "translate") {
            triggerTranslation()
          }
          if viewModel.foundationModelsAvailable {
            Button("Summarise", systemImage: "text.append") {
              summarisedContent = ""
              Task {
                summarisedContent = await viewModel.summarise(review.content)
              }
            }.disabled(summarisedContent != nil)
          }
          Divider()
          Button("Report", systemImage: "exclamationmark.triangle.fill") {
            if let urlString = ReportMailComposer.compose(
              title: title,
              code: code,
              year: review.lecture.year,
              semester: review.lecture.semester,
              professorName: review.lecture.professors.first?.name.localized() ?? "",
              content: review.content
            ), let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
              openURL(url) // NOTE: Does not work on Simulator since it does not have Mail app
            }
          }
          
        } label: {
          Label("More", systemImage: "ellipsis")
            .padding(8)
            .contentShape(.rect)
        }
        .labelStyle(.iconOnly)
      }
      
      if let summarisedContent {
        SummarisationView(text: summarisedContent)
          .padding(.bottom)
          .transition(.asymmetric(
            insertion: .offset(y: -10).combined(with: .opacity),
            removal: .opacity
          ))
      }
      
      Group {
        if let translatedContent, !isTranslating {
          Text(translatedContent)
        }
        else {
          Text(review.content)
            .redacted(reason: isTranslating ? [.placeholder] : [])
        }
      }
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
        
        Button(action: {
          Task {
            await toggleLike()
          }
        }, label: {
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
    .translationTask(configuration) { session in
      isTranslating = true
      defer { isTranslating = false }
      
      do {
        let response = try await session.translate(review.content)
        
        translatedContent = response.targetText
      } catch {
        logger.error(error)
      }
    }
  }
  
  private func toggleLike() async {
    let prevLiked = review.isLiked
    let prevLikeCount = review.like
    
    do {
      if prevLiked {
        try await viewModel.unlikeReview(reviewId: review.id)
        review.isLiked = false
        review.like -= 1
      } else {
        try await viewModel.likeReview(reviewId: review.id)
        review.isLiked = true
        review.like += 1
      }
    } catch {
      review.isLiked = prevLiked
      review.like = prevLikeCount
    }
  }
  
  private func triggerTranslation() {
    guard configuration == nil else {
      configuration?.invalidate()
      return
    }
    
    configuration = .init()
  }
}
