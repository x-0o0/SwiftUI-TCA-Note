# SwiftUI-TCA-Note
The Composable Architecture 공부 노트 (SwiftUI)

에피소드 별로 브랜치를 생성하여 관리하고 있습니다.

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

    Reduce { state, action in
    case .binding: // `BindingReducer` 에서 처리하기 때문에 `Reduce`에서는 처리할 필요 없음
        return .none
    // ...
    }
}
```
1. `BindingReducer` 가 가장 먼저 실행되어서 뷰에서 Binding action을 전송 시, state 변경을 위한 로직을 처리.
디테일한 변경 사항은 `onChange(of:)` 를 사용하여 접근할 수 있다.
```swift
BindingReducer()
    .onChange(of: \.standup.title) { oldTitle, newTitle in
        // ...
    }
```
2. `BindingReducer` 가 Binding action 을 처리하기 때문에 `Reduce` 에서는 `.binding` 케이스의 액션에서는 아무것도 하지 않는다. 

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

enum Field: Hashable {  // ⭐️ `Hashable` 준수 잊지 말것!
    case attendee(Attendee.ID) // 어떤 `attendee`(참석자)에 focus 할지
    case title
}
```
focus 에 사용하는 타입은 반드시 `Hashable` 를 준수하도록 해야함.

```swift
// Action
case binding(BindingAction<State>)
```
```swift
// Reducer
var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
        switch action {
        case .addAttendeeButtonTapped:
            // `state.standup` 에 새 참석자(newAttendee)를 추가한 다음...
            state.focus = .attendee(newAttendee.id)
            return .none
        case let .deleteAttendees(atOffsets: indices):
            // 1. 참석자 제거하고
            // 2. `state.standup.attendees` 가 비어있으면 새 참석자 추가한 다음...
            let index = min(removedItemIndex, lastAttendeeIndex)
            state.focus = .attendee(state.standup.attendees[index].id)
            return .none
        }
    }
}
```

```swift
// View
let store: StoreOf<StandupFeature>

/// 1️⃣
@FocusState var focus: StandupFeature.State.Field?

var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
        TextField("제목", text: viewStore.$standup.title)
            .focused(self.$focus, equals: .title) // 2️⃣ `focus` 값이 `.title` 이면 해당 텍스트필드에 초점 맞추기
            .bind(viewStore.$focus, to: self.$focus) // 3️⃣
    }
}
```
> **중요**
>
> SwiftUI 의 API 인, `.focused(_:equals:)`의 첫번째 파라미터 타입을 보면 `Binding<...>` 이 아니라 `FocusState<...>.Binding` 이다.
>
> `Binding` 과는 다른 타입이기 때문에 `Binding<...>` 타입인 `viewStore.$focus` 를 쓸 수가 없다. (Vanilla SwiftUI 에서도 동일하게 적용되는 내용)
>
> 그래서 SwiftUI 에서는 `@FocusState` 키워드를 사용한 변수를 사용하도록 한다.

1️⃣
`focused(_:equals:)`에 사용하기 위해 `@FocusState` 키워드 변수를 선언하고 타입을 StandupFeature 에 선언했던 focus 와 동일하게 맞춘다. 
```swift
@FocusState var focus: StandupFeature.State.Field?
```
2️⃣
선언한 `@FocusState` 변수를 `focused(_:equals:)` 에 사용
```swift
TextField("제목", text: viewStore.$standup.title)
    .focused(self.$focus, equals: .title)
```
3️⃣
`@FocusState` 로 선언한 변수와 `viewStore.$focus` 는 같은 목적을 갖지만 다른 변수이므로 서로 올바른 값을 가질 수 있도록 연결해준다.
```swift
.bind(viewStore.$focus, to: self.$focus)
```
이렇게 `bind(_:to:)` 를 사용하면, 어느 한쪽에 `.onChange` 가 불릴거나 `.onAppear` 가 호출될 때 상대방의 값도 동일하게 바꿔준다.


