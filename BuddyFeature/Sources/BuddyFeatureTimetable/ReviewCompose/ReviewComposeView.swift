//
//  ReviewComposeView.swift
//  soap
//
//  Created by Soongyu Kwon on 02/10/2025.
//

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
          prompt: Text("Share your thoughts on \(lecture.name)..."),
          axis: .vertical
        )
          .padding()
      }
      .scrollDismissesKeyboard(.immediately)
      .navigationTitle("Write a Review")
      .navigationBarTitleDisplayMode(.inline)
      .safeAreaBar(edge: .top) {
        HStack {
          Text("Grade")
            .foregroundStyle(.tertiary)
            .fontWeight(.medium)
            .textCase(.uppercase)

          Picker("Grade", selection: $grade) {
            Text("A").tag(5)
            Text("B").tag(4)
            Text("C").tag(3)
            Text("D").tag(2)
            Text("F").tag(1)
          }

          Text("Load")
            .foregroundStyle(.tertiary)
            .fontWeight(.medium)
            .textCase(.uppercase)
          Picker("Load", selection: $load) {
            Text("A").tag(5)
            Text("B").tag(4)
            Text("C").tag(3)
            Text("D").tag(2)
            Text("F").tag(1)
          }

          Text("Speech")
            .foregroundStyle(.tertiary)
            .fontWeight(.medium)
            .textCase(.uppercase)
          Picker("Speech", selection: $speech) {
            Text("A").tag(5)
            Text("B").tag(4)
            Text("C").tag(3)
            Text("D").tag(2)
            Text("F").tag(1)
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
                Label("Done", systemImage: "arrow.up")
              }
            }
          )
          .disabled(isUploading)
          .disabled(content.isEmpty)
        }
      }
      .alert("Error", isPresented: $showErrorAlert, actions: {
        Button("Okay", role: .close) { }
      }, message: {
        Text("There was an error. Please try again later.")
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
