//
//  CreditView.swift
//  soap
//
//  Created by Soongyu Kwon on 18/01/2026.
//

import SwiftUI

struct CreditView: View {
  private let credits: String = """
    권순규(soongyu)
    장승혁(hyuk)
    윤인하(amet)
    하정우(thread)
    김민찬(static)
    이종현(teddybear)
    김민재(neymar)
    박현우(namu)
    김희진(gimme)
    양채빈(yatcha)
    서인성(cheese)
    임가은(casio)
    """

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text(credits)
          .font(.caption)
          .foregroundStyle(.secondary)

        VStack(alignment: .leading, spacing: 0) {
          Text("Sponsored By")
            .font(.caption)
            .foregroundStyle(.secondary)
          Image(.hyundaiMobis)
            .resizable()
            .scaledToFit()
            .frame(height: 48)
        }

        Color.clear.frame(height: 1)
      }
      .padding()
    }
    .navigationTitle("Acknowledgements")
  }
}

#Preview {
  NavigationStack {
    CreditView()
      .background(Color.secondarySystemBackground)
  }
}
