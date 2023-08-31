//
//  TrailingIconLabelStyle.swift
//  Standups
//
//  Created by Jaesung Lee on 2023/09/01.
//

import SwiftUI

struct TrailingIconLabelStyle: LabelStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack {
      configuration.title
      configuration.icon
    }
  }
}

extension LabelStyle where Self == TrailingIconLabelStyle {
  static var trailingIcon: Self { Self() }
}