# EPISODE. Navigation

## Presentation

```swift
// State

@PresentationState var addStandup: StandupFormFeature.State?
```

```swift
// Action
case addStandup(PresentationAction<StandupFormFeature.Action>)
```
`PresentationAction` 에는 2가지 작업 케이스가 있음.
- `dismiss`
- `presented`

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

## 비포괄 테스트

### 포괄 방식 테스트
```swift
// 저장버튼 누른 경우
await store.send(.saveStandupButtonTapped) {
    $0.addStandup = nil
    $0.standups[0] = Standup(
        id: UUID(0),
        attendees: [Attendee(id: UUID(1))],
        title: "Point-Free Morning Sync"
    )
}
```
포괄 방식 테스트는 $0 에 업데이트한 값이 액션 후 상태값과 전부 일치해야 테스트가 통과.
👉 때로는 모든 데이터를 다보는 것이 아닌 특정 값의 업데이트만 확인하고 싶을 때가 있음
👉 이 때 필요한게 비포괄 테스트

### 비포괄 방식 테스트
모든 댠계를 거치면 마지막에 `Standup` 객체가 컬렉션에 추가되는지만 확인하고 싶을 때(모든 작동 검증 없이 특정 결과만 확인하고 싶은 경우), 비포괄 테스트를 사용한다.

비포괄적 테스트 모드를 하려면 `TestStore` 객체 생성 후 다음 코드를 추가한다.
```swift
store.exhaustivity = .off
```
그러면 `send` 의 클로져의 argument (`$0`) 가 액션 전의 상태가 아닌 **액션 후의 상태**를 의미

> INFO:
> 
> 만약 특정 결과만 확인하고 싶더라도 중간에 체크 안된 작동을 메세지로 받고 싶다면
> `store.exhaustivity = .off(showSkippedAssertions: true)`

```swift
await store.send(.saveStandupButtonTapped) {
-   $0.addStandup = nil // 🔴 제거해도 테스트 통과
    $0.standups[0] = Standup(
        id: UUID(0),
        attendees: [Attendee(id: UUID(1))],
        title: "Point-Free Morning Sync"
    )
}
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


# EPISODE. Stacks

아래는 순수 SwiftUI 에서의 네비게이션 스택.

```swift
NavigationStack(path: Binding<_>, root: ()-> _) {
    ...
}
```
이걸 TCA 로 다루는 법을 배우는 에피소드

## 네비게이션 스택

### 근본: App Feature

네비게이션 스택에서 띄워질 모든 feature들을 통합시킴
정리해보자면
- StandupsListFeature 은 가장 root 이기 때문에 pop 될 일이 없음
- StandupDetailView는 이번에 드릴 다운 네비게이션을 할 대상
- 그리고 회의 녹화 기능 같은 앞으로 배울 기능도 드릴 다운 대상  

```swift
struct AppFeature: Reducer {

}
```

**State**
```swift
// AppFeature.struct
struct State {
    var standupsList = StandupsListFeature.State() // 항상 root 로 갖고 있어서 절대로 팝 될 일이 없음
}
```
**Action**
```swift
enum Action {
    case standupsList(StandupsListFeature.Action)
}
```
**Reducer/Body**
```swift
Reduce { state, action in
    switch action {
    case .standupsList:
        return .none
    }
}
```
`StandupsListFeature` 리듀서를 `AppFeature/body` 에 compose 할 방법을 이제 고민

👉 이때 사용하는 것이 `Scope`

`Scope` 은 부모로 부터 도메인 일부를 떼어내서 자식 리듀서를 실행

```swift
var body: some ReducerOf<Self> {
    Scope(state: \.standupsList, action: /Action.standupsList) { 
        StandupsListFeature() // 자식 리듀서 
    }
    
    Reduce { ... }
}
```
액션이 들어오면 `Scope` 의 child 리듀서에서 먼저 돌아가고 그 다음에 `AppFeature` 코어 로직인 `Reduce` 가 실행됨

**Store**
```swift
// AppView.struct
let store: StoreOf<AppFeature> // 1️⃣ full parent domain of app feature

