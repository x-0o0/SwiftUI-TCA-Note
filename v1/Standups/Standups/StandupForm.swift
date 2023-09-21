//
//  StandupForm.swift
//  Standups
//
//  Created by Jaesung Lee on 2023/09/01.
//

import SwiftUI
import ComposableArchitecture

struct StandupFormFeature: Reducer {
    struct State: Equatable {
        @BindingState var standup: Standup
        
        /// 어떤 필드가 포커스 되었는지
        /// 화면이 처음 열릴 때 제목 텍스트 필드에 초점이 맞춰지고, 참석자가 추가되거나 제거될 때 적절한 필드에 초점이 맞춰지도록 하길 원함
        @BindingState var focus: Field? = .title
        
        /// 초점이 맞춰질 수 있는 모든 항목을 enum 에 정의
        enum Field: Hashable {
            case attendee(Attendee.ID) // 어느 필드에 초점이 맞춰져 있는지 식별하기 위해 `Attendee` 의 ID 사용
            case title
        }
        
        init(focus: Field? = .title, standup: Standup) {
            self.focus = focus
            self.standup = standup
            
            /// 스탠덥에 적어도 한명의 참석자가 있어야 하므로
            if self.standup.attendees.isEmpty {
                /// UUID 디펜던시 사용하기
                @Dependency(\.uuid) var uuid
                self.standup.attendees.append(Attendee(id: uuid()))
            }
        }
    }
    
    enum Action: BindableAction {
        case addAttendeeButtonTapped // insertAttendee ❌
        case deleteAttendees(atOffsets: IndexSet) // onDelete 에서 수행할 액션
        
        /// `setTitle`, `setDuration`, `setTheme`, `setAttendee` 과 같이 뷰에서 Binding 에 사용되는 데이터에 관한 액션은 **간소화**가 가능
        /// **State**: `@BindingState` 속성을 사용하여 뷰에서 바인딩을 할 수 있는 상태 정의
        /// **Action**: `BindableAction` 프로토콜 준수 + 단일 case 추가
        /// **body**: `BindingReducer()` 를 `Reduce` 보다 먼저 실행되도록 작성.
        case binding(BindingAction<State>)
    }
    
    /// 테스트를 위한 DI
    @Dependency(\.uuid) var uuid
    
    var body: some ReducerOf<Self> {
        /// 시스템에 들어오는 모든 바인딩 액션을 관리하고 BindingState 업데이트
        /// 즉, 어떤 feature 에 대해서 액션이 들어오면 BindingReducer가 가장 먼저 실행됨
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .addAttendeeButtonTapped:
                let id = self.uuid()
                state.standup.attendees.append(Attendee(id: id))
                state.focus = .attendee(id)
                return .none
                
            case let .deleteAttendees(atOffsets: indices):
                state.standup.attendees.remove(atOffsets: indices)
                if state.standup.attendees.isEmpty {
                    state.standup.attendees.append(Attendee(id: self.uuid()))
                }
                /// 방금 삭제한 필드에 가장 가까운 참석자 필드로 초점 맞추기
                /// 아래 논리는 잘못되기 쉬움
                /// - 인덱스 계산이 잘못되면 충돌이 발생할 수 있는 배열첨자를 수행하고 있음
                guard let firstIndex = indices.first else {
                    return .none
                }
                let index = min(firstIndex, state.standup.attendees.count - 1)
                state.focus = .attendee(state.standup.attendees[index].id)
                return .none
                
            case .binding(_):
                /// 다룰 필요 없음 -> `BindingReducer`가 다룰거라서 (`onChange`)
                return .none
            }
        }
    }
}

struct StandupForm: View {
    let store: StoreOf<StandupFormFeature>
    
    /// 뷰에`.bind(_:to:)` 를 적용해야함
    @FocusState var focus: StandupFormFeature.State.Field?
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            Form {
                Section {
                    TextField("제목", text: viewStore.$standup.title)
                        .focused(self.$focus, equals: .title)
                    
                    HStack {
                        Slider(
                            value: viewStore.$standup.duration.minutes,
                            in: 5...30,
                            step: 1
                        ) {
                            Text("길이")
                        }
                        
                        Spacer()
                        
                        Text(viewStore.standup.duration.formatted(.units()))
                    }
                    
                    ThemePicker(selection: viewStore.$standup.theme)
                } header: {
                    Text("스탠드업 정보")
                }
                
                Section {
                    ForEach(viewStore.$standup.attendees) { $attendee in
                        TextField("Name", text: $attendee.name)
                            .focused(self.$focus, equals: .attendee(attendee.id))
                    }
                    .onDelete { indices in
                        viewStore.send(.deleteAttendees(atOffsets: indices))
                    }
                    
                    Button("참석자 추가") {
                        viewStore.send(.addAttendeeButtonTapped)
                    }
                } header: {
                    Text("참석자")
                }
            }
            .bind(viewStore.$focus, to: self.$focus)
        }
    }
}

extension Duration {
    fileprivate var minutes: Double {
        get { Double(self.components.seconds / 60) }
        set { self = .seconds(newValue * 60) }
    }
}

struct ThemePicker: View {
    @Binding var selection: Theme
    
    var body: some View {
        Picker("Theme", selection: self.$selection) {
            ForEach(Theme.allCases) { theme in
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.mainColor)
                    Label(theme.name, systemImage: "paintpalette")
                        .padding(4)
                }
                .foregroundColor(theme.accentColor)
                .fixedSize(horizontal: false, vertical: true)
                .tag(theme)
            }
        }
    }
}

#Preview {
    MainActor.assumeIsolated {
        NavigationStack {
            StandupForm(
                store: .init(
                    initialState: .init(standup: .mock),
                    reducer: { StandupFormFeature() }
                )
            )
        }
    }
}
