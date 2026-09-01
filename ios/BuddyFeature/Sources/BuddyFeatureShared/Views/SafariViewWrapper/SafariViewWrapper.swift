//
//  SafariViewWrapper.swift
//  soap
//
//  Created by Soongyu Kwon on 01/08/2025.
//

import SwiftUI
import SafariServices

public struct SafariViewWrapper: UIViewControllerRepresentable {
  public let url: URL

  public init(url: URL) {
    self.url = url
  }

  public func makeUIViewController(context: Context) -> SFSafariViewController {
    return SFSafariViewController(url: url)
  }

  public func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {

  }
}
