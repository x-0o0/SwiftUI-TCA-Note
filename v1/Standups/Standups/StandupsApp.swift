//
//  StandupsApp.swift
//  Standups
//
//  Created by Jaesung Lee on 2023/08/31.
//

import SwiftUI
import ComposableArchitecture

@main
struct StandupsApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                StandupsList(
                    store: Store(
                        initialState: StandupsListFeature.State(),
                        reducer: { StandupsListFeature() }
                    )
                )
            }
        }
    }
}