var body: some View {
    NavigationStack {
        StandupsListView(
            store: self.store.scope( // 2️⃣ to pluck out the domain we're interested in, scope on the store
                state: \.standupsList, 
                action: { .standupsList($0) 
            )
        )
    }
}
```

### 푸시

푸시를 위한 TCA 도구가 있음.

**State**
현재 어떤 feature가 스택에서 돌아가는지를 나타내기 위해 `StackState` 라는 것을 사용한 collection 변수를 선언
```swift
struct State {
    var path = StackState<Path.State>()
    // ...
}
```
**Action**
```swift
enum Action {
    case path(StackAction<Path.state, Path.Action>)
    // ...
}
```
`StackAction` 는 PresentationAction 과 동일
- `element(id:action:)` 
    - 다루고자 하는 스택 요소의 `id` 와 `action` 을 사용해서 스택의 자식 요소에 어떤 일이 일어나는지 나타낼 수 있음
- `popFrom(id:)`
    - 어떤 `id` 로 부터 팝
- `push(id:state)`

**Reducer/body**
```swift
Reduce { state, action in
    switch action {
    case .path: // 1️⃣
        return .none
    }
}
.forEach(\.path, action: /Action.path) { // 2️⃣
    Path()
}
```
- 1️⃣ `.path` 케이스에서 `.popFrom(id:)` 같은 액션을 전달해서 스택 요소를 팝할 수 있음
- 2️⃣ `.forEach(_:action:destination:)`
    - `destination`에는 모든 destination 을 캡슐화한 리듀서를 사용
    - `$` 기호를 안쓰는 건 `StackState`가 프로퍼티 래퍼가 아니기 때문

**Store**
```swift
var body: some View {
    NavigationStackStore(
        self.store.scope(state: \.path, action: { .path($0) })  // 1️⃣
    ) {
        // 2️⃣ root
        StandupsListView(...)
    } destination: { state in // 3️⃣
        switch state {
        case .detail:
            CaseLet(    // 4️⃣
                /AppFeature.Path.State.detail,
                action: AppFeature.Path.Action.detail,
                then: { StandupDetailView(store: $0) }
            )
        }
    }
}
```
- NavigationStackStore 에서는 3가지를 다룸
    - 1️⃣ `store`: 네비게이션을 돌리기 위한 스택의 상태와 액션에 맞춘 store를 전달. 즉 `store.scope` 사용
    - 2️⃣ `root`: root 뷰
    - 3️⃣ `destination`: 스택에 푸시될 수 있는 모든 뷰의 destination
        - 4️⃣ destination 뷰에 store 를 전달할 때는 `scope` 보다는 `CaseLet` 을 사용할 것. `scope` 은 복잡하기 때문

**NavigationStackStore/destination**
```swift
// 미래의 TCA가 가질 모습: CaseLet 제거 하고 scope 사용하기
destination: { store in
    switch store.state {
    case .detail:
        if let store = store.scope(state: \.detail, action: { .detail($0) }) {
            StandupDetailView(store: store)
        }
    }
}
```

스택은 많은 스크린 타입을 다룰 수 있다. 그래야 Detail 스크린 말고도, 녹화 스크린, 지난 미팅 기록 스크린 으로도 드릴 다운 할 수 있다.

따라서 다양한 위치들을 enum 을 사용해서 모델링 해야하고 각 스택의 대상을 단일 기능으로 패키징 하기 위해 `Path` 라는 새로운 리듀서를 정의.

즉, Path 를 위한 State가 enum 인 리듀서를 생성
```swift
struct Path: Reducer {
    enum State {
        case detail(StandupDetailFeature.State)
        // 그 외의 destination
    }
    
    enum Action {
        case detail(StandupDetailFeature.Action)
    }
    
    var body: some ReducerOf<Self> {
        // Scope 을 사용해서 모든 destination 의 리듀서를 compose 해야한다.
        Scope(state: /State.detail, action: /Action.detail) {
            StandupDetailFeature()
        }
    }
}
```
앞으로 푸시해야할 새 feature가 생기면 `Path` 리듀서의 `State` 와 `Action` 에 `case` 를 추가하고 `body` 에 `Scope` 를 추가.
```swift
// Path.State.enum
+   case recordMeeting(RecordMeetingFeature.State)
```
```swift
// Path.Action.enum
+   case recordMeeting(RecordMeetingFeature.State)
```
```swift
// Path/body
+   Scope(state: /State.recordMeeting, action: /Action.recordMeeting) {
        RecordMeetingFeature()
    }
}
```

**푸시 액션**
```swift
// StandupsListView/body

