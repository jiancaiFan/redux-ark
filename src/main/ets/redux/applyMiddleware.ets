import { Action } from './types/actions'
import { Middleware, MiddlewareAPI } from './types/middleware'
import {
  Dispatch,
  Observable,
  Operator,
  Store,
  StoreCreator,
  StoreEnhancer,
  StoreSubscriber,
  StoreSubscription
} from './types/store'
import { Reducer } from './types/reducers'

class StoreDispatchAdapter<S, A extends Action = Action> implements Dispatch<Action> {
  private store: Store<S, A>

  constructor(store: Store<S, A>) {
    this.store = store
  }

  dispatch(action: Action): Action {
    return this.store.dispatch(action as A)
  }
}

class MiddlewareDispatchLink<S> implements Dispatch<Action> {
  private api: MiddlewareAPI<S>
  private middleware: Middleware<S>
  private next: Dispatch<Action>

  constructor(
    api: MiddlewareAPI<S>,
    middleware: Middleware<S>,
    next: Dispatch<Action>
  ) {
    this.api = api
    this.middleware = middleware
    this.next = next
  }

  dispatch(action: Action): Action {
    return this.middleware.dispatch(this.api, this.next, action)
  }
}

class MiddlewareStore<S, A extends Action = Action> implements Store<S, A>, MiddlewareAPI<S> {
  private inner: Store<S, A>
  private chain: Dispatch<Action>

  constructor(inner: Store<S, A>, middlewares: Middleware<S>[]) {
    this.inner = inner
    this.chain = new StoreDispatchAdapter<S, A>(inner)
    for (let i = middlewares.length - 1; i >= 0; i--) {
      this.chain = new MiddlewareDispatchLink<S>(this, middlewares[i], this.chain)
    }
  }

  dispatch(action: A): A {
    return this.chain.dispatch(action) as A
  }

  getState(): S {
    return this.inner.getState()
  }

  subscribe(listener: StoreSubscriber): StoreSubscription {
    return this.inner.subscribe(listener)
  }

  replaceReducer(nextReducer: Reducer<S, A>): void {
    this.inner.replaceReducer(nextReducer)
  }

  observable(): Observable<S> {
    return this.inner.observable()
  }
}

class MiddlewareStoreCreator<S, A extends Action = Action> implements StoreCreator<S, A> {
  private next: StoreCreator<S, A>
  private middlewares: Middleware<S>[]

  constructor(next: StoreCreator<S, A>, middlewares: Middleware<S>[]) {
    this.next = next
    this.middlewares = middlewares
  }

  create(reducer: Reducer<S, A>, preloadedState?: S, enhancer?: StoreEnhancer<S, A>): Store<S, A> {
    const store = this.next.create(reducer, preloadedState, enhancer)
    return new MiddlewareStore<S, A>(store, this.middlewares)
  }
}

class MiddlewareEnhancer<S, A extends Action = Action> extends Operator<StoreCreator<S, A>> {
  private middlewares: Middleware<S>[]

  constructor(middlewares: Middleware<S>[]) {
    super()
    this.middlewares = middlewares
  }

  apply(next: StoreCreator<S, A>): StoreCreator<S, A> {
    return new MiddlewareStoreCreator<S, A>(next, this.middlewares)
  }
}

export function applyMiddleware<S = Object, A extends Action = Action>(
  ...middlewares: Middleware<S>[]
): StoreEnhancer<S, A> {
  return new MiddlewareEnhancer<S, A>(middlewares)
}
