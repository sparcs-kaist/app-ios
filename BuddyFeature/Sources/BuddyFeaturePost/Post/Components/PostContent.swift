//
//  PostContent.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 15/05/2025.
//

import SwiftUI
import BuddyFeatureShared

/// The optional AI summary plus the post's HTML body (with loading and error states).
struct PostContent: View {
  let summarisedContent: String?
  let requestProvider: () -> URLRequest?
  let onLinkTapped: (URL) -> Void

  @State private var htmlHeight: CGFloat = .zero
  @State private var isWebViewLoading: Bool = false
  @State private var webViewLoadError: DynamicHeightWebView.LoadError?
  @State private var webViewReloadToken: Int = 0

  var body: some View {
    if let summarisedContent {
      SummarisationView(text: summarisedContent)
        .padding(.bottom)
        .transition(.asymmetric(
          insertion: .offset(y: -10).combined(with: .opacity),
          removal: .opacity
        ))
    }

    ZStack {
      DynamicHeightWebView(
        htmlString: "",
        dynamicHeight: $htmlHeight,
        requestProvider: requestProvider,
        isLoading: $isWebViewLoading,
        loadError: $webViewLoadError,
        reloadToken: webViewReloadToken,
        onLinkTapped: onLinkTapped
      )
      .frame(height: max(1, htmlHeight))
      .opacity(webViewLoadError == nil ? 1 : 0)

      if isWebViewLoading && webViewLoadError == nil {
        ProgressView()
          .padding()
      }

      if let webViewLoadError {
        VStack(spacing: 12) {
          Text(webViewLoadError.errorDescription ?? String(localized: "Unable to load post.", bundle: .module))
            .font(.callout)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
          Button {
            self.webViewLoadError = nil
            webViewReloadToken += 1
          } label: {
            Text("Retry", bundle: .module)
          }
          .buttonStyle(.bordered)
        }
        .padding()
      }
    }
  }
}
