//
//  AppTests.swift
//  StandupsTests
//
//  Created by Jaesung Lee on 2023/09/21.
//

import XCTest
import ComposableArchitecture
@testable import Standups

@MainActor
final class AppTests: XCTestCase {
    func test_edit() async {
        let standup = Standup.mock
        let store = TestStore(
            initialState: AppFeature.State(
                standupsList: StandupsListFeature.State(
                    standups: [standup]
                )
            ),
            reducer: { AppFeature() }
        )
        // state.path[id: id] 방식으로 look up
        await store.send(.path(.push(id: 0, state: .detail(StandupDetailFeature.State(standup: standup))))) {
            $0.path[id: 0] = .detail(StandupDetailFeature.State(standup: standup))
        }
    }
}
