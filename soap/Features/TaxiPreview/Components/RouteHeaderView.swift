//
//  RouteHeaderView.swift
//  soap
//
//  Created by Minjae Kim on 5/4/25.
//

import SwiftUI

struct RouteHeaderView: View {
    let origin: String
    let destination: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(origin)
            Image(systemName: "arrow.right")
            Text(destination)
        }
        .font(.title3)
        .fontWeight(.semibold)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    RouteHeaderView(origin: "Seoul", destination: "Busan")
        .padding()
}
