//
//  StandupFormTests.swift
//  StandupsTests
//
//  Created by Jaesung Lee on 2023/09/01.
//

import XCTest
import ComposableArchitecture
@testable import Standups

@MainActor
final class StandupFormTests: XCTestCase {
    func test_addDeleteAttendee() async {
        let store = TestStore(
            initialState: StandupFormFeature.State(
                standup: Standup(
                    id: UUID(),
                    attendees: [
                        Attendee(id: UUID())
                    ]
                )
            ),
            reducer: { StandupFormFeature() },
            withDependencies: {
                /// `UUID(0)` 부터 시작해서 증가하는 방식으로 uuid 생성
                $0.uuid = .incrementing
            }
        )
        
        await store.send(.addAttendeeButtonTapped) {
            /// 1. `attendees` 가 새 참석자 추가
            $0.standup.attendees.append(
                Attendee(id: UUID(0))
            )
            /// 2. `focus` 가 `.attendee` 로 변경됨
            $0.focus = .attendee(UUID(0))
        }
        await store.send(.deleteAttendees(atOffsets: [1])) {
            $0.standup.attendees.remove(at: 1)
            /// 삭제된 참석자와 가장 가까운 참석자로 초점 변경
            $0.focus = .attendee($0.standup.attendees[0].id)
        }
    }
}
