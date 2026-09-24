import SwiftUI
import UIKit

public struct ActivityView: UIViewControllerRepresentable {
  private let activityItems: [Any]
  private let applicationActivities: [UIActivity]?

  public init(activityItems: [Any], applicationActivities: [UIActivity]? = nil) {
    self.activityItems = activityItems
    self.applicationActivities = applicationActivities
  }

  public func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
  }

  public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}
