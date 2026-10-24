//
//  ComposeFileList.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 24/10/2026.
//

import SwiftUI
import UniformTypeIdentifiers

/// The files attached to a post being written, each removable.
struct ComposeFileList: View {
  let files: [ComposeFile]
  let onRemove: (ComposeFile) -> Void

  var body: some View {
    VStack(spacing: 8) {
      ForEach(files) { file in
        HStack(spacing: 12) {
          Image(systemName: Self.symbol(for: file))
            .font(.title3)
            .foregroundStyle(Color.accentColor)
            .frame(width: 28)

          VStack(alignment: .leading, spacing: 2) {
            Text(file.name)
              .font(.subheadline)
              .lineLimit(1)
              .truncationMode(.middle)
            Text(Int64(file.size).formatted(.byteCount(style: .file)))
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity, alignment: .leading)

          Button(String(localized: "Remove", bundle: .module), systemImage: "xmark.circle.fill", role: .destructive) {
            withAnimation(.snappy) { onRemove(file) }
          }
          .labelStyle(.iconOnly)
          .font(.title3)
          .foregroundStyle(.secondary)
          .buttonStyle(.plain)
        }
        .padding(12)
        .background(.fill.quaternary, in: .rect(cornerRadius: 12, style: .continuous))
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
      }
    }
  }

  private static func symbol(for file: ComposeFile) -> String {
    guard let type = UTType(mimeType: file.mimeType)
      ?? UTType(filenameExtension: (file.name as NSString).pathExtension) else { return "doc" }
    if type.conforms(to: .image) { return "photo" }
    if type.conforms(to: .pdf) { return "doc.richtext" }
    if type.conforms(to: .spreadsheet) { return "tablecells" }
    if type.conforms(to: .presentation) { return "rectangle.on.rectangle" }
    if type.conforms(to: .archive) { return "doc.zipper" }
    if type.conforms(to: .audio) { return "waveform" }
    if type.conforms(to: .movie) { return "film" }
    return "doc"
  }
}
