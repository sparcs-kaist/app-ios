//
//  TimetableThemeSharingView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 9/15/26.
//

import SwiftUI
import UIKit
import BuddyDomain
import BuddyFeatureShared

public enum TimetableThemeSharingViewState: Equatable {
	case loading
	case shared(code: String)
	case failed(message: String)
}

struct TimetableThemeSharingView: View {
	let theme: TimetableTheme
	
	@Environment(\.dismiss) private var dismiss
	
	@State private var viewModel = TimetableThemeSharingViewModel()
	@State private var didCopyCode = false
	@State private var sharedImage: ThemeShareImage?
	@State private var isShareErrorPresented = false
	
	var body: some View {
		NavigationStack {
			VStack {
				ThemedSampleGrid(theme: theme, timetable: TimetableThemeSample.timetable)
				
				Spacer()
				
				switch viewModel.viewState {
				case .loading:
					loadingView
				case .shared(let code):
					loadedView(code: code)
				case .failed(let message):
					failedView(message: message)
				}
				
				Spacer()
				
				switch viewModel.viewState {
				case .loading:
					Button(action: {}, label: { shareLabel })
						.buttonStyle(.glassProminent)
						.disabled(true)
						.transition(.blurReplace)
				case .shared(let code):
					Button {
						shareAsImage(code: code)
					} label: {
						shareLabel
					}
					.buttonStyle(.glassProminent)
					.transition(.blurReplace)
				case .failed:
					retryButton
						.transition(.blurReplace)
				}
			}
			.animation(.smooth, value: viewModel.viewState)
			.padding(.horizontal)
			.navigationBarTitleDisplayMode(.inline)
			.navigationTitle(Text("Share \"\(theme.displayName)\"", bundle: .module))
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Close", systemImage: "xmark", role: .close) {
						dismiss()
					}
				}
			}
		}
		.presentationDragIndicator(.visible)
		.task { await viewModel.share(theme) }
		.sheet(item: $sharedImage) { item in
			ActivityView(
				activityItems: [item.source],
				applicationActivities: [InstagramStoryActivity(
					appID: "2510700999432824",
					backgroundColorHex: item.backgroundColorHex
				)]
			)
		}
		.alert(Text("Error", bundle: .module), isPresented: $isShareErrorPresented) {
			Button(String(localized: "Okay", bundle: .module), role: .close) { }
		} message: {
			Text("Unable to create the theme image. Please try again.", bundle: .module)
		}
	}

	/// Mirrors the timetable share export: a transparent sticker for Instagram
	/// and a padded, theme-coloured image for everything else.
	private func shareAsImage(code: String) {
		// Themes without a background use the light system background for exports.
		let backgroundColorHex = theme.backgroundColorHex ?? "F2F2F7"

		let renderer = ImageRenderer(content:
			TimetableThemeShareRenderingView(theme: theme, code: code)
				.environment(\.colorScheme, .light)
		)
		renderer.scale = 3
		renderer.isOpaque = false

		do {
			guard let stickerImage = renderer.uiImage else { throw CocoaError(.fileWriteUnknown) }
			// Give regular image exports a visible theme-coloured border. Instagram
			// receives the original transparent sticker without this extra padding.
			let padding: CGFloat = 24
			let imageSize = CGSize(
				width: stickerImage.size.width + padding * 2,
				height: stickerImage.size.height + padding * 2
			)
			let format = UIGraphicsImageRendererFormat()
			format.scale = stickerImage.scale
			format.opaque = true
			let image = UIGraphicsImageRenderer(size: imageSize, format: format).image { context in
				let bounds = CGRect(origin: .zero, size: imageSize)
				UIColor(Color(hex: backgroundColorHex)).setFill()
				context.fill(bounds)
				stickerImage.draw(in: CGRect(origin: CGPoint(x: padding, y: padding), size: stickerImage.size))
			}
			let source = try ImageActivityItemSource(image: image, title: theme.displayName, instagramStoryImage: stickerImage)
			sharedImage = ThemeShareImage(source: source, backgroundColorHex: backgroundColorHex)
		} catch {
			isShareErrorPresented = true
		}
	}
	
	private var loadingView: some View {
		VStack {
			ProgressView()
			Text("Sharing \"\(theme.displayName)\"...", bundle: .module)
				.font(.caption)
		}
		.foregroundStyle(.secondary)
		.transition(.blurReplace)
	}
	
	private func loadedView(code: String) -> some View {
		VStack {
			Button {
				UIPasteboard.general.string = code
				didCopyCode = true
			} label: {
				HStack {
					Text(code)
						.font(.largeTitle)
						.fontDesign(.monospaced)

					Image(systemName: didCopyCode ? "checkmark" : "document.on.document")
						.contentTransition(.symbolEffect(.replace))
				}
				.padding()
				.background(Color(uiColor: .secondarySystemBackground), in: .rect(cornerRadius: 12))
			}
			.buttonStyle(.plain)
			.accessibilityIdentifier("theme.shareCode")
			.accessibilityLabel(Text(code))
			.accessibilityHint(Text("Copies the code", bundle: .module))
			// The checkmark is only confirmation, so it reverts to the copy symbol.
			.task(id: didCopyCode) {
				guard didCopyCode else { return }
				try? await Task.sleep(for: .seconds(2))
				didCopyCode = false
			}

			Text("Enter this code on another device to import this theme.", bundle: .module)
				.font(.footnote)
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)
				.padding()
		}
		.transition(.blurReplace)
	}
	
	private func failedView(message: String) -> some View {
		VStack {
			Image(systemName: "exclamationmark.triangle")
				.font(.largeTitle)
			
			Text(message)
				.font(.footnote)
				.multilineTextAlignment(.center)
				.padding()
				.accessibilityIdentifier("theme.shareError")
		}
		.foregroundStyle(.secondary)
		.transition(.blurReplace)
	}
	
	private var shareLabel: some View {
		Label(String(localized: "Share", bundle: .module), systemImage: "square.and.arrow.up")
			.padding(8)
			.frame(maxWidth: .infinity)
	}
	
	private var retryButton: some View {
		Button {
			Task { await viewModel.share(theme) }
		} label: {
			Label(String(localized: "Try Again", bundle: .module), systemImage: "arrow.clockwise")
				.padding(8)
				.frame(maxWidth: .infinity)
		}
		.buttonStyle(.glassProminent)
		.accessibilityIdentifier("theme.shareRetry")
	}
}

private struct ThemeShareImage: Identifiable {
	let id = UUID()
	let source: ImageActivityItemSource
	let backgroundColorHex: String
}

#Preview {
	@Previewable @State var showSheet = true
	
	NavigationStack {
	}
	.sheet(isPresented: $showSheet) {
		TimetableThemeSharingView(
			theme: TimetableTheme.builtIn
				.first { $0.id == "builtin.spring" }!
				.duplicated(named: "My Theme")
		)
	}
}
