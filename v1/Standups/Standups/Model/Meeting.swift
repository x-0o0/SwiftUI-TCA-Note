//
//  Meeting.swift
//  Standups
//
//  Created by Jaesung Lee on 2023/08/31.
//

import Foundation

struct Meeting: Equatable, Identifiable, Codable {
    let id: UUID
    let date: Date
    var transcript: String
}
