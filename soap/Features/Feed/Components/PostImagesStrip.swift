//
//  PostImagesStrip.swift
//  soap
//
//  Created by Soongyu Kwon on 20/08/2025.
//

import SwiftUI
import BuddyDomain

struct PostImagesStrip: View {
  let images: [FeedImage]
  private let hPadding: CGFloat = 16 // match your .padding(.horizontal, 16)

  @State private var parentWidth: CGFloat = 0

  var body: some View {
    // Fallback to screen width until we read the actual width
    let pw = parentWidth > 0 ? parentWidth : CGFloat.screenWidth
    let contentWidth = max(0, pw - hPadding * 2)
    let maxW = contentWidth
    let height = maxW * 3 / 4
    
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 12) {
        ForEach(images) { item in
          FeedLazyImage(item: item)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
      }
      .padding(.horizontal, hPadding)
    }
    .frame(height: height)                 // fixes row height to 16:9 of parent width (minus padding)
    .measureWidth { parentWidth = $0 }     // read parent width
  }
}
