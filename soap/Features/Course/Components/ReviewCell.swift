//
//  ReviewCell.swift
//  soap
//
//  Created by 하정우 on 10/1/25.
//

import SwiftUI

struct ReviewCell: View {
  @Binding var review: CourseReview
  @Environment(CourseViewModel.self) private var viewModel: CourseViewModel
  
  var body: some View {
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
}
