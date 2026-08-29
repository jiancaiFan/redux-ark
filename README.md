<div align="center">

<h1>redux_ark</h1>

<p><strong>Redux state management for HarmonyOS — written in strict ArkTS.</strong></p>

<p>为 ArkUI 应用提供可预测、可测试、可扩展的单向数据流。</p>

[![Version](https://img.shields.io/badge/version-1.0.0-6f42c1?style=flat-square)](./oh-package.json5)
[![HarmonyOS](https://img.shields.io/badge/HarmonyOS-6.1.1%2B-e60012?style=flat-square)](https://developer.huawei.com/consumer/cn/)
[![ArkTS](https://img.shields.io/badge/ArkTS-strict-0a59f7?style=flat-square)](https://developer.huawei.com/consumer/cn/arkts/)
[![License](https://img.shields.io/github/license/jiancaiFan/redux-ark?style=flat-square)](./LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/jiancaiFan/redux-ark?style=flat-square)](https://github.com/jiancaiFan/redux-ark/stargazers)
[![Author](https://img.shields.io/badge/author-EricFan-182431?style=flat-square)](https://github.com/jiancaiFan)

<p><sub>Created and maintained by <a href="https://github.com/jiancaiFan"><strong>EricFan（樊建财）</strong></a></sub></p>

[快速开始](#快速开始) · [ArkUI 接入](#arkui-componentv2-接入) · [异步处理](#异步与-sideeffect) · [API](#核心-api) · [设计边界](#设计边界) · [作者](#作者)

</div>

---

`redux_ark` 是面向 HarmonyOS ArkTS / ArkUI 全新设计的 Redux 状态管理库。它以官方 `redux@5.0.1` Core 的可观察行为为基线，针对 ArkTS 的静态类型、对象模型和模块规则进行原生实现。

```text
Action → Middleware → Reducer → State → Subscriber → ArkUI
```

## 为什么选择 redux_ark

| | 能力 | 说明 |
| --- | --- | --- |
| 🧭 | 可预测状态 | 所有状态变化都由明确的 Action 驱动，并经过 Reducer 生成新 State。 |
| 🧩 | ArkTS 原生 | 生产源码全部使用 `.ets`，不依赖 DOM、Node.js、React 或 JavaScript 包装层。 |
| 🛡️ | 严格类型 | 不使用 `any`、`unknown`、动态 index signature 或 `Symbol.observable`。 |
| 🔌 | Middleware | 支持 SideEffect、日志、缓存和 Action 编排，内部 dispatch 会重新经过完整链路。 |
| 🎨 | ArkUI 友好 | Store 与 UI 解耦，可自然接入 ComponentV2、ViewModel 和页面生命周期。 |
| 🪶 | 轻量独立 | 无运行时依赖，适合以源码模块或 HAR 引入现有鸿蒙工程。 |

### 项目状态

| 项目 | 当前状态 |
| --- | --- |
| 包版本 | `1.0.0` |
| 验证 SDK | HarmonyOS `6.1.1(24)` |
| Redux 行为基线 | `redux@5.0.1` Core |
| 运行时依赖 | `0` |
| 许可证 | MIT |

## 安装

目前推荐通过本地源码模块或 HAR 接入。项目尚未发布到 OHPM 公共仓库。

### 本地源码模块

在 DevEco Studio 工程级 `build-profile.json5` 中注册模块：

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

然后在使用方模块的 `oh-package.json5` 中添加：

```json5
{
  "dependencies": {
    "redux_ark": "file:../redux_ark"
  }
}
```

### 本地 HAR

将 `redux_ark.har` 放入使用方模块的 `libs` 目录：

```json5
{
  "dependencies": {
    "redux_ark": "file:./libs/redux_ark.har"
  }
}
```

配置完成后，在 DevEco Studio 中执行 **Sync Project**，或运行 `ohpm install`。

## 快速开始

下面的最小示例展示 Action、State、Reducer、Store 和订阅的完整闭环。

### 1. Action 与 State

```typescript
import { Action } from 'redux_ark'

export class CounterAddAction implements Action<'counter/add'> {
  type: 'counter/add' = 'counter/add'
  amount: number

  constructor(amount: number) {
    this.amount = amount
  }
}

export class CounterState {
  count: number

  constructor(count: number = 0) {
    this.count = count
  }
}
```

### 2. Reducer

Reducer 保持纯函数语义：不执行网络、数据库或定时器操作，也不修改旧 State。

```typescript
import { Action, Reducer } from 'redux_ark'
import { CounterAddAction, CounterState } from './CounterModel'

export class CounterReducer implements Reducer<CounterState> {
  reduce(state: CounterState | undefined, action: Action): CounterState {
    const current = state === undefined ? new CounterState() : state

    if (action.type === 'counter/add') {
      const addAction = action as CounterAddAction
      return new CounterState(current.count + addAction.amount)
    }

    return current
  }
}
```

### 3. Store

```typescript
import { Action, Store, createStore } from 'redux_ark'
import { CounterReducer } from './CounterReducer'
import { CounterState } from './CounterModel'

export const counterStore: Store<CounterState, Action> =
  createStore<CounterState, Action>(
    new CounterReducer(),
    new CounterState()
  )
```

### 4. Dispatch 与订阅

```typescript
import { StoreSubscriber } from 'redux_ark'
import { CounterAddAction } from './CounterModel'
import { counterStore } from './CounterStore'

class CounterSubscriber implements StoreSubscriber {
  onStateChanged(): void {
    console.info('count = ' + counterStore.getState().count.toString())
  }
}

const subscription = counterStore.subscribe(new CounterSubscriber())

counterStore.dispatch(new CounterAddAction(1))
// count = 1

subscription.unsubscribe()
```

## 数据流

```text
┌───────────────────┐
│ ArkUI / ViewModel │
└─────────┬─────────┘
          │ dispatch(Action)
          ▼
┌───────────────────┐
│    Middleware     │──── SideEffect / logging / orchestration
└─────────┬─────────┘
          │ next.dispatch(Action)
          ▼
┌───────────────────┐
│      Reducer      │──── pure: old State + Action → new State
└─────────┬─────────┘
          │
          ▼
┌───────────────────┐
│       Store       │──── snapshot listeners and notify
└─────────┬─────────┘
          │
          ▼
┌───────────────────┐
│ ArkUI re-render   │
└───────────────────┘
```

### 同步 Action

`dispatch()` 会同步执行 Reducer、更新 State、通知订阅者，并返回传入的同一个 Action。

```text
dispatch(AddAction) → Reducer → new State → notify → return AddAction
```

### 异步 Action

Store 和 Reducer 始终保持同步。异步任务由 Middleware / SideEffect 执行，完成后重新派发普通 Action。

```text
dispatch(FetchAction)
  → SideEffect
  → dispatch(LoadingAction)
  → async work
  → dispatch(LoadAction | ErrorAction)
  → Reducer
  → new State
```

## 异步与 SideEffect

```typescript
import { Action, Dispatch, Middleware, MiddlewareAPI } from 'redux_ark'
import { CounterState } from './CounterModel'

class CounterFetchAction implements Action<'counter/fetch'> {
  type: 'counter/fetch' = 'counter/fetch'
}

class CounterLoadingAction implements Action<'counter/loading'> {
  type: 'counter/loading' = 'counter/loading'
}

class CounterLoadAction implements Action<'counter/load'> {
  type: 'counter/load' = 'counter/load'
  amount: number

  constructor(amount: number) {
    this.amount = amount
  }
}

export class CounterSideEffect implements Middleware<CounterState> {
  dispatch(
    store: MiddlewareAPI<CounterState>,
    next: Dispatch<Action>,
    action: Action
  ): Action {
    const result = next.dispatch(action)

    if (action.type === 'counter/fetch') {
      store.dispatch(new CounterLoadingAction())

      setTimeout(() => {
        store.dispatch(new CounterLoadAction(1))
      }, 500)
    }

    return result
  }
}
```

创建带 Middleware 的 Store：

```typescript
import { Action, Store, applyMiddleware, createStore } from 'redux_ark'

const store: Store<CounterState, Action> = createStore<CounterState, Action>(
  new CounterReducer(),
  new CounterState(),
  applyMiddleware<CounterState, Action>(new CounterSideEffect())
)
```

> [!IMPORTANT]
> `next.dispatch(action)` 将当前 Action 交给后续 Middleware 或 Reducer；`store.dispatch(action)` 会从完整 Middleware 链的起点重新派发。

## ArkUI ComponentV2 接入

推荐由 ViewModel 持有 Store 和订阅关系，UI 只读取可观察 State 并派发用户意图。

<details>
<summary><strong>查看 ComponentV2 + ViewModel 示例</strong></summary>

```typescript
import {
  Action,
  Store,
  StoreSubscriber,
  StoreSubscription
} from 'redux_ark'
import { CounterAddAction, CounterState } from './CounterModel'
import { counterStore } from './CounterStore'

@ObservedV2
export class CounterViewModel implements StoreSubscriber {
  private store: Store<CounterState, Action> = counterStore
  @Trace public state: CounterState = this.store.getState()
  private subscription?: StoreSubscription

  start(): void {
    if (this.subscription === undefined) {
      this.subscription = this.store.subscribe(this)
    }
  }

  onStateChanged(): void {
    this.state = this.store.getState()
  }

  add(amount: number): void {
    this.store.dispatch(new CounterAddAction(amount))
  }

  onCleared(): void {
    if (this.subscription !== undefined) {
      this.subscription.unsubscribe()
      this.subscription = undefined
    }
  }
}
```

```typescript
import { CounterViewModel } from './CounterViewModel'

@Entry
@ComponentV2
struct Index {
  @Local viewModel: CounterViewModel = new CounterViewModel()

  aboutToAppear(): void {
    this.viewModel.start()
  }

  aboutToDisappear(): void {
    this.viewModel.onCleared()
  }

  build() {
    Column({ space: 16 }) {
      Text(this.viewModel.state.count.toString())
        .fontSize(48)

      Button('+1')
        .onClick(() => {
          this.viewModel.add(1)
        })
    }
  }
}
```

</details>

> [!NOTE]
> ViewModel 应在 `aboutToAppear()` 之后建立订阅，避免在 ArkUI 创建 `@ObservedV2` 代理之前捕获原始 `this`，导致 `@Trace` 更新无法触发刷新。

## 推荐项目结构

```text
feature/
├── FeatureAction.ets          # 用户意图和状态事件
├── FeatureState.ets           # 唯一状态模型
├── FeatureUIModel.ets         # UI 展示模型（可选）
├── FeatureMapper.ets          # Response / Action → UIModel（可选）
├── FeatureReducer.ets         # 纯状态转换
├── FeatureSideEffect.ets      # 网络、数据库、缓存、定时器
├── FeatureStoreProvider.ets   # Store 组装与依赖注入
└── FeatureViewModel.ets       # ArkUI 生命周期和订阅桥接
```

Store 不依赖 UI 层，也可以放在应用级容器、服务或独立业务模块中。

## 核心 API

| API | 用途 |
| --- | --- |
| `createStore` | 创建标准 Redux Store。 |
| `createConcurrentStore` | `createStore` 的简洁别名，状态管理语义相同。 |
| `Store.dispatch` | 同步派发 Action，并返回同一个 Action。 |
| `Store.getState` | 获取当前 State。 |
| `Store.subscribe` | 订阅每次 dispatch 后的状态通知。 |
| `Store.replaceReducer` | 动态替换 Reducer，并保留已有 State。 |
| `applyMiddleware` | 按声明顺序组装 Middleware 链。 |
| `combineReducers` | 将多个 Slice Reducer 组合成根 Reducer。 |
| `bindActionCreators` | 将 ActionCreator 与 dispatch 绑定。 |
| `compose` | 从右向左组合 `Operator<T>` 或 StoreEnhancer。 |
| `Store.observable` | 以 Observer 方式接收当前 State 和后续更新。 |
| `isAction` | 校验 ArkTS typed Action 和字符串 `type`。 |
| `isPlainObject` | 校验 Action 对象，并支持数据型 ArkTS class Action。 |

## 行为保障

核心回归测试位于 [`test/ReduxCoreBehavior.ets`](./test/ReduxCoreBehavior.ets)。

| Redux 行为 | 状态 |
| --- | :---: |
| Store 创建时初始化 State | ✅ |
| dispatch 返回同一个 Action | ✅ |
| Reducer 重入保护 | ✅ |
| Reducer 异常后的 dispatch 恢复 | ✅ |
| 订阅列表快照 | ✅ |
| 嵌套 dispatch | ✅ |
| Middleware 顺序与递归 dispatch | ✅ |
| replaceReducer 保留已有 State | ✅ |
| combineReducers 初始化与未知 Action 探测 | ✅ |
| Observable 初始值、更新与取消订阅 | ✅ |

## ArkTS 适配

`redux_ark` 保留 Redux 的状态管理语义，但不会逐字复制 JavaScript 动态类型实现。

- Function、Reducer、Dispatch 和 Middleware 使用具名强类型接口。
- 动态对象 Map 使用 `ReducersMapObject`、`ActionCreatorsMapObject` 和 `StateObject` 表达。
- `compose` 使用 `Operator<T>.apply()` 实现从右到左组合。
- `Symbol.observable` 改为显式 `store.observable()`。
- 数据型 ArkTS class 可作为 Action，仍要求稳定的字符串 `type`。
- 生产 `.ets` 源码不依赖 `any` 或 `unknown`。

## 设计边界

为了保持库轻量和职责清晰，当前版本有以下明确边界：

- `createConcurrentStore` 不表示同一个 Store 可以跨 Worker 直接共享；跨 Worker 状态应通过 HarmonyOS 消息机制同步。
- base dispatch 与 Middleware 的输入、返回值均为 `Action`，当前不提供 thunk dispatch 或 Promise 返回值扩展。
- 不包含 Redux Toolkit、React-Redux、浏览器 Redux DevTools 或持久化方案。
- 网络、Preferences、关系型数据库和缓存通过业务 Middleware 接入。
- Action 建议仅包含可预测的数据字段，不应保存 UI Context、连接或平台资源对象。

## 构建与验证

在已经注册 `redux_ark` 模块的 DevEco Studio 工程根目录运行：

```shell
hvigorw assembleHar \
  --mode module \
  -p module=redux_ark@default \
  -p product=default \
  --no-incremental
```

`1.0.0` 已通过：

- HarmonyOS `6.1.1(24)` HAR 全量 ArkTS 编译。
- 示例 HAP 全量 ArkTS 编译。
- Store、订阅、Middleware、递归 dispatch、Observable、ActionCreator 和 combineReducers 行为回归。
- 生产源码及生成声明的 `any`、`unknown` 检查。

## 贡献

欢迎通过 [Issues](https://github.com/jiancaiFan/redux-ark/issues) 报告问题或提出建议。提交改动前请确保：

1. 生产代码符合严格 ArkTS 语法规则。
2. Reducer 保持纯函数语义，SideEffect 位于 Middleware。
3. 新行为包含对应的回归测试。
4. HAR 与示例 HAP 均能完成全量编译。

## 致谢

核心状态管理语义参考 [Redux](https://github.com/reduxjs/redux) `5.0.1`。`redux_ark` 是独立面向 HarmonyOS ArkTS / ArkUI 设计和维护的实现。

## 作者

<table>
  <tr>
    <td align="center" width="150">
      <a href="https://github.com/jiancaiFan">
        <img src="https://github.com/jiancaiFan.png?size=160" width="96" alt="EricFan（樊建财）" />
        <br />
        <strong>EricFan（樊建财）</strong>
      </a>
      <br />
      <sub>Creator &amp; Maintainer</sub>
    </td>
    <td>
      <strong>关于作者</strong>
      <br /><br />
      <code>redux_ark</code> 的创建者与主要维护者，负责 HarmonyOS ArkTS 架构设计、Redux Core 行为对齐、API 设计和版本维护。
      <br /><br />
      <a href="https://github.com/jiancaiFan">GitHub Profile</a>
      ·
      <a href="https://github.com/jiancaiFan/redux-ark/issues">Issues</a>
    </td>
  </tr>
</table>

## License

[MIT](./LICENSE) © 2026 EricFan（樊建财）

---

<div align="center">

<p>如果这个项目对你有帮助，欢迎点亮 ⭐ Star，让更多 HarmonyOS 开发者看到它。</p>

<p><strong>Designed &amp; maintained with care by EricFan（樊建财）.</strong></p>

</div>
