//
//  ReviewComposeView.swift
//  soap
//
//  Created by Soongyu Kwon on 02/10/2025.
//

import Foundation
import SwiftUI
import Factory
import BuddyDomain
import FirebaseAnalytics

struct ReviewComposeView: View {
  let lecture: Lecture

  @Environment(\.dismiss) private var dismiss
  @Injected(\.v2ReviewUseCase) private var reviewUseCase: ReviewUseCaseProtocol?

  @State private var grade: Int = 5
  @State private var load: Int = 5
  @State private var speech: Int = 5
  @State private var content: String = ""

  @State private var isUploading: Bool = false
  @State private var showErrorAlert: Bool = false

  var body: some View {
    NavigationView {
      ScrollView {
        TextField(
          "",
          text: $content,
          prompt: Text(String(localized: "Share your thoughts on \(lecture.name)...", bundle: .module)),
          axis: .vertical
        )
          .padding()
      }
      .scrollDismissesKeyboard(.immediately)
      .navigationTitle(String(localized: "Write a Review", bundle: .module))
      .navigationBarTitleDisplayMode(.inline)
      .safeAreaBar(edge: .top) {
        HStack {
          Text(String(localized: "Grade", bundle: .module))
            .foregroundStyle(.tertiary)
            .fontWeight(.medium)
            .textCase(.uppercase)

          Picker(String(localized: "Grade", bundle: .module), selection: $grade) {
            Text(String(localized: "A", bundle: .module)).tag(5)
            Text(String(localized: "B", bundle: .module)).tag(4)
            Text(String(localized: "C", bundle: .module)).tag(3)
            Text(String(localized: "D", bundle: .module)).tag(2)
            Text(String(localized: "F", bundle: .module)).tag(1)
          }

          Text(String(localized: "Load", bundle: .module))
            .foregroundStyle(.tertiary)
            .fontWeight(.medium)
            .textCase(.uppercase)
          Picker(String(localized: "Load", bundle: .module), selection: $load) {
            Text(String(localized: "A", bundle: .module)).tag(5)
            Text(String(localized: "B", bundle: .module)).tag(4)
            Text(String(localized: "C", bundle: .module)).tag(3)
            Text(String(localized: "D", bundle: .module)).tag(2)
            Text(String(localized: "F", bundle: .module)).tag(1)
          }

          Text(String(localized: "Speech", bundle: .module))
            .foregroundStyle(.tertiary)
            .fontWeight(.medium)
            .textCase(.uppercase)
          Picker(String(localized: "Speech", bundle: .module), selection: $speech) {
            Text(String(localized: "A", bundle: .module)).tag(5)
            Text(String(localized: "B", bundle: .module)).tag(4)
            Text(String(localized: "C", bundle: .module)).tag(3)
            Text(String(localized: "D", bundle: .module)).tag(2)
            Text(String(localized: "F", bundle: .module)).tag(1)
          }
        }
        .font(.callout)
        .buttonStyle(.glass)
      }
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(
            role: .confirm,
            action: {
              Task {
                guard let reviewUseCase else { return }
                isUploading = true
                defer { isUploading = false }
                do {
                  try await reviewUseCase
                    .writeReview(
                      lectureID: lecture.id,
                      content: content,
                      grade: grade,
                      load: load,
                      speech: speech
                    )
                  dismiss()
                } catch {
                  showErrorAlert = true
                }
              }
            },
            label: {
              if isUploading {
                ProgressView()
              } else {
                Label(String(localized: "Done", bundle: .module), systemImage: "arrow.up")
              }
            }
          )
          .disabled(isUploading)
          .disabled(content.isEmpty)
        }
      }
      .alert(String(localized: "Error", bundle: .module), isPresented: $showErrorAlert, actions: {
        Button(String(localized: "Okay", bundle: .module), role: .close) { }
      }, message: {
        Text(String(localized: "There was an error. Please try again later.", bundle: .module))
      })
    }
    .analyticsScreen(name: "Review Compose", class: String(describing: Self.self))
  }
}

//#Preview {
//  ReviewComposeView(lecture: Lecture.mock, onWrite: { _ in
//
//  })
//}
