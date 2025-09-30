//
//  LectureDetailView.swift
//  soap
//
//  Created by Soongyu Kwon on 26/06/2025.
//

import SwiftUI

struct LectureDetailView: View {
  let lecture: Lecture
  let onAdd: (() -> Void)?

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 20) {
        // Lecture Summary
        LectureSummary(lecture: lecture)

        // Lecture Information
        lectureInformation

        // Lecture Reviews
        lectureReviews
      }
      .padding([.horizontal, .bottom])
    }
    .navigationTitle(lecture.title.localized())
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      if onAdd != nil {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Add", systemImage: "plus", role: .confirm) {
            dismiss()
            onAdd?()
          }
        }
      }
    }
  }

  var lectureReviews: some View {
    VStack {
      HStack {
        Text("Reviews")
          .font(.title3)
          .fontWeight(.bold)
        Spacer()
      }

      HStack {
        LectureSummaryRow(title: "Grade", description: lecture.gradeLetter)
        Spacer()
        LectureSummaryRow(title: "Load", description: lecture.loadLetter)
        Spacer()
        LectureSummaryRow(title: "Speech", description: lecture.speechLetter)
        Spacer()

        Button(action: { }, label: {
          Label("Write a Review", systemImage: "square.and.pencil")
            .padding(8)
        })
          .font(.callout)
          .buttonStyle(.glassProminent)
          .tint(Color.secondarySystemBackground)
          .foregroundStyle(.primary)
      }
      .padding(.vertical, 4)

      Spacer()
        .frame(height: 16)

      LazyVStack(spacing: 16) {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text(lecture.professors.first?.name.localized() ?? "Unknown")
              .font(.headline)

            Text(String(lecture.year).suffix(2) + lecture.semester.shortCode)
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

          Text("재수강할 각오로 기말 던지고 나왔는데 교수님이 B0를 주신 ㅎㅎ...\n\n수업 잘하시는데, 개인적으로 못 따라가서 좀 아쉽네요\n\n밑 글처럼 전산쪽 베이스 부족하면 좀 힘들 것 같습니다\n\n왜 전산을 하고 싶으면 시프를 들으라는지 알 수 있었네요")
            .truncationMode(.head)

          HStack(alignment: .bottom) {
            HStack(spacing: 4) {
              Text("Grade")
                .foregroundStyle(.tertiary)
                .fontWeight(.medium)
                .textCase(.uppercase)

              Text("A+")
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

              Text("A+")
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

              Text("A")
                .foregroundStyle(.secondary)
                .fontDesign(.rounded)
                .fontWeight(.semibold)
            }
            .font(.footnote)

            Spacer()

            Button(action: { }, label: {
              HStack {
                Text("20")
                Image(systemName: "arrowshape.up")
              }
            })
            .tint(.primary)
          }
        }
        .padding()
        .background(.white)
        .clipShape(.rect(cornerRadius: 26))
        .shadow(color: .black.opacity(0.1), radius: 8)

        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text(lecture.professors.first?.name.localized() ?? "Unknown")
              .font(.headline)

            Text(String(lecture.year).suffix(2) + lecture.semester.shortCode)
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

          Text("재수강할 각오로 기말 던지고 나왔는데 교수님이 B0를 주신 ㅎㅎ...\n\n수업 잘하시는데, 개인적으로 못 따라가서 좀 아쉽네요\n\n밑 글처럼 전산쪽 베이스 부족하면 좀 힘들 것 같습니다\n\n왜 전산을 하고 싶으면 시프를 들으라는지 알 수 있었네요")
            .truncationMode(.head)

          HStack(alignment: .bottom) {
            HStack(spacing: 4) {
              Text("Grade")
                .foregroundStyle(.tertiary)
                .fontWeight(.medium)
                .textCase(.uppercase)

              Text("A+")
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

              Text("A+")
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

              Text("A")
                .foregroundStyle(.secondary)
                .fontDesign(.rounded)
                .fontWeight(.semibold)
            }
            .font(.footnote)

            Spacer()

            Button(action: { }, label: {
              HStack {
                Text("20")
                Image(systemName: "arrowshape.up")
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
    }
  }

  var lectureInformation: some View {
    VStack {
      HStack {
        Text("Information")
          .font(.title3)
          .fontWeight(.bold)
        Spacer()
      }

      LectureDetailRow(title: "Code", description: lecture.code)
      LectureDetailRow(title: "Type", description: lecture.typeDetail.localized())
      LectureDetailRow(title: "Department", description: lecture.department.name.localized())
      LectureDetailRow(
        title: "Professor",
        description: lecture.professors.isEmpty ? "Unknown" : lecture.professors.map { $0.name.localized() }.joined(separator: "\n")
      )
      LectureDetailRow(
        title: "Classroom",
        description: lecture.classTimes.first?.classroomNameShort.localized() ?? "Unknown"
      )
      LectureDetailRow(title: "Capacity", description: String(lecture.capacity))
      LectureDetailRow(
        title: "Exams",
        description: lecture.examTimes.isEmpty ? "Unknown" : lecture.examTimes
          .map { $0.description.localized() }
          .joined(separator: "\n")
      )

      // Lecture Action Buttons
      Button(action: { }, label: {
        HStack {
          Text("View Dictionary")
          Spacer()
          Image(systemName: "text.book.closed")
        }
      })
      .font(.callout)
      .padding(.vertical, 4)
      Divider()

      Button(action: { }, label: {
        HStack {
          Text("View Syllabus")
          Spacer()
          Image(systemName: "append.page")
        }
      })
      .font(.callout)
      .padding(.vertical, 4)
      Divider()
    }
  }
}

#Preview {
  LectureDetailView(lecture: Lecture.mock, onAdd: nil)
}
