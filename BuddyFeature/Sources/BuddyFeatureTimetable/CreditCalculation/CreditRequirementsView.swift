//
//  CreditRequirementsView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 26/09/2026.
//

import SwiftUI
import BuddyDomain

/// Credits taken per requirement type against the user's editable minimums,
/// grouped into cards: graduation, basic, each major, humanities, AU and other.
/// One column on iPhone; pairs of equal-height cards on wide screens.
struct CreditRequirementsView: View {
	let viewModel: CreditCalculationViewModel

	@State private var isEditing = false
	@State private var width: CGFloat = 0

	var body: some View {
		let breakdown = viewModel.creditBreakdown
		let groups = Self.groups(
			breakdown: breakdown,
			requirements: viewModel.requirements,
			earnedCredits: viewModel.overallSummary.earnedCredits
		)

		ScrollView {
			VStack(spacing: 20) {
				if CreditLayout.isWide(width) {
					ForEach(Self.pairs(of: groups), id: \.first.id) { pair in
						// Fixed vertical size lets both cards stretch to the taller one.
						HStack(alignment: .top, spacing: 20) {
							RequirementSection(group: pair.first)
							if let second = pair.second {
								RequirementSection(group: second)
							} else {
								Color.clear.frame(maxWidth: .infinity)
							}
						}
						.fixedSize(horizontal: false, vertical: true)
					}
				} else {
					ForEach(groups) { group in
						RequirementSection(group: group)
					}
				}

				Text("Minimums differ by department and admission year. Tap Edit to match your own.", bundle: .module)
					.font(.footnote)
					.foregroundStyle(.secondary)
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(.horizontal, 4)
			}
			.padding()
			.creditContentWidth()
		}
		.onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
		.background(Color.systemGroupedBackground)
		.navigationTitle(String(localized: "Credit Requirements", bundle: .module))
		.toolbarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Button(String(localized: "Edit", bundle: .module)) {
					isEditing = true
				}
			}
		}
		.sheet(isPresented: $isEditing) {
			CreditRequirementsEditor(
				requirements: viewModel.requirements,
				departments: breakdown.majors.map(\.department),
				onSave: viewModel.updateRequirements
			)
		}
	}

	/// The cards to show, in order.
	private static func groups(
		breakdown: CreditBreakdown,
		requirements: CreditRequirements,
		earnedCredits: Int
	) -> [RequirementGroup] {
		var groups = [
			RequirementGroup(id: "graduation", title: String(localized: "Graduation", bundle: .module), systemImage: "graduationcap", rows: [
				RequirementItem(title: String(localized: "Total Credits", bundle: .module), taken: earnedCredits, minimum: requirements.graduation)
			]),
			RequirementGroup(id: "basic", title: String(localized: "Basic", bundle: .module), systemImage: "books.vertical", rows: [
				RequirementItem(title: String(localized: "Basic Required", bundle: .module), taken: breakdown.basicRequired, minimum: requirements.basicRequired),
				RequirementItem(title: String(localized: "Basic Elective", bundle: .module), taken: breakdown.basicElective, minimum: requirements.basicElective)
			])
		]

		groups += breakdown.majors.map { group in
			RequirementGroup(id: "major-\(group.id)", title: group.department.name, systemImage: "building.columns", rows: [
				RequirementItem(title: String(localized: "Major Required", bundle: .module), taken: group.required, minimum: requirements.majorRequired(for: group.department)),
				RequirementItem(title: String(localized: "Major Elective", bundle: .module), taken: group.elective, minimum: requirements.majorElective(for: group.department))
			])
		}

		var hseRows = [
			RequirementItem(title: String(localized: "HSE Core", bundle: .module), taken: breakdown.hseCore, minimum: requirements.hseCore),
			RequirementItem(title: String(localized: "HSE General", bundle: .module), taken: breakdown.hseGeneral, minimum: requirements.hseGeneral)
		]
		// Older curricula without a core/general split have no minimum of their own.
		if breakdown.hse > 0 {
			hseRows.append(RequirementItem(title: String(localized: "HSE", bundle: .module), taken: breakdown.hse, minimum: nil))
		}
		groups.append(RequirementGroup(id: "hse", title: String(localized: "Humanities & Social", bundle: .module), systemImage: "person.2", rows: hseRows))

		groups.append(RequirementGroup(id: "au", title: String(localized: "AU", bundle: .module), systemImage: "figure.run", rows: [
			RequirementItem(title: String(localized: "AU", bundle: .module), taken: breakdown.au, minimum: requirements.au, unit: .au)
		]))

		if breakdown.etc > 0 {
			groups.append(RequirementGroup(id: "other", title: String(localized: "Other", bundle: .module), systemImage: "ellipsis.circle", rows: [
				RequirementItem(title: String(localized: "ETC", bundle: .module), taken: breakdown.etc, minimum: nil)
			]))
		}
		return groups
	}

	/// Groups two at a time for the wide layout's rows; the last may be alone.
	private static func pairs(of groups: [RequirementGroup]) -> [(first: RequirementGroup, second: RequirementGroup?)] {
		stride(from: 0, to: groups.count, by: 2).map { index in
			(groups[index], index + 1 < groups.count ? groups[index + 1] : nil)
		}
	}
}

// MARK: - Cards

/// One card's content: a header and its requirement rows.
private struct RequirementGroup: Identifiable {
	let id: String
	let title: String
	let systemImage: String
	let rows: [RequirementItem]
}

private struct RequirementItem: Identifiable {
	var id: String { title }
	let title: String
	let taken: Int
	/// `nil` for types without a minimum; those show the count only.
	let minimum: Int?
	var unit: RequirementUnit = .credits
}

