import {
  Action,
  ActionCreator,
  ActionCreatorArgs,
  Dispatch,
  Middleware,
  MiddlewareAPI,
  Observer,
  Reducer,
  ReducersMapObject,
  ReduxValue,
  StateObject,
  Store,
  StoreCreator,
  StoreSubscriber,
  StoreSubscription,
  applyMiddleware,
  bindActionCreators,
  combineReducers,
  compose,
  createStore,
  isAction,
  isPlainObject
} from '../index'

class TestAction implements Action {
  type: string
  amount: number

  constructor(type: string, amount: number = 0) {
    this.type = type
    this.amount = amount
  }
}

class CounterReducer implements Reducer<number, Action> {
  reduce(state: number | undefined, action: Action): number {
    const current = state === undefined ? 0 : state
    if (action.type === 'add') {
      return current + (action as TestAction).amount
    }
    return current
  }
}

class DoubleReducer implements Reducer<number, Action> {
  reduce(state: number | undefined, action: Action): number {
    const current = state === undefined ? 0 : state
    if (action.type === 'add') {
      return current + (action as TestAction).amount * 2
    }
    return current
  }
}

class FailingReducer implements Reducer<number, Action> {
  reduce(state: number | undefined, action: Action): number {
    const current = state === undefined ? 0 : state
    if (action.type === 'fail') {
      throw new Error('expected reducer failure')
    }
    if (action.type === 'add') {
      return current + (action as TestAction).amount
    }
    return current
  }
}

class ListenerCounter implements StoreSubscriber {
  calls: number = 0

  onStateChanged(): void {
    this.calls += 1
  }
}

class RemovingSubscriber implements StoreSubscriber {
  calls: number = 0
  subscription?: StoreSubscription

  onStateChanged(): void {
    this.calls += 1
    if (this.subscription !== undefined) {
      this.subscription.unsubscribe()
    }
  }
}

class AddingSubscriber implements StoreSubscriber {
  calls: number = 0
  private store: Store<number, Action>
  private added: StoreSubscriber
  private didAdd: boolean = false

  constructor(store: Store<number, Action>, added: StoreSubscriber) {
    this.store = store
    this.added = added
  }

  onStateChanged(): void {
    this.calls += 1
    if (!this.didAdd) {
      this.didAdd = true
      this.store.subscribe(this.added)
    }
  }
}

class NestedDispatchSubscriber implements StoreSubscriber {
  calls: number = 0
  private store: Store<number, Action>
  private nested: boolean = false

  constructor(store: Store<number, Action>) {
    this.store = store
  }

  onStateChanged(): void {
    this.calls += 1
    if (!this.nested) {
      this.nested = true
      this.store.dispatch(new TestAction('add', 1))
    }
  }
}

class NumberObserver implements Observer<number> {
  values: number[] = []

  next(value: number): void {
    this.values.push(value)
  }
}

class TraceMiddleware implements Middleware<number> {
  private name: string
  private trace: string[]

  constructor(name: string, trace: string[]) {
    this.name = name
    this.trace = trace
  }

  dispatch(store: MiddlewareAPI<number>, next: Dispatch<Action>, action: Action): Action {
    this.trace.push(this.name + ':before:' + store.getState().toString())
    const result = next.dispatch(action)
    this.trace.push(this.name + ':after:' + store.getState().toString())
    return result
  }
}

class RecursiveMiddleware implements Middleware<number> {
  dispatch(store: MiddlewareAPI<number>, next: Dispatch<Action>, action: Action): Action {
    const result = next.dispatch(action)
    if (action.type === 'outer') {
      store.dispatch(new TestAction('add', 2))
    }
    return result
  }
}

class FixedActionCreator implements ActionCreator<Action> {
  create(args: ActionCreatorArgs): Action {
    const amount = args.values[0] as number
    return new TestAction('add', amount)
  }
}

class NumberSliceReducer implements Reducer<ReduxValue, Action, ReduxValue> {
  reduce(state: ReduxValue, action: Action): ReduxValue {
    const current = typeof state === 'number' ? state : 0
    if (action.type === 'add') {
      return current + (action as TestAction).amount
    }
    return current
  }
}

class StableStringSliceReducer implements Reducer<ReduxValue, Action, ReduxValue> {
  reduce(state: ReduxValue, action: Action): ReduxValue {
    return typeof state === 'string' ? state : 'ready'
  }
}

function assertEqual<T>(actual: T, expected: T, label: string): void {
  if (actual !== expected) {
    throw new Error(label + ': expected ' + String(expected) + ', got ' + String(actual))
  }
}

function assertTrue(value: boolean, label: string): void {
  if (!value) {
    throw new Error(label)
  }
}

function runStoreChecks(): void {
  const store = createStore<number, Action>(new CounterReducer())
  assertEqual<number>(store.getState(), 0, 'reducer initializes state')

  const action = new TestAction('add', 2)
  assertTrue(store.dispatch(action) === action, 'dispatch returns the same action')
  assertEqual<number>(store.getState(), 2, 'dispatch reduces previous state')

  store.replaceReducer(new DoubleReducer())
  assertEqual<number>(store.getState(), 2, 'replaceReducer preserves state')
  store.dispatch(new TestAction('add', 2))
  assertEqual<number>(store.getState(), 6, 'replaceReducer installs next reducer')

  const recovered = createStore<number, Action>(new FailingReducer())
  let didThrow = false
  try {
    recovered.dispatch(new TestAction('fail'))
  } catch (error) {
    didThrow = error instanceof Error
  }
  assertTrue(didThrow, 'reducer errors propagate')
  recovered.dispatch(new TestAction('add', 1))
  assertEqual<number>(recovered.getState(), 1, 'store recovers after reducer error')
}

