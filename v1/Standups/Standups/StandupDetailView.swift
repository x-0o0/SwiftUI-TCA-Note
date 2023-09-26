//
//  StandupDetailView.swift
//  Standups
//
//  Created by Jaesung Lee on 2023/09/05.
//

import SwiftUI
import ComposableArchitecture

struct StandupDetailFeature: Reducer {
    struct State: Equatable {
        var standup: Standup
        
        @PresentationState var editStandup: StandupFormFeature.State?

        /// Alert
        @PresentationState var alert: AlertState<Action.Alert>?
    }
    
    enum Action: Equatable {
        case deleteButtonTapped
        case deleteMeetings(atOffsets: IndexSet)
        
        // Edit
        case editButtonTapped
        case cancelEditStandupButtonTapped
        case saveStandupButtonTapped
        case editStandup(PresentationAction<StandupFormFeature.Action>)
        
        // Delegate
        case delegate(Delegate)
        
        enum Delegate: Equatable {
            // 부모 도메인에게 얘기하고자 하는 액션을 여기에 적어주면 됨
            // 그러면 부모 도메인이 해당 delegate 액션을 listen 하고 있다가 정보가 들어오면 필요한 동작을 수행하게 됨
            case standupUpdated(Standup)
        }
        
        // Alert
        case alert(PresentationAction<Alert>)
        
        enum Alert {
            case confirmDeletion
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .deleteButtonTapped:
                if state.editStandup == nil, state.alert == nil {
                    // 뭔가 하기
                }
                state.alert = AlertState {
                    // title
                    TextState("정말 삭제 하시겠습니까?")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDeletion) {
                        TextState("삭제")
                    }
                }
                return .none
                
            case .deleteMeetings(atOffsets: let indices):
                state.standup.meetings.remove(atOffsets: indices)
                return .none
                
            case .editButtonTapped:
                state.editStandup = StandupFormFeature.State(
                    standup: state.standup
                )
                return .none

            case .cancelEditStandupButtonTapped:
                state.editStandup = nil
                return .none
                
            case .saveStandupButtonTapped:
                guard let standup = state.editStandup?.standup else {
                    return .none
                }
                state.standup = standup
                state.editStandup = nil
                return .none
                
            case .editStandup:
                return .none
                
            case .delegate:
                // 자식 도메인은 절대로 delegate 액션에 대해서 아무것도 하지 말아야 한다.
                return .none
                
            case .alert(.presented(.confirmDeletion)):
                // TODO: 현재 standup 제거
                return .none
                
            case .alert(.dismiss):
                return .none
            }
        }
        .ifLet(\.$alert, action: /Action.alert) // Alert
        .ifLet(\.$editStandup, action: /Action.editStandup) {
            // Stack
            StandupFormFeature()
        }
        .onChange(of: \.standup) { oldValue, newValue in
            // Custom 리듀서
            Reduce { state, action in
                return .send(.delegate(.standupUpdated(newValue)))
            }
        }
    }
}

struct StandupDetailView: View {
    let store: StoreOf<StandupDetailFeature>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            List {
                Section {
                    NavigationLink {
                        
                    } label: {
                        Label("미팅 시작하기", systemImage: "timer")
                            .font(.headline)
                            .foregroundStyle(Color.accentColor)
                    }
                    
                    HStack {
                        Label("길이", systemImage: "clock")
                        
                        Spacer()
                        
                        Text(viewStore.standup.duration.formatted(.units()))
                    }
                    
                    HStack {
                        Label("테마", systemImage: "paintpalette")
                        
                        Spacer()
                        
                        Text(viewStore.standup.theme.name)
                            .padding(4)
                            .foregroundStyle(viewStore.standup.theme.accentColor)
                            .background(viewStore.standup.theme.mainColor)
                            .clipShape(.rect(cornerRadius: 4))
                    }
                } header: {
                    Text("스탠드업 정보")
                }
                
                if !viewStore.standup.meetings.isEmpty {
                    Section {
                        ForEach(viewStore.standup.meetings) { meeting in
                            NavigationLink {
                                
                            } label: {
                                HStack {
                                    Image(systemName: "calendar")
                                    
                                    Text(meeting.date, style: .date)
                                    
                                    Text(meeting.date, style: .time)
                                }
                            }
                        }
                        .onDelete { indices in
                            viewStore.send(.deleteMeetings(atOffsets: indices))
                        }
                    } header: {
                        Text("이전 미팅")
                    }
                }
                
                Section {
                    ForEach(viewStore.standup.attendees) { attendee in
                        Label(attendee.name, systemImage: "person")
                    }
                } header: {
                    Text("참석자 명단")
                }
                
                Section {
                    Button("삭제") {
                        viewStore.send(.deleteButtonTapped)
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle(viewStore.standup.title)
            .toolbar {
                Button("편집") {
                    viewStore.send(.editButtonTapped)
                }
            }
            .alert(
                store: self.store.scope(
                    state: \.$alert,
                    action: { .alert($0) }
                )
            )
            .sheet(
                store: self.store.scope(
                    state: \.$editStandup,
                    action: { .editStandup($0) }
                )
            ) { store in
                NavigationStack {
                    StandupForm(store: store)
                        .toolbar {
                            ToolbarItem {
                                Button("저장") {
                                    viewStore.send(.saveStandupButtonTapped)
                                }
                            }
                            
                            ToolbarItem(placement: .cancellationAction) {
                                Button("취소") {
                                    viewStore.send(.cancelEditStandupButtonTapped)
                                }
                            }
                        }
                }
            }
        }
    }
}

#Preview {
    MainActor.assumeIsolated {
        NavigationStack {
            StandupDetailView(
                store: Store(
                    initialState: StandupDetailFeature.State(standup: .mock),
                    reducer: { StandupDetailFeature() }
                )
            )
        }
    }
}
