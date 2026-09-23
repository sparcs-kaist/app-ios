import SwiftUI
import UIKit

public struct ActivityView: UIViewControllerRepresentable {
  private let activityItems: [Any]

  public init(activityItems: [Any]) {
    self.activityItems = activityItems
  }

  public func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
  }

  public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}
