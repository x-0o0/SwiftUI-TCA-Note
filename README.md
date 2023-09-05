# SwiftUI-TCA-Note
The Composable Architecture 공부 노트 (SwiftUI)

<img width="75%" alt="Screenshot 2023-09-01 at 2 00 58 AM" src="https://github.com/jaesung-0o0/SwiftUI-TCA-Note/assets/53814741/e308fd18-c2c9-4a2e-9628-2f1874a3f94a">

# EPISODE. The Basics

## Testing

### MainActor
```swift
@MainActor
final class TheBasicsTests: XCTestCase
```
XCTestCase 클래스에 MainActor 속성 추가하여 테스트들이 메인쓰레드에서 돌아가는 것을 보장.

### TestStore
```swift
let store = TestStore(initialState: CounterFeature.State()) {
    CounterFeature()
}
```

### `store.send(_:)`
```swift
await store.send(.incrementButtonTapped) {
    // $0: in-out piece of state. 액션 보내지기 전의 상태.
    // 액션 전의 State의 값을 액션 후 기대되는 State에 맞춰 값으로 세팅
    $0.count = 1
}
```

## Dependencies

### Task & Clock

```swift
Task.sleep(for: .second(1))
```
Task 를 쓰면 테스팅할때 아래와 같은 코드 작성시 sleep 시간만큼 정직하게 기다려야해서 테스트 시간이 오래 걸림.
```swift
Task.sleep(for: .second(1))

await store.receive(.timerTicked) {
    $0.count = 1
}

Task.sleep(for: .second(1))

await store.receive(.timerTicked) {
    $0.count = 1
}
```
이를 개선하기 위해 TCA 에서 제공하는 clock을 사용
```swift
// Reducer
@Dependency(\.continuousClock) var clock

var body: some ReducerOf<Self> { state, action in
    // ...
    self.clock.timer(interval: .seconds(1))
}
```
테스트에서는 `advance(by:)` 를 사용해서 시간을 앞당기는 효과를 줄 수 있음. 타임워프
```swift
let clock = TestClock()

let store = TestStore(initialState: CounterFeature.State()) {
    CounterFeature()
} withDependencies: {
    $0.continuousClock = clock
}

await clock.advance(by: .seconds(1))
```
위의 Task 를 사용한 코드를 아래와 같이 바꾸면 순식간에 테스트가 완료
```swift
await clock.advance(by: .seconds(1))

await store.receive(.timerTicked) {
    $0.count = 1
}

await clock.advance(by: .seconds(1))

await store.receive(.timerTicked) {
    $0.count = 1
}
```

### Testing Error Case

```swift
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
```

### UUID

```swift
// Reducer
@Dependency(\.uuid) var uuid

var body: some ReducerOf<Self> { state, action in
    // ...
    let id = self.uuid()
}
```
```swift
// Testing method
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
```

### 디펜던시 만들기
```swift
/// 숫자에 대한 재밌는 사실을 가져오는 API Client
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
```

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


# EPISODE. Navigation

## Presentation

```swift
// State

@PresentationState var addStandup: StandupFormFeature.State?
```

```swift
// Action

/// `PresentationAction` 에는 `dismiss` 와 `presented` 케이스가 있음
case addStandup(PresentationAction<StandupFormFeature.Action>)
```

```swift
// Reducer

Reduce { state, action in
    switch action {
        case .addButtonTapped:
            // 네비게이션 활성화
            state.addStandup = StandupFormFeature.State(standup: Standup.empty)
            return .none
            
        case .saveStandupButtonTapped:
            // 부모와 통신
            guard let standup = state.addStateup?.standup else {
                return .none
            }
            state.standups.apped(standup)
            
            // 네비게이션 비활성화
            state.addStandup = nil
            return .none
        }
    }
    .ifLet(\.$addStandup, action: /Action.addStandup) { // keyPath, casePath
        StandupFormFeature()
    }
}
```

```swift
// View

/// `sheet(store:content:)` 사용
.sheet(
    /// `scope` 을 사용하여 `Store`의 범위를 **특정 부분에만 초점을** 맞출 수 있음
    store: self.store.scope(
        state: \.$addStandup,       // keyPath
        action: { .addStandup($0) } // closure
    )
) { store in
    StandupForm(store: store)
} 
/// **스와이프로 dismiss**하면 자동으로 `state.addStandup = nil` 이 됨
```

### scope

`store.scope` 을 사용하여 `Store`의 범위를 **특정 부분에만 초점을** 맞출 수 있음

### ifLet

부모-자식 간의 Feature를 통합하여 서로간의 통신이 가능.

예를 들어 부모가 언제 "참석자 추가" 버튼을 눌렀는지 알고 싶다면 아래와 같이 하면됨
```swift
case .addStandup(.presented(.addAttendeeButtonTapped)):
    // do something
```


## 네비게이션 방식 (Navigation Styles)

### 트리 기반 네비게이션 (Tree-based navigation)
네비게이션 state를 옵셔널로 모델링 하는 것
- nil 이면, 해당 feature로 네비게이트 하지 않음을 나타냄
- 값이 존재하면, 네비게이션을 활성화함을 나타냄.
sheet 에서 사용하는 방식. 

### 스택 기반 네비게이션 (Stack-based navigation)
state의 1차원 배열로 네비게이션 스택을 모델링 하는 것
드릴 다운 네비게이션을 위한 방식으로. 스택에 값을 추가하는 방식에 대응.
