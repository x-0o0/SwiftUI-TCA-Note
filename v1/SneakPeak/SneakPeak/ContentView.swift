//
//  ContentView.swift
//  SneakPeak
//
//  Created by 이재성 on 12/16/23.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct CounterFeature {
    @ObservableState /// `SwiftUI.Observable` 는 `struct` 에서 동작하지 않기 때문에 등장
    struct State {
        var count = 0
        var isObservingCount = true
    }
    
    enum Action {
        case decrementButtonTapped
        case incrementButtonTapped
        case toggleIsObservingCount
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .decrementButtonTapped:
                state.count -= 1
                return .none
            case .incrementButtonTapped:
                state.count += 1
                return .none
            case .toggleIsObservingCount:
                state.isObservingCount.toggle()
                return .none
            }
        }
    }
}

struct ContentView: View {
    let store: StoreOf<CounterFeature>
    
    /// project build settings > deployment target > ios17 미만으로 낮추면 액션이 동작하지 않고 런타임 경고(보라색)이 뜨는 것을 확일할 수 있음
    ///
    /// > Observable state was accessed but is not being tracked. Track changes to store state in a ‘WithPerceptionTracking’ to ensure the delivery of view updates.
    ///
    /// 이 경우에는 `body` 를 `WithPerceptionTracking` 로 감싸야함
    /// ```swift
    /// WithPerceptionTracking {
    ///     let _ = print("\(Self.self).body")
    ///     Form { ... }
    /// }
    /// ```
    var body: some View {
        let _ = Self._printChanges()
        Form {
            if self.store.isObservingCount {
                // 뷰에 등장하면 state 값을 옵저빙 하기 시작
                // _printChanges() 했을 때 로그를 볼 수 있음
                Text(self.store.count.description)
            }
            
            Button("감소") {
                self.store.send(.decrementButtonTapped)
            }
            
            Button("증가") {
                self.store.send(.incrementButtonTapped)
            }
            
            Button("숫자 토글하기") {
                self.store.send(.toggleIsObservingCount)
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
