//
//  UIImage+Extensions.swift
//  soap
//
//  Created by Soongyu Kwon on 28/07/2025.
//

import Foundation
import UIKit

extension UIImage {
  func compressForUpload(maxSizeMB: Double = 1.0, maxDimension: CGFloat = 1024) -> Data? {
    let maxBytes = Int(maxSizeMB * 1024 * 1024)

    // Step 1: Reduce resolution
    let resizedImage = self.resized(to: maxDimension)

    // Step 2: JPEG compression (much smaller than PNG)
    var compressionQuality: CGFloat = 0.8
    var imageData = resizedImage.jpegData(compressionQuality: compressionQuality)

    // Step 3: Gradually reduce quality to fit size
    while let data = imageData, data.count > maxBytes && compressionQuality > 0.1 {
      compressionQuality -= 0.1
      imageData = resizedImage.jpegData(compressionQuality: compressionQuality)
    }

    return imageData
  }

  private func resized(to maxDimension: CGFloat) -> UIImage {
    let ratio = min(maxDimension / size.width, maxDimension / size.height)

    // If already small enough, return as is
    if ratio >= 1.0 {
      return self
    }

    let newSize = CGSize(
      width: size.width * ratio,
      height: size.height * ratio
    )

    let renderer = UIGraphicsImageRenderer(size: newSize)
    return renderer.image { _ in
      self.draw(in: CGRect(origin: .zero, size: newSize))
    }
  }
}
