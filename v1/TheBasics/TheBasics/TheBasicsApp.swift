//
//  TheBasicsApp.swift
//  TheBasics
//
//  Created by Jaesung Lee on 2023/08/31.
//

import SwiftUI

@main
struct TheBasicsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(store: .init(initialState: CounterFeature.State(), reducer: { CounterFeature() }))
        }
    }
}
