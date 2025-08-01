//
//  SafariViewWrapper.swift
//  soap
//
//  Created by Soongyu Kwon on 01/08/2025.
//

import SwiftUI
import SafariServices

struct SafariViewWrapper: UIViewControllerRepresentable {
  let url: URL

  func makeUIViewController(context: Context) -> SFSafariViewController {
    return SFSafariViewController(url: url)
  }

  func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {

  }
}