/// One group of requirements in its own card, under an icon + title header.
/// Fills the height it's offered, so paired cards line up on wide screens.
private struct RequirementSection: View {
	let group: RequirementGroup

	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			Label(group.title, systemImage: group.systemImage)
				.font(.subheadline)
				.fontWeight(.semibold)
				.foregroundStyle(.secondary)

			ForEach(group.rows) { row in
				RequirementRow(title: row.title, taken: row.taken, minimum: row.minimum, unit: row.unit)
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
		.timetableCardStyle()
	}
}

private enum RequirementUnit { case credits, au }

/// A type's taken credits against its minimum. Taken may exceed the minimum; the
/// bar then stays full and the row is marked as met.
private struct RequirementRow: View {
	let title: String
	let taken: Int
	/// `nil` for types without a minimum; those show the count only.
	let minimum: Int?
	var unit: RequirementUnit = .credits

	private var isMet: Bool { minimum.map { taken >= $0 } ?? false }

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack(alignment: .firstTextBaseline, spacing: 6) {
				Text(title)
					.font(.subheadline)

				Spacer()

				if isMet {
					Image(systemName: "checkmark.circle.fill")
						.font(.footnote)
						.foregroundStyle(.green)
				}

				HStack(alignment: .firstTextBaseline, spacing: 1) {
					Text(verbatim: "\(taken)")
						.font(.headline)
						.fontDesign(.rounded)
					if let minimum {
						Text(verbatim: "/\(minimum)")
							.font(.subheadline)
							.foregroundStyle(.secondary)
					}
				}
				.monospacedDigit()
			}

			if let minimum {
				ProgressView(value: Double(min(taken, max(minimum, 1))), total: Double(max(minimum, 1)))
					.progressViewStyle(ThickLinearProgressViewStyle(height: 8))
					.tint(isMet ? .green : .accentColor)
			}
		}
		// One element with its own label and value: combining children would read the
		// checkmark as "Selected" and the numbers as "9 of 5" once a minimum is passed.
		.accessibilityElement(children: .ignore)
		.accessibilityLabel(title)
		.accessibilityValue(accessibilityValue)
	}

	private var accessibilityValue: String {
		let takenText = switch unit {
		case .au: String(localized: "\(taken) AU", bundle: .module)
		case .credits: String(localized: "\(taken) credits", bundle: .module)
		}
		guard let minimum else { return takenText }
		return isMet
			? String(localized: "\(takenText), minimum \(minimum), requirement met", bundle: .module)
			: String(localized: "\(takenText), minimum \(minimum)", bundle: .module)
	}
}

// MARK: - Editor

/// Edits every minimum; changes apply on Done.
private struct CreditRequirementsEditor: View {
	let departments: [Department]
	let onSave: (CreditRequirements) -> Void

	@State private var draft: CreditRequirements
	@Environment(\.dismiss) private var dismiss

	init(requirements: CreditRequirements, departments: [Department], onSave: @escaping (CreditRequirements) -> Void) {
		self.departments = departments
		self.onSave = onSave
		self._draft = State(initialValue: requirements)
	}

	var body: some View {
		NavigationStack {
			Form {
				Section(String(localized: "Graduation", bundle: .module)) {
					field(String(localized: "Total Credits", bundle: .module), value: $draft.graduation)
				}

				Section(String(localized: "Basic", bundle: .module)) {
					field(String(localized: "Basic Required", bundle: .module), value: $draft.basicRequired)
					field(String(localized: "Basic Elective", bundle: .module), value: $draft.basicElective)
				}

				ForEach(departments) { department in
					Section(department.name) {
						field(String(localized: "Major Required", bundle: .module), value: Binding(
							get: { draft.majorRequired(for: department) },
							set: { draft.majorRequired[department.id] = $0 }
						))
						field(String(localized: "Major Elective", bundle: .module), value: Binding(
							get: { draft.majorElective(for: department) },
							set: { draft.majorElective[department.id] = $0 }
						))
					}
				}

				Section(String(localized: "Humanities & Social", bundle: .module)) {
					field(String(localized: "HSE Core", bundle: .module), value: $draft.hseCore)
					field(String(localized: "HSE General", bundle: .module), value: $draft.hseGeneral)
				}

				Section(String(localized: "AU", bundle: .module)) {
					field(String(localized: "AU", bundle: .module), value: $draft.au)
				}

				Section {
					Button(String(localized: "Reset to Defaults", bundle: .module), role: .destructive) {
						draft = CreditRequirements()
					}
				}
			}
			.navigationTitle(String(localized: "Minimum Credits", bundle: .module))
			.toolbarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(String(localized: "Cancel", bundle: .module), role: .cancel) { dismiss() }
				}
				ToolbarItem(placement: .confirmationAction) {
					Button(String(localized: "Done", bundle: .module), role: .confirm) {
						onSave(draft)
						dismiss()
					}
				}
			}
		}
	}

	private func field(_ title: String, value: Binding<Int>) -> some View {
		LabeledContent(title) {
			TextField(title, value: value, format: .number)
				.keyboardType(.numberPad)
				.multilineTextAlignment(.trailing)
				.frame(maxWidth: 80)
		}
	}
}

#Preview {
	let item = TakenSemester(id: "2025-Spring", title: "2025 Spring", semester: nil)
	let timetable = Timetable.mockList[0]
	let major = timetable.lectures.first { $0.type == .mr || $0.type == .me }?.department

	NavigationStack {
		CreditRequirementsView(viewModel: CreditCalculationViewModel(
			semesters: [item],
			timetables: [item.id: timetable],
			majorDepartments: major.map { [$0] } ?? []
		))
	}
}
