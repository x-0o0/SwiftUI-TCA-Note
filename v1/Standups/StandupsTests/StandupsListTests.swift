//
//  StandupsListTests.swift
//  StandupsTests
//
//  Created by Jaesung Lee on 2023/09/05.
//

import XCTest
import ComposableArchitecture
@testable import Standups

@MainActor
final class StandupsListTests: XCTestCase {
    func test_addStandup() async {
        let store = TestStore(initialState: StandupsListFeature.State()) {
            StandupsListFeature()
        } withDependencies: {
            $0.uuid = .incrementing
        }
        
        // 추가버튼 누른 경우
        var standup = Standup(
            id: UUID(0),
            attendees: [Attendee(id: UUID(1))]
        )
        await store.send(.addButtonTapped) {
            $0.addStandup = StandupFormFeature.State(
                standup: standup
            )
        }
        
        // title 바꾼 경우
        standup.title = "Point-Free Morning Sync"
        await store.send(.addStandup(.presented(.set(\.$standup, standup)))) {
            $0.addStandup?.standup.title = "Point-Free Morning Sync"
        }
        
        // 저장버튼 누른 경우
        await store.send(.saveStandupButtonTapped) {
            // 모든 데이터를 다 보는 것은 너무 포괄적인 테스트라고 느껴질 수도 있음
            $0.addStandup = nil
            $0.standups[0] = Standup(
                id: UUID(0),
                attendees: [Attendee(id: UUID(1))],
                title: "Point-Free Morning Sync"
            )
        }
    }
    
    /// 모든 댠계를 거치면 마지막에 `Standup` 객체가 컬렉션에 추가되는지만 확인하고 싶을 때,
    /// (모든 작동 검증 없이 특정 결과만 확인하고 싶은 경우)
    ///
    /// 비포괄적 테스트 모드를 하려면
    /// ```swift
    /// store.exhaustivity = .off
    /// ```
    ///
    /// 그러면 `send` 의 클로져의 argument (`$0`) 가 액션 전의 상태가 아닌 **액션 후의 상태**를 의미
    ///
    /// 만약 특정 결과만 확인하고 싶더라도 중간에 체크 안된 작동을 메세지로 받고 싶다면
    /// ```swift
    /// store.exhaustivity = .off(showSkippedAssertions: true)
    /// ```
    func test_addStandup_nonExhausted() async {
        let store = TestStore(initialState: StandupsListFeature.State()) {
            StandupsListFeature()
        } withDependencies: {
            $0.uuid = .incrementing
        }
        /// 비포괄적 테스트 모드
        /// `send` 의 클로져의 argument (`$0`) 가 액션 전의 상태가 아닌 **액션 후의 상태**를 의미
        store.exhaustivity = .off(showSkippedAssertions: true)
        
        var standup = Standup(
            id: UUID(0),
            attendees: [Attendee(id: UUID(1))]
        )
        await store.send(.addButtonTapped)
        
        standup.title = "Point-Free Morning Sync"
        await store.send(.addStandup(.presented(.set(\.$standup, standup))))
        
        await store.send(.saveStandupButtonTapped) {
            /// `exhaustivity = .off` 일 때,
            /// `$0`은 **액션 후의 상태**
            $0.standups[0] = Standup(
                id: UUID(0),
                attendees: [Attendee(id: UUID(1))],
                title: "Point-Free Morning Sync"
            )
        }
    }
}
