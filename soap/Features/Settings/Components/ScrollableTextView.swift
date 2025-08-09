//
//  ScrollableTextView.swift
//  soap
//
//  Created by 하정우 on 8/9/25.
//

import SwiftUI

struct ScrollableTextView: View {
  var text: String
  
  init(_ text: String) {
    self.text = text
  }
  
  var body: some View {
    ScrollView {
      HStack {
        Text(text)
          .multilineTextAlignment(.leading)
        Spacer()
      }
    }
  }
}

#Preview {
  ScrollableTextView("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut eu interdum magna, eu tristique felis. Mauris in nisi nec leo auctor dictum et sed nisi. Integer porttitor blandit nunc, sit amet lobortis leo ornare sed. Vestibulum mattis at ante blandit sagittis. Duis interdum nisi ac quam dignissim ultrices. Vivamus aliquam.").padding()
}
