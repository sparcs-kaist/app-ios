//
//  PostAttachmentList.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 24/10/2026.
//

import SwiftUI
import QuickLook
import UniformTypeIdentifiers
import BuddyDomain

/// Files attached to a post (PDFs, documents…), listed after the body. Tapping one downloads it
/// and opens it in Quick Look; the download button saves it to Files. Once downloaded, an open
/// button appears beside it.
struct PostAttachmentList: View {
  let attachments: [AraPostAttachment]

  @State private var loadingIDs: Set<Int> = []
  @State private var downloadedIDs: Set<Int> = []
  @State private var previewURL: URL?
  @State private var fileToSave: URL?
  @State private var errorMessage: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Attachments", bundle: .module)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)

      ForEach(attachments) { attachment in
        PostAttachmentRow(
          attachment: attachment,
          isLoading: loadingIDs.contains(attachment.id),
          isDownloaded: downloadedIDs.contains(attachment.id),
          onOpen: { Task { await open(attachment) } },
          onSave: { Task { await save(attachment) } }
        )
      }
    }
    .onAppear {
      // Files downloaded earlier in this launch are still in the temporary directory.
      downloadedIDs = Set(attachments.filter { attachment in
        localURL(for: attachment).map { FileManager.default.fileExists(atPath: $0.path(percentEncoded: false)) } ?? false
      }.map(\.id))
    }
    .quickLookPreview($previewURL)
    .fileMover(isPresented: Binding(get: { fileToSave != nil }, set: { if !$0 { fileToSave = nil } }), file: fileToSave) { result in
      if case .failure(let error) = result {
        errorMessage = error.localizedDescription
      }
    }
    .alert(
      String(localized: "Unable to Open File", bundle: .module),
      isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    ) {
      Button(String(localized: "OK", bundle: .module), role: .cancel) {}
    } message: {
      Text(errorMessage ?? "")
    }
  }

  private func open(_ attachment: AraPostAttachment) async {
    if let url = await download(attachment) {
      previewURL = url
    }
  }

  /// Saves a copy, since the file mover moves what it's given and the cached file is kept for Quick Look.
  private func save(_ attachment: AraPostAttachment) async {
    guard let url = await download(attachment) else { return }
    do {
      let copy = FileManager.default.temporaryDirectory
        .appending(path: "AttachmentExports/\(UUID().uuidString)", directoryHint: .isDirectory)
      try FileManager.default.createDirectory(at: copy, withIntermediateDirectories: true)
      let destination = copy.appending(path: url.lastPathComponent)
      try FileManager.default.copyItem(at: url, to: destination)
      fileToSave = destination
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  /// Where an attachment is kept once downloaded, named after the file.
  private func localURL(for attachment: AraPostAttachment) -> URL? {
    guard attachment.file != nil else { return nil }
    let directory = FileManager.default.temporaryDirectory
      .appending(path: "Attachments/\(attachment.id)", directoryHint: .isDirectory)
    let local = directory.appending(path: attachment.localFileName, directoryHint: .notDirectory)
    // The name comes from whoever uploaded it; never let it point anywhere but this folder.
    guard Array(local.standardizedFileURL.pathComponents.dropLast())
      == directory.standardizedFileURL.pathComponents else { return nil }
    return local
  }

  /// The attachment as a local file named after it, downloaded once and then reused.
  private func download(_ attachment: AraPostAttachment) async -> URL? {
    guard let remote = attachment.file, let local = localURL(for: attachment) else { return nil }
    let directory = local.deletingLastPathComponent()
    if FileManager.default.fileExists(atPath: local.path(percentEncoded: false)) {
      return local
    }

    loadingIDs.insert(attachment.id)
    defer { loadingIDs.remove(attachment.id) }
    do {
      let (downloaded, response) = try await URLSession.shared.download(from: remote)
      if let status = (response as? HTTPURLResponse)?.statusCode, !(200..<300).contains(status) {
        throw URLError(.badServerResponse)
      }
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      try? FileManager.default.removeItem(at: local)
      try FileManager.default.moveItem(at: downloaded, to: local)
      downloadedIDs.insert(attachment.id)
      return local
    } catch {
      errorMessage = error.localizedDescription
      return nil
    }
  }
}

/// One file: its type's icon, name and size, opening on tap.
private struct PostAttachmentRow: View {
  let attachment: AraPostAttachment
  let isLoading: Bool
  let isDownloaded: Bool
  let onOpen: () -> Void
  let onSave: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      Button(action: onOpen) {
        HStack(spacing: 12) {
          Image(systemName: attachment.symbolName)
            .font(.title3)
            .foregroundStyle(Color.accentColor)
            .frame(width: 28)

          VStack(alignment: .leading, spacing: 2) {
            Text(attachment.displayName)
              .font(.subheadline)
              .foregroundStyle(.primary)
              .lineLimit(1)
              .truncationMode(.middle)
            Text(attachment.size.formatted(.byteCount(style: .file)))
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(.rect)
      }
      .buttonStyle(.plain)

      if isDownloaded && !isLoading {
        Button(String(localized: "Open", bundle: .module), systemImage: "arrow.up.forward.square", action: onOpen)
          .labelStyle(.iconOnly)
          .font(.title3)
          .frame(width: 28)
      }

      if isLoading {
        ProgressView()
          .frame(width: 28)
      } else {
        Button(String(localized: "Save to Files", bundle: .module), systemImage: "arrow.down.circle", action: onSave)
          .labelStyle(.iconOnly)
          .font(.title3)
          .frame(width: 28)
      }
    }
    .padding(12)
    .background(.fill.quaternary, in: .rect(cornerRadius: 12, style: .continuous))
    .disabled(isLoading || attachment.file == nil)
  }
}

extension AraPostAttachment {
  /// The file name without the percent-encoding it has in the URL.
  var displayName: String {
    filename.removingPercentEncoding ?? filename
  }

  /// `displayName` made safe to save under: a single path component, so a name such as
  /// `../../Documents` (or its percent-encoded form) can't reach outside the download folder.
  var localFileName: String {
    let name = displayName
      .map { "/\\:\0".contains($0) ? "_" : String($0) }
      .joined()
      .trimmingCharacters(in: .whitespacesAndNewlines)
    return name.isEmpty || name.allSatisfy({ $0 == "." }) ? "attachment" : name
  }

  var symbolName: String {
    guard let type = UTType(mimeType: mimeType) ?? UTType(filenameExtension: (displayName as NSString).pathExtension) else {
      return "doc"
    }
    if type.conforms(to: .pdf) { return "doc.richtext" }
    if type.conforms(to: .spreadsheet) { return "tablecells" }
    if type.conforms(to: .presentation) { return "rectangle.on.rectangle" }
    if type.conforms(to: .archive) { return "doc.zipper" }
    if type.conforms(to: .audio) { return "waveform" }
    if type.conforms(to: .movie) { return "film" }
    if type.conforms(to: .text) { return "doc.text" }
    return "doc"
  }
}
