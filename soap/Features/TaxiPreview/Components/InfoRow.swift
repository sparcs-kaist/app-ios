//
//  InfoRow.swift
//  soap
//
//  Created by Minjae Kim on 5/4/25.
//

import SwiftUI

struct InfoRow: View {
    let label: String
    let value: String
    var labelColor: Color = Color(hex: "9D9C9E")
    var valueColor: Color = .black
    var trailingIcon: String? = nil
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(labelColor)
            Spacer()
            HStack(spacing: 4) {
                Text(value)
                    .foregroundColor(valueColor)
                if let icon = trailingIcon {
                    Image(systemName: icon)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

#Preview {
    InfoRow(label: "Test Label", value: "Test Value", trailingIcon: "chevron.right")
        .padding()
}
