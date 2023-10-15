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
        
        // MARK: Destination
        /// `@PresentationState` 을 전부 `destination` 으로 통합
        @PresentationState var destination: Destination.State?
    }
    
    enum Action: Equatable {
        case deleteButtonTapped
        case deleteMeetings(atOffsets: IndexSet)
        
        // Edit
        case editButtonTapped
        case cancelEditStandupButtonTapped
        case saveStandupButtonTapped
                
        // MARK: Destination
        /// `PresentationAction<Action>` 들을 전부 `destination` 으로 통합
        case destination(PresentationAction<Destination.Action>)
        
        // Delegate
        case delegate(Delegate)
        
        enum Delegate: Equatable {
            // 부모 도메인에게 얘기하고자 하는 액션을 여기에 적어주면 됨
            // 그러면 부모 도메인이 해당 delegate 액션을 listen 하고 있다가 정보가 들어오면 필요한 동작을 수행하게 됨
            case standupUpdated(Standup)
            
            case deleteStandup(id: Standup.ID)
        }
    }
    
    /// `@Environment(\.dismiss) var dismiss` 와 유사한 역할
    @Dependency(\.dismiss) var dismiss
    
    struct Destination: Reducer {
        enum State: Equatable {
            case alert(AlertState<Action.Alert>)
            case editStandup(StandupFormFeature.State)
        }
        
        enum Action: Equatable {
            case alert(Alert)
            case editStandup(StandupFormFeature.Action)
            
            enum Alert {
                case confirmDeletion
            }
        }
        
        var body: some ReducerOf<Self> {
            Scope(
                state: /State.editStandup,
                action: /Action.editStandup
            ) {
                StandupFormFeature()
            }
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .deleteButtonTapped:
                state.destination = .alert(
                    AlertState {
                        // title
                        TextState("정말 삭제 하시겠습니까?")
                    } actions: {
                        ButtonState(role: .destructive, action: .confirmDeletion) {
                            TextState("삭제")
                        }
                    }
                )
                return .none
                
            case .deleteMeetings(atOffsets: let indices):
                state.standup.meetings.remove(atOffsets: indices)
                return .none
                
            case .editButtonTapped:
                state.destination = .editStandup(
                    StandupFormFeature.State(
                        standup: state.standup
                    )
                )
                return .none

            case .cancelEditStandupButtonTapped:
                state.destination = nil
                return .none
                
            case .saveStandupButtonTapped:
                guard case let .editStandup(standupForm) = state.destination else {
                    return .none
                }
                state.standup = standupForm.standup
                state.destination = nil
                return .none
                
            case .delegate:
                // 자식 도메인은 절대로 delegate 액션에 대해서 아무것도 하지 말아야 한다.
                return .none
                
                // MARK: destination
            case .destination(.presented(.alert(.confirmDeletion))):
                // TODO: 현재 standup 제거
                return .run { [id = state.standup.id] send in
                    await send(.delegate(.deleteStandup(id: id)))
                    await self.dismiss() // dismiss 할 때는 send 필요 없음
                }
                
            case .destination:
                return .none
            }
        }
        // MARK: Destination
        .ifLet(\.$destination, action: /Action.destination) {
            Destination()
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
                    state: \.$destination,
                    action: { .destination($0) }
                ),
                state: /StandupDetailFeature.Destination.State.alert,
                action: StandupDetailFeature.Destination.Action.alert
            )
            .sheet(
                store: self.store.scope(
                    state: \.$destination,
                    action: { .destination($0) }
                ),
                state: /StandupDetailFeature.Destination.State.editStandup,
                action: StandupDetailFeature.Destination.Action.editStandup
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
