//
//  MeetingProgressViewStyle.swift
//  Standups
//
//  Created by 이재성 on 10/15/23.
//

import SwiftUI

struct MeetingProgressViewStyle: ProgressViewStyle {
    var theme: Theme
    
    func makeBody(
        configuration: Configuration
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(self.theme.accentColor)
                .frame(height: 20)
            
            ProgressView(configuration)
                .tint(self.theme.mainColor)
                .frame(height: 12)
                .padding(.horizontal)
        }
    }
}