NavigationLink(
    state: AppFeature.Path.State.detail(
        StandupDetailFeature.State(standup: standup)
    )
) {
    CardView(standup: standup)
}
```
`NavigationLink(state:)` 라는 새로운 생성자를 사용해서 `AppFeature.Path` 스택 상태를 `detail` 로 변경할 수 있음

### 앱 실행시 즉각 네비게이션 실행하기
**StandupsApp**
```swift
var body: some Scene {
    WindowGroup {
        var editedStandup = Standup.mock
        let _ = editedStandup.title += "오전 싱크"
        
        AppView(
            store: Store(
                initialState: AppFeature.State(
                    // 1️⃣ path 지정하여 푸시하기
                    path: StackState([
                        .detail(
                            StandupDetailFeature.State(
                                standup: .mocl,
                                // 2️⃣ `editStandup` 값 넣어서 present sheet
                                editStandup: StandupFormFeature.State(
                                    focus: .attendee(editedStandup.atteendees[3].id),
                                    standup: editiedStandup
                                )
                            )
                        )
                    ]),
                    standupsList: ...
                ),
                reducer: { ... }
            )
        )
    }
}
```
- 1️⃣ path 지정해서 Detail 뷰로 드릴 다운 하기.
- 2️⃣ `editStandup` 값 넣어서 Form 뷰 present 하기

### Detail 뷰에서 Root 뷰로 신호 전달하기

**AppFeature/body**
```swift
Reduce { state, action in
    switch action {
    
    case let .path(.popFrom(id: id)):   // 1️⃣
        // 2️⃣
        guard case let .some(.detail(detailState)) = state.path[id: id] else {
            return .none
        }
        // 3️⃣
        state.standupsList.standups[id: detailState.standup.id] = detailState.standup
        return .none
    }
    // ...
}
```

- 1️⃣ `popFrom`: 뒤로가기 버튼을 누를 때 호출 된다. 여기서 전달받은 상태변화를 root 로 전달해주면 된다.
- 2️⃣ 만약 pop 하는 상태가 `detail` 이면 해당 상태를 `detailState` 로 잡아서
- 3️⃣ `detailState` 의 스탠드업 ID 에 해당하는 스탠드업을 `standupsList` 에서 가져와서 `detailState` 의 변경된 스탠드업으로 교체
- 하지만 root 로 돌아오는 애니메이션이 완전히 종료될 때까지 root 의 상태가 바뀌지 않는다.
    - 이 때는 `popFrom` 말고 `element(id:action)` 에서 `.saveStanupButtonTapped` 같은 액션을 처리하는 방식으로 하면 된다.
    
```swift
Reduce { state, action in
    switch action {
    
    case let .path(.element(id: id, action: .detail(.saveStandupButtonTapped))):
        guard case let .some(.detail(detailState)) = state.path[id: id] else {
            return .none
        }
        state.standupsList.standups[id: detailState.standup.id] = detailState.standup
        return .none
    }
    // ...
}
```

- 그러나, 부모 도메인이 자식 도메인을 가로채기 하는 것은 이상적이지 않음
    - 부모 도메인이 로직을 올바르게 실행하기 위해서는 자식 도메인에서 무슨일이 일어나는 지를 너무 많이 알아야하기 때문
    - 이 때는 `delegate` 액션을 사용하는 것이 좋다.

### 델리게이트 액션

**Action**
```swift
enum Action {
    // Delegate
    case delegate(Delegate)
        
