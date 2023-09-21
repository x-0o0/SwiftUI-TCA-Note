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
            var editedStandup = Standup.mock
            let _ = editedStandup.title += " 오전 싱크"
            
            AppView(
                store: Store(
                    initialState: AppFeature.State(
                        path: StackState([
                            .detail(
                                StandupDetailFeature.State(
                                    standup: .mock,
                                    editStandup: StandupFormFeature.State(
                                        focus: .attendee(editedStandup.attendees[3].id),
                                        standup: editedStandup
                                    )
                                )
                            )
                        ]),
                        standupsList: StandupsListFeature.State(standups: [.mock])
                    ),
                    reducer: { AppFeature() }
                )
            )
        }
    }
}
