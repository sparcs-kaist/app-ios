//
//  PostComposeView.swift
//  soap
//
//  Created by Soongyu Kwon on 26/01/2025.
//

import SwiftUI

struct PostComposeView: View {
  @Environment(PostListViewModel.self) private var viewModel
  @Environment(\.dismiss) private var dismiss

  @FocusState private var isTitleFocused
  @FocusState private var isDescriptionFocused

  @State private var selectedFlair = "No flair"
  @State private var title = ""
  @State private var description = ""

  @State private var writeAsAnonymous = true
  @State private var isNSFW = false
  @State private var isPolitical = false

  var body: some View {
    NavigationView {
      VStack(alignment: .leading) {
        flairSelector
        Spacer()
          .frame(maxHeight: 16)
        TextField("Please enter the title", text: $title)
          .font(.title3)
          .focused($isTitleFocused)
          .submitLabel(.next)
          .onSubmit {
            isDescriptionFocused = true
          }
        Divider()
        TextField("What's happening?", text: $description, axis: .vertical)
          .focused($isDescriptionFocused)
          .submitLabel(.return)

        termsOfUseButton

        Spacer()

        HStack {
          Button("select photos", systemImage: "photo") {}
            .labelStyle(.iconOnly)
            .font(.title2)

          Spacer()

          Checkbox("Anonymous", isChecked: $writeAsAnonymous)
          Checkbox("NSFW", isChecked: $isNSFW)
          Checkbox("Political", isChecked: $isPolitical)
        }
        .tint(.primary)
      }
      .padding()
      .navigationTitle("Write")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Cancel", systemImage: "xmark", role: .close) {
            dismiss()
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button("Done", systemImage: "arrow.up", role: .confirm) {
            dismiss()
          }
          .disabled(title.isEmpty || description.isEmpty)
        }
      }
    }
  }

  private var termsOfUseButton: some View {
    HStack {
      Spacer()
      Button {

      } label: {
        Text("terms of use")
          .underline()
      }
      .tint(.secondary)
    }
  }

  private var flairSelector: some View {
    Menu {
      Button("No flair") {
        withAnimation(.spring()) { selectedFlair = "No flair" }
      }
      ForEach(viewModel.flairList, id: \.self) { flair in
        Button(flair) {
          withAnimation(.spring()) { selectedFlair = flair }
        }
      }
    } label: {
      HStack {
        Text(selectedFlair)
          .contentTransition(.numericText())
        Image(systemName: "chevron.down")
      }
      .padding(8)
      .padding(.horizontal, 4)
      .background {
        Capsule()
          .fill(Color(uiColor: UIColor.systemGray6))
      }
    }
//    .buttonStyle(.bordered)
//    .buttonBorderShape(.capsule)
    .foregroundStyle(.primary)
    .font(.subheadline)
    .fontWeight(.semibold)
  }
}

#Preview {
  PostComposeView()
    .environment(PostListViewModel())
}
