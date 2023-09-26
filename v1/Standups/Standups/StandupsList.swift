//
//  StandupsList.swift
//  Standups
//
//  Created by Jaesung Lee on 2023/08/31.
//

import SwiftUI
import ComposableArchitecture

struct StandupsListFeature: Reducer {
    struct State: Equatable {
        /// - NOTE:
        /// 일반 배열은 SwiftUI에서 문제가 좀 있음.
        /// 일반 배열은 안정적인 식별자가 아닌 **위치 인덱스로 배열 요소를 참조** 하도록 강제 함
        /// Usecase 예시: 특정 행에서 어떤 비동기 작업이 수행되고 해당 작업이 완료되면 배열에서 해당 요소를 업데이트 하거나 제거하려는 경우가 있음
        /// 그러나 업뎃 또는 제거할 때 쯤에는 요소가 **다른 위치로 이동했거나 이미 제거되었을 수도 있으므로 참조하는 위치 인덱스가 유효하지 않을 수 있음**
        /// 이는 **잘못된 행을 업데이트하거나 충돌이 발생**
        ///
        /// 해결방안: TCA 에서 제공하는 `IdentifiedArrayOf` 를 사용할 것
        var standups: IdentifiedArrayOf<Standup> = []
        
        @PresentationState var addStandup: StandupFormFeature.State?
    }
    
    enum Action: Equatable {
        case addButtonTapped
        
        /// `PresentationAction` 에는 `dismiss` 와 `presented` 케이스가 있음
        case addStandup(PresentationAction<StandupFormFeature.Action>)
        
        case cancelStandupButtonTapped
        case saveStandupButtonTapped
    }
    
    @Dependency(\.uuid) var uuid
    
    var body: some ReducerOf<Self> {
        /// Core reducer
        Reduce { state, action in
            switch action {
            case .addButtonTapped:
                state.addStandup = StandupFormFeature.State(
                    standup: Standup(id: self.uuid())
                )
                return .none
                
            case .addStandup:
                return .none
                
            case .cancelStandupButtonTapped:
                state.addStandup = nil
                return .none
                
            case .saveStandupButtonTapped:
                guard let standup = state.addStandup?.standup else {
                    return .none
                }
                state.standups.append(standup)
                state.addStandup = nil
                return .none
            }
        }
        /// 부모-자식 간의 Feature를 통합하여 서로간의 통신이 가능
        /// 예를 들어 부모가 언제 "참석자 추가" 버튼을 눌렀는지 알고 싶다면 아래와 같이 하면됨
        /// ```swift
        /// case .addStandup(.presented(.addAttendeeButtonTapped)):
        ///     // do something
        /// ```
        .ifLet(\.$addStandup, action: /Action.addStandup) { // keyPath, casePath (TO-BE: #casePath(...))
            // Destination
            StandupFormFeature()
        }
    }
}

struct StandupsList: View {
    let store: StoreOf<StandupsListFeature>
    
    var body: some View {
        WithViewStore(self.store, observe: \.standups) { viewStore in
            List {
                ForEach(viewStore.state) { standup in
                    NavigationLink(
                        state: AppFeature.Path.State.detail(StandupDetailFeature.State(standup: standup))
                    ) {
                        CardView(standup: standup)
                    }
                    .listRowBackground(standup.theme.mainColor)
                }
            }
            .navigationTitle("일일 스탠드업")
            .toolbar {
                ToolbarItem {
                    Button("추가") {
                        viewStore.send(.addButtonTapped)
                    }
                }
            }
            .sheet(
                /// `scope` 을 사용하여 `Store`의 범위를 **특정 부분에만 초점을** 맞출 수 있음
                store: self.store.scope(
                    state: \.$addStandup,       // keyPath
                    action: { .addStandup($0) } // closure
                )
            ) { store in
                NavigationStack {
                    StandupForm(store: store)
                        .navigationTitle("새로운 스탠드업")
                        .toolbar {
                            ToolbarItem {
                                Button("저장") {
                                    viewStore.send(.saveStandupButtonTapped)
                                }
                            }
                            
                            ToolbarItem(placement: .cancellationAction) {
                                Button("취소") {
                                    viewStore.send(.cancelStandupButtonTapped)
                                }
                            }
                        }
                }
            } /// **스와이프로 dismiss**하면 자동으로 `state.addStandup = nil` 이 됨
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
                store: Store(
                    initialState: StandupsListFeature.State(
                        standups: [Standup.mock]
                    ),
                    reducer: { StandupsListFeature() }
                )
            )
        }
    }
}
