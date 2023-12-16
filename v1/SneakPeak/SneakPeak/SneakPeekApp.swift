//
//  SneakPeekApp.swift
//  SneakPeek
//
//  Created by 이재성 on 12/16/23.
//

import SwiftUI
import ComposableArchitecture

@main
struct SneakPeekApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                store: Store(
                    initialState: CounterFeature.State(),
                    reducer: { CounterFeature() }
                )
            )
        }
    }
}
