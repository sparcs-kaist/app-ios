//
//  Text+Extensions.swift
//  soap
//
//  Created by Soongyu Kwon on 28/12/2024.
//

import SwiftUI

extension Text {
    init(_ localizedString: LocalizedString) {
        self.init(localizedString.description)
    }
}
