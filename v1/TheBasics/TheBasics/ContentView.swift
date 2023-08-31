//
//  ContentView.swift
//  TheBasics
//
//  Created by Jaesung Lee on 2023/08/31.
//

import SwiftUI
import ComposableArchitecture

/// 디펜던시 만들기
struct NumberFactClient {
    var fetch: @Sendable (Int) async throws -> String
}

extension NumberFactClient: DependencyKey {
    static var liveValue = Self { number in
        let (data, _) = try await URLSession.shared.data(
            from: URL(
                string: "http://www.numbersapi.com/\(number)"
            )!
        )
        return String(decoding: data, as: UTF8.self)
    }
}

extension DependencyValues {
    var numberFact: NumberFactClient {
        get { self[NumberFactClient.self] }
        set { self[NumberFactClient.self] = newValue }
    }
}

struct CounterFeature: Reducer {
    /// State 는 항상은 아니지만 보통은 struct 로 선언
    struct State: Equatable {
        var count = 0
        var fact: String?
        var isLoadingFact = false
        var isTimerOn = false
    }
    
    /// UI에서 발생하는 액션들, 시스템으로 돌아오는 이펙트를 케이스로 정의
    /// 네이밍: 어느 UI에서 보내져야하는지 명확하게 네이밍
    enum Action: Equatable {
        
        case decrementButtonTapped
        case incrementButtonTapped
        
        case getFactButtonTapped
        case factResponse(String) // 이번 강의에서는 에러는 신경 안씀
        
        case toggleTimerButtonTapped
        case timerTicked
    }
    
    private enum CancelID {
        case timer
    }
    
    /// MARK: 디펜던시
    /// default value: not safe. diff part -> diff dependency
    @Dependency(\.continuousClock) var clock
    @Dependency(\.numberFact) var numberFact
    
    /// SwiftUI View 처럼 body 를 정의 -> 여러개의 리듀서를 하나의 큰 리듀서로 만들어줄 수 있음
    /// 기능을 완전히 분리하여 구축한 다음 서로 통합할 수 있도록 통합할 수 있습니다.
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            /// 1. switch on the action
            /// 2. what is it that happens in the UI
            switch action {
            case .decrementButtonTapped:
                state.count -= 1
                state.fact = nil
                state.isLoadingFact = false
                return .none
                
            case .incrementButtonTapped:
                state.count += 1
                state.fact = nil
                state.isLoadingFact = false
                return .none
                
            case .getFactButtonTapped:
                // TODO: 네트워크 요청 수행
                state.fact = nil
                state.isLoadingFact = true
                return .run { [count = state.count] send in
                    try await send(.factResponse(self.numberFact.fetch(count)))
                }
                
            case let .factResponse(fact):
                state.fact = fact
                state.isLoadingFact = false
                return .none

            case .toggleTimerButtonTapped:
                state.isTimerOn.toggle()
                // TODO: 타이머 시작하기
                if state.isTimerOn {
                    // 타이머 시작
                    return .run { send in
                        for await _ in self.clock.timer(interval: .seconds(1)) {
//                            send(.incrementButtonTapped) // UI 를 탭한게 아니므로 새로 정의할것
                            await send(.timerTicked)
                        }
                    }
                    .cancellable(id: CancelID.timer)
                } else {
                    // 타이머 정지
                    return .cancel(id: CancelID.timer)
                }
    
            case .timerTicked:
                state.count += 1
                return .none
            }
        }
    }
}

struct ContentView: View {
    let store: StoreOf<CounterFeature>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            Form {
                Section {
                    Text("\(viewStore.count)")
                    
                    Button("숫자 감소") {
                        viewStore.send(.decrementButtonTapped)
                    }
                     
                    Button("숫자 증가") {
                        viewStore.send(.incrementButtonTapped)
                    }
                }
                
                Section {
                    Button {
                        viewStore.send(.getFactButtonTapped)
                    } label: {
                        HStack {
                            Text("팩트 가져오기")
                            
                            if viewStore.isLoadingFact {
                                Spacer()
                                
                                ProgressView()
                            }
                        }
                    }
                    
                    if let fact = viewStore.fact {
                        Text(fact)
                    }
                }
                
                Section {
                    if viewStore.isTimerOn {
                        Button("타이머 멈추기") {
                            viewStore.send(.toggleTimerButtonTapped)
                        }
                    } else {
                        Button("타이머 시작") {
                            viewStore.send(.toggleTimerButtonTapped)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView(
        store: Store(
            initialState: CounterFeature.State(),
            reducer: { CounterFeature() }
        )
    )
}
