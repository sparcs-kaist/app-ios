//
//  CreditsSummaryCard.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 26/09/2026.
//

import SwiftUI

/// The Timetable screen's entry to Credits: cumulative GPA and credits, styled like
/// the screen's other cards.
struct CreditsSummaryCard: View {
	static let transitionID = "credits"

	let gpa: Double?
	let earnedCredits: Int
	let graduationCredits: Int
	/// Every semester has loaded; until then the numbers are redacted.
	let isReady: Bool
	/// The semester list has arrived, or failed; Credits then shows the data or a retry.
	let isEnabled: Bool
	let namespace: Namespace.ID
	let onTap: () -> Void

	/// `timetableCardStyle`'s corner radius, so the zoom keeps the card's shape.
	private static let cornerRadius: CGFloat = 28

	var body: some View {
		Button {
			onTap()
		} label: {
			GPASummaryContent(gpa: gpa, earnedCredits: earnedCredits, graduationCredits: graduationCredits)
				.redacted(reason: isReady ? [] : .placeholder)
				.frame(maxWidth: .infinity, alignment: .leading)
				.timetableCardStyle()
				.contentShape(.rect(cornerRadius: Self.cornerRadius))
		}
		.buttonStyle(.plain)
		.accessibilityHint(String(localized: "Shows your credits and GPA", bundle: .module))
		.disabled(!isEnabled)
		.matchedTransitionSource(id: Self.transitionID, in: namespace) { source in
			source.clipShape(.rect(cornerRadius: Self.cornerRadius))
		}
	}
}
