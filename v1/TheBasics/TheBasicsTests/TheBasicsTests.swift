//
//  TheBasicsTests.swift
//  TheBasicsTests
//
//  Created by Jaesung Lee on 2023/08/31.
//

import XCTest
import ComposableArchitecture

@testable import TheBasics

@MainActor
final class TheBasicsTests: XCTestCase {
    /// Defaults
    func test_app() async {
        let store = TestStore(initialState: CounterFeature.State()) {
            CounterFeature()
        }
        
        await store.send(.incrementButtonTapped) {
            // $0: in-out piece of state. 액션 보내지기 전의 상태.
            // 액션 보내지기 전의 상태의 값을 액션 전달 후 기대되는 상태에 맞춰 값 업데이트
            $0.count = 1
        }
    }
    
    /// Suspend Task
    func test_timer() async throws {
        let clock = TestClock()
        
        let store = TestStore(initialState: CounterFeature.State()) {
            CounterFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }
        
        // Error: An effect returned for this action is still running. It must complete before the end of the test. …
        // Resolve: Add `await store.send(.toggleTimerButtonTapped)`
        await store.send(.toggleTimerButtonTapped) {
            $0.isTimerOn = true
        }
        
        // Unimplemented: ContinuousClock.now …
//        try await Task.sleep(for: .milliseconds(1_100))
        await clock.advance(by: .seconds(1)) // 1초 앞당기기
        await store.receive(.timerTicked) {
            $0.count = 1
        }
        
        await clock.advance(by: .seconds(1)) // 1초 앞당기기
        await store.receive(.timerTicked) {
            $0.count = 2
        }
        
        await store.send(.toggleTimerButtonTapped) {
            $0.isTimerOn = false
        }
    }
    
    /// API 통신
    /// `NumberFactClient` 정의
    func test_getFact() async {
        let store = TestStore(initialState: CounterFeature.State()) {
            CounterFeature()
        } withDependencies: {
            /// 테스트용 API Client  디펜던시
            $0.numberFact.fetch = {
                "\($0)은 멋진 숫자입니다!"
            }
        }
        
        await store.send(.getFactButtonTapped) {
            $0.isLoadingFact = true
        }
        await store.receive(.factResponse("0은 멋진 숫자입니다!")) {
            $0.fact = "0은 멋진 숫자입니다!"
            $0.isLoadingFact = false
        }
    }
    
    func test_getFact_Failure() async {
        let store = TestStore(initialState: CounterFeature.State()) {
            CounterFeature()
        } withDependencies: {
            /// 테스트용 API Client  디펜던시
            $0.numberFact.fetch = { _ in
                struct SomeError: Error { }
                throw SomeError()
            }
        }
        /// 실패가 예상된다고 알리고  실패가 발생하면 테스트 성공 (강제로 통과)
        XCTExpectFailure()
        
        await store.send(.getFactButtonTapped) {
            /// 리듀서에서는 에러 처리 안하고 있음
            /// 따라서 액션 보낼 때 아무 사이드 이펙트를 받지 못함
            ///
            /// 테스트는 통과 -> isLoadingFact 이 계속 true -> 무한 로딩
            $0.isLoadingFact = true
        }
    }
}
