import Foundation
import SwiftUI

struct TaxiSettlementAmountSheet: View {
  let participantCount: Int
  let onCommit: (Int) -> Void

  @Environment(\.dismiss) private var dismiss
  @FocusState private var isAmountFocused: Bool
  @State private var amountText: String = ""

  private var totalAmount: Int? {
    guard let amount = Int(amountText), amount > 0 else { return nil }
    return amount
  }

  private var perPersonAmount: Int? {
    guard let totalAmount, participantCount > 0 else { return nil }
    return totalAmount / participantCount
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          HStack {
            Text("₩")
              .foregroundStyle(.secondary)
            
            TextField(String(localized: "Enter amount", bundle: .module), text: $amountText)
              .keyboardType(.numberPad)
              .focused($isAmountFocused)
              .onChange(of: isAmountFocused) { wasFocused, isFocused in
                if wasFocused && !isFocused {
                  normalizeAmount()
                }
              }
          }

          HStack {
            Text("Participants", bundle: .module)
            Spacer()
            Text("\(participantCount) people", bundle: .module)
              .foregroundStyle(.secondary)
          }

          if let perPersonAmount {
            HStack {
              Text("Per person", bundle: .module)
              Spacer()
              Text(formattedWon(perPersonAmount))
                .fontWeight(.semibold)
            }
          }
        } header: {
          Text("Total amount", bundle: .module)
        } footer: {
          Text("The per-person amount is rounded down to whole won.", bundle: .module)
        }
      }
      .navigationTitle(Text("Request Settlement", bundle: .module))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(String(localized: "Cancel", bundle: .module)) {
            dismiss()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button(String(localized: "Request Settlement", bundle: .module)) {
            guard let totalAmount else { return }
            onCommit(totalAmount)
            dismiss()
          }
          .disabled(totalAmount == nil || participantCount == 0)
        }
      }
    }
    .presentationDetents([.medium])
    .presentationDragIndicator(.visible)
  }

  private func formattedWon(_ amount: Int) -> String {
    "₩" + amount.formatted(.number.grouping(.automatic))
  }

  private func normalizeAmount() {
    let trimmedAmount = amountText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let amount = Int(trimmedAmount), amount > 0 else {
      amountText = ""
      return
    }

    amountText = String(amount)
  }
}