function runSubscriptionChecks(): void {
  const store = createStore<number, Action>(new CounterReducer())
  const removing = new RemovingSubscriber()
  const retained = new ListenerCounter()
  store.subscribe(removing)
  removing.subscription = store.subscribe(retained)
  store.dispatch(new TestAction('add', 1))
  assertEqual<number>(retained.calls, 1, 'unsubscribe does not alter current snapshot')
  store.dispatch(new TestAction('add', 1))
  assertEqual<number>(retained.calls, 1, 'unsubscribe alters next snapshot')

  const added = new ListenerCounter()
  const adding = new AddingSubscriber(store, added)
  store.subscribe(adding)
  store.dispatch(new TestAction('add', 1))
  assertEqual<number>(added.calls, 0, 'subscribe does not alter current snapshot')
  store.dispatch(new TestAction('add', 1))
  assertEqual<number>(added.calls, 1, 'subscribe alters next snapshot')

  const nestedStore = createStore<number, Action>(new CounterReducer())
  const nested = new NestedDispatchSubscriber(nestedStore)
  const second = new ListenerCounter()
  nestedStore.subscribe(nested)
  nestedStore.subscribe(second)
  nestedStore.dispatch(new TestAction('add', 1))
  assertEqual<number>(nested.calls, 2, 'nested dispatch uses current snapshot')
  assertEqual<number>(second.calls, 2, 'all listeners see nested and outer dispatch')
}

function runMiddlewareChecks(): void {
  const trace: string[] = []
  const enhancer = compose<StoreCreator<number, Action>>(
    applyMiddleware<number, Action>(new TraceMiddleware('first', trace)),
    applyMiddleware<number, Action>(new TraceMiddleware('second', trace))
  )
  const store = createStore<number, Action>(new CounterReducer(), enhancer)
  store.dispatch(new TestAction('add', 1))

  assertEqual<string>(trace[0], 'first:before:0', 'compose enters first enhancer first')
  assertEqual<string>(trace[1], 'second:before:0', 'compose enters second enhancer next')
  assertEqual<string>(trace[2], 'second:after:1', 'compose leaves second enhancer first')
  assertEqual<string>(trace[3], 'first:after:1', 'compose leaves first enhancer last')

  const recursiveTrace: string[] = []
  const recursiveStore = createStore<number, Action>(
    new CounterReducer(),
    applyMiddleware<number, Action>(
      new TraceMiddleware('recursive', recursiveTrace),
      new RecursiveMiddleware()
    )
  )
  recursiveStore.dispatch(new TestAction('outer'))
  assertEqual<string>(recursiveTrace[1], 'recursive:before:0', 'recursive dispatch traverses complete chain')
  assertEqual<number>(recursiveStore.getState(), 2, 'recursive middleware dispatch updates state')
}

function runObservableChecks(): void {
  const store = createStore<number, Action>(new CounterReducer(), 4)
  const observer = new NumberObserver()
  const subscription = store.observable().subscribe(observer)
  assertEqual<number>(observer.values[0], 4, 'observable emits current state immediately')
  store.dispatch(new TestAction('add', 3))
  assertEqual<number>(observer.values[1], 7, 'observable emits state updates')
  subscription.unsubscribe()
  subscription.unsubscribe()
  store.dispatch(new TestAction('add', 1))
  assertEqual<number>(observer.values.length, 2, 'observable unsubscribe is idempotent')
}

function runUtilityChecks(): void {
  const action = new TestAction('add', 3)
  assertTrue(isAction(action), 'isAction accepts typed actions')
  assertTrue(isPlainObject(action), 'ArkTS typed action is treated as a plain action object')
  assertTrue(!isPlainObject(new Date()), 'isPlainObject rejects Date')

  const store = createStore<number, Action>(new CounterReducer())
  const creator = bindActionCreators<Action>(new FixedActionCreator(), store)
  creator.create(new ActionCreatorArgs([5]))
  assertEqual<number>(store.getState(), 5, 'bindActionCreators dispatches created action')
}

function runCombineReducerChecks(): void {
  const reducers = new ReducersMapObject<ReduxValue, Action>()
  reducers.add('count', new NumberSliceReducer())
  reducers.add('status', new StableStringSliceReducer())
  const reducer = combineReducers(reducers)
  const initial = reducer.reduce(undefined, new TestAction('init'))
  assertEqual<number>(initial.get('count') as number, 0, 'combineReducers initializes numeric slice')
  assertEqual<string>(initial.get('status') as string, 'ready', 'combineReducers initializes string slice')

  const unchanged = reducer.reduce(initial, new TestAction('noop'))
  assertTrue(unchanged === initial, 'combineReducers preserves referential equality')
  const changed = reducer.reduce(initial, new TestAction('add', 2))
  assertTrue(changed !== initial, 'combineReducers returns new state after slice change')
  assertEqual<number>(changed.get('count') as number, 2, 'combineReducers stores changed slice')

  const preloaded = new StateObject()
  preloaded.set('count', 9)
  preloaded.set('status', 'ready')
  preloaded.set('unexpected', true)
  const cleaned = reducer.reduce(preloaded, new TestAction('noop'))
  assertTrue(!cleaned.has('unexpected'), 'combineReducers removes unexpected keys')
}

export function runReduxCoreBehaviorChecks(): void {
  runStoreChecks()
  runSubscriptionChecks()
  runMiddlewareChecks()
  runObservableChecks()
  runUtilityChecks()
  runCombineReducerChecks()
}

runReduxCoreBehaviorChecks()
console.info('redux_ark core behavior checks passed')
