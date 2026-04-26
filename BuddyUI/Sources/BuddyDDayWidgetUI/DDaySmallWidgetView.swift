//
//  DDaySmallWidgetView.swift
//  BuddyUI
//
//  Created by Soongyu Kwon on 4/26/26.
//

import SwiftUI
import BuddyDomain

public struct DDaySmallWidgetView: View {
	var entry: DDayEntry
	
	public init(entry: DDayEntry) {
		self.entry = entry
	}
	
	public var body: some View {
		switch entry.type {
		case .endOfSemester(let daysLeft, _, let description):
			VStack(alignment: .leading, spacing: 2) {
				Text("Ends in", bundle: .module)
					.font(.caption)
					.fontWeight(.medium)
					.foregroundStyle(.indigo)
					.textCase(.uppercase)
				
				HStack(alignment: .bottom, spacing: 4) {
					Text(String(daysLeft))
						.font(.system(size: 48))
						.fontDesign(.rounded)
						.frame(height: 48, alignment: .center)
						.offset(x: -2)
					
					Text("days", bundle: .module)
						.font(.callout)
						.fontDesign(.rounded)
						.padding(.bottom, 2)
					
					Spacer(minLength: 0)
				}
				
				Spacer()
				
				HStack {
					Text(description)
						.font(.callout)
						.foregroundStyle(.indigo)
						.fontWeight(.medium)
					
					Spacer()
				}
			}
		case .startOfSemester(let daysUntil, let description):
			VStack(alignment: .leading, spacing: 2) {
				Text("Starts in", bundle: .module)
					.font(.caption)
					.fontWeight(.medium)
					.foregroundStyle(.indigo)
					.textCase(.uppercase)
				
				HStack(alignment: .bottom, spacing: 4) {
					Text(String(daysUntil))
						.font(.system(size: 48))
						.fontDesign(.rounded)
						.frame(height: 48, alignment: .center)
						.offset(x: -2)
					
					Text("days", bundle: .module)
						.font(.callout)
						.fontDesign(.rounded)
						.padding(.bottom, 2)
					
					Spacer(minLength: 0)
				}
				
				Spacer()
				
				HStack {
					Text(description)
						.font(.callout)
						.foregroundStyle(.indigo)
						.fontWeight(.medium)
					
					Spacer()
				}
			}
		case .error:
			signInRequiredView
		}
	}
	
	private var signInRequiredView: some View {
		Text("Sign in to see upcoming classes.", bundle: .module)
			.multilineTextAlignment(.center)
	}
}
