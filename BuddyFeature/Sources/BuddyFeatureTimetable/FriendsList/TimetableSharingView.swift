//
//  TimetableSharingView.swift
//  BuddyFeature
//

import SwiftUI
import BuddyDomain
import TimetableUI

/// Lists each semester with the timetable friends see for it; a semester opens its
/// page, with a preview and the choices.
struct TimetableSharingView: View {
  @State private var viewModel = TimetableSharingViewModel()
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      content
        .navigationTitle(Text("Timetable Sharing", bundle: .module))
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button(String(localized: "Done", bundle: .module), systemImage: "checkmark", role: .confirm) {
              dismiss()
            }
          }
        }
        .navigationDestination(for: Semester.self) { semester in
          TimetableSharingSemesterView(viewModel: viewModel, semester: semester)
        }
        .task { await viewModel.load() }
        .alert(item: $viewModel.alertState) { state in
          Alert(
            title: Text(state.title),
            message: Text(state.message),
            dismissButton: .default(Text("OK", bundle: .module))
          )
        }
    }
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.listState {
    case .loading:
      ProgressView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)

    case .error(let message):
      ContentUnavailableView {
        Label(String(localized: "Unable to Load Timetable", bundle: .module), systemImage: "exclamationmark.triangle")
      } description: {
        Text(message)
      } actions: {
        Button(String(localized: "Try Again", bundle: .module)) {
          Task { await viewModel.load() }
        }
      }

    case .loaded:
      List {
        Section {
          ForEach(viewModel.semesters) { semester in
            NavigationLink(value: semester) {
              LabeledContent {
                if let name = viewModel.sharedName(for: semester) {
                  Text(name)
                } else if case .error = viewModel.sharing(for: semester) {
                  Image(systemName: "exclamationmark.triangle")
                } else {
                  ProgressView()
                }
              } label: {
                Text(semester.description)
              }
            }
            .task { await viewModel.loadSharing(for: semester) }
          }
        } footer: {
          SharingNotice()
        }
      }
      .listStyle(.insetGrouped)
      .refreshable { await viewModel.load() }
    }
  }
}

/// One semester: the same selector the timetable uses, choosing what friends see,
/// over a preview of it.
struct TimetableSharingSemesterView: View {
  let viewModel: TimetableSharingViewModel
  let semester: Semester

  /// Keeps the grid usable on short (landscape) screens, as the main timetable does.
  private static let minimumGridHeight: CGFloat = 500

  var body: some View {
    GeometryReader { reader in
      ScrollView {
        content(gridHeight: max(reader.size.height * 0.75, Self.minimumGridHeight))
          .padding()
      }
      .scrollContentWidth()
    }
    .background(Color.systemGroupedBackground)
    .navigationTitle(semester.description)
    .toolbarTitleDisplayMode(.inline)
    .task { await viewModel.loadSharing(for: semester) }
  }

  @ViewBuilder
  private func content(gridHeight: CGFloat) -> some View {
    switch viewModel.sharing(for: semester) {
    case .loading:
      ProgressView()
        .frame(maxWidth: .infinity, minHeight: gridHeight)

    case .error(let message):
      ContentUnavailableView {
        Label(String(localized: "Unable to Load Timetable", bundle: .module), systemImage: "exclamationmark.triangle")
      } description: {
        Text(message)
      } actions: {
        Button(String(localized: "Try Again", bundle: .module)) {
          Task { await viewModel.loadSharing(for: semester) }
        }
      }

    case .loaded(let sharing):
      VStack(alignment: .leading, spacing: 16) {
        HStack {
          Spacer()
          selector(sharing)
        }

        ThemedGridCard {
          preview(of: sharing.sharedTimetableID)
        }
        .frame(height: gridHeight)

        SharingNotice()
          .font(.footnote)
          .foregroundStyle(.secondary)
          .padding(.horizontal)
      }
    }
  }

  /// The timetable view's table menu, holding only what can be shared.
  private func selector(_ sharing: TimetableSharing) -> some View {
    Menu {
      Button {
        Task { await viewModel.share(nil, semester: semester) }
      } label: {
        HStack {
          if sharing.sharedTimetableID == nil {
            Image(systemName: "checkmark")
          }
          Text("Enrolled Lectures", bundle: .module)
        }
      }

      ForEach(sharing.timetables) { timetable in
        Button {
          Task { await viewModel.share(timetable.id, semester: semester) }
        } label: {
          HStack {
            if sharing.sharedTimetableID == timetable.id {
              Image(systemName: "checkmark")
            }
            Text(TimetableSharingViewModel.title(of: timetable))
          }
        }
      }
    } label: {
      HStack(spacing: 16) {
        Text(viewModel.sharedName(for: semester) ?? "")
          .fontWeight(.semibold)
          .contentTransition(.numericText())
          .animation(.spring, value: sharing.sharedTimetableID)

        Image(systemName: "ellipsis")
      }
      .padding(12)
      .padding(.horizontal, 4)
      .contentShape(.rect)
    }
    .tint(.primary)
    .glassEffect(.regular.interactive())
    // A choice waits for the one being saved.
    .disabled(viewModel.isSaving(semester))
  }

  /// The timetable friends see now, drawn as the main timetable draws it.
  private func preview(of timetableID: Int?) -> some View {
    ZStack {
      if let timetable = viewModel.preview(of: timetableID, in: semester) {
        TimetableGrid(selectedTimetable: timetable, placement: .view)
          .transition(.opacity)
      } else {
        ProgressView()
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .animation(.spring, value: viewModel.preview(of: timetableID, in: semester))
    .task(id: timetableID) { await viewModel.loadPreview(of: timetableID, in: semester) }
  }
}

/// Every friend sees the chosen timetable; said wherever the choice is made.
private struct SharingNotice: View {
  var body: some View {
    Label {
      Text("All of your friends can see the timetable you choose for each semester.", bundle: .module)
    } icon: {
      Image(systemName: "person.2")
    }
  }
}

#Preview {
  TimetableSharingView()
}
