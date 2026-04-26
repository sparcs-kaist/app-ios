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
          prompt: Text("Share your thoughts on \(lecture.name)...", bundle: .module),
          axis: .vertical
        )
          .padding()
      }
      .scrollDismissesKeyboard(.immediately)
      .navigationTitle(String(localized: "Write a Review", bundle: .module))
      .navigationBarTitleDisplayMode(.inline)
      .safeAreaBar(edge: .top) {
        HStack {
          Text("Grade", bundle: .module)
            .foregroundStyle(.tertiary)
            .fontWeight(.medium)
            .textCase(.uppercase)

          Picker(String(localized: "Grade", bundle: .module), selection: $grade) {
            Text("A", bundle: .module).tag(5)
            Text("B", bundle: .module).tag(4)
            Text("C", bundle: .module).tag(3)
            Text("D", bundle: .module).tag(2)
            Text("F", bundle: .module).tag(1)
          }

          Text("Load", bundle: .module)
            .foregroundStyle(.tertiary)
            .fontWeight(.medium)
            .textCase(.uppercase)
          Picker(String(localized: "Load", bundle: .module), selection: $load) {
            Text("A", bundle: .module).tag(5)
            Text("B", bundle: .module).tag(4)
            Text("C", bundle: .module).tag(3)
            Text("D", bundle: .module).tag(2)
            Text("F", bundle: .module).tag(1)
          }

          Text("Speech", bundle: .module)
            .foregroundStyle(.tertiary)
            .fontWeight(.medium)
            .textCase(.uppercase)
          Picker(String(localized: "Speech", bundle: .module), selection: $speech) {
            Text("A", bundle: .module).tag(5)
            Text("B", bundle: .module).tag(4)
            Text("C", bundle: .module).tag(3)
            Text("D", bundle: .module).tag(2)
            Text("F", bundle: .module).tag(1)
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
        Text("There was an error. Please try again later.", bundle: .module)
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
