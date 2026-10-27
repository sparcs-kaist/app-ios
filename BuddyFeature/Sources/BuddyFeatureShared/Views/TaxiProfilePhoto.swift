//
//  TaxiProfilePhoto.swift
//  BuddyFeature
//

import SwiftUI
import NukeUI
import BuddyDomain

/// A rider's photo in a circle, sized by the caller, over a grey circle that stands in for it
/// while it loads, when there is none, when it fails to load, and behind one that comes back
/// empty or transparent.
public struct TaxiProfilePhoto: View {
  let url: URL?

  public init(url: URL?) {
    self.url = url
  }

  public var body: some View {
    Circle()
      .fill(Color.systemGray4)
      .overlay {
        if let url {
          LazyImage(url: url) { state in
            if let image = state.image {
              image
                .resizable()
                .aspectRatio(contentMode: .fill)
            }
          }
        }
      }
      .clipShape(.circle)
  }
}
