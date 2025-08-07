//
//  DynamicHeightWebView.swift
//  soap
//
//  Created by Soongyu Kwon on 24/05/2025.
//

import SwiftUI
import WebKit

struct DynamicHeightWebView: UIViewRepresentable {
  // The HTML content to display.
  let htmlString: String
  
  // A binding to communicate the calculated height of the web content back to the parent view.
  @Binding var dynamicHeight: CGFloat
  
  var onLinkTapped: ((URL) -> Void)?
  
  // Creates and configures the initial WKWebView.
  func makeUIView(context: Context) -> WKWebView {
    let webView = WKWebView()
    webView.scrollView.isScrollEnabled = false // Disable internal scrolling.
    webView.navigationDelegate = context.coordinator // Handle navigation events to calculate height.
    
    // Set background to clear to prevent a white flash during loading.
    webView.isOpaque = false
    webView.backgroundColor = UIColor.clear
    webView.scrollView.backgroundColor = UIColor.clear
    
    return webView
  }
  
  // Updates the WKWebView when the view's state changes.
  func updateUIView(_ uiView: WKWebView, context: Context) {
    // Construct the full HTML document with the necessary viewport and styling.
    // This ensures content scales correctly and avoids unwanted margins.
    let fullHTML = """
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, shrink-to-fit=no">
          <style>
            html, body {
              margin: 0;
              padding: 0;
              width: 100%;
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
              background-color: #fff;
              color: #000;
            }
        
            @media (prefers-color-scheme: dark) {
              html, body {
                background-color: #000;
                color: #fff;
              }
        
              html, body,
              [style*="background-color"],
              [style*="background:#fff"],
              [style*="background:white"],
              [style*="background-color: white"],
              [style*="background-color:#fff"],
              [style*="background-color:#ffffff"],
              [style*="background-color:rgb(255,255,255)"] {
                background-color: transparent !important;
                color: #fff !important;
              }
        
              [style*="color:#000"],
              [style*="color:#000000"],
              [style*="color:#000000;"],
              [style*="color:#111"],
              [style*="color:#111111"],
              [style*="color:rgb(0,0,0)"],
              [style*="color:hsl(0,0%,0%)"],
              [style*="color:hsl(0, 0%, 0%)"] {
                color: #fff !important;
              }
        
              *, *::before, *::after {
                color: #fff !important;
              }
        
              a { color: #80bfff; }
            }
        
            img {
              max-width: 100%;
              height: auto;
              display: block;
            }
        
            p {
              margin: 0 0 1em;
            }
          </style>
        </head>
        <body>
          \(htmlString)
        </body>
        </html>
        """
    uiView.loadHTMLString(fullHTML, baseURL: nil)
  }
  
  // Creates the coordinator that acts as the WKNavigationDelegate.
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  // The coordinator class handles communication from the WKWebView back to the SwiftUI view.
  class Coordinator: NSObject, WKNavigationDelegate {
    var parent: DynamicHeightWebView
    
    init(_ parent: DynamicHeightWebView) {
      self.parent = parent
    }
    
    // This delegate method is called when the web content has finished loading.
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      // After loading, execute JavaScript to get the total height of the document.
      webView.evaluateJavaScript("document.documentElement.scrollHeight") { (height, error) in
        DispatchQueue.main.async {
          if let contentHeight = height as? CGFloat {
            // Update the binding with the new height.
            self.parent.dynamicHeight = contentHeight
          }
        }
      }
    }
    
    // Handle link click inside the post
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void) {
      if navigationAction.navigationType == .linkActivated {
        if let url = navigationAction.request.url {
          parent.onLinkTapped?(url)
        }
        
        decisionHandler(.cancel)
        return
      }
      
      decisionHandler(.allow)
    }
  }
}
