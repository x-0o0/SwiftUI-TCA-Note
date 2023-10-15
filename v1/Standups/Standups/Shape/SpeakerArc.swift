//
//  SpeakerArc.swift
//  Standups
//
//  Created by 이재성 on 10/15/23.
//

import SwiftUI

struct SpeakerArc: Shape {
    let totalSpeakers: Int
    let speakerIndex: Int
    
    func path(in rect: CGRect) -> Path {
        let diameter = min(
            rect.size.width, rect.size.height
        ) - 24
        let radius = diameter / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        return Path { path in
            path.addArc(
                center: center,
                radius: radius,
                startAngle: self.startAngle,
                endAngle: self.endAngle,
                clockwise: false
            )
        }
    }
    
    private var degreesPerSpeaker: Double {
        360 / Double(self.totalSpeakers)
    }
    private var startAngle: Angle {
        Angle(
            degrees: self.degreesPerSpeaker
            * Double(self.speakerIndex)
            + 1
        )
    }
    private var endAngle: Angle {
        Angle(
            degrees: self.startAngle.degrees
            + self.degreesPerSpeaker
            - 1
        )
    }
}
