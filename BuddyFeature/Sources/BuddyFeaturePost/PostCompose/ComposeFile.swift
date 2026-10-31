//
//  ComposeFile.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 24/10/2026.
//

import Foundation
import UniformTypeIdentifiers
import BuddyDomain

/// A file attached to a post being written, listed under the text rather than placed in it:
/// one picked from Files, or one the edited post already has.
struct ComposeFile: Identifiable, Hashable, Sendable {
  enum Source: Hashable, Sendable {
    /// A copy in the app's temporary directory, uploaded when the post is sent.
    case local(URL)
    /// Already on Ara, kept by its id.
    case existing(id: Int)
  }

  let id = UUID()
  let name: String
  let size: Int
  let mimeType: String
  let source: Source

  /// The extensions Ara accepts for an attachment. Photos go in the text instead.
  static let allowedTypes: [UTType] = [
    "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "zip", "tar", "gz", "mp4", "mp3",
  ].compactMap { UTType(filenameExtension: $0) }

  init(existing attachment: AraPostAttachment) {
    name = attachment.filename.removingPercentEncoding ?? attachment.filename
    size = attachment.size
    mimeType = attachment.mimeType
    source = .existing(id: attachment.id)
  }

  /// Copies a picked file so it outlives its security scope, ready to upload later.
  init(picked url: URL) throws {
    let accessing = url.startAccessingSecurityScopedResource()
    defer { if accessing { url.stopAccessingSecurityScopedResource() } }

    let directory = FileManager.default.temporaryDirectory
      .appending(path: "ComposeFiles/\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let copy = directory.appending(path: url.lastPathComponent)
    try FileManager.default.copyItem(at: url, to: copy)

    let values = try copy.resourceValues(forKeys: [.fileSizeKey, .contentTypeKey])
    name = url.lastPathComponent
    size = values.fileSize ?? 0
    mimeType = values.contentType?.preferredMIMEType ?? "application/octet-stream"
    source = .local(copy)
  }
}
