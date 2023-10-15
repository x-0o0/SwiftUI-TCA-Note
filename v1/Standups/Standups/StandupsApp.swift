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
            AppView(
                store: Store(
                    initialState: AppFeature.State(
                        path: StackState([
                            .detail(
                                StandupDetailFeature.State(standup: .mock)
                            ),
                            .recordMeeting(
                                RecordMeetingFeature.State(standup: .mock)
                            ),
                        ]),
                        standupsList: StandupsListFeature.State(standups: [.mock])
                    ),
                    reducer: { AppFeature() }
                )
            )
        }
    }
}
