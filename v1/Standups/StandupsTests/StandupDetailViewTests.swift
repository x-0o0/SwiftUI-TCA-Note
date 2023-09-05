//
//  StandupDetailViewTests.swift
//  StandupsTests
//
//  Created by Jaesung Lee on 2023/09/05.
//

import XCTest
import ComposableArchitecture
@testable import Standups

@MainActor
final class StandupDetailViewTests: XCTestCase {
    func test_edit() async throws {
        var standup = Standup.mock
        let store = TestStore(
            initialState: StandupDetailFeature.State(standup: standup)
        ) {
            StandupDetailFeature()
        }
        store.exhaustivity = .off
        
        // 편집버튼 누른 경우
        await store.send(.editButtonTapped)
        standup.title = "Point-Free Morning Sync"
        
        // title 바꾼 경우
        await store.send(.editStandup(.presented(.set(\.$standup, standup))))
        
        // 저장버튼 누른 경우
        await store.send(.saveStandupButtonTapped) {
            $0.standup.title = "Point-Free Morning Sync"
        }
    }
}
