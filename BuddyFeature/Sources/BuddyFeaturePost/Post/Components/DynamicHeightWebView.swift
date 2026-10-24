//
//  DynamicHeightWebView.swift
//  soap
//
//  Created by Soongyu Kwon on 24/05/2025.
//

import SwiftUI
import WebKit

/// Renders a post's HTML body locally, sized to fit its content.
///
/// Theming is plain CSS (`prefers-color-scheme`), so it follows the system without a reload.
/// The page's own scripts are disabled; height reporting runs in the app's own content world.
struct DynamicHeightWebView: UIViewRepresentable {
  let html: String
  /// Resolves relative image and link URLs in the HTML.
  let baseURL: URL?
  @Binding var height: CGFloat
  var onLinkTapped: (URL) -> Void

  private static let heightChannel = "height"

  func makeUIView(context: Context) -> WKWebView {
    let configuration = WKWebViewConfiguration()
    configuration.defaultWebpagePreferences.allowsContentJavaScript = false
    configuration.dataDetectorTypes = []

    let contentController = configuration.userContentController
    contentController.add(context.coordinator, contentWorld: .defaultClient, name: Self.heightChannel)
    contentController.addUserScript(WKUserScript(
      source: Self.heightReportingScript,
      injectionTime: .atDocumentEnd,
      forMainFrameOnly: true,
      in: .defaultClient
    ))

    let webView = WKWebView(frame: .zero, configuration: configuration)
    webView.scrollView.isScrollEnabled = false
    webView.navigationDelegate = context.coordinator
    webView.isOpaque = false
    webView.backgroundColor = .clear
    webView.scrollView.backgroundColor = .clear
    webView.underPageBackgroundColor = .clear
    return webView
  }

  func updateUIView(_ webView: WKWebView, context: Context) {
    context.coordinator.parent = self
    guard context.coordinator.loadedHTML != html else { return }
    context.coordinator.loadedHTML = html
    webView.loadHTMLString(Self.document(wrapping: html), baseURL: baseURL)
  }

  static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
    webView.configuration.userContentController.removeAllScriptMessageHandlers()
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  @MainActor
  final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    var parent: DynamicHeightWebView
    var loadedHTML: String?

    init(_ parent: DynamicHeightWebView) {
      self.parent = parent
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
      guard let height = (message.body as? NSNumber).map({ CGFloat(truncating: $0) }),
            height > 0, height != parent.height else { return }
      parent.height = height
    }

    func webView(
      _ webView: WKWebView,
      decidePolicyFor navigationAction: WKNavigationAction,
      decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
    ) {
      guard navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url else {
        // The initial `loadHTMLString` and embedded frames.
        decisionHandler(.allow)
        return
      }
      decisionHandler(.cancel)
      if ["http", "https"].contains(url.scheme?.lowercased()) {
        parent.onLinkTapped(url)
      } else {
        UIApplication.shared.open(url)
      }
    }
  }

  // MARK: - Document

  /// Measures the content wrapper rather than the document, which never reports less than
  /// the current frame and so couldn't shrink after rotation.
  private static let heightReportingScript = """
    (function() {
      var content = document.getElementById('content');
      if (!content) return;
      var last = 0;
      function report() {
        var height = Math.ceil(content.getBoundingClientRect().height);
        if (height !== last) {
          last = height;
          window.webkit.messageHandlers.\(heightChannel).postMessage(height);
        }
      }
      new ResizeObserver(report).observe(content);
      report();
    })();
    """

  private static func document(wrapping html: String) -> String {
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
      <style>
        :root { color-scheme: light dark; --text: #1a1a1a; --link: #0066cc; --rule: rgba(0, 0, 0, 0.15); }
        @media (prefers-color-scheme: dark) {
          :root { --text: #e0e0e0; --link: #80bfff; --rule: rgba(255, 255, 255, 0.2); }
        }
        html, body { margin: 0; padding: 0; -webkit-text-size-adjust: 100%; }
        body { font: -apple-system-body; line-height: 1.45; overflow-wrap: anywhere; }
        /* Portal notices carry inline colours and backgrounds picked for a white page. */
        html, body, body * { background: transparent !important; background-color: transparent !important; }
        body, body * { color: var(--text) !important; }
        a, a * { color: var(--link) !important; }
        #content > :first-child { margin-top: 0; }
        #content > :last-child { margin-bottom: 0; }
        p { margin: 0 0 0.8em; }
        img, video, iframe { max-width: 100% !important; height: auto !important; }
        img { border-radius: 8px; }
        pre { white-space: pre-wrap; font: -apple-system-footnote; font-family: ui-monospace, monospace; }
        blockquote { margin: 0 0 0.8em; padding-left: 12px; border-left: 3px solid var(--rule); }
        table { display: block; max-width: 100%; overflow-x: auto; border-collapse: collapse; }
        td, th { border: 1px solid var(--rule); padding: 4px 6px; }
        hr { border: none; border-top: 1px solid var(--rule); }
      </style>
    </head>
    <body><div id="content">\(html)</div></body>
    </html>
    """
  }
}
