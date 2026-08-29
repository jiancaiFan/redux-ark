# redux_ark

`redux_ark` 是一个面向 HarmonyOS ArkTS / ArkUI 全新设计的 Redux 状态管理库。核心行为以 `redux@5.0.1` 为基线实现，并针对 ArkTS 的静态类型、对象布局和模块规则进行了原生适配。

它为鸿蒙应用提供单向数据流、Reducer、Middleware、不可变 State，以及清晰可维护的业务分层能力。

## 主要优势

### ArkTS 原生实现

- 全部生产代码使用 `.ets`，不是把 JavaScript 包直接塞进鸿蒙工程。
- 不依赖 DOM、浏览器对象、Node.js 或 React。
- 不使用 `any`、`unknown`、动态 index signature、`Symbol.observable` 等不符合 ArkTS 规则的实现。
- 已使用 HarmonyOS `6.1.1(24)` SDK 编译验证。

### 保留 Redux 的核心能力

- `createStore` 和简洁的 `createConcurrentStore`。
- `dispatch`、`getState`、`subscribe`、`replaceReducer`。
- `applyMiddleware`、递归 dispatch 和从右向左的 `compose`。
- `combineReducers`、`bindActionCreators`。
- 订阅快照、嵌套 dispatch、reducer 重入保护和异常恢复。
- 显式 `store.observable()` 状态观察能力。

### 适合 ArkUI 生命周期

Store 不依赖 UI 框架，可以在 ArkUI 页面、ViewModel、服务或业务模块中使用。页面可在 `aboutToAppear` 中订阅，在 `aboutToDisappear` 中取消订阅，并把 Store State 同步到 ArkUI `@State`。

### 清晰的鸿蒙业务分层

推荐保持下面的业务结构：

```text
feature/
├── FeatureAction.ets
├── FeatureState.ets
├── FeatureReducer.ets
├── FeatureSideEffect.ets
└── FeatureStoreProvider.ets
```

Action、State、Reducer、SideEffect、StoreProvider 各司其职，适合在 HarmonyOS Feature 模块中独立组织、测试与复用。

### 轻量、无运行时依赖

- `dependencies` 为空。
- 当前 HAR 大约 23 KB。
- Redux 状态逻辑与 ArkUI 页面解耦，便于测试和复用。

## 安装

### 同一 DevEco Studio 工程中的本地模块

工程级 `build-profile.json5`：

```json5
{
  "modules": [
    {
      "name": "redux_ark",
      "srcPath": "./redux_ark",
      "targets": [
        {
          "name": "default",
          "applyToProducts": ["default"]
        }
      ]
    }
  ]
}
```

使用方模块的 `oh-package.json5`：

```json5
{
  "dependencies": {
    "redux_ark": "file:../redux_ark"
  }
}
```

### 使用编译后的 HAR

将 `redux_ark.har` 放入使用方模块的 `libs` 目录：

```json5
{
  "dependencies": {
    "redux_ark": "file:./libs/redux_ark.har"
  }
}
```

然后在 DevEco Studio 中执行 Sync，或运行 `ohpm install`。

## 快速开始

### 1. 定义 Action

ArkTS 使用明确的 class 表达 Action，所有 Action 都具有字符串 `type`。

```typescript
import { Action } from 'redux_ark'

export class CounterAddAction implements Action {
  type: string = 'CounterAdd'
  amount: number

  constructor(amount: number) {
    this.amount = amount
  }
}

export class CounterLoadingAction implements Action {
  type: string = 'CounterLoading'
}

export class CounterAsyncAddAction implements Action {
  type: string = 'CounterAsyncAdd'
  amount: number

  constructor(amount: number) {
    this.amount = amount
  }
}

export class CounterAction {
  static add(amount: number): CounterAddAction {
    return new CounterAddAction(amount)
  }

  static loading(): CounterLoadingAction {
    return new CounterLoadingAction()
  }

  static asyncAdd(amount: number): CounterAsyncAddAction {
    return new CounterAsyncAddAction(amount)
  }
}
```

### 2. 定义 State

```typescript
export class CounterState {
  count: number
  isLoading: boolean

  constructor(count: number = 0, isLoading: boolean = false) {
    this.count = count
    this.isLoading = isLoading
  }
}
```

### 3. 定义 Reducer

Reducer 必须保持纯函数语义：不执行网络请求，不直接修改旧 State，而是返回新的 State。

```typescript
import { Action, Reducer } from 'redux_ark'
import { CounterAddAction } from './CounterAction'
import { CounterState } from './CounterState'

export class CounterReducer implements Reducer<CounterState> {
  reduce(state: CounterState | undefined, action: Action): CounterState {
    const current = state === undefined ? new CounterState() : state

    switch (action.type) {
      case 'CounterLoading':
        return new CounterState(current.count, true)
      case 'CounterAdd':
        const add = action as CounterAddAction
        return new CounterState(current.count + add.amount, false)
      default:
        return current
    }
  }
}
```

### 4. 定义 Middleware / SideEffect

异步请求、缓存、日志和 action 编排应放在 Middleware 中。

```typescript
import { Action, Dispatch, Middleware, MiddlewareAPI } from 'redux_ark'
import { CounterAction, CounterAsyncAddAction } from './CounterAction'
import { CounterState } from './CounterState'

export class CounterSideEffect implements Middleware<CounterState> {
  dispatch(store: MiddlewareAPI<CounterState>, next: Dispatch<Action>, action: Action): Action {
    const result = next.dispatch(action)

    if (action.type === 'CounterAsyncAdd') {
      const asyncAction = action as CounterAsyncAddAction
      store.dispatch(CounterAction.loading())

      setTimeout(() => {
        store.dispatch(CounterAction.add(asyncAction.amount))
      }, 500)
    }

    return result
  }
}
```