    enum Delegate {
        // 1️⃣
        case standupUpdated(Standup)
    }
    
    // ...
}
```
- 1️⃣ 부모 도메인에게 얘기하고자 하는 액션을 `Delegate` enum 에 적어주면 됨
- 그러면 부모 도메인이 해당 Delegate 액션을 listen 하고 있다가 정보가 들어오면 필요한 동작을 수행하게 됨

**Reducer/body**
```swift
var body: some ReducerOf<Self> {
    Reducer { state, action in
    case .delegate:
        // 1️⃣
        return .none
        
    case .saveStandupButtonTapped:
        // state.standup 업데이트
        
        // 2️⃣
        return .send(.delegate(.standupUpdated(state.standup)))
    }
}
```
- 1️⃣ 자식 도메인은 절대로 delegate 액션에 대해서 아무것도 하지 말아야 한다.
- 2️⃣ `send(_:)` 를 사용해서 `delegate` 액션 전달

⭐️ 하지만 더 좋은 방법은 `state.standup` 의 변화를 감지하면 delegate 액션을 전달하는 것이다.

**Reducer/body**

```swift
var body: some ReducerOf<Self> {
    Reducer { state, action in
    case .delegate:
        return .none
        
    case .saveStandupButtonTapped:
        return .none
    }
    .onChange(of: \.standup) { oldValue, newValue in
        // 1️⃣
        Reduce { state, action in
            .send(.delegate(.standupUpdated(newValue)))
        }
    }
}
```
- 1️⃣ 커스텀 리듀서

**부모Feature/body**
```swift
Reduce { state, action in
    case let .path(.element(id: _, action: .detail(.delegate(action)))):
        switch action {
        case let .standupUpdated(standup):
            state.standupsList.standups[id: standup.id] = standup
            return .none
        }
    }
}
```

## Alert

다음 API 를 사용하여 Alert 기능을 구현한다.
- State: `PresentationState`, `AlertState` 
- Action: `PresentationAlert`
- Reducer: `AlertState`, `TextState`, `ButtonState`, `ifLet`
- View: `alert(store:)` 

**Action**

```swift
enum Alert {
    case confirmDelete
}
case alert(PresentationAlert<Alert>)
```

**State**

```swift
@PresentationState var alert: AlertState<Action.Alert>?
```

**Reducer/body**

```swift
Reduce { state, action in
    switch action{
    // 삭제 버튼을 눌렀을 때
    case .deleteButtonTapped:
        state.alert = AlertState {
            // title
            TextState("정말 삭제하시겠습니까?")
        } actions {
            ButtonState(role: .destructive, action: .confirmDeletion) {
                TextState("삭제")
            }
        }
        return .none
    
    case .alert(.presented(.confirmDeletion):
        return .none
        
    case .alert(.dismiss):
        return .none
    }
    .ifLet(\.$alert, action: /Action.alert)
}
```

**View**

```swift
.alert(
    store: self.store.scope(
        state: \.$alert,
        action: { .alert($0) }
    )
)
```

## Multiple navigation
> **문제**: 너무 많이 @PresentationState 의 옵셔널 타입 프로퍼티가 계속 늘어나고 한번에 관리해야한다면?

```swift
state.editStandup = ...
state.alert = AlertState(...)
```

**해결책**: `enum` 을 사용하자 -> 열거형 네비게이션 `// 다음 에피소드`
