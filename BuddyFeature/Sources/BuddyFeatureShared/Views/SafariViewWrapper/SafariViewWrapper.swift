//
//  SafariViewWrapper.swift
//  soap
//
//  Created by Soongyu Kwon on 01/08/2025.
//

import SwiftUI
#if os(iOS)
import SafariServices
#elseif os(macOS)
import WebKit
#endif

#if os(iOS)

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

#elseif os(macOS)

/// macOS has no SFSafariViewController, so in-app browsing runs on a plain WKWebView.
/// Same initialiser as the iOS version, so the five call sites are unchanged.
public struct SafariViewWrapper: View {
  public let url: URL

  public init(url: URL) {
    self.url = url
  }

  public var body: some View {
    WebViewRepresentable(url: url)
      // These sheets are presented without an explicit size on macOS.
      .frame(minWidth: 800, minHeight: 600)
  }
}

private struct WebViewRepresentable: NSViewRepresentable {
  let url: URL

  func makeNSView(context: Context) -> WKWebView {
    let webView = WKWebView()
    webView.load(URLRequest(url: url))
    return webView
  }

  func updateNSView(_ webView: WKWebView, context: Context) {
    guard webView.url != url else { return }
    webView.load(URLRequest(url: url))
  }
}

#endif
