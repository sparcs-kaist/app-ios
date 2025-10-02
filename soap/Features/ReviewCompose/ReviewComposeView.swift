//
//  ReviewComposeView.swift
//  soap
//
//  Created by Soongyu Kwon on 02/10/2025.
//

import SwiftUI
import Factory

struct ReviewComposeView: View {
  let lecture: Lecture
  let onWrite: ((LectureReview) -> Void)

  @Environment(\.dismiss) private var dismiss
  @Injected(\.otlLectureRepository) private var otlLectureRepository: OTLLectureRepositoryProtocol

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
          prompt: Text("Share your thoughts on \(lecture.title.localized())..."),
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
                isUploading = true
                defer { isUploading = false }
                do {
                  let review: LectureReview = try await otlLectureRepository.writeReview(
                    lectureID: lecture.id,
                    content: content,
                    grade: grade,
                    load: load,
                    speech: speech
                  )
                  onWrite(review)
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
  }
}

#Preview {
  ReviewComposeView(lecture: Lecture.mock, onWrite: { _ in

  })
}
