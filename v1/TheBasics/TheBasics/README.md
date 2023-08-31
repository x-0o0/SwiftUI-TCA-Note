#  The Basics

# Reducer

```swift
struct CounterFeature: Reducer
```

## 상태 (State)

State 는 항상은 아니지만 보통은 struct 로 선언 State

## 액션 (Action)

- UI에서 발생하는 액션들
- 시스템으로 돌아오는 이펙트

를 케이스로 정의

## body

```swift
var body: some ReducerOf<Self> {
    Reduce { state, action in
        /// 1. 액션 스위칭
        /// 2. 케이스가 UI에서 어떤 역할을 수행하는지 구현
    }
}
```

### Reduce
```swift
    Reduce { state, action in
        switch action {
        case .decrementButtonTapped:
            state.count -= 1
            return .none
        case .incrementButtonTapped:
            state.count += 1
            return .none
        }
    }
```

### Effect

추가적인 행동이 없으면 `.none.` 을 리턴
```swift
case .incrementButtonTapped:
    state.count += 1
    return .none
```
