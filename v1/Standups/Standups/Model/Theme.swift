//
//  Theme.swift
//  Standups
//
//  Created by Jaesung Lee on 2023/08/31.
//

import SwiftUI

enum Theme: String, CaseIterable, Equatable, Hashable, Identifiable, Codable {
    case bubblegum
    case buttercup
    case indigo
    case lavender
    case magenta
    case navy
    case orange
    case oxblood
    case periwinkle
    case poppy
    case purple
    case seafoam
    case sky
    case tan
    case teal
    case yellow
    
    var id: Self { self }
    
    var accentColor: Color {
        switch self {
        case .indigo, .magenta, .navy, .oxblood, .purple:
            return .white
        default:
            return .black
        }
    }
    
    var mainColor: Color {
        switch self {
        case .bubblegum: return Color.purple
        case .buttercup: return Color.brown
        case .indigo: return Color.indigo
        case .lavender: return Color.pink
        case .magenta: return Color.red
        case .navy: return Color.blue
        case .orange: return Color.orange
        case .oxblood: return Color.black
        case .periwinkle: return Color.pink
        case .poppy: return Color.mint
        case .purple: return Color.purple
        case .seafoam: return Color.mint
        case .sky: return Color.cyan
        case .tan: return Color.gray
        case .teal: return Color.gray
        case .yellow: return Color.yellow
        }
    }

    
    var name: String { self.rawValue.capitalized }
}
