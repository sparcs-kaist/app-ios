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
struct CreditRequirementsView: View {
	let viewModel: CreditCalculationViewModel

	@State private var isEditing = false

	var body: some View {
		let breakdown = viewModel.creditBreakdown
		let requirements = viewModel.requirements

		ScrollView {
			VStack(spacing: 20) {
				RequirementSection(title: String(localized: "Graduation", bundle: .module), systemImage: "graduationcap") {
					RequirementRow(
						title: String(localized: "Total Credits", bundle: .module),
						taken: viewModel.overallSummary.earnedCredits,
						minimum: requirements.graduation
					)
				}

				RequirementSection(title: String(localized: "Basic", bundle: .module), systemImage: "books.vertical") {
					RequirementRow(title: String(localized: "Basic Required", bundle: .module), taken: breakdown.basicRequired, minimum: requirements.basicRequired)
					RequirementRow(title: String(localized: "Basic Elective", bundle: .module), taken: breakdown.basicElective, minimum: requirements.basicElective)
				}

				ForEach(breakdown.majors) { group in
					RequirementSection(title: group.department.name, systemImage: "building.columns") {
						RequirementRow(
							title: String(localized: "Major Required", bundle: .module),
							taken: group.required,
							minimum: requirements.majorRequired(for: group.department)
						)
						RequirementRow(
							title: String(localized: "Major Elective", bundle: .module),
							taken: group.elective,
							minimum: requirements.majorElective(for: group.department)
						)
					}
				}

				RequirementSection(title: String(localized: "Humanities & Social", bundle: .module), systemImage: "person.2") {
					RequirementRow(title: String(localized: "HSE Core", bundle: .module), taken: breakdown.hseCore, minimum: requirements.hseCore)
					RequirementRow(title: String(localized: "HSE General", bundle: .module), taken: breakdown.hseGeneral, minimum: requirements.hseGeneral)
					// Older curricula without a core/general split have no minimum of their own.
					if breakdown.hse > 0 {
						RequirementRow(title: String(localized: "HSE", bundle: .module), taken: breakdown.hse, minimum: nil)
					}
				}

				RequirementSection(title: String(localized: "AU", bundle: .module), systemImage: "figure.run") {
					RequirementRow(title: String(localized: "AU", bundle: .module), taken: breakdown.au, minimum: requirements.au, unit: .au)
				}

				if breakdown.etc > 0 {
					RequirementSection(title: String(localized: "Other", bundle: .module), systemImage: "ellipsis.circle") {
						RequirementRow(title: String(localized: "ETC", bundle: .module), taken: breakdown.etc, minimum: nil)
					}
				}

				Text("Minimums differ by department and admission year. Tap Edit to match your own.", bundle: .module)
					.font(.footnote)
					.foregroundStyle(.secondary)
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(.horizontal, 4)
			}
			.padding()
			.contentWidth()
		}
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
				requirements: requirements,
				departments: breakdown.majors.map(\.department),
				onSave: viewModel.updateRequirements
			)
		}
	}
}

// MARK: - Cards

/// One group of requirements in its own card, under an icon + title header.
private struct RequirementSection<Content: View>: View {
	let title: String
	let systemImage: String
	@ViewBuilder let content: Content

	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			Label(title, systemImage: systemImage)
				.font(.subheadline)
				.fontWeight(.semibold)
				.foregroundStyle(.secondary)

			content
		}
		.frame(maxWidth: .infinity, alignment: .leading)
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
