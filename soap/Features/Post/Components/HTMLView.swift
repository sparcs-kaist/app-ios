//
//  HTMLView.swift
//  soap
//
//  Created by Soongyu Kwon on 24/05/2025.
//

import SwiftUI
import WebKit

struct HTMLView: UIViewRepresentable {
  @Binding var contentHeight: CGFloat
  let htmlString: String

  func makeUIView(context: Context) -> WKWebView {
    let webView = WKWebView()
    webView.scrollView.isScrollEnabled = false
    // 1) Observe contentSize
    webView.scrollView.addObserver(
      context.coordinator,
      forKeyPath: "contentSize",
      options: .new,
      context: nil
    )
    return webView
  }

  func updateUIView(_ webView: WKWebView, context: Context) {
    // 2) Reset HTML margins/padding & include viewport
    let fullHTML = """
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        html, body {
          margin: 0;
          padding: 0;
          width: 100%;
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
        }
        img {
          max-width: 100%;
          height: auto;
          display: block;
        }
      </style>
    </head>
    <body>
      \(htmlString)
    </body>
    </html>
    """
    webView.loadHTMLString(fullHTML, baseURL: nil)
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject {
    var parent: HTMLView

    init(_ parent: HTMLView) {
      self.parent = parent
    }

    override func observeValue(
      forKeyPath keyPath: String?,
      of object: Any?,
      change: [NSKeyValueChangeKey : Any]?,
      context: UnsafeMutableRawPointer?
    ) {
      if keyPath == "contentSize",
         let scroll = object as? UIScrollView,
         scroll == (scroll.superview as? WKWebView)?.scrollView,
         let newSize = change?[.newKey] as? CGSize {
        DispatchQueue.main.async {
          self.parent.contentHeight = newSize.height
        }
      }
    }

    deinit {
      // Note: WKWebView’s scrollView will remove observers when deallocated,
      // but if you ever reuse the webView you’d remove observer here.
    }
  }
}
