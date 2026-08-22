//
//  PlatformImage+Extensions.swift
//  soap
//
//  Created by Soongyu Kwon on 28/07/2025.
//

import Foundation
import BuddyDomain
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public extension PlatformImage {
  func compressForUpload(maxSizeMB: Double = 1.0, maxDimension: CGFloat = 1024) -> Data? {
    let maxBytes = Int(maxSizeMB * 1024 * 1024)

    // Step 1: Reduce resolution
    let resizedImage = self.resized(to: maxDimension)

    // Step 2: JPEG compression (much smaller than PNG)
    var compressionQuality: CGFloat = 0.8
    var imageData = resizedImage.jpegData(quality: compressionQuality)

    // Step 3: Gradually reduce quality to fit size
    while let data = imageData, data.count > maxBytes && compressionQuality > 0.1 {
      compressionQuality -= 0.1
      imageData = resizedImage.jpegData(quality: compressionQuality)
    }

    return imageData
  }

  private func resized(to maxDimension: CGFloat) -> PlatformImage {
    let ratio = min(maxDimension / size.width, maxDimension / size.height)

    // If already small enough, return as is
    if ratio >= 1.0 {
      return self
    }

    let newSize = CGSize(
      width: size.width * ratio,
      height: size.height * ratio
    )

    #if os(iOS)
    let renderer = UIGraphicsImageRenderer(size: newSize)
    return renderer.image { _ in
      self.draw(in: CGRect(origin: .zero, size: newSize))
    }
    #elseif os(macOS)
    let resized = NSImage(size: newSize)
    resized.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    draw(
      in: CGRect(origin: .zero, size: newSize),
      from: CGRect(origin: .zero, size: size),
      operation: .copy,
      fraction: 1.0
    )
    resized.unlockFocus()
    return resized
    #endif
  }

  /// JPEG bytes at the given quality. `UIImage.jpegData(compressionQuality:)` has no
  /// AppKit equivalent, so macOS goes through an NSBitmapImageRep.
  private func jpegData(quality: CGFloat) -> Data? {
    #if os(iOS)
    return jpegData(compressionQuality: quality)
    #elseif os(macOS)
    guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      return nil
    }
    return NSBitmapImageRep(cgImage: cgImage).representation(
      using: .jpeg,
      properties: [.compressionFactor: quality]
    )
    #endif
  }
}
