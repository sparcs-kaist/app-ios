//
//  DynamicHeightWebView.swift
//  soap
//
//  Created by Soongyu Kwon on 24/05/2025.
//

import SwiftUI
import WebKit

struct DynamicHeightWebView: UIViewRepresentable {
  // The HTML content to display. Ignored when `request` is set.
  let htmlString: String

  // A binding to communicate the calculated height of the web content back to the parent view.
  @Binding var dynamicHeight: CGFloat

  // When set, loads this request instead of `htmlString`.
  var request: URLRequest? = nil

  var onLinkTapped: ((URL) -> Void)?

  @Environment(\.colorScheme) private var colorScheme

  func makeUIView(context: Context) -> WKWebView {
    let configuration = WKWebViewConfiguration()
    configuration.userContentController.add(context.coordinator, name: "HeightChannel")

    let webView = WKWebView(frame: .zero, configuration: configuration)
    webView.scrollView.isScrollEnabled = false
    webView.navigationDelegate = context.coordinator
    webView.isOpaque = false
    webView.backgroundColor = UIColor.clear
    webView.scrollView.backgroundColor = UIColor.clear
    webView.underPageBackgroundColor = UIColor.clear

    return webView
  }

  func updateUIView(_ uiView: WKWebView, context: Context) {
    // Re-apply theme whenever the system color scheme changes.
    context.coordinator.applyTheme(webView: uiView, isDark: colorScheme == .dark)

    guard !context.coordinator.hasLoaded else { return }
    context.coordinator.hasLoaded = true

    if let request {
      uiView.load(request)
    } else {
      let textColor = colorScheme == .dark ? "#e0e0e0" : "#000000"
      let fullHTML = """
          <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, shrink-to-fit=no">
            <style>
              html, body {
                margin: 0; padding: 0; width: 100%;
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                background: transparent; color: \(textColor);
              }
              img { max-width: 100%; height: auto; display: block; }
              p { margin: 0 0 1em; }
            </style>
          </head>
          <body>\(htmlString)</body>
          </html>
          """
      uiView.loadHTMLString(fullHTML, baseURL: nil)
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    var parent: DynamicHeightWebView
    var hasLoaded = false

    // Once fitted from onPageFinished, further updates come only via HeightChannel.
    private var isFitted = false
    private var currentHeight: CGFloat = 0
    private var heightReportCount = 0
    private let maxHeightReports = 30

    init(_ parent: DynamicHeightWebView) {
      self.parent = parent
    }

    // MARK: - Theme injection

    /// Imperatively injects CSS overrides after the page has loaded.
    /// Called from updateUIView so it re-runs whenever colorScheme changes.
    func applyTheme(webView: WKWebView, isDark: Bool) {
      // Only inject once the page has actually finished loading.
      guard isFitted else { return }

      let textColor = isDark ? "#e0e0e0" : "#1a1a1a"
      let linkColor = isDark ? "#80bfff" : "#0066cc"

      let js = """
        (function() {
          var id = '__ara_theme_style__';
          var existing = document.getElementById(id);
          if (existing) existing.remove();
          var s = document.createElement('style');
          s.id = id;
          s.textContent = `
            html, body, body * {
              background: transparent !important;
              background-color: transparent !important;
            }
            body, body * {
              color: \(textColor) !important;
            }
            a, a * { color: \(linkColor) !important; }
            img { max-width: 100% !important; height: auto !important; }
          `;
          document.head.appendChild(s);
        })();
        """
      webView.evaluateJavaScript(js, completionHandler: nil)
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      guard !isFitted else { return }

      // Mark as fitted before applyTheme so it proceeds.
      isFitted = true

      // Apply theme immediately after page load.
      applyTheme(webView: webView, isDark: parent.colorScheme == .dark)

      // Initial height measurement.
      updatePageHeight(webView: webView)

      // For remote URLs, inject the ResizeObserver + MutationObserver + polling
      // script — exactly mirroring the Flutter _injectResizeObserver approach.
      if parent.request != nil {
        injectResizeObserver(webView: webView)
      }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void) {
      if navigationAction.navigationType == .linkActivated,
         let url = navigationAction.request.url {
        parent.onLinkTapped?(url)
        decisionHandler(.cancel)
        return
      }
      decisionHandler(.allow)
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
      guard heightReportCount < maxHeightReports else { return }

      let newHeight: CGFloat
      if let str = message.body as? String, let d = Double(str) {
        newHeight = CGFloat(d)
      } else if let d = message.body as? Double {
        newHeight = CGFloat(d)
      } else {
        return
      }

      guard newHeight > 0, abs(newHeight - currentHeight) > 10 else { return }
      heightReportCount += 1
      currentHeight = newHeight
      DispatchQueue.main.async {
        self.parent.dynamicHeight = newHeight
      }
    }

    // MARK: - Private helpers

    private func updatePageHeight(webView: WKWebView) {
      webView.evaluateJavaScript("""
        Math.max(
          document.body.scrollHeight || 0,
          document.documentElement.scrollHeight || 0,
          document.body.offsetHeight || 0,
          document.documentElement.offsetHeight || 0,
          document.body.clientHeight || 0,
          document.documentElement.clientHeight || 0
        )
        """) { [weak self] result, _ in
        guard let self else { return }
        let h: CGFloat
        if let d = result as? Double { h = CGFloat(d) }
        else if let i = result as? Int { h = CGFloat(i) }
        else { return }
        guard h > 0, abs(h - self.currentHeight) > 10 else { return }
        self.currentHeight = h
        DispatchQueue.main.async { self.parent.dynamicHeight = h }
      }
    }

    /// Injects ResizeObserver + MutationObserver + setInterval polling into the
    /// page — exactly mirrors Flutter's _injectResizeObserver. All height
    /// updates are pushed via HeightChannel.postMessage so the native cap
    /// (maxHeightReports) applies uniformly.
    private func injectResizeObserver(webView: WKWebView) {
      webView.evaluateJavaScript("""
        (function() {
          if (window._araResizeObserverInstalled) return;
          window._araResizeObserverInstalled = true;
          var lastHeight = 0;
          function reportHeight() {
            var h = Math.max(
              document.body.scrollHeight || 0,
              document.documentElement.scrollHeight || 0,
              document.body.offsetHeight || 0,
              document.documentElement.offsetHeight || 0
            );
            if (h !== lastHeight && h > 0) {
              lastHeight = h;
              window.webkit.messageHandlers.HeightChannel.postMessage(h.toString());
            }
          }
          if (typeof ResizeObserver !== 'undefined') {
            new ResizeObserver(function() { reportHeight(); }).observe(document.body);
          }
          new MutationObserver(function() { reportHeight(); }).observe(
            document.body, { childList: true, subtree: true, attributes: true }
          );
          var pollCount = 0;
          var pollInterval = setInterval(function() {
            reportHeight();
            pollCount++;
            if (pollCount > 20) clearInterval(pollInterval);
          }, 500);
          reportHeight();
        })();
        """, completionHandler: nil)
    }
  }
}
