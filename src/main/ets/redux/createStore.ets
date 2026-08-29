import { Action } from './types/actions'
import { Reducer } from './types/reducers'
import {
  Observable,
  Observer,
  Operator,
  Store,
  StoreCreator,
  StoreEnhancer,
  StoreSubscriber,
  StoreSubscription,
  SubscriptionRemover
} from './types/store'
import ActionTypes from './utils/actionTypes'
import { isAction } from './utils/isAction'

class InternalAction implements Action {
  type: string

  constructor(type: string) {
    this.type = type
  }
}

class ListenerEntry {
  id: number
  listener: StoreSubscriber

  constructor(id: number, listener: StoreSubscriber) {
    this.id = id
    this.listener = listener
  }
}

class ObserverSubscriber<S, A extends Action> implements StoreSubscriber {
  private store: Store<S, A>
  private observer: Observer<S>

  constructor(store: Store<S, A>, observer: Observer<S>) {
    this.store = store
    this.observer = observer
  }

  onStateChanged(): void {
    this.observer.next(this.store.getState())
  }
}

class StoreObservable<S, A extends Action> implements Observable<S> {
  private store: Store<S, A>

  constructor(store: Store<S, A>) {
    this.store = store
  }

  subscribe(observer: Observer<S>): StoreSubscription {
    observer.next(this.store.getState())
    return this.store.subscribe(new ObserverSubscriber<S, A>(this.store, observer))
  }

  observable(): Observable<S> {
    return this
  }
}

class BasicStoreCreator<S, A extends Action = Action> implements StoreCreator<S, A> {
  create(
    reducer: Reducer<S, A>,
    preloadedState?: S,
    enhancer?: StoreEnhancer<S, A>
  ): Store<S, A> {
    if (enhancer !== undefined) {
      return enhancer.apply(this).create(reducer, preloadedState)
    }

    return new ReduxStore<S, A>(reducer, preloadedState)
  }
}

class ReduxStore<S, A extends Action = Action> implements Store<S, A>, SubscriptionRemover {
  private currentReducer: Reducer<S, A>
  private currentState: S
  private currentListeners: ListenerEntry[] = []
  private nextListeners: ListenerEntry[] = this.currentListeners
  private listenerIdCounter: number = 0
  private isDispatching: boolean = false

  constructor(reducer: Reducer<S, A>, preloadedState?: S) {
    this.currentReducer = reducer
    this.currentState = this.reduceInitialState(preloadedState)
  }

  private reduceInitialState(preloadedState?: S): S {
    try {
      this.isDispatching = true
      return this.currentReducer.reduce(preloadedState, new InternalAction(ActionTypes.INIT) as A)
    } finally {
      this.isDispatching = false
    }
  }

  private ensureCanMutateNextListeners(): void {
    if (this.nextListeners === this.currentListeners) {
      this.nextListeners = this.currentListeners.slice()
    }
  }

  getState(): S {
    if (this.isDispatching) {
      throw new Error(
        'You may not call store.getState() while the reducer is executing. ' +
          'The reducer has already received the state as an argument.'
      )
    }

    return this.currentState
  }

  subscribe(listener: StoreSubscriber): StoreSubscription {
    if (this.isDispatching) {
      throw new Error('You may not call store.subscribe() while the reducer is executing.')
    }

    this.ensureCanMutateNextListeners()
    const listenerId = this.listenerIdCounter
    this.listenerIdCounter += 1
    this.nextListeners.push(new ListenerEntry(listenerId, listener))
    return new StoreSubscription(this, listenerId)
  }

  removeSubscription(id: number): void {
    if (this.isDispatching) {
      throw new Error('You may not unsubscribe from a store listener while the reducer is executing.')
    }

    this.ensureCanMutateNextListeners()
    for (let i = 0; i < this.nextListeners.length; i++) {
      if (this.nextListeners[i].id === id) {
        this.nextListeners.splice(i, 1)
        return
      }
    }
  }

  dispatch(action: A): A {
    if (!isAction(action)) {
      throw new Error('Actions must be objects with a string type property.')
    }

    if (this.isDispatching) {
      throw new Error('Reducers may not dispatch actions.')
    }

    try {
      this.isDispatching = true
      this.currentState = this.currentReducer.reduce(this.currentState, action)
    } finally {
      this.isDispatching = false
    }

    const listeners = this.nextListeners
    this.currentListeners = listeners
    for (let i = 0; i < listeners.length; i++) {
      listeners[i].listener.onStateChanged()
    }

    return action
  }

  replaceReducer(nextReducer: Reducer<S, A>): void {
    this.currentReducer = nextReducer
    this.dispatch(new InternalAction(ActionTypes.REPLACE) as A)
  }

  observable(): Observable<S> {
    return new StoreObservable<S, A>(this)
  }
}

function createStoreInternal<S, A extends Action = Action>(
  reducer: Reducer<S, A>,
  preloadedState?: S | StoreEnhancer<S, A>,
  enhancer?: StoreEnhancer<S, A>
): Store<S, A> {
  let actualState: S | undefined = undefined
  let actualEnhancer: StoreEnhancer<S, A> | undefined = enhancer

  if (preloadedState instanceof Operator) {
    if (enhancer !== undefined) {
      throw new Error('Only one store enhancer may be supplied to createStore().')
    }
    actualEnhancer = preloadedState
  } else {
    actualState = preloadedState
  }

  return new BasicStoreCreator<S, A>().create(reducer, actualState, actualEnhancer)
}

export function createStore<S, A extends Action = Action>(
  reducer: Reducer<S, A>,
  enhancer?: StoreEnhancer<S, A>
): Store<S, A>
export function createStore<S, A extends Action = Action>(
  reducer: Reducer<S, A>,
  preloadedState?: S,
  enhancer?: StoreEnhancer<S, A>
): Store<S, A>
export function createStore<S, A extends Action = Action>(
  reducer: Reducer<S, A>,
  preloadedState?: S | StoreEnhancer<S, A>,
  enhancer?: StoreEnhancer<S, A>
): Store<S, A> {
  return createStoreInternal<S, A>(reducer, preloadedState, enhancer)
}

export function createConcurrentStore<S, A extends Action = Action>(
  reducer: Reducer<S, A>,
  enhancer?: StoreEnhancer<S, A>
): Store<S, A>
export function createConcurrentStore<S, A extends Action = Action>(
  reducer: Reducer<S, A>,
  preloadedState?: S,
  enhancer?: StoreEnhancer<S, A>
): Store<S, A>
export function createConcurrentStore<S, A extends Action = Action>(
  reducer: Reducer<S, A>,
  preloadedState?: S | StoreEnhancer<S, A>,
  enhancer?: StoreEnhancer<S, A>
): Store<S, A> {
  return createStoreInternal<S, A>(reducer, preloadedState, enhancer)
}
