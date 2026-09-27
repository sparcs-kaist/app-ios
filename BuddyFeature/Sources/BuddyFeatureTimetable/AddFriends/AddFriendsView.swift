//
//  AddFriendsView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 9/26/26.
//

import SwiftUI
import BuddyDomain

struct AddFriendsView: View {
	var body: some View {
		NavigationStack {
			VStack {
				HStack {
					Text("Nearby Friends", bundle: .module)
						.font(.headline)
						.foregroundStyle(.primary.opacity(0.8))
					
					Spacer()
				}
				
				Text("Scanning for nearby friends...", bundle: .module)
					.foregroundStyle(.secondary)
					.padding()
				
				Spacer()
			}
			.padding()
			.navigationTitle("Add Friends")
		}
		.safeAreaBar(edge: .bottom) {
			Button("Add Friends via Code") {
				
			}
			.buttonSizing(.flexible)
			.controlSize(.large)
			.scenePadding()
			.buttonStyle(.glass)
		}
		.background {
			AnimatedMeshGradientView()
				.ignoresSafeArea()
		}
		// Scoped to this subtree; `.preferredColorScheme` would propagate to the
		// presenting window and briefly flash the parent dark while presenting.
		.environment(\.colorScheme, .dark)
	}
}

struct AnimatedMeshGradientView: View {
	var body: some View {
		TimelineView(.animation) { timeline in
			let t = timeline.date.timeIntervalSince1970
			let redY = Self.columnTop(at: t, index: 0)
			let blueY = Self.columnTop(at: t, index: 1)
			let purpleY = Self.columnTop(at: t, index: 2)
			let blueX = Float(0.50 + sin(t * 0.55) * 0.12)
			let topX = Float(0.50 + sin(t * 0.48) * 0.10)
			let bottomX = Float(0.50 + sin(t * 0.51 + 0.8) * 0.12)

			let red = Color(red: 0.34, green: 0.08, blue: 0.24)
			let blue = Color(red: 0.07, green: 0.18, blue: 0.46)
			let purple = Color(red: 0.20, green: 0.07, blue: 0.44)

			// Top row stays dark; each column's colour fades into it above its
			// animated height.
			MeshGradient(
				width: 3,
				height: 3,
				points: [
					[0, 0], [topX, 0], [1, 0],
					[0, redY], [blueX, blueY], [1, purpleY],
					[0, 1], [bottomX, 1], [1, 1]
				],
				colors: [
					Color(red: 0.01, green: 0.01, blue: 0.03),
					Color(red: 0.00, green: 0.00, blue: 0.02),
					Color(red: 0.01, green: 0.02, blue: 0.05),
					red, blue, purple,
					red, blue, purple
				]
			)
		}
	}

	/// Each colour is a column rising from the bottom edge, and the columns
	/// take turns reaching for the top. Every column gets the same pulse offset
	/// by a third of a cycle; raising it to the 4th power keeps the pulse narrow,
	/// so only one column is tall at a time while the others rest low. A small
	/// slow wobble keeps the resting columns from looking frozen.
	private static func columnTop(at t: TimeInterval, index: Double) -> Float {
		let phase = index * 2 * .pi / 3
		let pulse = pow((1 + cos(t * 0.35 - phase)) / 2, 4)
		let wobble = sin(t * 0.27 + phase * 1.7) * 0.04
		return Float(0.80 - pulse * 0.55 + wobble)
	}
}

#Preview {
	@Previewable @State var showSheet = true
	
	NavigationStack {
		Button("hello") {
			showSheet = true
		}
		.sheet(isPresented: $showSheet) {
			AddFriendsView()
		}
	}
}
