//
//  GPATrendChart.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 25/09/2026.
//

import SwiftUI
import Charts

/// Semester GPAs as a single line on KAIST's 0–4.3 scale. Tap or drag to inspect
/// a semester; otherwise only the latest value is labelled.
struct GPATrendChart: View {
	let points: [SemesterGPA]
	/// The card colour behind the chart, used to ring the markers.
	var surface: Color = Color(uiColor: .secondarySystemBackground)

	@State private var selectedLabel: String?

	/// Top of KAIST's 4.3 scale, plus headroom so a label above a 4.3 point isn't clipped.
	private static let yDomain = 0.0...4.6

	private var selectedPoint: SemesterGPA? {
		selectedLabel.flatMap { label in points.first { $0.label == label } }
	}

	var body: some View {
		Chart {
			ForEach(points) { point in
				LineMark(
					x: .value("Semester", point.label),
					y: .value("GPA", point.gpa)
				)
				.foregroundStyle(Color.accentColor)
				.lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
				.accessibilityHidden(true)

				PointMark(
					x: .value("Semester", point.label),
					y: .value("GPA", point.gpa)
				)
				.symbol {
					// 8pt dot with a 2pt surface ring, so it stays legible on the line.
					Circle()
						.fill(Color.accentColor)
						.frame(width: 8, height: 8)
						.padding(2)
						.background(surface, in: .circle)
				}
				.accessibilityLabel(point.title)
				.accessibilityValue(formatted(point.gpa))
			}

			// Label only the latest value, and not while a tooltip is showing. A separate,
			// invisible mark carries it; a conditional inside a mark's annotation doesn't render.
			if let last = points.last, selectedPoint == nil {
				PointMark(
					x: .value("Semester", last.label),
					y: .value("GPA", last.gpa)
				)
				.opacity(0)
				.accessibilityHidden(true)
				.annotation(position: .top, spacing: 8) {
					Text(formatted(last.gpa))
						.font(.caption)
						.fontWeight(.semibold)
						.foregroundStyle(Color.secondary)
				}
			}

			if let selectedPoint {
				RuleMark(x: .value("Semester", selectedPoint.label))
					.foregroundStyle(Color.secondary.opacity(0.4))
					.lineStyle(StrokeStyle(lineWidth: 1))
					.annotation(
						position: .top,
						spacing: 0,
						overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
					) {
						tooltip(for: selectedPoint)
					}
			}
		}
		.chartYScale(domain: Self.yDomain)
		.chartYAxis {
			AxisMarks(position: .leading, values: [0, 1, 2, 3, 4]) {
				AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
				// Explicit text colour: the default y label is too faint in dark mode, and a
				// hierarchical `.secondary` would pick up the chart's accent colour.
				AxisValueLabel()
					.foregroundStyle(Color.secondary)
			}
		}
		.chartXAxis {
			AxisMarks {
				AxisValueLabel()
					.foregroundStyle(Color.secondary)
			}
		}
		.chartXSelection(value: $selectedLabel)
	}

	private func tooltip(for point: SemesterGPA) -> some View {
		VStack(alignment: .leading, spacing: 2) {
			Text(point.title)
				.font(.caption)
				.foregroundStyle(.secondary)
			Text(formatted(point.gpa))
				.font(.subheadline)
				.fontWeight(.semibold)
				.fontDesign(.rounded)
		}
		.padding(.horizontal, 8)
		.padding(.vertical, 6)
		.background(.background, in: .rect(cornerRadius: 8))
		.shadow(color: .black.opacity(0.1), radius: 4, y: 1)
	}

	private func formatted(_ gpa: Double) -> String {
		gpa.formatted(.number.precision(.fractionLength(1...2)))
	}
}

#Preview(traits: .fixedLayout(width: 360, height: 200)) {
	GPATrendChart(points: [
		SemesterGPA(id: "2023-Spring", label: "23S", title: "2023 Spring", gpa: 4.15),
		SemesterGPA(id: "2023-Autumn", label: "23F", title: "2023 Fall", gpa: 2.2),
		SemesterGPA(id: "2024-Spring", label: "24S", title: "2024 Spring", gpa: 3.41),
		SemesterGPA(id: "2024-Autumn", label: "24F", title: "2024 Fall", gpa: 2.94),
		SemesterGPA(id: "2026-Spring", label: "26S", title: "2026 Spring", gpa: 4.3)
	])
	.padding()
	.background(Color(uiColor: .secondarySystemBackground))
}