`next.dispatch(action)` 表示把当前 action 继续交给后面的 Middleware 或 Reducer。`store.dispatch(...)` 会重新经过完整 Middleware 链，适合派生 loading、success、error 等 Action。

### 5. 创建 StoreProvider

```typescript
import {
  Action,
  Store,
  applyMiddleware,
  createConcurrentStore
} from 'redux_ark'
import { CounterReducer } from './CounterReducer'
import { CounterSideEffect } from './CounterSideEffect'
import { CounterState } from './CounterState'

export class CounterStoreProvider {
  static create(): Store<CounterState, Action> {
    return createConcurrentStore<CounterState, Action>(
      new CounterReducer(),
      new CounterState(),
      applyMiddleware<CounterState, Action>(new CounterSideEffect())
    )
  }
}
```

Store 使用统一、简洁的创建方式：

```text
createConcurrentStore(reducer, preloadedState, applyMiddleware(middleware))
```

### 6. 在 ArkUI 页面中订阅

```typescript
import { StoreSubscriber, StoreSubscription } from 'redux_ark'
import { CounterAction } from './CounterAction'
import { CounterState } from './CounterState'
import { CounterStoreProvider } from './CounterStoreProvider'

const counterStore = CounterStoreProvider.create()

@Entry
@Component
struct Index {
  @State state: CounterState = counterStore.getState()
  private subscription?: StoreSubscription

  aboutToAppear(): void {
    this.subscription = counterStore.subscribe(this as StoreSubscriber)
  }

  onStateChanged(): void {
    this.state = counterStore.getState()
  }

  aboutToDisappear(): void {
    if (this.subscription !== undefined) {
      this.subscription.unsubscribe()
      this.subscription = undefined
    }
  }

  build() {
    Column({ space: 12 }) {
      Text('Count: ' + this.state.count.toString())

      Button('+1')
        .onClick(() => {
          counterStore.dispatch(CounterAction.add(1))
        })

      Button('Async +1')
        .onClick(() => {
          counterStore.dispatch(CounterAction.asyncAdd(1))
        })
    }
  }
}
```

## 数据流

```text
ArkUI / ViewModel
      │ dispatch(Action)
      ▼
Middleware / SideEffect
      │ next.dispatch(Action)
      ▼
Reducer(oldState, action)
      │ return newState
      ▼
Store
      │ notify subscribers
      ▼
ArkUI @State 更新并重绘
```

## 核心 API

| API | 用途 |
| --- | --- |
| `createStore` | 创建标准 Redux Store。 |
| `createConcurrentStore` | 鸿蒙友好的简洁入口，与 `createStore` 具有相同状态管理语义。 |
| `Store.dispatch` | 派发 Action，并返回同一个 Action。 |
| `Store.getState` | 获取当前 State。 |
| `Store.subscribe` | 订阅每次 dispatch 后的状态通知。 |
| `Store.replaceReducer` | 动态替换 Reducer，并保留已有 State。 |
| `applyMiddleware` | 组合异步、日志、缓存等 Middleware。 |
| `combineReducers` | 把多个 slice Reducer 组合成一个 Reducer。 |
| `bindActionCreators` | 将 ActionCreator 与 dispatch 绑定。 |
| `compose` | 从右向左组合 `Operator<T>` 或 StoreEnhancer。 |
| `Store.observable` | 以 Observer 方式接收当前 State 和后续更新。 |

## 正确性保障

Store 实现保留了 Redux 重要的边界行为：

- Reducer 执行期间禁止再次 dispatch。
- Reducer 执行期间禁止 getState、subscribe 和 unsubscribe。
- Reducer 抛出异常后，Store 能恢复到可继续 dispatch 的状态。
- 每次 dispatch 使用订阅列表快照。
- 通知过程中新增或移除订阅者，只影响下一次 dispatch。
- 支持订阅回调中的嵌套 dispatch。
- unsubscribe 可以安全地重复调用。

## 使用建议

- State 使用 class，并将字段类型全部显式声明。
- Reducer 返回新 State，不修改旧 State。
- 网络请求、数据库、定时器等副作用放入 Middleware。
- Action `type` 使用稳定、唯一的字符串。
- 页面销毁时必须取消 Store 订阅。
- Store 通常由应用级依赖注入容器或 Feature StoreProvider 管理，避免在每次 UI 重绘时重复创建。

## 使用边界

- `createConcurrentStore` 是面向鸿蒙业务提供的简洁入口，目前不表示同一个 Store 可以跨 Worker 共享。
- 不包含 Redux Toolkit、React-Redux、浏览器 Redux DevTools 或持久化实现。
- 跨 Worker 状态同步应通过 HarmonyOS Worker 消息传递，并在各自线程维护明确的状态边界。
- 持久化应由 Middleware 接入 Preferences、关系型数据库或业务仓库。

## 构建与验证

HAR 构建命令：

```shell
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk \
PATH=/Applications/DevEco-Studio.app/Contents/tools/ohpm/bin:/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin:$PATH \
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw \
assembleHar --mode module -p module=redux_ark@default -p product=default --no-incremental
```

当前版本已经通过：

- HAR ArkTS 全量编译。
- 示例 HAP ArkTS 全量编译。
- Store、订阅快照、Middleware、递归 dispatch、Observable、ActionCreator、combineReducers 行为回归。
- 生产源码与生成声明中的 `any`、`unknown` 检查。

## 版本信息

- 包名：`redux_ark`
- 当前版本：`1.0.0`
- Redux 行为基线：`redux@5.0.1` core
- 许可证：MIT
