//
//  StandupsList.swift
//  Standups
//
//  Created by Jaesung Lee on 2023/08/31.
//

import SwiftUI
import ComposableArchitecture

struct StandupsListFeature: Reducer {
    struct State {
        /// - NOTE:
        /// 일반 배열은 SwiftUI에서 문제가 좀 있음.
        /// 일반 배열은 안정적인 식별자가 아닌 **위치 인덱스로 배열 요소를 참조** 하도록 강제 함
        /// Usecase 예시: 특정 행에서 어떤 비동기 작업이 수행되고 해당 작업이 완료되면 배열에서 해당 요소를 업데이트 하거나 제거하려는 경우가 있음
        /// 그러나 업뎃 또는 제거할 때 쯤에는 요소가 **다른 위치로 이동했거나 이미 제거되었을 수도 있으므로 참조하는 위치 인덱스가 유효하지 않을 수 있음**
        /// 이는 **잘못된 행을 업데이트하거나 충돌이 발생**
        ///
        /// 해결방안: TCA 에서 제공하는 `IdentifiedArrayOf` 를 사용할 것
        var standups: IdentifiedArrayOf<Standup> = []
    }
    
    enum Action {
        case addButtonTapped
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .addButtonTapped:
                state.standups.append(
                    Standup(
                        id: UUID(),
                        theme: .allCases.randomElement()!
                    )
                )
                return .none
            }
        }
    }
}

struct StandupsList: View {
    let store: StoreOf<StandupsListFeature>
    
    var body: some View {
        WithViewStore(self.store, observe: \.standups) { viewStore in
            List {
                ForEach(viewStore.state) { standup in
                    CardView(standup: standup)
                        .listRowBackground(standup.theme.mainColor)
                }
            }
            .navigationTitle("일일 미팅")
            .toolbar {
                ToolbarItem {
                    Button("추가") { }
                }
            }
        }
    }
}

struct CardView: View {
    let standup: Standup
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(self.standup.title)
                .font(.headline)
            
            Spacer()
            
            HStack {
                Label(
                    "\(self.standup.attendees.count)",
                    systemImage: "person.3"
                )
                
                Spacer()
                
                Label(
                    self.standup.duration.formatted(.units()),
                    systemImage: "clock"
                )
                .labelStyle(.trailingIcon)
            }
            .font(.caption)
        }
        .padding()
        .foregroundStyle(self.standup.theme.accentColor)
    }
}

#Preview {
    MainActor.assumeIsolated {
        NavigationStack {
            StandupsList(
                store: .init(
                    initialState: StandupsListFeature.State(
                        standups: [Standup.mock]
                    ),
                    reducer: { StandupsListFeature() }
                )
            )
        }
    }
}
