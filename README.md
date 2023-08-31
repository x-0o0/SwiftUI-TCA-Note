# SwiftUI-TCA-Note
The Composable Architecture 공부 노트 (SwiftUI)

# EPISODE. Standups

## Binding

### Basics
```swift
// State
@BindingState var standup: Standup
```
```swift
// Action
case binding(BindingAction<State>)
```
```swift
// Reducer
var body: some ReducerOf<Self> {
    BindingReducer() // 먼저 실행. 들어온 Binding action 을 다루고 BindingState 값을 업데이트

    Reduce { state, action in ... }
}
```

```swift
// View
let store: StoreOf<StandupFeature>

var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
        TextField("제목", text: viewStore.$standup.title)
    }
}
```
Pointfree 에서 지향하는 모습 (`WithViewStore` 가 사라지고 `Store` 를 `@State` 속성래퍼와 함께 사용)
```swift
// View (To-Be)
@State var store: StoreOf<StandupFeature>
Var body: some View {
    TextField("제목", text: $store.standup.title)
}
```

### Focus
```swift
// State
@BindingState var focus: Field?

enum Field: Hashable {
    case attendee(Attendee.ID)
    case title
}
```
```swift
// Action
case binding(BindingAction<State>)
```
```swift
// Reducer
var body: some ReducerOf<Self> {
    BindingReducer() // 먼저 실행. 들어온 Binding action 을 다루고 BindingState 값을 업데이트

    Reduce { state, action in
        switch action {
        case .addAttendeeButtonTapped:
            // append new attendee to `state.standup` and then...
            state.focus = .attendee(newAttend.id)
        }
    }
}
```

```swift
// View
let store: StoreOf<StandupFeature>

/// 1️⃣ 뷰에`.bind(_:to:)` 를 통해 store의 focus 를 self.focus 에 바인딩
@FocusState var focus: StandupFeature.State.Field?

var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
        TextField("제목", text: viewStore.$standup.title)
            .focused(self.$focus, equals: .title) // 3️⃣ `focus` 값이 `.title` 이면 해당 텍스트필드에 초점 맞추기
            .bind(viewStore.$focus, to: self.$focus) // 2️⃣
    }
}
```
