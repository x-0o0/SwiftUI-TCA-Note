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
        
        /// 푸시 액션
        /// 스택에 푸시된 state 의 ID 를 명시해야함.
        /// `AppReducer` 에서 스택 작업을 리듀스할때 사용할 때 state ID 를 본 적 있음
        /// ```swift
        /// case let .path(.element(id: stateID, action: .detail(.delegate(delegate))):
        /// ```
        // state.path[id: id] 방식으로 스택에서 state 를 찾을 수 있음. (`Path.State`)
        await store.send(
            .path(
                .push(
                    id: 0,
                    state: .detail(StandupDetailFeature.State(standup: standup))
                )
            )
        ) {
            $0.path[id: 0] = .detail(StandupDetailFeature.State(standup: standup))
        }
        await store.send(
            .path(
                .element(
                    id: 0,
                    action: .detail(.editButtonTapped)
                )
            )
        ) {
            /// mutate 하고 싶은 case 명시하가능
            $0.path[id: 0, case: /AppFeature.Path.State.detail]?.editStandup = StandupFormFeature.State(standup: standup)
        }
        
        var editedStandup = standup
        editedStandup.title = "Point-Free Morning Sync"
        await store.send(
            .path(
                .element(
                    id: 0,
                    action: .detail(.editStandup(.presented(.set(\.$standup, editedStandup))))
                )
            )
        ) {
            $0.path[id: 0, case: /AppFeature.Path.State.detail]?.editStandup?.standup.title = "Point-Free Morning Sync"
        }
        await store.send(
            .path(
                .element(
                    id: 0,
                    action: .detail(.saveStandupButtonTapped)
                )
            )
        ) {
            $0.path[id: 0, case: /AppFeature.Path.State.detail]?.editStandup = nil
            $0.path[id: 0, case: /AppFeature.Path.State.detail]?.standup.title = "Point-Free Morning Sync"
        }
        
        /// Action 이 equatable 이어야함
        await store.receive(
            .path(
                .element(
                    id: 0,
                    action: .detail(.delegate(.standupUpdated(editedStandup)))
                )
            )
        ) {
            $0.standupsList.standups[0].title = "Point-Free Morning Sync"
        }
    }
    
    /// 최종적으로 standupsList 의 standups 의 title이 업데이트 되었는지만 확인
    func test_edit_nonExhaustive() async {
        let standup = Standup.mock
        let store = TestStore(
            initialState: AppFeature.State(
                standupsList: StandupsListFeature.State(
                    standups: [standup]
                )
            ),
            reducer: { AppFeature() }
        )
        store.exhaustivity = .off
        
        await store.send(
            .path(
                .push(
                    id: 0,
                    state: .detail(StandupDetailFeature.State(standup: standup))
                )
            )
        )
        await store.send(
            .path(
                .element(
                    id: 0,
                    action: .detail(.editButtonTapped)
                )
            )
        )
        
        var editedStandup = standup
        editedStandup.title = "Point-Free Morning Sync"
        await store.send(
            .path(
                .element(
                    id: 0,
                    action: .detail(.editStandup(.presented(.set(\.$standup, editedStandup))))
                )
            )
        )
        await store.send(
            .path(
                .element(
                    id: 0,
                    action: .detail(.saveStandupButtonTapped)
                )
            )
        )
        /// 전달받은 모든 액션을 skip 하고 최종 결과만 체크하고 싶을 때
        await store.skipReceivedActions()
        store.assert {
            $0.standupsList.standups[0].title = "Point-Free Morning Sync"
        }
    }
}
